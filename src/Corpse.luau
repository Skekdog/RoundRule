local Types = require(script.Parent.Types)
local module = {}

local function GetSearchedBy(self: Types.Corpse): {Types.Participant}
    return self._searchedBy :: {Types.Participant}
end

local function AddSearchedBy(self: Types.Corpse, participant: Types.Participant): ()
    table.insert(self._searchedBy, participant)
end

local function GetCorpseView(self: Types.Corpse): Types.CorpseView
    return {
        WasFreeKill = self.WasFreeKill,
        WasHeadshot = self.WasHeadshot,
        WasSelfDefense = self.WasSelfDefense,
        DeathTime = self.DeathTime,
        DNAExpiry = self.DNAExpiry,
        DamageSource = self.DamageSource,
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

        Killer = params.Attacker,
    } :: Types.Corpse -- there is some obnoxious-looking type error here
end

return module