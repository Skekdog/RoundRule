local Types = require(script.Parent.Types)

local module = {}

function module.new(definition: Types.ExplosionInfo, position: Vector3, attacker: Types.Participant?, item: Types.ItemComponents?): Types.ExplosionParams
	return {
		Kind = "ExplosionParams",

		Definition = definition,
		Position = position,
		Attacker = attacker,
		SourceItem = item,
	}
end

return module