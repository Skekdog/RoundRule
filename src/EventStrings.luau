local Types = require(script.Parent.Types)
local function GetEventString(event: Types.RoundEvent): string
    local data = event.Data
    if data.Kind == "StartRoundEvent" then
        return "The round begins."
    elseif data.Kind == "EndRoundEvent" then
        return data.VictoryText
    elseif data.Kind == "CorpseSearchedRoundEvent" then
        if data.FoundCredits then
            return `{data.SearchedBy:GetFormattedName()} found {data.FoundCredits} credits on the body of {data.Victim:GetFormattedName()}.`
        end
        return `{data.SearchedBy:GetFormattedName()} found the body of {data.Victim:GetFormattedName()}.`
    elseif data.Kind == "DeathRoundEvent" then
        local corpse = data.Victim:GetCorpse()
        assert(corpse)

        local msg: string

        local source = corpse.CorpseView.DamageSource
        if source == "Shot" then
            msg = `{data.Victim:GetFormattedName()} was shot to death{if corpse.Killer then ` by {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Bludgeon" then
            msg = `{data.Victim:GetFormattedName()} was beat to death{if corpse.Killer then ` by {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Stab" then
            msg = `{data.Victim:GetFormattedName()} was stabbed to death{if corpse.Killer then ` by {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Burn" then
            msg = `{data.Victim:GetFormattedName()} was burned to death{if corpse.Killer then ` by {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Crush" then
            msg = `{data.Victim:GetFormattedName()} was crushed{if corpse.Killer then ` by {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Drown" then
            msg = `{data.Victim:GetFormattedName()} drowned{if corpse.Killer then ` at the hands of {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Fall" then
            msg = `{data.Victim:GetFormattedName()} fell to their death{if corpse.Killer then ` at the hands of {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Explode" then
            msg = `{data.Victim:GetFormattedName()} exploded{if corpse.Killer then ` at the hands of {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Magic" then
            msg = `{data.Victim:GetFormattedName()} was killed by magic{if corpse.Killer then ` at the hands of {corpse.Killer:GetFormattedName()}` else ""}.`
        elseif source == "Other" then
            msg = `{data.Victim:GetFormattedName()} died{if corpse.Killer then ` at the hands of {corpse.Killer:GetFormattedName()}` else ""}.`
        end

        return msg
    end

    error("Unknown event kind: " .. data.Kind)
end

return GetEventString