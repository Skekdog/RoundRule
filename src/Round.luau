local MaterialService = game:GetService("MaterialService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local AmmoBox = require(script.Parent.AmmoBox)
local Item = require(script.Parent.Item)
local Map = require(script.Parent.Map)
local Participant = require(script.Parent.Participant)
local Prop = require(script.Parent.MapProp)
local Replication = require(script.Parent.Replication)
local Role = require(script.Parent.Role)
local Types = require(script.Parent.Types)
local module = {}

-- We can get away with this, because if a property is not known, that means no map has overriden it, meaning it's still the default.
local knownWaterSettings: {string} = {}
local knownTerrainColours: {[Enum.Material]: Color3} = {}

local HIGHLIGHTS_TIME = 20
local PREPARING_TIME = 20

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
        spawnParticipant(participant)
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
        round:SendMessage(Players:GetPlayers(), `{participant:GetFormattedName()} has disconnected. They were a {role:GetFormattedRoleName()}{role:GetExclamatoryString()}`)
    end

    local count = 0
    for _ in round:GetParticipants() do
        count += 1
    end

    if count > 0 and participant:IsAlive() then -- check count so that error doesn't get thrown when last person disconnects
        participant:UnspawnCharacter()

        if round:IsInProgress() then
            round.Gamemode:OnDeath(participant, false)
        end
    end

    if count < round.Gamemode.MinimumPlayers and round:IsPreGame() then
        round:SetRoundPhase("Waiting", math.huge)
    end
end

local function GetRoundPhase(round: Types.Round): Types.RoundPhase
    return round._roundPhase
end

local function destroyRound(round: Types.Round): ()
    for _, v in round:GetParticipants() do
        assert(v)
        v:SetRole(nil)
        v:_setStatus("Spectating")
        v:UnspawnCharacter()
    end
end

local function setAdvanceTime(round: Types.Round, duration: number, callback: () -> ()): ()
    Replication.ReplicateAdvanceTime(duration + workspace:GetServerTimeNow())

    if round._heartbeat then
        round._heartbeat:Disconnect()
    end

    local wasPaused = false

    local elapsedTime = 0
    round._heartbeat = RunService.Heartbeat:Connect(function(dt)
        if round:GetIsRoundPaused() then
            wasPaused = true
            return
        end
        
        if wasPaused then
            wasPaused = false
            Replication.ReplicateAdvanceTime((duration - elapsedTime) + workspace:GetServerTimeNow())
        end

        elapsedTime += dt

        if elapsedTime >= duration then
            assert(round._heartbeat):Disconnect()
            callback()
        end
    end)
end

local function SetRoundPhase(round: Types.Round, phase: Types.RoundPhase, duration: number): ()
    round._roundPhase = phase

    local callback: (() -> ()) | false
    if phase == "Waiting" then
        callback = false
    elseif phase == "Preparing" then
        callback = function()
            round:StartRound()
        end
    elseif phase == "Playing" then
        callback = function(): ()
            local victors = round.Gamemode:TimeoutVictor(round)
            round:EndRound(victors, true)
        end
    elseif phase == "Highlights" then
        callback = function(): ()
            round:SetRoundPhase("Intermission", 0)
            destroyRound(round)
        end
    elseif phase == "Intermission" then
        callback = false
    end

    Replication.ReplicateRoundPhase(phase)

    setAdvanceTime(round, duration, callback or function() end)
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
    Replication.ReplicateRoundPause(paused)
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

    Replication.ReplicateStartTime(workspace:GetServerTimeNow())
    round:SetRoundPhase("Playing", round.Gamemode.Duration(#participantList))

    Random.new():Shuffle(participantList)
    round.Gamemode:AssignRoles(participantList)
end

local function EndRound(round: Types.Round, victor: Types.Victor, isTimeout: boolean?): ()
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
    
    Replication.ClearEvents()
    Replication.ClearHighlights()
    Replication.ClearScores()
    for _, v in round:GetEventLog() do
        Replication.AddEvent(v)
    end

    for _, v in round:GetParticipants() do
        assert(v)
        Replication.AddScore(v)
        Replication.ReplicateRole("All", v, false)
        Replication.ReplicatePlayerStatus("All", v, v:GetStatus())
    end

    local possibleMusic: {Sound}
    if isTimeout and round.Gamemode.TimeoutMusic then
        possibleMusic = round.Gamemode.TimeoutMusic
    else
        possibleMusic = victorRole.Definition.VictoryMusic or {}
    end
    local chosenMusic = if #possibleMusic > 0 then possibleMusic[math.random(#possibleMusic)] else nil -- note: math.random(0) errors
    if chosenMusic then
        chosenMusic = chosenMusic:Clone()
        chosenMusic:SetAttribute("IsRoundVictoryMusic", true)
        chosenMusic.Parent = SoundService

        chosenMusic.Ended:Once(function()
            chosenMusic:Destroy()
        end)

        chosenMusic:Play()
    end

    Replication.ReplicateWinner(victor)
    round:SetRoundPhase("Highlights", HIGHLIGHTS_TIME)
end

local function GetProps(round: Types.Round): {[Types.DataModelProp]: Types.Prop?}
    return round._props
end

local function GetProp(round: Types.Round, model: Types.DataModelProp): Types.Prop?
    return round._props[model]
end

local function loadMapProp(round: Types.Round, model: Types.DataModelMapProp): Types.MapProp
    local prop = Prop.new(model, round)
    return prop
end

local function loadItem(round: Types.Round, model: Types.DataModelItem): Types.ItemProp
    local itemDefinition = round:GetItemDefinition(model.Name) or error(`Item {model.Name} does not exist in map or gamemode`)

    local item = Item.new(itemDefinition, model)
    round._items[model] = item
    
    model:SetAttribute("AmmoType", if item.Kind == "Gun" then item.Definition.AmmoType.Name else nil)
    model:SetAttribute("StoredAmmo", if item.Kind == "Gun" then item.Ammo else nil)
    model.CollisionGroup = "DroppedItems"

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

    return {
        Kind = "ItemProp",
        Model = model,
        Item = item,
    }
end

local function loadAmmoBox(round: Types.Round, model: Types.DataModelAmmo): Types.AmmoProp
    local definition = round:GetAmmoDefinition(model.Name) or error(`AmmoBox {model.Name} does not exist in map or gamemode`)
    local ammoBox = AmmoBox.new(definition, model)
    round._ammoBoxes[model] = ammoBox

    model:SetAttribute("AmmoType", ammoBox.Definition.Name)
    model:SetAttribute("StoredAmmo", ammoBox.Ammo)
    model.CollisionGroup = "DroppedItems"

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
            return model:Destroy()
        end

        model:SetAttribute("StoredAmmo", ammoBox.Ammo)
    end)

    return {
        Kind = "AmmoProp",
        Model = model,
        AmmoBox = ammoBox,
    }
end

local function loadCorpse(round: Types.Round, model: Types.DataModelCorpse): Types.CorpseProp
    local participant = round:GetParticipant(model.Name)
    assert(participant, "Participant does not exist")

    return {
        Kind = "CorpseProp",
        Model = model,
        Participant = participant,
    }
end

local function LoadProp(round: Types.Round, model: Types.DataModelProp, kind: "MapProp" | "CorpseProp" | "ItemProp" | "AmmoProp"): Types.Prop
    assert(not round:GetProp(model), "Prop already exists")

    local prop: Types.Prop?
    if kind == "MapProp" then
        assert(model:IsA("BasePart"), "MapProp must be a BasePart")
        prop = loadMapProp(round, model)
    elseif kind == "CorpseProp" then
        assert(model:IsA("Model"), "CorpseProp must be a Model")
        prop = loadCorpse(round, model)
    elseif kind == "ItemProp" then
        assert(model:IsA("BasePart"), "ItemProp must be a BasePart")
        prop = loadItem(round, model)
    elseif kind == "AmmoProp" then
        assert(model:IsA("BasePart"), "AmmoProp must be a BasePart")
        prop = loadAmmoBox(round, model)
    end

    assert(prop, "Invalid prop type")

    round._props[model] = prop
    return prop
end

local function GetItems(round: Types.Round): {[Types.DataModelItem]: Types.AnyItem?}
    return round._items
end

local function GetItem(round: Types.Round, model: Types.DataModelItem): Types.AnyItem?
    return round._items[model]
end

local function GetAmmoBoxes(round: Types.Round): {[Types.DataModelItem]: Types.AmmoBox?}
    return round._ammoBoxes
end

local function GetAmmoBox(round: Types.Round, model: Types.DataModelItem): Types.AmmoBox?
    return round._ammoBoxes[model]
end

local function loadBound(round: Types.Round, bound: Types.Bound): ()
    bound.CollisionGroup = "Bounds"
    
    local onTouch = bound:FindFirstChild("OnTouch")
    if onTouch then
        assert(onTouch:IsA("ModuleScript"), "Invalid OnTouch in Bound")
        
        bound.Touched:Connect(function(touchPart)
            local touchModel = touchPart:FindFirstAncestorOfClass("Model")

            if not touchModel then
                return
            end
    
            local participant = round:GetParticipant(touchModel.Name)
            if not participant or not participant:IsAlive() then
                return
            end

            (require)(onTouch)(bound, participant)
        end)
    end
end

local function GetRoleFromRoleName(round: Types.Round, name: string): Types.Role
    return round._roles[name] or error("Unknown role: " .. name)
end

local function GetParticipantsWithRole(round: Types.Round, role: Types.Role): {Types.Participant}
    local participants = {}
    
    for _, v in round:GetParticipants() do
        assert(v)
        if v:GetRole() == role then
            table.insert(participants, v)
        end
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
            round:LoadProp(v, "MapProp")
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
            round:LoadProp(v, "ItemProp")
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
            round:LoadProp(v, "AmmoProp")
        elseif v:IsA("Folder") then
            loadAmmoBoxes(round, map)
        end
    end
end

local function loadBounds(round: Types.Round, map: Types.Map): ()
    for _, v in map.Bounds:GetDescendants() do
        if v:IsA("BasePart") then
            loadBound(round, v)
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

        for _, v in knownWaterSettings do
            workspace.Terrain:ResetPropertyToDefault(v)
        end

        for i, v in map.WaterSettings do
            if not table.find(knownWaterSettings, i) then
                table.insert(knownWaterSettings, v)
            end
            (workspace.Terrain :: any)[i] = v
        end

        for i, v in knownTerrainColours do
            workspace.Terrain:SetMaterialColor(i, v)
        end

        for i, v in map.TerrainColors do
            local material = (Enum.Material :: any)[i]
            if not knownTerrainColours[material] then
                knownTerrainColours[material] = workspace.Terrain:GetMaterialColor(material)
            end
            workspace.Terrain:SetMaterialColor(material, v)
        end

        workspace.Terrain:Clear()
        workspace.Terrain:PasteRegion(map.TerrainRegion, Vector3int16.new(-32000, -32000, -32000), true)

        local materialVariants = map.MaterialVariants:Clone()
        materialVariants.Name = "MapMaterialVariants"
        materialVariants.Parent = MaterialService

        loadBounds(round, map)

        mapScript.Name = "Map"
        mapScript.Parent = workspace
    elseif lastMap then
        lastMap.DynamicMap:Destroy()
        lastMap.Props:Destroy()
        lastMap.Windows:Destroy()
        lastMap.ItemSpawns:Destroy()
        lastMap.AmmoSpawns:Destroy()
        lastMap.InteractableObjects:Destroy()

        map.DynamicMap.Parent = lastMapScript
        map.Props.Parent = lastMapScript
        map.Windows.Parent = lastMapScript
        map.ItemSpawns.Parent = lastMapScript
        map.AmmoSpawns.Parent = lastMapScript
        map.InteractableObjects.Parent = lastMapScript
    end

    round._map = map -- Must be done here otherwise we fail to load everything below

    loadProps(round, map)
    loadItems(round, map)
    loadAmmoBoxes(round, map)

    for _, v in round:GetParticipants() do
        assert(v)
        v:MoveToSpawn()
    end

    currentMap = map
    assert(currentMap)

    Replication.ReplicateMap()
end

local function GetExclamatoryString(role: Types.RoleDefinition): string
    return if role.IsExclamatory then "!" else "."
end

local function SendMessage(round: Types.Round, to: {Player} | Player, message: string, kind: Types.MessageKind?): ()
    if typeof(to) == "Instance" then
        to = {to}
    end

    for _, v in to :: {Player} do
        Replication.SendMessage(v, message, kind)
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

        GetAmmoDefinition = GetAmmoDefinition,
        GetItemDefinition = GetItemDefinition,

        IsPreGame = IsPreGame,
        IsPostGame = IsPostGame,
        IsInProgress = IsInProgress,

        _ammoBoxes = {},
        GetAmmoBoxes = GetAmmoBoxes,
        GetAmmoBox = GetAmmoBox,

        AddEvent = AddEvent,
        GetEventLog = GetEventLog,

        GetExclamatoryString = GetExclamatoryString,

        GetParticipant = GetParticipant,
        GetParticipants = GetParticipants,
        AddPlayer = AddPlayer,
        RemoveParticipant = RemoveParticipant,
        GetRoundPhase = GetRoundPhase,
        SetRoundPhase = SetRoundPhase,
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

    Replication.ReplicateRoundPhase(round:GetRoundPhase())
    Replication.ReplicateRoundPause(round:GetIsRoundPaused())
    Replication.ReplicateGamemode(gamemode)

    Replication.Reset()

    for _, v in SoundService:GetChildren() do
        if v:GetAttribute("IsRoundVictoryMusic") then
            v:Destroy()
        end
    end

    return round
end

return module