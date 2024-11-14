local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.ItemDefinition): Types.Item
    return {
        Definition = definition,
    }
end

return module