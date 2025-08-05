local GetDisplayName = require(script.Parent.Common.GetDisplayName)
local Types = require(script.Parent.Types)
local module = {}

local function GetFormattedString(role: Types.Role, str: string): string
    return `<font color="#{role.Definition.Color:ToHex()}">{str}</font>`
end

local function GetFormattedName(role: Types.Role): string
    return role:GetFormattedString(GetDisplayName(role.Definition))
end

local function GetExclamatoryString(role: Types.Role): string
    return if role.Definition.IsExclamatory then "!" else "."
end

local function IsAlliedWith(role: Types.Role, otherRole: Types.Role): boolean
    return table.find(role.Definition.Allies or {}, otherRole.Definition.Name) ~= nil
end

function module.fromDefinition(roleDefinition: Types.RoleDefinition): Types.Role
    return {
        Kind = "Role",
        Definition = roleDefinition,

        GetFormattedName = GetFormattedName,
        GetExclamatoryString = GetExclamatoryString,
        GetFormattedString = GetFormattedString,
        IsAlliedWith = IsAlliedWith,
    }
end

return module