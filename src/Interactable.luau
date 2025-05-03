local Types = require(script.Parent.Types)
local module = {}

local function destroyInteractable(interactable: Types.Interactable, params: Types.DamageParams?): ()
	local onBreakServer = interactable.Definition.OnBreakServer
	if onBreakServer then
		onBreakServer(interactable, params)
	end

	interactable.Object:Destroy()
end

local function GetHealth(interactable: Types.Interactable): number?
	return interactable._health
end

local function SetHealth(interactable: Types.Interactable, health: number): ()
	interactable._health = health
end

local function TryTakeDamage(interactable: Types.Interactable, params: Types.DamageParams, deferDeath: boolean?): boolean
	if interactable.Round and interactable.Round:IsPreGame() then
        return false
    end

    local health = interactable:GetHealth()
    if health == nil or health <= 0 then
        return false
    end

    interactable:SetHealth(health - params.Amount)

    if health - params.Amount <= 0 then
        if deferDeath then
            task.defer(destroyInteractable, interactable, params)
        else
            destroyInteractable(interactable, params)
        end
    end

    return true
end

function module.new(definition: Types.InteractableDefinition, object: BasePart?): Types.Interactable
	object = object or definition.Model:Clone()
	assert(object)

	object.Name = definition.Name
	object.CollisionGroup = "Interactables"

	local health = object:GetAttribute("Health")
    assert((typeof(health) == "number") or typeof(health) == "nil")
	
	return {
		Kind = "Interactable",
		Definition = definition,
		Object = object,
		Extras = {},

		_health = health,
		GetHealth = GetHealth,
		SetHealth = SetHealth,
		TryTakeDamage = TryTakeDamage,
	}
end

return module