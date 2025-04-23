local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.InteractableDefinition): Types.Interactable
	local object = definition.Model:Clone()
	object.CollisionGroup = "InteractableObjects"
	
	return {
		Definition = definition,
		Object = object,
		Extras = {},
	}
end

return module