local Types = require(script.Parent.Types)

local DamageSource = {}

local passiveSources: {Types.GeneralDamageSource} = {
	"Fall",
	"Drown",
}

function DamageSource.IsPassive(source: Types.DamageSource): boolean
	return if typeof(source) == "table" then false else not not table.find(passiveSources, source)
end

function DamageSource.IsFirearm(source: Types.DamageSource): boolean
	local kind: Types.GeneralDamageSource = if typeof(source) == "table" then source.DamageKind or "Other" else source
	return kind == "Shot"
end

function DamageSource.IsMelee(source: Types.DamageSource): boolean
	local kind: Types.GeneralDamageSource = if typeof(source) == "table" then source.DamageKind or "Other" else source
	return kind == "Stab" or kind == "Bludgeon"
end

return DamageSource