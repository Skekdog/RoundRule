local Types = require(script.Parent.Types)

local module = {}

function module.new(definition: Types.ItemComponents, model: Types.MapObject?): Types.Item
    if not model then
        model = if definition.Model then definition.Model:Clone() else nil
    end

    local item: Types.Item = setmetatable({
        Kind = "Item" :: "Item",
        Extras = {},
        Definition = definition,
        Components = {},
    }, {
        __index = function(self: Types.Item, index: string)
            return if self.Components[index] ~= nil then self.Components[index] else self.Base[index]
        end,
        __newindex = function(self: Types.Item, index: string, value: any)
            self.Components[index] = value
        end,
    }) :: any

    return item
end

return module