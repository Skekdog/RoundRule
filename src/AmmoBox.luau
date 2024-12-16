local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.AmmoDefinition, model: BasePart?, amount: number?): Types.AmmoBox
    return {
        Kind = "AmmoBox",
        Definition = definition,
        Model = if model then model else definition.Model:Clone(),
        Ammo = amount or definition.Capacity,
    }
end

return module