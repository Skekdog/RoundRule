local Types = require(script.Parent.Types)
local module = {}

local function GetSearchedBy(corpse: Types.Corpse): {Types.Participant}
    return corpse._searchedBy :: {Types.Participant}
end

local function AddSearchedBy(corpse: Types.Corpse, participant: Types.Participant): ()
    if table.find(corpse._searchedBy, participant) then
        return
    end
    table.insert(corpse._searchedBy, participant)
end

function module.new(participant: Types.Participant, params: Types.DamageParams): Types.Corpse
    local selfDefense
    if not params.IgnoreSelfDefense and params.Attacker then
        selfDefense = params.Attacker:HasSelfDefenseAgainstParticipant(params.Attacker)
    end

    local source: Types.GeneralDamageSource
    if typeof(params.Source) == "string" then
        source = params.Source
    else
        source = "Shot"
    end

    local corpseView: Types.CorpseView = {
        WasFreeKill = participant:IsFreeKill() :: boolean?, 
        WasHeadshot = params.IsHeadshot,
        WasSelfDefense = selfDefense,

        DeathTime = workspace:GetServerTimeNow(),
        DNAExpiry = nil :: number?,

        DamageSource = source,
    }

    return {
        CorpseView = corpseView,
        WasCorrectKill = if params.Attacker then params.Attacker:IsDamageJustifiedAgainstParticipant(participant) else nil,

        Model = nil :: Model?,
        
        _searchedBy = {},
        GetSearchedBy = GetSearchedBy,
        AddSearchedBy = AddSearchedBy,

        Killer = params.Attacker,
    }
end

return module