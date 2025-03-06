local GetDisplayName = require(script.Parent.Common.GetDisplayName)
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

local function tryStealCredits(corpse: Types.Corpse, searcher: Types.Participant): boolean
    local searcherRole = searcher:GetRole()
    if not searcherRole or not searcherRole.Definition.CanStealCreditsFromCorpses then
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

local function updateCorpseForPlayer(corpse: Types.Corpse, participant: Types.Participant): ()
    addSearchedBy(corpse, participant)

    local role = corpse.Participant:GetRole()
    if participant ~= corpse.Participant and role then
        Replication.ReplicateRole(participant.Player, corpse.Participant, false)
    end
    
    Replication.ReplicateCorpse(participant.Player, corpse)
end

local function notifyCorpseFound(corpse: Types.Corpse, searcher: Types.Participant, isFromKillList: boolean): ()
    local msg = `[PLAYER-{searcher.Player.Name}] {if isFromKillList then "confirmed the death" else "found the body"} of {corpse.Participant:GetFormattedName()}.`
    local otherRole = corpse.Participant:GetRole()
    if otherRole then
        msg ..= ` They were a {otherRole:GetFormattedRoleName()}{otherRole:GetExclamatoryString()}`
    end

    searcher.Round:SendMessage(searcher.Player, msg)
end

local function tryLogEvent(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean, didSteal: boolean): ()
    if didSteal or covert then
        return
    end

    searcher.Round:AddEvent({
        Kind = "CorpseSearchedRoundEvent",
        SearchedBy = searcher,
        Victim = corpse.Participant,
    })
end

local function tryAwardScore(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean, isFromKillList: boolean): ()
    if covert then
        return
    end

    if corpse.Participant:GetStatus() ~= "Missing" then
        return
    end

    local searcherRole = searcher:GetRole()
    if not searcherRole then
        return
    end

    searcher:AddScore("Bodies Found", searcherRole.Definition.ScoreForFindingBodies or 0)
end

local function updateCorpseInfo(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean): ()
    local shouldUpdateForAll = false
    if not covert then
        corpse.Participant:_setStatus("Dead")

        local char = corpse.Participant:GetCharacter()
        if char then
            char:SetAttribute("Unidentified", false)
        end

        local searcherRole = searcher:GetRole()
        if searcherRole then
            shouldUpdateForAll = searcherRole.Definition.CorpseSearchResultsPublicised == true
        end
    end

    if shouldUpdateForAll then
        for _, v in searcher.Round:GetParticipants() do
            assert(v)
            updateCorpseForPlayer(corpse, v)
        end

        return
    end

    updateCorpseForPlayer(corpse, searcher)
end

local function tryConfirmKillList(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean): ()
    if covert then
        return
    end

    for _, v in corpse.Participant:GetKillList() do
        if v:GetStatus() ~= "Missing" then
            continue
        end

        local otherCorpse = v:GetCorpse()
        if not otherCorpse then
            continue
        end

        v:_setStatus("Dead")
        tryAwardScore(otherCorpse, searcher, false, false)
        notifyCorpseFound(otherCorpse, searcher, true)
        tryLogEvent(otherCorpse, searcher, false, false)
    end
end

local function searchAsAlive(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean): boolean
    local searcherChar = searcher:GetCharacter()
    if not searcherChar or not searcherChar.PrimaryPart then
        return false
    end

    local corpseChar = corpse.Participant:GetCharacter()
    if not corpseChar or not corpseChar.PrimaryPart then
        return false
    end

    if (searcherChar.PrimaryPart.Position - corpseChar.PrimaryPart.Position).Magnitude > 10 then
        return false
    end

    local didSteal = tryStealCredits(corpse, searcher)
    tryAwardScore(corpse, searcher, covert, didSteal)
    updateCorpseInfo(corpse, searcher, covert)
    notifyCorpseFound(corpse, searcher, false)
    tryLogEvent(corpse, searcher, covert, didSteal)
    tryConfirmKillList(corpse, searcher, covert)

    return true
end

local function searchAsSpectator(corpse: Types.Corpse, searcher: Types.Participant): boolean
    updateCorpseForPlayer(corpse, searcher)
    return true
end

local function Search(corpse: Types.Corpse, searcher: Types.Participant, covert: boolean): boolean
    if table.find(corpse:GetSearchedBy(), searcher) then
        return false
    end

    if searcher:GetStatus() == "Alive" then
        return searchAsAlive(corpse, searcher, covert)
    end

    return searchAsSpectator(corpse, searcher)
end

function module.new(participant: Types.Participant, params: Types.DamageParams): Types.Corpse
    local selfDefense
    if not params.IgnoreSelfDefense and params.Attacker then
        selfDefense = params.Attacker:HasSelfDefenseAgainstParticipant(params.Attacker)
    end

    local source: Types.NamedDamageSource = if typeof(params.Source) == "table" then GetDisplayName(params.Source.Definition) else params.Source

    local killList: {string} = {}
    for _, v in participant:GetKillList() do
        table.insert(killList, v:GetFormattedName())
    end

    local equipmentList: {string} = {}
    for i in participant:GetItemPurchases() do
        local definition = participant.Round:GetItemDefinition(i)
        assert(definition)

        if definition.Model then
            continue
        end
        table.insert(equipmentList, i)
    end

    local corpseView: Types.CorpseView = {
        Name = participant.Player.Name,
        UserId = participant.Player.UserId,

        WasFreeKill = participant:IsFreeKill(), 
        WasHeadshot = params.IsHeadshot,
        WasSelfDefense = selfDefense,

        KillList = killList,
        EquipmentList = equipmentList,

        DeathTime = workspace:GetServerTimeNow(),

        DamageSource = source,
    }

    return {
        Participant = participant,

        CorpseView = corpseView,
        WasCorrectKill = if params.Attacker then params.Attacker:IsDamageJustifiedAgainstParticipant(participant) else nil,
        
        _searchedBy = {},
        GetSearchedBy = GetSearchedBy,

        Search = Search,

        Killer = params.Attacker,
    }
end

return module