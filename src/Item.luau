local RunBeforeHit = require(script.Parent.RunBeforeHit)
local RunOnHitClient = require(script.Parent.RunOnHitClient)
local Types = require(script.Parent.Types)

local module = {}

function module.new(definition: Types.AnyItemDefinition, model: Types.MapObject?): Types.AnyItem
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

            Extras = {},

            RunBeforeHit = RunBeforeHit,
            RunOnHitClient = RunOnHitClient,
        }
    elseif definition.Kind == "Grenade" then
        return {
            Kind = "Grenade",
            Definition = definition,
            Model = model :: BasePart,

            Extras = {},

            RunBeforeHit = RunBeforeHit,
            RunOnHitClient = RunOnHitClient,
        }
    elseif definition.Kind == "Melee" then
        return {
            Kind = "Melee",
            Definition = definition,
            Model = model :: BasePart,

            LastAttackTime = 0,

            Extras = {},

            RunBeforeHit = RunBeforeHit,
            RunOnHitClient = RunOnHitClient,
        }
    else
        error("Unknown item kind: " .. definition.Kind)
    end
end

return module