local RunBeforeHit = require(script.Parent.RunBeforeHit)
local RunOnHitClient = require(script.Parent.RunOnHitClient)
local Types = require(script.Parent.Types)

local module = {}

function module.new(definition: Types.ExplosionInfo, position: Vector3, attacker: Types.Participant?): Types.ExplosionParams
	return {
		Kind = "ExplosionParams",
		Definition = definition,
		Position = position,
		Attacker = attacker,

		RunBeforeHit = RunBeforeHit,
		RunOnHitClient = RunOnHitClient,
	}
end

return module