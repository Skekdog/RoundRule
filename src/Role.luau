local Types = require(script.Parent.Types)
local module = {}

local function GetFormattedRoleName(role: Types.Role): string
    return `<font color="#{role.Definition.Color:ToHex()}">{role.Definition.Name}</font>`
end

local function GetFormattedPlayerName(role: Types.Role, name: string): string
    return `<font color="#{role.Definition.Color:ToHex()}">{name}</font>`
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

        GetFormattedRoleName = GetFormattedRoleName,
        GetExclamatoryString = GetExclamatoryString,
        GetFormattedPlayerName = GetFormattedPlayerName,
        IsAlliedWith = IsAlliedWith,
    }
end

return module