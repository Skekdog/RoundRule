local Types = require(script.Parent.Types)
local module = {}

local function destroyProp(prop: Types.MapProp, params: Types.DamageParams): ()
    local onBreak = prop.Model:FindFirstChild("OnBreak")
    if onBreak and onBreak:IsA("ModuleScript") then
        ((require)(onBreak) :: Types.OnMapPropBreak)(prop, params)
    end

    prop.Model:Destroy()
end

local function tryRunOnDamage(prop: Types.MapProp, params: Types.DamageParams): boolean?
    local onDamage = prop.Model:FindFirstChild("OnDamage")
    if onDamage and onDamage:IsA("ModuleScript") then
        return ((require)(onDamage) :: Types.OnMapPropBreak)(prop, params)
    end
    return true
end

local function GetHealth(prop: Types.MapProp): number?
    return prop._health
end

local function SetHealth(prop: Types.MapProp, health: number): ()
    prop._health = health
end

local function TryTakeDamage(prop: Types.MapProp, params: Types.DamageParams, deferDeath: boolean?): boolean
    if prop.Round:IsPreGame() then
        return false
    end
    
    local health = prop:GetHealth()
    if health and health <= 0 then
        return false
    end

    local canDamage = tryRunOnDamage(prop, params)
    if canDamage == false then -- if nil we still want to deal damage
        return false
    end

    if health == nil then
        return false
    end

    prop:SetHealth(health - params.Amount)

    if health - params.Amount <= 0 then
        if deferDeath then
            task.defer(destroyProp, prop, params)
        else
            destroyProp(prop, params)
        end
    end

    return true
end

function module.new(model: Types.DataModelMapProp, round: Types.Round): Types.MapProp
    local health = model:GetAttribute("Health")
    assert((typeof(health) == "number") or typeof(health) == "nil")

    return {
        Kind = "MapProp",
        Model = model,

        Round = round,

        _health = health,

        GetHealth = GetHealth,
        SetHealth = SetHealth,
        TryTakeDamage = TryTakeDamage,
    }
end

return module