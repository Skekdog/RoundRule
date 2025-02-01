local Types = require(script.Parent.Types)
local module = {}

local function destroyProp(prop: Types.Prop, params: Types.DamageParams?): ()
    local onBreak = prop.Model:FindFirstChild("OnBreak")
    if onBreak and onBreak:IsA("ModuleScript") then
        ((require)(onBreak) :: Types.OnPropBreak)(prop, params)
    end

    prop.Model:Destroy()
end

local function GetHealth(prop: Types.Prop): number?
    return prop._health
end

local function SetHealth(prop: Types.Prop, health: number): ()
    prop._health = health
end

local function TryTakeDamage(prop: Types.Prop, params: Types.DamageParams): ()
    local health = prop:GetHealth()
    if health == nil then
        return
    end

    prop:SetHealth(health - params.Amount)

    if health - params.Amount <= 0 then
        destroyProp(prop, params)
    end
end

function module.new(model: Types.DataModelProp): Types.Prop
    local health = model:GetAttribute("Health")
    assert((typeof(health) == "number") or typeof(health) == "nil")

    return {
        Kind = "Prop",
        Model = model,

        _health = health,

        GetHealth = GetHealth,
        SetHealth = SetHealth,
        TryTakeDamage = TryTakeDamage,
    }
end

return module