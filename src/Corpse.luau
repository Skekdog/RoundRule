local Types = require(script.Parent.Types)
local module = {}

local function GetSearchedBy(corpse: Types.Corpse): {Types.Participant}
    return corpse._searchedBy :: {Types.Participant}
end

local function AddSearchedBy(corpse: Types.Corpse, participant: Types.Participant): ()
    table.insert(corpse._searchedBy, participant)
end

local function GetCorpseView(corpse: Types.Corpse): Types.CorpseView
    return {
        WasFreeKill = corpse.WasFreeKill,
        WasHeadshot = corpse.WasHeadshot,
        WasSelfDefense = corpse.WasSelfDefense,
        DeathTime = corpse.DeathTime,
        DNAExpiry = corpse.DNAExpiry,
        DamageSource = corpse.DamageSource,
    }
end

function module.new(participant: Types.Participant, params: Types.DamageParams): Types.Corpse
    local selfDefense
    if not params.IgnoreSelfDefense and params.Attacker then
        selfDefense = params.Attacker:HasSelfDefenseAgainstParticipant(params.Attacker)
    end

    local source = params.Source
    if typeof(source) == "table" then
        source = source.Definition.Name
    end

    return {
        WasFreeKill = participant:IsFreeKill(),
        WasHeadshot = params.IsHeadshot,
        WasSelfDefense = selfDefense,

        DeathTime = workspace:GetServerTimeNow(),

        DamageSource = source,

        _searchedBy = {},
        GetSearchedBy = GetSearchedBy,
        AddSearchedBy = AddSearchedBy,

        GetCorpseView = GetCorpseView,

        Killer = params.Attacker,
    } :: Types.Corpse -- there is some obnoxious-looking type error here
end

return module