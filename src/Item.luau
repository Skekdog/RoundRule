local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.AnyItemDefinition): Types.AnyItem
    return {
        Kind = "Item",
        Definition = definition :: Types.ItemDefinition,
        Model = Instance.new("Model") :: Model?,
    }
end

return module