local Lighting = game:GetService("Lighting")
local MaterialService = game:GetService("MaterialService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetDisplayName = require(ReplicatedStorage.Shared.RoundRule.Common.GetDisplayName)
local GetTaggedDescendants = require(ReplicatedStorage.Shared.RoundRule.Common.GetTaggedDescendants)
local HasTag = require(ReplicatedStorage.Shared.RoundRule.Common.HasAnyTag)
local AmmoBox = require(script.Parent.AmmoBox)
local Item = require(script.Parent.Item)
local Map = require(script.Parent.Map)
local Participant = require(script.Parent.Participant)
local Prop = require(script.Parent.Prop)
local Replication = require(script.Parent.Replication)
local Role = require(script.Parent.Role)
local Types = require(script.Parent.Types)
local module = {}

module.Config = {} :: Types.GameConfig
module.Config.DeathSounds = {}

local HIGHLIGHTS_TIME = 20
local PREPARING_TIME = 20

local lastMap: Types.Map?

local function removeInvalidItems(round: Types.Round): ()
    for _, v in round:GetParticipants() do
        for _, item in v:GetItems() do
            assert(item)
            if not round:GetItemDefinition(item.Name) then
                v:RemoveItem(item)
            end
        end
    end
end

local function IsPreGame(round: Types.Round): boolean
    return round:GetPhase() == "Waiting" or round:GetPhase() == "Preparing"
end

local function IsInProgress(round: Types.Round): boolean
    return round:GetPhase() == "Playing"
end

local function IsPostGame(round: Types.Round): boolean
    return round:GetPhase() == "Highlights" or round:GetPhase() == "Intermission"
end

local function GetParticipant(round: Types.Round, identifier: string | Player | Model): Types.Participant?
    if typeof(identifier) == "string" then
        return round._participants[identifier]
    end

    for _, v in round:GetParticipants() do
        if identifier:IsA("Player") and v.Player == identifier or identifier:IsA("Model") and v:GetCharacter() == identifier then
            return v
        end
    end

    return nil
end

local function GetParticipants(round: Types.Round): {[string]: Types.Participant}
    return round._participants :: {[string]: Types.Participant}
end

local function spawnParticipant(participant: Types.Participant): ()
    local round = participant.Round

    if not round._heartbeat or not round._heartbeat.Connected then
        local count = 0
        for _, v in round:GetParticipants() do
            assert(v)
            count += 1
            if count == round.MinimumRequiredPlayers then
                round:SetPhase("Preparing", PREPARING_TIME)
                break
            end
        end
    end

    participant:SpawnCharacter()
end

local function LoadBoss(round: Types.Round, boss: Types.BossDefinition): ()
    round:GetMap().Structure.Static:SetAttribute("BossSpawned", true)
    round:LoadGamemode(boss.Gamemode)

    local prop = round:LoadProp(boss.Model:Clone())
    boss.OnSummon(boss, prop)
end

local function LoadGamemode(round: Types.Round, gamemode: Types.GamemodeDefinition): ()
    round.Gamemode = gamemode

    removeInvalidItems(round)

    round:SetPhase("Waiting", 0)

    if round._heartbeat then
        round._heartbeat:Disconnect()
    end

    local roles: {[string]: Types.Role} = {}
    for _, v in gamemode.Roles do
        roles[v.Name] = Role.fromDefinition(v)
    end

    round._roles = roles

    round.MinimumRequiredPlayers = if typeof(gamemode.MinimumPlayers) == "number" then gamemode.MinimumPlayers else gamemode.MinimumPlayers()

    local count = 0
    for _, v in round:GetParticipants() do
        assert(v)
        count += 1
        v:SetRole()
        v:SetCredits(0)
        if not v:IsAlive() then
            v:SpawnCharacter()
        end
    end

    if count == round.MinimumRequiredPlayers then
        round:SetPhase("Preparing", PREPARING_TIME)
    end

    Replication.ReplicateGamemode(gamemode)
end

local function AddPlayer(round: Types.Round, player: Player, karma: number?): Types.Participant
    local existingParticipant = round:GetParticipant(player.Name)
    if existingParticipant then
        error("Participant already exists")
    end

    local participant = Participant.new(player, round)
    round._participants[player.Name] = participant

    if karma then
        participant:SetKarma(karma)
    end

    spawnParticipant(participant)

    if round.Gamemode.EnableKarma then
        local msg: string
        local dmgMult = participant:GetKarmaDamageMultiplier()
        if dmgMult == 1 then
            msg = "Your karma is 100%. You will deal full damage this round."
        else
            msg = string.format("Your karma is %d. You will deal %.1f%% damage this round.", participant:GetKarma(), dmgMult * 100)
        end
        round:SendMessage(participant.Player, msg, "All")
    end

    if round:IsPreGame() then
        round:SendMessage(participant.Player, "The round will begin soon. Prepare yourself.", "All")
    end

    return participant
end

local function RemoveParticipant(round: Types.Round, participant: Types.Participant, isRejoining: boolean): ()
    local role = participant:GetRole()
    if role.Definition.ShouldAnnounceDisconnect then
        round:SendMessage(Players:GetPlayers(), `{participant:GetFormattedName()} has disconnected. They were a {role:GetFormattedName()}{role:GetExclamatoryString()}`)
    end

    local count = 0
    for _ in round:GetParticipants() do
        count += 1
    end

    participant:DespawnCharacter()

    if participant:IsAlive() then
        if round:IsInProgress() then
            if round.Gamemode.OnDeath then
                round.Gamemode.OnDeath(round, participant, false)
            end
        end
    end

    for _, v in participant:GetItems() do
        assert(v)
        participant:RemoveItem(v)
    end

    if not isRejoining and count < round.MinimumRequiredPlayers and round:IsPreGame() then
        round:SetPhase("Waiting", 0)
        assert(round._heartbeat):Disconnect()
    end

    round._participants[participant.Player.Name] = nil
end

local function GetPhase(round: Types.Round): Types.Phase
    return round._phase
end

local function destroyRound(round: Types.Round): ()
    for _, v in round:GetParticipants() do
        assert(v)
        v:SetRole(nil)
        v:DespawnCharacter()
    end
end

local function setAdvanceTime(round: Types.Round, duration: number, callback: () -> ()): ()
    Replication.ReplicateAdvanceTime(duration + workspace:GetServerTimeNow())

    if round._heartbeat then
        round._heartbeat:Disconnect()
        round._heartbeat = nil
    end

    local wasPaused = false

    round.ElapsedPhaseTime = 0
    round._heartbeat = RunService.Heartbeat:Connect(function(dt)
        if round:IsPaused() then
            wasPaused = true
            return
        end

        if wasPaused then
            wasPaused = false
            Replication.ReplicateAdvanceTime((duration - round.ElapsedPhaseTime) + workspace:GetServerTimeNow())
        end

        round.ElapsedPhaseTime += dt

        if round.ElapsedPhaseTime >= duration then
            assert(round._heartbeat):Disconnect()
            callback()
        end
    end)
end

local function SetPhase(round: Types.Round, phase: Types.Phase, duration: number, callback: false | () -> ()?): ()
    round._phase = phase
    round.PhaseLength = duration

    if callback == nil then
        if phase == "Waiting" then
            callback = false
        elseif phase == "Preparing" then
            callback = function()
                round:_start()
            end
        elseif phase == "Playing" then
            callback = function(): ()
                local victors = round.Gamemode.TimeoutVictor(round)
                round:Finish(victors, true)
            end
        elseif phase == "Highlights" then
            callback = function(): ()
                round:SetPhase("Intermission", 0)
                destroyRound(round)
            end
        elseif phase == "Intermission" then
            callback = false
        end
    end

    assert(callback ~= nil, "Callback cannot be nil")

    Replication.ReplicateRoundPhase(phase)

    setAdvanceTime(round, duration, callback or function() end)
end

local function AddEvent(round: Types.Round, data: Types.RoundEventData): ()
    table.insert(round._eventLog, {
        Timestamp = workspace:GetServerTimeNow(),
        Data = data,
    })
end

local function GetEventLog(round: Types.Round): {Types.Event}
    return round._eventLog
end

local function AddHighlight(round: Types.Round, highlight: Types.Highlight): ()
    if not round.Highlights[highlight.Group] or round.Highlights[highlight.Group].Priority < highlight.Priority then
        round.Highlights[highlight.Group] = highlight
    end
end

local function IsPaused(round: Types.Round): boolean
    return round._isPaused
end

local function Pause(round: Types.Round, paused: boolean): ()
    round._isPaused = paused
    Replication.ReplicateRoundPause(paused)
end

local function _start(round: Types.Round): ()
    assert(round:IsPreGame(), "Round is not in PreGame phase")

    local participantList: {Types.Participant} = {}

    for _, v in round:GetParticipants() do
        assert(v)
        table.insert(participantList, v)
    end

    assert(#participantList >= round.MinimumRequiredPlayers, "Not enough players to start round")

    for _, v in participantList do
        while not v:GetCharacter() and v.Player:IsDescendantOf(Players) do
            task.wait()
        end
    end

    round:AddEvent({
        Kind = "StartRoundEvent",
    })

    Replication.ReplicateStartTime(workspace:GetServerTimeNow())
    round:SetPhase("Playing", round.Gamemode.Duration(round, #participantList))

    Random.new():Shuffle(participantList)

    if round.Gamemode.AssignRoles then
        round.Gamemode.AssignRoles(round, participantList)
    end

    local exclamatoryRoles: {[Types.Role]: {Types.Participant}} = {}
    for _, v in participantList do
        local role = v:GetRole()
        if not role.Definition.IsExclamatory then
            continue
        end

        exclamatoryRoles[role] = exclamatoryRoles[role] or {}
        table.insert(exclamatoryRoles[role], v)
    end

    local exclamatoryCount = 0
    for _ in exclamatoryRoles do
        exclamatoryCount += 1
    end

    local index = 0
    local message = "There "
    for role, participants in exclamatoryRoles do
        index += 1
        if index == 1 then
            message ..= if #participants == 1 then "is" else "are"
        end
        message ..= ` {#participants} {role:FormatString(GetDisplayName(role.Definition) .. if #participants == 1 then "" else "s")},`

        local comrades = role:GetFormattedName() .. ", "
        if #participants == 1 then
            comrades ..= "you stand alone"
        else
            comrades ..= "your comrades this round are: "
            for i, participant in participants do
                comrades ..= participant:GetFormattedName() .. if i ~= #participants then ", " else ""
            end
        end

        comrades ..= "."

        for _, participant in participants do
            round:SendMessage(participant.Player, comrades, "Team")
        end
    end

    if message ~= "There " then
        message = message:sub(1, -2)
        message ..= " this round."

        round:SendMessage(Players:GetPlayers(), message)
    end

    if round.Gamemode.OnStart then
        round.Gamemode.OnStart(round)
    end
end

local function Finish(round: Types.Round, victor: Types.Victor, isTimeout: boolean?): ()
    assert(round:IsInProgress(), "Round is not in Playing phase")

    local role: Types.Role
    if victor.Kind == "Role" then
        role = victor
    elseif victor.Kind == "Participant" then
        role = victor:GetRole()
    end

    local victorRole: Types.Role
    if role.Definition.Allegiance.Kind == "Role" then
        victorRole = round:GetRoleFromRoleName(role.Definition.Allegiance.Role)
    elseif role.Definition.Allegiance.Kind == "Solo" then
        victorRole = role
    end

    local victoryText = if round.Gamemode.GetVictoryEventText then round.Gamemode.GetVictoryEventText(round, victor, isTimeout or false) else nil
    if not victoryText then
        if victor.Kind == "Role" then
            victoryText = `The {victorRole:FormatString(victorRole:GetPluralName())} have won the round!`
        else
            victoryText = `{victor:GetFormattedName()} has won the round!`
        end
    end
    assert(victoryText)

    round.VictoryData = {
        Victor = victor,
        DidTimeout = isTimeout or false,
        EndedAt = workspace:GetServerTimeNow(),
    }
    assert(round.VictoryData)

    round:AddEvent({
        Kind = "EndRoundEvent",
        VictoryText = victoryText,
    })

    Replication.ClearEvents()
    Replication.ClearHighlights()
    Replication.ClearScores()
    for _, v in round:GetEventLog() do
        Replication.AddEvent(v)
    end

    if round.Gamemode.AddFinishHighlights then
        round.Gamemode.AddFinishHighlights(round)
    end

    for _, v in round.Highlights do
        Replication.AddHighlight(v)
    end

    for _, v in round:GetParticipants() do
        assert(v)
        Replication.AddScore(v)
        Replication.ReplicateRole("All", v, false)
        Replication.ReplicatePlayerStatus("All", v, v:GetStatus())

        if round.Gamemode.EnableKarma and not v:IsFreeKill() then
            v:SetKarma(v:GetKarma() + 100)
        end
    end

    local chosenMusic = round.Gamemode.GetRoundEndMusic(round, victor, isTimeout or false)
    if chosenMusic then
        round.VictoryData.Music = chosenMusic
        Replication.ReplicateRoundEndMusic("All", chosenMusic, workspace:GetServerTimeNow())
    end

    Replication.ReplicateWinner(victor)
    round:SetPhase("Highlights", HIGHLIGHTS_TIME)

    if round.Gamemode.OnFinish then
        round.Gamemode.OnFinish(round)
    end
end

local function GetProps(round: Types.Round): {[Types.MapObject]: Types.Prop}
    return round._props :: {[Types.MapObject]: Types.Prop}
end

local function GetProp(round: Types.Round, model: Types.MapObject): Types.Prop?
    return round._props[model]
end

local function loadProp(round: Types.Round, model: Types.MapObject, interactable: Types.InteractableDefinition?): Types.Prop
    if not model.Parent then
        (model :: Instance).Parent = round:GetMap().Structure.Dynamic
    end
    model:AddTag("Prop")
    local prop = Prop.new(model, round, interactable)
    return prop
end

local function LoadItem(round: Types.Round, components: Types.ItemComponents, model: Types.MapObject?): Types.Item
    if model then
        local existingItem = round:GetItem(model)
        if existingItem then
            return existingItem
        end
    end

    local item = Item.new(components, model)
    model = item.Model

    if not model then
        return item
    end

    round._items[model] = item

    model:SetAttribute("StoredAmmo", item.Ammo)
    model:SetAttribute("AmmoType", if item.AmmoDefinition then item.AmmoDefinition.Name else nil)

    ForEachPart(model, function(part)
        part.Touched:Connect(function(touchPart)
            local touchModel = touchPart:FindFirstAncestorOfClass("Model")

            if not touchModel then
                return
            end

            local participant = round:GetParticipant(touchModel.Name)
            if not participant or not participant:IsAlive() then
                return
            end

            if participant:GetItemOccupyingGroup(item.ItemGroup) then
                return
            end

            (model :: PVInstance).Parent = nil
            participant:AddItem(item)
        end)
    end)

    return item
end

local function LoadItemFromMapObject(round: Types.Round, model: Types.MapObject): Types.Item
    local existingItem = round:GetItem(model)
    if existingItem then
        return existingItem
    end

    local definition = round:GetItemDefinition(model.Name) or error(`Item {model.Name} does not exist in map or gamemode`)

    local item = round:LoadItem(definition, model)

    return item
end

local function loadAmmoBox(round: Types.Round, model: Types.MapObject): ()
    local definition = round:GetAmmoDefinition(model.Name) or error(`AmmoBox {model.Name} does not exist in map or gamemode`)
    local ammoBox = AmmoBox.new(definition, model)
    round._ammoBoxes[model] = ammoBox

    model:SetAttribute("AmmoType", ammoBox.Definition.Name)
    model:SetAttribute("StoredAmmo", ammoBox.Ammo)

    ForEachPart(model, function(part)
        if not part.CanTouch or not part.CanCollide then
            return
        end

        part.Touched:Connect(function(touchPart)
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
    end)

    return {
        Kind = "AmmoProp",
        Model = model,
        AmmoBox = ammoBox,
    }
end

local function loadInteractable(round: Types.Round, model: Types.MapObject): Types.InteractableDefinition?
    if not model:HasTag("Interactable") then
        return nil
    end

    local name = model.Name
    if model:HasTag("Door") then
        name = "Door"
    elseif model:HasTag("Ladder") then
        name = "Ladder"
    elseif model:HasTag("Item") then
        name = "Item"
    end
    local definition = round:GetInteractableDefinition(name) or error(`Interactable {name} does not exist in map or gamemode`)
    return definition
end

local function LoadProp(round: Types.Round, model: Types.MapObject): Types.Prop
    local existingProp = round:GetProp(model)
    if existingProp then
        return existingProp
    end

    if model:HasTag("Item") then
        round:LoadItemFromMapObject(model)
        model:AddTag("Interactable")
    elseif model:HasTag("AmmoBox") then
        loadAmmoBox(round, model)
    end

    local prop = loadProp(round, model, loadInteractable(round, model))

    round._props[model] = prop
    return prop
end

local function GetItems(round: Types.Round): {[Types.MapObject]: Types.Item}
    return round._items :: {[Types.MapObject]: Types.Item}
end

local function GetItem(round: Types.Round, model: Types.MapObject): Types.Item?
    return round._items[model]
end

local function GetAmmoBoxes(round: Types.Round): {[Types.MapObject]: Types.AmmoBox}
    return round._ammoBoxes :: {[Types.MapObject]: Types.AmmoBox}
end

local function GetAmmoBox(round: Types.Round, model: Types.MapObject): Types.AmmoBox?
    return round._ammoBoxes[model]
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
    return round:GetMap().AmmoDefinitions[ammo] or round.Gamemode.AvailableAmmo[ammo]
end

local function GetItemDefinition(round: Types.Round, item: string): Types.ItemComponents?
    return round:GetMap().ItemDefinitions[item] or round.Gamemode.AvailableItems[item]
end

local function GetInteractableDefinition(round: Types.Round, interactable: string): Types.InteractableDefinition?
    return round:GetMap().InteractableDefinitions[interactable] or round.Gamemode.InteractableDefinitions[interactable]
end

local knownWaterSettings: {string} = {}
local knownTerrainColours: {[Enum.Material]: Color3} = {}
local knownLightingSettings: {string} = {}

local function loadStatic(round: Types.Round, structure: Types.MapStructure): ()
    local map = Map.new(structure)

    workspace.Gravity = map.Gravity

    if lastMap then
        lastMap.Structure:Destroy()
    end

    local lastVariants = MaterialService:FindFirstChild("MapMaterialVariants")
    if lastVariants then
        lastVariants:Destroy()
    end

    local materialVariants = structure:FindFirstChild("MaterialVariants")
    if materialVariants then
        materialVariants.Name = "MapMaterialVariants"
        materialVariants.Parent = MaterialService
    end

    for _, v in knownWaterSettings do
        workspace.Terrain:ResetPropertyToDefault(v)
    end

    local waterSettings = structure:FindFirstChild("WaterSettings")
    if waterSettings then
        for k, v in waterSettings:GetAttributes() do
            if not table.find(knownWaterSettings, k) then
                table.insert(knownWaterSettings, k)
            end
            (workspace.Terrain :: any)[k] = v
        end
    end

    for i, v in knownTerrainColours do
        workspace.Terrain:SetMaterialColor(i, v)
    end

    local terrainColors = structure:FindFirstChild("TerrainColors")
    if terrainColors then
        for k, v in terrainColors:GetAttributes() do
            assert(typeof(v) == "Color3", "Terrain color must be a Color3")

            local material = Enum.Material:FromName(k)
            assert(material, "Invalid material name " .. k)

            if not knownTerrainColours[material] then
                knownTerrainColours[material] = workspace.Terrain:GetMaterialColor(material)
            end

            workspace.Terrain:SetMaterialColor(material, v)
        end
    end

    local oldClouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
    if oldClouds then
        oldClouds:Destroy()
    end

    local clouds = structure:FindFirstChild("Clouds")
    if clouds then
        clouds.Parent = workspace.Terrain
    end

    workspace.Terrain:Clear()
    local terrain = structure:FindFirstChild("Terrain") :: TerrainRegion
    if terrain then
        workspace.Terrain:PasteRegion(terrain, Vector3int16.new(-32000, -32000, -32000), true)
    end

    for _, v in knownLightingSettings do
        Lighting:ResetPropertyToDefault(v)
    end

    for _, v in Lighting:GetChildren() do
        if v:HasTag("MapLighting") then
            v:Destroy()
        end
    end

    local lighting = structure:FindFirstChild("LightingSettings")
    if lighting then
        for _, v in lighting:GetChildren() do
            v:AddTag("MapLighting")
            v.Parent = Lighting
        end

        for k, v in lighting:GetAttributes() do
            if not table.find(knownLightingSettings, k) then
                table.insert(knownLightingSettings, k)
            end
            (Lighting :: any)[k] = v
        end
    end

    for _, v in structure.PlayerSpawns:GetChildren() do
        if v:IsA("BasePart") then
            v.Transparency = 1
            v.CanCollide = false
            v.CanQuery = false
            v.CanTouch = false
            v.Anchored = true
        end
    end

    lastMap = map
    round._map = lastMap

    structure:SetAttribute("OriginalName", structure.Name)
    structure.Name = "Map"

    structure.Parent = workspace
end

local function reloadDynamic(round: Types.Round, structure: Types.MapStructure): ()
    assert(lastMap)

    round._map = lastMap

    lastMap.Structure.Dynamic:Destroy()
    structure.Dynamic.Parent = lastMap.Structure
end

local function LoadMap(round: Types.Round, structure: Types.MapStructure): ()
    structure = structure:Clone()

    if not lastMap or lastMap.Name ~= structure.Name then
        loadStatic(round, structure)
    elseif lastMap and lastMap.Name == structure.Name then
        reloadDynamic(round, structure)
    else
        error("what")
    end

    assert(lastMap)

    structure = lastMap.Structure

    for _, v in GetTaggedDescendants(structure.Dynamic, Prop.Tags) do
        if v:IsA("BasePart") or v:IsA("Model") then
            round:LoadProp(v)
        end
    end

    structure.Dynamic.DescendantAdded:Connect(function(descendant)
        if (descendant:IsA("BasePart") or descendant:IsA("Model")) and not round:GetProp(descendant) and HasTag(descendant, Prop.Tags) then
            round:LoadProp(descendant)
        end
    end)

    task.delay(1, function()
        for _, v in round:GetParticipants() do
            v:MoveToSpawn()
        end
    end)
    removeInvalidItems(round)

    Replication.ReplicateMap()
end

local function SendMessage(round: Types.Round, to: {Player} | Player?, message: string, kind: Types.MessageKind?): ()
    if not to then
        return Replication.SendMessage("All", message, kind)
    end

    if typeof(to) == "Instance" then
        to = {to}
    end

    for _, v in to :: {Player} do
        Replication.SendMessage(v, message, kind)
    end
end

function module.new(gamemode: Types.GamemodeDefinition): Types.Round
    local roles: {[string]: Types.Role} = {}
    for _, v in gamemode.Roles do
        roles[v.Name] = Role.fromDefinition(v)
    end

    local round: Types.Round = {
        Config = module.Config,
        Gamemode = gamemode,

        MinimumRequiredPlayers = if typeof(gamemode.MinimumPlayers) == "number" then gamemode.MinimumPlayers else gamemode.MinimumPlayers(),

        Extras = {},

        LoadMap = LoadMap,
        GetMap = GetMap,

        ElapsedPhaseTime = 0,
        PhaseLength = 0,

        _participants = {},
        _phase = "Waiting",
        _isPaused = false,

        _eventLog = {},
        _props = {},

        _roles = roles,

        _items = {},
        GetItems = GetItems,
        GetItem = GetItem,
        LoadItemFromMapObject = LoadItemFromMapObject,
        LoadItem = LoadItem,

        GetAmmoDefinition = GetAmmoDefinition,
        GetItemDefinition = GetItemDefinition,
        GetInteractableDefinition = GetInteractableDefinition,

        IsPreGame = IsPreGame,
        IsPostGame = IsPostGame,
        IsInProgress = IsInProgress,

        _ammoBoxes = {},
        GetAmmoBoxes = GetAmmoBoxes,
        GetAmmoBox = GetAmmoBox,

        AddEvent = AddEvent,
        GetEventLog = GetEventLog,

        Highlights = {},
        AddHighlight = AddHighlight,

        GetParticipant = GetParticipant,
        GetParticipants = GetParticipants,
        AddPlayer = AddPlayer,
        RemoveParticipant = RemoveParticipant,
        GetPhase = GetPhase,
        SetPhase = SetPhase,
        IsPaused = IsPaused,
        Pause = Pause,
        _start = _start,
        Finish = Finish,
        GetRoleFromRoleName = GetRoleFromRoleName,
        GetParticipantsWithRole = GetParticipantsWithRole,

        GetProps = GetProps,
        GetProp = GetProp,
        LoadProp = LoadProp,

        SendMessage = SendMessage,

        LoadBoss = LoadBoss,
        LoadGamemode = LoadGamemode,
    }

    Replication.ReplicateRoundPhase(round:GetPhase())
    Replication.ReplicateRoundPause(round:IsPaused())
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