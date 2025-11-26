local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GetMapObjectWithTag = require(ReplicatedStorage.Shared.RoundRule.Common.GetMapObjectWithTag)
local Types = require(script.Parent.Types)

local function RunBeforeHit(item: Types.AnyWeapon | Types.ExplosionParams, round: Types.Round, hitPart: BasePart, params: Types.DamageParams): boolean
    local beforeHitAnythingItem = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitAnything else item.Definition.BeforeHitAnything
    if beforeHitAnythingItem then
        beforeHitAnythingItem(item, round, hitPart, params)
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

        if not hitThing then
            local participant = round:GetParticipant(model.Name)
            if not participant then
                return false
            end

            hitThing = participant
        end
    elseif hitPart:IsDescendantOf(game) then
        local MapObject = GetMapObjectWithTag(hitPart, "Prop")
        if not MapObject then
            return false
        end

        local prop: Types.Prop | Types.Interactable? = round:GetInteractable(MapObject) or round:GetProp(MapObject)

        if not prop then
            return false
        end

        hitThing = prop
    end

    if not hitThing then
        return false
    end

    if hitThing.Kind == "Participant" then
        local beforeHitParticipantItem = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitParticipant else item.Definition.BeforeHitParticipant
        if beforeHitParticipantItem and not beforeHitParticipantItem(item, round, hitThing, params) then
            return false
        end

        return true
    elseif hitThing.Kind == "Prop" or hitThing.Kind == "Interactable" then
        local beforeHitProp = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitProp else item.Definition.BeforeHitProp
        if not beforeHitProp then
            return true
        end

        return beforeHitProp(item, round, hitThing, params)
    end

    error("Unknown hit thing kind: " .. hitThing.Kind)
end

return RunBeforeHit