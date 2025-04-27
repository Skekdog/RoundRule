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

        local victim = data.Victim:GetFormattedName()
        local killer = if corpse.Killer then corpse.Killer:GetFormattedName() else nil

        local source = corpse.CorpseView.DamageSource
        if source == "Shot" then
            msg = `{victim} was shot to death{if killer then ` by {killer}` else ""}.`
        elseif source == "Bludgeon" then
            msg = `{victim} was beat to death{if killer then ` by {killer}` else ""}.`
        elseif source == "Stab" then
            msg = `{victim} was stabbed to death{if killer then ` by {killer}` else ""}.`
        elseif source == "Burn" then
            msg = `{victim} was burned to death{if killer then ` by {killer}` else ""}.`
        elseif source == "Crush" then
            msg = `{victim} was crushed{if killer then ` by {killer}` else ""}.`
        elseif source == "Drown" then
            msg = `{victim} drowned{if killer then ` at the hands of {killer}` else ""}.`
        elseif source == "Fall" then
            msg = `{victim} fell to their death{if killer then ` at the hands of {killer}` else ""}.`
        elseif source == "Explode" then
            msg = `{victim} was exploded{if killer then ` by {killer}` else ""}.`
        elseif source == "Magic" then
            msg = `{victim} was killed by magic{if killer then ` used by {killer}` else ""}.`
        elseif source == "Poison" then
            msg = `{victim} was poisoned{if killer then ` by {killer}` else ""}.`
        elseif source == "Other" then
            msg = `{victim} died{if killer then ` at the hands of {killer}` else ""}.`
        else
            if killer then
                msg = `{victim} was killed by {killer}.`
            else
                msg = `{victim} died.`
            end
        end

        return msg
    elseif data.Kind == "DeathConfirmedRoundEvent" then
        return `{data.ConfirmedBy:GetFormattedName()} confirmed the death of {data.Victim:GetFormattedName()}.`
    end

    error("Unknown event kind: " .. data.Kind)
end

return GetEventString