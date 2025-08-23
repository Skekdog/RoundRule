local Types = require(script.Parent.Types)

local function RunBeforeHit(item: Types.AnyWeapon | Types.ExplosionParams, round: Types.Round, hitPart: BasePart, params: Types.DamageParams): boolean
    local beforeHitAnything = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitAnything else item.Definition.BeforeHitAnything
    if beforeHitAnything then
        beforeHitAnything(item, round, hitPart, params)
    end

    local hitThing: Types.Participant | Types.Prop | Types.Interactable?

    if hitPart:IsDescendantOf(workspace.Characters) then
        local model = hitPart:FindFirstAncestorOfClass("Model")
        if not model then
            return false
        end

        if model:HasTag("Corpse") then
            local prop = round:GetProp(model)
            if not prop then
                return false
            end

            hitThing = prop
        end

        local participant = round:GetParticipant(model.Name)
        if not participant then
            return false
        end

        hitThing = participant
    else
        local prop: Types.Prop | Types.Interactable?

        if not prop then
            prop = round:GetProp(hitPart)
        end

        if not prop then
            return false
        end

        hitThing = prop
    end

    if not hitThing then
        return false
    end

    if hitThing.Kind == "Participant" then
        local beforeHitParticipant = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitParticipant else item.Definition.BeforeHitParticipant
        if not beforeHitParticipant then
            return true
        end

        return beforeHitParticipant(item, round, hitThing, params)
    elseif hitThing.Kind == "Prop" then
        local beforeHitProp = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitProp else item.Definition.BeforeHitProp
        if not beforeHitProp then
            return true
        end

        return beforeHitProp(item, round, hitThing, params)
    end

    error("Unknown hit thing kind: " .. hitThing.Kind)
end

return RunBeforeHit