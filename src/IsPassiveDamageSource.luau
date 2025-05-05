local Types = require(script.Parent.Types)

local passiveSources: {Types.GeneralDamageSource} = {
	"Fall",
	"Drown",
}

local function IsPassiveDamageSource(source: Types.DamageSource): boolean
	return if typeof(source) == "table" then false else not not table.find(passiveSources, source)
end

return IsPassiveDamageSource