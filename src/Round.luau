local Players = game:GetService("Players")
local Item = require(script.Parent.Item)
local Participant = require(script.Parent.Participant)
local Prop = require(script.Parent.Prop)
local Types = require(script.Parent.Types)
local module = {}

local data = script.Parent.ReplicatedData

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

local function GetParticipants(round: Types.Round): index<Types.Round, "_participants">
    return round._participants
end

local function AddPlayer(round: Types.Round, player: Player): Types.Participant
    if round:GetRoundPhase() ~= "Waiting" and round:GetRoundPhase() ~= "Preparing" then
        error("Round is not in Waiting or Preparing phase")
    end

    assert(not round._participants[player.Name], "Participant already exists")

    local participant = Participant.new(player, round)
    round._participants[player.Name] = participant

    for _, v in round.Gamemode.StartingItems do
        participant:AddItem(Item.new(v))
    end

    local count = 0
    for _ in round:GetParticipants() do
        count += 1
        if count == round.Gamemode.MinimumPlayers then
            round:SetRoundPhase("Preparing", PREPARING_TIME)
            break
        end
    end

    participant:SpawnCharacter()

    player.Destroying:Once(function()
        round:RemoveParticipant(participant)
    end)

    return participant
end

local function RemoveParticipant(round: Types.Round, participant: Types.Participant): ()
    round._participants[participant.Player.Name] = nil

    local role = participant:GetRole()
    if role and role.ShouldAnnounceDisconnect then
        print(participant:GetFormattedName() .. " has disconnected. They were a " .. role.Name .. ".")
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

    round:SetAdvanceTime(workspace:GetServerTimeNow() + duration, callback or (false :: false))
end

local function SetAdvanceTime(round: Types.Round, finishTime: number, callback: false | "preserve" | Types.RoundAdvanceCallback): ()
    if round._activeAdvanceThread then
        coroutine.close(round._activeAdvanceThread)
    end

    if callback == "preserve" then
        callback = round._lastAdvanceCallback or function() end
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

        assert(typeof(callback) == "function")
		
    	callback(round)
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
    assert(#round:GetParticipants() >= round.Gamemode.MinimumPlayers, "Not enough players to start round")

    round = round :: Types.Round -- more type refinement nonsense

    for _, v in round:GetParticipants() do
        assert(v)
        while not v:GetCharacter() and v.Player:IsDescendantOf(Players) do
            task.wait()
        end
    end

    round:AddEvent({
        Kind = "StartRoundEvent",
    })

    local participantList = {}
    for _, v in round:GetParticipants() do
        table.insert(participantList, v)
    end

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
    if role.Allegiance.Kind == "Role" then
        victorRole = round:GetRoleFromRoleName(role.Allegiance.Role)
    elseif role.Allegiance.Kind == "Solo" then
        victorRole = role :: Types.Role
    end

    assert(victorRole.VictoryText, "Victory role has no VictoryText")

    round:AddEvent({
        Kind = "EndRoundEvent",
        VictoryText = victorRole.VictoryText :: string,
    })
    round:SetRoundPhase("Highlights", HIGHLIGHTS_TIME)
end

local function GetProps(round: Types.Round): index<Types.Round, "_props">
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

local function GetItems(round: Types.Round): index<Types.Round, "_items">
    return round._items
end

local function GetItem(round: Types.Round, model: Types.DataModelItem): Types.AnyItem?
    return round._items[model]
end

local function LoadItem(round: Types.Round, map: Types.Map, model: Types.DataModelItem): Types.AnyItem
    assert(not round:GetItem(model), "Item already exists")

    local itemDefinition = map.AvailableItems[model.Name] or round.Gamemode.AvailableItems[model.Name]
    assert(itemDefinition, "Item does not exist in map or gamemode")

    local item = Item.new(itemDefinition)
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

        model.Parent = nil
        participant:AddItem(item)
    end)

    return item
end

local function GetRoleFromRoleName(round: Types.Round, name: string): Types.Role
    return round.Gamemode.Roles[name] or error("Unknown role: " .. name)
end

local function GetParticipantsWithRole(round: Types.Round, role: Types.Role): {Types.Participant}
    local participants = {}
    
    for _, v in round:GetParticipants() do
        table.insert(participants, v)
    end

    return participants
end

local function GetFormattedRoleName(role: Types.Role): string
    return `<font color='#{role.Color:ToHex()}'>#{role.Name}</font>`
end

local function IsRoleAlliedWithRole(role1: Types.Role, role2: Types.Role): boolean
    return table.find(role1.Allies or {} :: {string}, role2.Name) ~= nil
end

local function GetMap(round: Types.Round): Types.Map
    return round._map or error("Round has no map")
end

local function tryResetDynamicMapObject(mapFolder: Folder, map: Types.Map, name: keyof<Types.Map>): ()
    local old = mapFolder:FindFirstChild(name)
    if old then
        old:Destroy()
    end

    if (map :: any)[name] then
        (map :: any)[name].Parent = mapFolder
    end
end

local function tryClone(folder: Folder?): Folder?
    return if folder then folder:Clone() else nil
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

local function LoadMap(round: Types.Round, map: Types.Map): ()
    local mapFolder = workspace:FindFirstChild("MapFolder") or Instance.new("Folder", workspace)
    assert(mapFolder:IsA("Folder"), "MapFolder is not a Folder")

    mapFolder.Name = "MapFolder"

    map = table.clone(map)

    map.DynamicMap = tryClone(map.DynamicMap)
    map.Props = tryClone(map.Props)
    map.Windows = tryClone(map.Windows)
    map.ItemSpawns = tryClone(map.ItemSpawns)

    if currentMap ~= map then
        local oldStaticMap = mapFolder:FindFirstChild("StaticMap")
        if oldStaticMap then
            oldStaticMap.Parent = nil
        end

        local oldBounds = mapFolder:FindFirstChild("Bounds")
        if oldBounds then
            oldBounds.Parent = nil
        end

        local oldPlayerSpawns = mapFolder:FindFirstChild("PlayerSpawns")
        if oldPlayerSpawns then
            oldPlayerSpawns.Parent = nil
        end

        local oldFIBLighting = mapFolder:FindFirstChild("FutureLightingSettings")
        if oldFIBLighting then
            oldFIBLighting.Parent = nil
        end

        local oldLighting = mapFolder:FindFirstChild("LightingSettings")
        if oldLighting then
            oldLighting.Parent = nil
        end

        local oldMaterialVariants = mapFolder:FindFirstChild("MaterialVariants")
        if oldMaterialVariants then
            oldMaterialVariants.Parent = nil
        end

        map.StaticMap.Parent = mapFolder
        map.PlayerSpawns.Parent = mapFolder
        map.LightingSettings.Parent = mapFolder

        if map.FutureLightingSettings then
            map.FutureLightingSettings.Parent = mapFolder
        end

        if map.MaterialVariants then
            map.MaterialVariants.Parent = mapFolder
        end

        for _, v in map.WaterSettings:GetChildren() do
            if v:IsA("ValueBase") then
                (workspace.Terrain :: any)[v.Name] = (v :: any).Value
            end
        end

        for _, v in map.TerrainColors:GetChildren() do
            if v:IsA("ValueBase") then
                workspace.Terrain:SetMaterialColor((Enum.Material :: any)[v.Name], (v :: any).Value)
            end
        end

        workspace.Gravity = map.Gravity

        workspace.Terrain:Clear()
        workspace.Terrain:PasteRegion(map.TerrainRegion, Vector3int16.new(-32000, -32000, -32000), true)
    end

    tryResetDynamicMapObject(mapFolder, map, "DynamicMap" :: "DynamicMap")
    tryResetDynamicMapObject(mapFolder, map, "Props" :: "Props")
    tryResetDynamicMapObject(mapFolder, map, "Windows" :: "Windows")
    tryResetDynamicMapObject(mapFolder, map, "ItemSpawns" :: "ItemSpawns")

    loadProps(round, map)
    loadItems(round, map)

    round._map = map

    currentMap = map

    data:SetAttribute("CurrentMap", currentMap.DisplayName)
end

local function SendMessage(round: Types.Round, to: {Player} | Player, message: string): ()
    if typeof(to) == "Instance" then
        to = {to}
    end

    for _, v in to do
        print("Send message: " .. message .. " to: " .. v.Name)
    end
end

function module.new(gamemode: Types.Gamemode): Types.Round
    local round: Types.Round = {
        Gamemode = gamemode,

        LoadMap = LoadMap,
        GetMap = GetMap,

        _participants = {},
        _roundPhase = "Waiting",
        _isPaused = false,

        _eventLog = {},
        _props = {},

        _items = {},
        GetItems = GetItems,
        GetItem = GetItem,
        LoadItem = LoadItem,

        IsPreGame = IsPreGame,
        IsPostGame = IsPostGame,
        IsInProgress = IsInProgress,

        AddEvent = AddEvent,
        GetEventLog = GetEventLog,

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

        GetFormattedRoleName = GetFormattedRoleName,
        IsRoleAlliedWithRole = IsRoleAlliedWithRole,

        GetProps = GetProps,
        GetProp = GetProp,
        LoadProp = LoadProp,

        SendMessage = SendMessage,
    }

    data:SetAttribute("Phase", round:GetRoundPhase())
    data:SetAttribute("Paused", round:GetIsRoundPaused())
    data:SetAttribute("AdvanceTime", nil)
    data:SetAttribute("CurrentMap", nil)

    return round
end

return module