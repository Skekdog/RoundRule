local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.AnyItemDefinition): Types.AnyItem
    local model = if definition.Model then definition.Model:Clone() else nil

    if definition.Kind == "Item" then
        return {
            Kind = "Item",
            Definition = definition :: Types.ItemDefinition,
            Model = model :: BasePart?,

            Extras = {},
        }
    elseif definition.Kind == "Gun" then
        return {
            Kind = "Gun",
            Definition = definition :: Types.GunWeaponDefinition,
            Model = model :: BasePart,

            Ammo = 0,
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