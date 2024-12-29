local MaterialService = game:GetService("MaterialService")
local Players = game:GetService("Players")
local AmmoBox = require(script.Parent.AmmoBox)
local EventStrings = require(script.Parent.EventStrings)
local Item = require(script.Parent.Item)
local Map = require(script.Parent.Map)
local Participant = require(script.Parent.Participant)
local Prop = require(script.Parent.Prop)
local Role = require(script.Parent.Role)
local Types = require(script.Parent.Types)
local module = {}

local data = script.Parent.ReplicatedData
local remotes = script.Parent.Remotes

local HIGHLIGHTS_TIME = 5
local PREPARING_TIME = 5

local currentMap: Types.Map?

local function IsPreGame(round: Types.Round): boolean
    return round:GetRoundPhase() == "Waiting" or round:GetRoundPhase() == "Preparing"
end

local function IsInProgress(round: Types.Round): boolean
    return round:GetRoundPhase() == "Playing"
end

local function IsPostGame(round: Types.Round): boolean
    return round:GetRoundPhase() == "Highlights" or round:GetRoundPhase() == "Intermission"
end

local function GetParticipant(round: Types.Round, name: string): Types.Participant?
    return round._participants[name]
end

local function GetParticipants(round: Types.Round): {[string]: Types.Participant?}
    return round._participants
end

local function spawnParticipant(participant: Types.Participant)
    local round = participant.Round

    participant:_setStatus("Alive")

    for _, v in round.Gamemode.StartingItems do
        participant:AddItem(Item.new(v))
    end

    local count = 0
    for _, v in round:GetParticipants() do
        assert(v)
        if v:GetStatus() ~= "Spectating" then
            count += 1
            if count == round.Gamemode.MinimumPlayers then
                round:SetRoundPhase("Preparing", PREPARING_TIME)
                break
            end
        end
    end

    participant:SpawnCharacter()
end

local function AddPlayer(round: Types.Round, player: Player, addAsSpectator: boolean?): Types.Participant
    if round:GetRoundPhase() ~= "Waiting" and round:GetRoundPhase() ~= "Preparing" then
        error("Round is not in Waiting or Preparing phase")
    end

    local existingParticipant = round:GetParticipant(player.Name)
    if existingParticipant then
        if existingParticipant:GetStatus() == "Spectating" then
            assert(not addAsSpectator, "Participant already exists as spectator")
            spawnParticipant(existingParticipant)
            return existingParticipant
        else
            error("Participant already exists")
        end
    end

    local participant = Participant.new(player, round)
    round._participants[player.Name] = participant

    if not addAsSpectator then
        
    else
        participant:_setStatus("Spectating")
    end

    player.Destroying:Once(function()
        round:RemoveParticipant(participant)
    end)

    return participant
end

local function RemoveParticipant(round: Types.Round, participant: Types.Participant): ()
    round._participants[participant.Player.Name] = nil

    local role = participant:GetRole()
    if role and role.Definition.ShouldAnnounceDisconnect then
        round:SendMessage(Players:GetPlayers(), `{participant:GetFormattedName()} has disconnected. They were a {role:GetFormattedName()}{role:GetExclamatoryString()}`)
    end

    participant:UnspawnCharacter()
    round.Gamemode:OnDeath(participant)

    local count = 0
    for _ in round:GetParticipants() do
        count += 1
    end

    if count < round.Gamemode.MinimumPlayers then
        round:SetRoundPhase("Waiting", math.huge)
    end
end

local function GetRoundPhase(round: Types.Round): Types.RoundPhase
    return round._roundPhase
end

local function SetRoundPhase(round: Types.Round, phase: Types.RoundPhase, duration: number): ()
    round._roundPhase = phase

    local callback: Types.RoundAdvanceCallback | false
    if phase == "Waiting" then
        callback = false
    elseif phase == "Preparing" then
        callback = round.StartRound
    elseif phase == "Playing" then
        callback = function(round: Types.Round): ()
            local victors = round.Gamemode:TimeoutVictor(round)
            round:EndRound(victors)
        end
    elseif phase == "Highlights" then
        callback = function(round: Types.Round): ()
            round:SetRoundPhase("Intermission", 0)
        end
    elseif phase == "Intermission" then
        callback = false
    end

    data:SetAttribute("Phase", phase)

    round:SetAdvanceTime(workspace:GetServerTimeNow() + duration, callback or false)
end

local function SetAdvanceTime(round: Types.Round, finishTime: number, callback: false | "preserve" | Types.RoundAdvanceCallback): ()
    if round._activeAdvanceThread then
        coroutine.close(round._activeAdvanceThread)
    end

    if callback == "preserve" then
        round._lastAdvanceCallback = round._lastAdvanceCallback or function() end
	elseif callback == false then
		round._lastAdvanceCallback = function() end
    else
        round._lastAdvanceCallback = callback
    end

    data:SetAttribute("AdvanceTime", finishTime)

    round._activeAdvanceThread = coroutine.wrap(function()
        while workspace:GetServerTimeNow() < finishTime do
            task.wait()
        end
		
        assert(round._lastAdvanceCallback)(round)
    end)()
end

local function AddEvent(round: Types.Round, data: Types.RoundEventData): ()
    table.insert(round._eventLog, {
        Timestamp = workspace:GetServerTimeNow(),
        Data = data,
    })
end

local function GetEventLog(round: Types.Round): {Types.RoundEvent}
    return round._eventLog
end

local function GetIsRoundPaused(round: Types.Round): boolean
    return round._isPaused
end

local function PauseRound(round: Types.Round, paused: boolean): ()
    round._isPaused = paused

    data:SetAttribute("Paused", paused)
end

local function StartRound(round: Types.Round): ()
    assert(round:IsPreGame(), "Round is not in PreGame phase")

    local participantList = {}
    for _, v in round:GetParticipants() do
        assert(v)
        table.insert(participantList, v)
    end

    assert(#participantList >= round.Gamemode.MinimumPlayers, "Not enough players to start round")

    for _, v in round:GetParticipants() do
        assert(v)
        while not v:GetCharacter() and v.Player:IsDescendantOf(Players) do
            task.wait()
        end
    end

    round:AddEvent({
        Kind = "StartRoundEvent",
    })

    round:SetRoundPhase("Playing", round.Gamemode.Duration(#participantList))

    Random.new():Shuffle(participantList)
    round.Gamemode:AssignRoles(participantList)
end

local function EndRound(round: Types.Round, victor: Types.Victor): ()
    assert(round:IsInProgress(), "Round is not in Playing phase")

    local role: Types.Role
    if victor.Kind == "Role" then
        role = victor
    elseif victor.Kind == "Participant" then
        role = victor:GetRole() or error("Winning Participant has no assigned role")
    end

    local victorRole: Types.Role
    if role.Definition.Allegiance.Kind == "Role" then
        victorRole = round:GetRoleFromRoleName(role.Definition.Allegiance.Role)
    elseif role.Definition.Allegiance.Kind == "Solo" then
        victorRole = role
    end

    assert(victorRole.Definition.VictoryText, "Victory role has no VictoryText")

    round:AddEvent({
        Kind = "EndRoundEvent",
        VictoryText = victorRole.Definition.VictoryText,
    })
    round:SetRoundPhase("Highlights", HIGHLIGHTS_TIME)

    data.Events:ClearAllChildren()
    data.Highlights:ClearAllChildren()
    for _, v in round:GetEventLog() do
        local value = Instance.new("StringValue")
        value.Name = tostring(v.Timestamp)
        value.Value = EventStrings(v)
    end

    remotes.RoundHighlights:FireAllClients()
end

local function GetProps(round: Types.Round): {[Types.DataModelProp]: Types.Prop?}
    return round._props
end

local function GetProp(round: Types.Round, model: Types.DataModelProp): Types.Prop?
    return round._props[model]
end

local function LoadProp(round: Types.Round, model: Types.DataModelProp): Types.Prop
    assert(not round:GetProp(model), "Prop already exists")
    local prop = Prop.new(model)
    round._props[model] = prop
    return prop
end

local function GetItems(round: Types.Round): {[Types.DataModelItem]: Types.AnyItem?}
    return round._items
end

local function GetItem(round: Types.Round, model: Types.DataModelItem): Types.AnyItem?
    return round._items[model]
end

local function LoadItem(round: Types.Round, map: Types.Map, model: Types.DataModelItem): Types.AnyItem
    assert(not round:GetItem(model), "Item already exists")

    local itemDefinition = round:GetItemDefinition(model.Name) or error(`Item {model.Name} does not exist in map or gamemode`)

    local item = Item.new(itemDefinition, model)
    round._items[model] = item

    model.Touched:Connect(function(touchPart)
        local touchModel = touchPart:FindFirstAncestorOfClass("Model")

        if not touchModel then
            return
        end

        local participant = round:GetParticipant(touchModel.Name)
        if not participant or not participant:IsAlive() then
            return
        end

        if item.Definition.Slot and participant:IsItemSlotOccupied(item.Definition.Slot) then
            return
        end

        model.Parent = nil
        participant:AddItem(item)
    end)

    return item
end

local function GetAmmoBoxes(round: Types.Round): {[Types.DataModelItem]: Types.AmmoBox?}
    return round._ammoBoxes
end

local function GetAmmoBox(round: Types.Round, model: Types.DataModelItem): Types.AmmoBox?
    return round._ammoBoxes[model]
end

local function LoadAmmoBox(round: Types.Round, map: Types.Map, model: Types.DataModelItem): Types.AmmoBox
    assert(not round:GetAmmoBox(model), "AmmoBox already exists")

    local definition = round:GetAmmoDefinition(model.Name) or error(`AmmoBox {model.Name} does not exist in map or gamemode`)
    local ammoBox = AmmoBox.new(definition, model)
    round._ammoBoxes[model] = ammoBox

    model.Touched:Connect(function(touchPart)
        local touchModel = touchPart:FindFirstAncestorOfClass("Model")

        if not touchModel then
            return
        end

        local participant = round:GetParticipant(touchModel.Name)
        if not participant or not participant:IsAlive() or not participant:HasWeaponOfAmmoType(model.Name) then
            return
        end

        local currentAmmo = participant:GetAmmo(model.Name)

        local maxGain = math.min(ammoBox.Definition.ReserveCapacity - currentAmmo, ammoBox.Ammo)
        if maxGain <= 0 then
            return
        end

        ammoBox.Ammo -= maxGain
        participant:SetAmmo(model.Name, currentAmmo + maxGain)

        if ammoBox.Ammo <= 0 then
            model:Destroy()
        end
    end)

    return ammoBox
end

local function GetRoleFromRoleName(round: Types.Round, name: string): Types.Role
    return round._roles[name] or error("Unknown role: " .. name)
end

local function GetParticipantsWithRole(round: Types.Round, role: Types.Role): {Types.Participant}
    local participants = {}
    
    for _, v in round:GetParticipants() do
        assert(v)
        table.insert(participants, v)
    end

    return participants
end

local function GetMap(round: Types.Round): Types.Map
    return round._map or error("Round has no map")
end

local function GetAmmoDefinition(round: Types.Round, ammo: string): Types.AmmoDefinition?
    return round:GetMap().AvailableAmmo[ammo] or round.Gamemode.AvailableAmmo[ammo]
end

local function GetItemDefinition(round: Types.Round, item: string): Types.AnyItemDefinition?
    return round:GetMap().AvailableItems[item] or round.Gamemode.AvailableItems[item]
end

local function loadProps(round: Types.Round, map: Types.Map): ()
    if not map.Props then
        return
    end

    for _, v in map.Props:GetChildren() do
        if v:IsA("BasePart") then
            round:LoadProp(v)
        elseif v:IsA("Folder") then
            loadProps(round, map)
        end
    end
end

local function loadItems(round: Types.Round, map: Types.Map): ()
    if not map.ItemSpawns then
        return
    end

    for _, v in map.ItemSpawns:GetChildren() do
        if v:IsA("BasePart") then
            round:LoadItem(map, v)
        elseif v:IsA("Folder") then
            loadItems(round, map)
        end
    end
end

local function loadAmmoBoxes(round: Types.Round, map: Types.Map): ()
    if not map.AmmoSpawns then
        return
    end

    for _, v in map.AmmoSpawns:GetChildren() do
        if v:IsA("BasePart") then
            round:LoadAmmoBox(map, v)
        elseif v:IsA("Folder") then
            loadAmmoBoxes(round, map)
        end
    end
end

local function LoadMap(round: Types.Round, mapScript: ModuleScript): ()
    mapScript = mapScript:Clone()
    local map = Map.fromModuleScript(mapScript)

    local lastMap: Types.Map?

    local lastMapScript = workspace:FindFirstChild("Map")
    if lastMapScript then
        assert(lastMapScript:IsA("ModuleScript"), "Invalid Map in Workspace")

        lastMap = Map.fromModuleScript(lastMapScript)
    end

    if not lastMap or lastMap and lastMap.Name ~= map.Name then
        if lastMapScript then
            lastMapScript:Destroy()
        end

        local lastMapMaterialVariants = MaterialService:FindFirstChild("MapMaterialVariants")
        if lastMapMaterialVariants then
            lastMapMaterialVariants:Destroy()
        end

        workspace.Gravity = map.Gravity

        for i, v in map.WaterSettings do
            (workspace.Terrain :: any)[i] = v
        end

        for i, v in map.TerrainColors do
            workspace.Terrain:SetMaterialColor((Enum.Material :: any)[i], v)
        end

        workspace.Terrain:Clear()
        if map.TerrainRegion then
            workspace.Terrain:PasteRegion(map.TerrainRegion, Vector3int16.new(-32000, -32000, -32000), true)
        end

        local materialVariants = map.MaterialVariants:Clone()
        materialVariants.Name = "MapMaterialVariants"
        materialVariants.Parent = MaterialService

        mapScript.Name = "Map"
        mapScript.Parent = workspace
    elseif lastMap then
        lastMap.DynamicMap:Destroy()
        lastMap.Props:Destroy()
        lastMap.Windows:Destroy()
        lastMap.ItemSpawns:Destroy()
        lastMap.AmmoSpawns:Destroy()

        map.DynamicMap.Parent = lastMapScript
        map.Props.Parent = lastMapScript
        map.Windows.Parent = lastMapScript
        map.ItemSpawns.Parent = lastMapScript
        map.AmmoSpawns.Parent = lastMapScript
    end

    round._map = map -- Must be done here otherwise we fail to load everything below

    loadProps(round, map)
    loadItems(round, map)
    loadAmmoBoxes(round, map)

    currentMap = map
    assert(currentMap)
end

local function GetExclamatoryString(role: Types.RoleDefinition): string
    return if role.IsExclamatory then "!" else "."
end

local function SendMessage(round: Types.Round, to: {Player} | Player, message: string): ()
    if typeof(to) == "Instance" then
        to = {to}
    end

    for _, v in to :: {Player} do
        remotes.SendMessage:FireClient(v, message)
    end
end

function module.new(gamemode: Types.Gamemode): Types.Round
    local roles: {[string]: Types.Role} = {}
    for _, v in gamemode.Roles do
        roles[v.Name] = Role.fromDefinition(v)
    end

    local round: Types.Round = {
        Gamemode = gamemode,

        LoadMap = LoadMap,
        GetMap = GetMap,

        _participants = {},
        _roundPhase = "Waiting",
        _isPaused = false,

        _eventLog = {},
        _props = {},

        _roles = roles,

        _items = {},
        GetItems = GetItems,
        GetItem = GetItem,
        LoadItem = LoadItem,

        GetAmmoDefinition = GetAmmoDefinition,
        GetItemDefinition = GetItemDefinition,

        IsPreGame = IsPreGame,
        IsPostGame = IsPostGame,
        IsInProgress = IsInProgress,

        _ammoBoxes = {},
        GetAmmoBoxes = GetAmmoBoxes,
        GetAmmoBox = GetAmmoBox,
        LoadAmmoBox = LoadAmmoBox,

        AddEvent = AddEvent,
        GetEventLog = GetEventLog,

        GetExclamatoryString = GetExclamatoryString,

        GetParticipant = GetParticipant,
        GetParticipants = GetParticipants,
        AddPlayer = AddPlayer,
        RemoveParticipant = RemoveParticipant,
        GetRoundPhase = GetRoundPhase,
        SetRoundPhase = SetRoundPhase,
        SetAdvanceTime = SetAdvanceTime,
        GetIsRoundPaused = GetIsRoundPaused,
        PauseRound = PauseRound,
        StartRound = StartRound,
        EndRound = EndRound,
        GetRoleFromRoleName = GetRoleFromRoleName,
        GetParticipantsWithRole = GetParticipantsWithRole,

        GetProps = GetProps,
        GetProp = GetProp,
        LoadProp = LoadProp,

        SendMessage = SendMessage,
    }

    data:SetAttribute("Phase", round:GetRoundPhase())
    data:SetAttribute("Paused", round:GetIsRoundPaused())
    data:SetAttribute("AdvanceTime", nil)
    data:SetAttribute("Gamemode", gamemode.Name)

    return round
end

return module