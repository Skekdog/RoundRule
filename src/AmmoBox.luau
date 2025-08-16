local Types = require(script.Parent.Types)
local module = {}

local function SetAmmo(ammoBox: Types.AmmoBox, amount: number): ()
    ammoBox.Ammo = amount
    ammoBox.Model:SetAttribute("StoredAmmo", amount)
end

function module.new(definition: Types.AmmoDefinition, model: Types.MapThing?, amount: number?): Types.AmmoBox
    return {
        Kind = "AmmoBox",
        Definition = definition,
        Model = if model then model else assert(definition.Model):Clone(),
        Ammo = amount or definition.Capacity,

        SetAmmo = SetAmmo,
    }
end

return module