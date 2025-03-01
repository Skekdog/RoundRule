local Types = require(script.Parent.Types)
local module = {}

local function RunBeforeHit(item: Types.AnyWeapon, round: Types.Round, hitPart: BasePart, params: Types.DamageParams): boolean
    local beforeHitAnything = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitAnything else item.Definition.BeforeHitAnything
    if beforeHitAnything then
        beforeHitAnything(item, hitPart, params)
    end

    local hitThing: Types.Participant | Types.Prop?

    if hitPart:IsDescendantOf(workspace.Characters) then
        local model = hitPart:FindFirstAncestorOfClass("Model")
        if not model then
            return false
        end

        local participant = round:GetParticipant(model.Name)
        if not participant then
            return false
        end

        hitThing = participant
    else
        local prop = round:GetProp(hitPart)
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

        return beforeHitParticipant(item, hitThing, params)
    elseif hitThing.Kind == "MapProp" or hitThing.Kind == "ItemProp" or hitThing.Kind == "CorpseProp" then
        local beforeHitProp = if item.Kind == "Grenade" then item.Definition.ExplosionInfo.BeforeHitProp else item.Definition.BeforeHitProp
        if not beforeHitProp then
            return true
        end

        return beforeHitProp(item, hitThing, params)
    end

    error("Unknown hit thing kind: " .. hitThing.Kind)
end

function module.new(definition: Types.AnyItemDefinition, model: BasePart?): Types.AnyItem
    if not model then
        model = if definition.Model then definition.Model:Clone() else nil
    end

    if definition.Kind == "Item" then
        return {
            Kind = "Item",
            Definition = definition,
            Model = model,

            Extras = {},
        }
    elseif definition.Kind == "Gun" then
        return {
            Kind = "Gun",
            Definition = definition,
            Model = model :: BasePart,

            Ammo = definition.AmmoType.Capacity,
            LastAttackTime = 0,

            IsReloading = false,

            RunBeforeHit = RunBeforeHit,

            Extras = {},
        }
    elseif definition.Kind == "Grenade" then
        return {
            Kind = "Grenade",
            Definition = definition,
            Model = model :: BasePart,

            RunBeforeHit = RunBeforeHit,

            Extras = {},
        }
    elseif definition.Kind == "Melee" then
        return {
            Kind = "Melee",
            Definition = definition,
            Model = model :: BasePart,

            RunBeforeHit = RunBeforeHit,

            LastAttackTime = 0,

            Extras = {},
        }
    else
        error("Unknown item kind: " .. definition.Kind)
    end
end

return module