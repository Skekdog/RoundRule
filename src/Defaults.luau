local Role = require(script.Parent.Role)
local Types = require(script.Parent.Types)

local module = {}

local defaultRoleDefinition: Types.RoleDefinition = {
	Kind = "RoleDefinition",

	Name = "",
	Description = "",
	Color = Color3.new(1, 1, 1),
	Sound = "",

	Allegiance = {Kind = "Solo"},
}

module.Role = Role.fromDefinition(defaultRoleDefinition)

module.WalkSpeed = 16
module.JumpPower = 18
module.Health = 100

return table.freeze(module)