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
        return item._additionalPrimaryServerData
    end
    return item._additionalAlternateServerData
end

local function ResetLastUse(item: Types.Item, action: "Primary" | "Alternate"): ()
    if action == "Primary" and item.PrimaryLastUse then
        item.PrimaryLastUse = 0
    elseif action == "Alternate" and item.AlternateLastUse then
        item.AlternateLastUse = 0
    end
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

        ResetLastUse = ResetLastUse,
    }, {
        __index = function(self: Types.Item, index: string)
            return if self.Components[index] ~= nil then self.Components[index] else self.Base[index]
        end,
        __newindex = function(self: Types.Item, index: string, value: any)
            if index == "Name" then
                error("Cannot change Name component, consider DisplayName instead")
            end
            self.Components[index] = value
        end,
    }) :: any

    if item.AmmoDefinition then
        item.Ammo = item.AmmoDefinition.Capacity
    end

    return item
end

return module