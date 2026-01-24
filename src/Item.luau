local Types = require(script.Parent.Types)

local module = {}

local function SetServerData(item: Types.Item, action: "Primary" | "Alternate", data: unknown): ()
    if action == "Primary" then
        item._additionalPrimaryServerData = data
    else
        item._additionalAlternateServerData = data
    end
end

local function GetServerData(item: Types.Item, action: "Primary" | "Alternate"): ()
    if action == "Primary" then
        local data = item._additionalPrimaryServerData
        item:SetServerData(action, nil)
        return data
    end

    local data = item._additionalAlternateServerData
    item:SetServerData(action, nil)

    return data
end

function module.new(definition: Types.ItemComponents, model: Types.MapObject?): Types.Item
    if not model then
        model = if definition.Model then definition.Model:Clone() else nil
    end

    local item: Types.Item = setmetatable({
        Kind = "Item" :: "Item",
        Extras = {},
        Base = definition,
        Components = {
            Model = model
        },

        SetServerData = SetServerData,
        GetServerData = GetServerData,
    }, {
        __index = function(self: Types.Item, index: string)
            return if self.Components[index] ~= nil then self.Components[index] else self.Base[index]
        end,
        __newindex = function(self: Types.Item, index: string, value: any)
            self.Components[index] = value
        end,
    }) :: any

    if item.AmmoDefinition then
        item.Ammo = item.AmmoDefinition.Capacity
    end

    return item
end

return module