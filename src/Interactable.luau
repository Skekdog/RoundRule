local Types = require(script.Parent.Types)
local module = {}

function module.new(definition: Types.InteractableDefinition, object: BasePart?): Types.Interactable
	object = object or definition.Model:Clone()
	assert(object)

	object.Name = definition.Name
	object.CollisionGroup = "Interactables"
	
	return {
		Definition = definition,
		Object = object,
		Extras = {},
	}
end

return module