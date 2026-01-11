local Players = game:GetService("Players")
local Defaults = require(script.Parent.Defaults)
local Replication = require(script.Parent.Replication)
local Types = require(script.Parent.Types)

local module = {}

local function GetSearchedBy(corpse: Types.Corpse): {Types.Participant}
    return corpse._searchedBy
end

local function addSearchedBy(corpse: Types.Corpse, participant: Types.Participant): ()
    if table.find(corpse._searchedBy, participant) then
        return
    end
    table.insert(corpse._searchedBy, participant)
end

local function generateKillList(participant: Types.Participant): {string}
    local killList: {string} = {}
    for _, v in participant.KillList do
        table.insert(killList, v:GetFormattedName())
    end
    return killList
end


local function UpdateKillList(corpse: Types.Corpse): ()
    local killList = generateKillList(corpse.Participant)

    corpse.CorpseView.KillList = killList

    for _, v in corpse:GetSearchedBy() do
        Replication.ReplicateCorpse(v.Player, corpse, false)
    end
end

local function tryStealCredits(corpse: Types.Corpse, searcher: Types.Participant): boolean
    if not searcher:GetRole().Definition.CanStealCreditsFromCorpses then
        return false
    end

    local credits = corpse.Participant:GetCredits()
    if credits <= 0 then
        return false
    end

    searcher:AddCredits(credits)
    corpse.Participant:SetCredits(0)

    searcher.Round:AddEvent({
        Kind = "CorpseSearchedRoundEvent",
        SearchedBy = searcher,
        Victim = corpse.Participant,
        FoundCredits = credits,
    })

    searcher.Round:SendMessage(searcher.Player, `You found {credits} {if credits == 1 then "credit" else "credits"} on the corpse.`, "Team")

    return true
end

local function updateCorpseForPlayer(corpse: Types.Corpse, participant: Types.Participant?, covert: boolean, player: Player?): ()
    if not covert and participant then
        addSearchedBy(corpse, participant)
    end

    if participant and participant ~= corpse.Participant then
        Replication.ReplicateRole(participant.Player, corpse.Participant, false)
    end

    Replication.ReplicateCorpse(player or (participant or error("Must have either a player or participant")).Player, corpse, covert)
end

local function tryNotifyCorpseFound(corpse: Types.Corpse, searcher: Types.Participant, isFromKillList: boolean): ()
    if corpse.Participant:GetStatus() ~= "Missing" then
        return
    end

    local msg = `[PLAYER-{searcher.Player.Name}] {if isFromKillList then "confirmed the death" else "found the body"} of {corpse.Participant:GetFormattedName()}.`
    local otherRole = corpse.Participant:GetRole()
    if otherRole ~= Defaults.Role then
        msg ..= ` They were a {otherRole:GetFormattedName()}{otherRole:GetExclamatoryString()}`
    end

    searcher.Round:SendMessage(Players:GetPlayers(), msg)
end

local function logEvent(corpse: Types.Corpse, searcher: Types.Participant, isFromKillList: boolean): ()
    if isFromKillList then
        return searcher.Round:AddEvent({
            Kind = "DeathConfirmedRoundEvent",
            Victim = corpse.Participant,
            ConfirmedBy = searcher,
        })
    end

    searcher.Round:AddEvent({
        Kind = "CorpseSearchedRoundEvent",
        SearchedBy = searcher,
        Victim = corpse.Participant,
    })
end

local function tryAwardScore(corpse: Types.Corpse, searcher: Types.Participant): ()
    if corpse.Participant:GetStatus() ~= "Missing" then
        return
    end

    searcher:AddScore("Bodies Found", searcher:GetRole().Definition.ScoreForFindingBodies or 0)
end

local function updateCorpseInfo(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean): ()
    local shouldUpdateForAll = not covert and searcher:GetRole().Definition.CorpseSearchResultsPublicised == true

    if shouldUpdateForAll then
        for _, v in searcher.Round:GetParticipants() do
            assert(v)
            updateCorpseForPlayer(corpse, v, covert)
        end

        return
    end

    updateCorpseForPlayer(corpse, searcher, covert)
end

local function tryMarkIdentified(corpse: Types.Corpse, searcher: Types.Participant): ()
    corpse.Participant:_setStatus("Dead")

    local char = corpse.Model
    if char then
        char:SetAttribute("Unidentified", false)
    end

    local gamemode = corpse.Participant.Round.Gamemode
    if gamemode.OnIdentifyCorpse then
        gamemode.OnIdentifyCorpse(corpse.Participant.Round, corpse, searcher)
    end
end

local function tryConfirmKillList(corpse: Types.Corpse, searcher: Types.Participant): ()
    for _, v in corpse.Participant.KillList do
        if v == corpse.Participant or v:GetStatus() ~= "Missing" then
            continue
        end

        local otherCorpse = v.Corpse
        if not otherCorpse then
            continue
        end

        tryNotifyCorpseFound(otherCorpse, searcher, true)
        tryAwardScore(otherCorpse, searcher)
        logEvent(otherCorpse, searcher, true)
        tryMarkIdentified(otherCorpse, searcher)
    end
end

local function SearchAsAlive(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean): boolean
    local searcherChar = searcher:GetCharacter()
    if not searcherChar or not searcherChar.PrimaryPart then
        return false
    end

    local corpseChar = corpse.Model
    if not corpseChar or not corpseChar.PrimaryPart then
        return false
    end

    if (searcherChar.PrimaryPart.Position - corpseChar.PrimaryPart.Position).Magnitude > searcher.CorpseSearchDistance then
        return false
    end

    local didSteal = tryStealCredits(corpse, searcher)

    if not covert and corpse.Participant:GetStatus() == "Missing" then
        tryAwardScore(corpse, searcher)
        tryNotifyCorpseFound(corpse, searcher, false)
        tryConfirmKillList(corpse, searcher)
        tryMarkIdentified(corpse, searcher)

        if not didSteal then
            logEvent(corpse, searcher, false)
        end
    end

    updateCorpseInfo(corpse, searcher, covert)

    return true
end

local function CallRole(corpse: Types.Corpse, caller: Types.Participant): ()
    local round = caller.Round
    if not round.Gamemode.RoleCanCallToCorpse then
        return
    end

    if not corpse.Model or corpse._hasBeenCalledTo then
        return
    end

    if corpse.Participant:GetStatus() ~= "Dead" then
        return
    end

    local callerRole = caller:GetRole()
    if callerRole.Definition == round.Gamemode.RoleCanCallToCorpse then
        return
    end

    corpse._hasBeenCalledTo = true

    local role = round:GetRoleFromRoleName(round.Gamemode.RoleCanCallToCorpse.Name)

    round:SendMessage(Players:GetPlayers(), `[PLAYER-{caller.Player.Name}] has called a {role:GetFormattedName()} to the body of {corpse.Participant:GetFormattedName()}.`, "Chat")

    for _, v in round:GetParticipantsWithRole(role) do
        Replication.CallRoleToCorpse(v.Player, corpse.Model)
    end
end

local function searchAsSpectator(corpse: Types.Corpse, searcher: Types.Participant?, player: Player?): boolean
    updateCorpseForPlayer(corpse, searcher, false, player)
    return true
end

local function Search(corpse: Types.Corpse, searcher: Types.Participant?, covert: boolean, player: Player?): boolean
    if searcher and table.find(corpse:GetSearchedBy(), searcher) then
        return false
    end

    if searcher and searcher:GetStatus() == "Alive" then
        return corpse:SearchAsAlive(searcher, covert)
    end

    return searchAsSpectator(corpse, searcher, player)
end

function module.new(participant: Types.Participant, params: Types.DamageParams, ragdoll: Model?, freeKill: boolean?): Types.Corpse
    local selfDefense: boolean?
    if not params.IgnoreSelfDefense and params.Attacker and not participant:GetRole().Definition.CorpseHidesSelfDefense then
        selfDefense = params.Attacker:HasSelfDefenseAgainstParticipant(participant)
    end

    local source: Types.NamedDamageSource = if typeof(params.Source) == "table" then params.Source.Name else params.Source

    local equipmentList: {string} = {}
    for i in participant:GetItems() do
        local definition = participant.Round:GetItemDefinition(i)
        assert(definition)

        if definition.ItemGroup then
            continue
        end
        table.insert(equipmentList, i)
    end

    local corpseView: Types.CorpseView = {
        Name = participant.Player.Name,
        UserId = participant.Player.UserId,

        AdditionalIcons = participant.ExtraCorpseIcons,

        WasFreeKill = if freeKill == nil then participant:IsFreeKill(params.Attacker) else freeKill,
        WasHeadshot = params.IsHeadshot,
        WasSelfDefense = selfDefense,

        KillList = generateKillList(participant),
        EquipmentList = equipmentList,

        DeathTime = workspace:GetServerTimeNow(),

        DamageSource = source,
    }

    return {
        Participant = participant,

        Model = ragdoll,

        CorpseView = corpseView,
        WasCorrectKill = if params.Attacker then params.Attacker:IsDamageJustifiedAgainstParticipant(participant) else nil,

        _searchedBy = {},
        GetSearchedBy = GetSearchedBy,

        UpdateKillList = UpdateKillList,

        CallRole = CallRole,

        Search = Search,
        SearchAsAlive = SearchAsAlive,

        Killer = params.Attacker,
    }
end

return module