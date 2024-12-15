local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.AnyItemDefinition, model: BasePart?): Types.AnyItem
    if not model then
        model = if definition.Model then definition.Model:Clone() else nil
    end

    if definition.Kind == "Item" then
        return {
            Kind = "Item",
            Definition = definition :: Types.ItemDefinition,
            Model = model,

            Extras = {},
        }
    elseif definition.Kind == "Gun" then
        local gunDefinition = definition :: Types.GunWeaponDefinition
        return {
            Kind = "Gun",
            Definition = definition :: Types.GunWeaponDefinition,
            Model = model :: BasePart,

            Ammo = gunDefinition.AmmoType.Capacity,
            LastFireTime = 0,

            IsReloading = false,

            Extras = {},
        }
    elseif definition.Kind == "Grenade" then
        return {
            Kind = "Grenade",
            Definition = definition :: Types.GrenadeWeaponDefinition,
            Model = model :: BasePart,

            Extras = {},
        }
    elseif definition.Kind == "Melee" then
        return {
            Kind = "Melee",
            Definition = definition :: Types.MeleeWeaponDefinition,
            Model = model :: BasePart,

            LastAttackTime = 0,

            Extras = {},
        }
    else
        error("Unknown item kind: " .. definition.Kind)
    end
end

return module