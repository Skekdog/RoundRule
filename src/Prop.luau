local Types = require(script.Parent.Types)
local module = {}

local function destroyProp(prop: Types.Prop, params: Types.DamageParams?): ()
    local onBreak = prop.Model:FindFirstChild("OnBreak")
    if onBreak and onBreak:IsA("ModuleScript") then
        (require)(onBreak)(prop, params)
    end
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

function module.new(model: Model): Types.Prop
    local health = model:GetAttribute("Health")
    assert(typeof(health) == "number" or health == nil)

    return {
        Model = model,

        _health = health or 0 :: number?,

        GetHealth = GetHealth,
        SetHealth = SetHealth,
        TryTakeDamage = TryTakeDamage,
    }
end

return module