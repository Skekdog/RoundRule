local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.ItemDefinition): Types.Item
    return {
        Definition = definition,
        Model = (if definition.Model then definition.Model:Clone() else nil) :: Model?,
    }
end

return module