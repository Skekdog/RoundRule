local GetDisplayName = require(script.Parent.GetDisplayName)
local Types = require(script.Parent.Types)
local module = {}

local function GetSearchedBy(corpse: Types.Corpse): {Types.Participant}
    return corpse._searchedBy
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

    local source: Types.NamedDamageSource = if typeof(params.Source) == "table" then GetDisplayName(params.Source.Definition) else params.Source

    local killList: {string} = {}
    for _, v in participant:GetKillList() do
        table.insert(killList, v:GetFormattedName())
    end

    local equipmentList: {string} = {}
    for i in participant:GetItemPurchases() do
        table.insert(equipmentList, i)
    end

    local corpseView: Types.CorpseView = {
        Name = participant.Player.Name,
        WasFreeKill = participant:IsFreeKill(), 
        WasHeadshot = params.IsHeadshot,
        WasSelfDefense = selfDefense,

        KillList = killList,
        EquipmentList = equipmentList,

        DeathTime = workspace:GetServerTimeNow(),

        DamageSource = source,
    }

    return {
        CorpseView = corpseView,
        WasCorrectKill = if params.Attacker then params.Attacker:IsDamageJustifiedAgainstParticipant(participant) else nil,
        
        _searchedBy = {},
        GetSearchedBy = GetSearchedBy,
        AddSearchedBy = AddSearchedBy,

        Killer = params.Attacker,
    }
end

return module