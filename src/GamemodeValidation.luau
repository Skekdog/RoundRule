local Types = require(script.Parent.Types)

-- Note: this only validates thing that the type-checker can't validate.

local GamemodeValidation = {}

function GamemodeValidation.ValidateDefinition(instance: Instance, definition: Types.GamemodeDefinition): Types.GamemodeDefinition
	assert(typeof(definition) == "table", "Gamemode must be a table")

	assert(definition.Name == instance.Name, "Gamemode name must match script name")

	for i, v in definition.AvailableAmmo do
		assert(i == v.Name, "Ammo name in AvailableAmmo must match index")
	end

	for i, v in definition.AvailableItems do
		assert(i == v.Name, "Item name in AvailableItems must match index")
	end

	for i, v in definition.Roles do
		assert(i == v.Name, "Role name in Roles must match index")
	end

	return definition
end

function GamemodeValidation.ValidateGamemodeScript(instance: Instance): Types.GamemodeDefinition
	assert(instance:IsA("ModuleScript"), "Gamemode script must be a ModuleScript")
	return GamemodeValidation.ValidateDefinition(instance, (require)(instance))
end

return GamemodeValidation