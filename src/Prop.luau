local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local Types = require(script.Parent.Types)
local module = {}

module.Tags = {"Prop", "Item", "AmmoBox", "Interactable", "Corpse"}

local function destroyProp(prop: Types.Prop, params: Types.DamageParams): ()
    prop.OnBreak(prop, params)
    prop.Model:Destroy()
end

local function tryRunOnDamage(prop: Types.Prop, params: Types.DamageParams): boolean?
    local onDamage = prop.Model:FindFirstChild("OnDamage")
    if onDamage and onDamage:IsA("ModuleScript") then
        return ((require)(onDamage) :: Types.OnPropBreak)(prop, params)
    end
    return true
end

local function OnBreak(prop: Types.Prop, params: Types.DamageParams): ()
    local onBreak = prop.Model:FindFirstChild("OnBreak")
    if onBreak and onBreak:IsA("ModuleScript") then
        -- To allow the OnBreak script to continue running after the prop is destroyed :ghost:
        prop.OnBreak = ((require)(onBreak) :: Types.OnPropBreak)
        prop.OnBreak(prop, params)
    end
end

local function GetHealth(prop: Types.Prop): number?
    return prop._health
end

local function SetHealth(prop: Types.Prop, health: number): ()
    prop._health = health
    prop.Model:SetAttribute("Health", health)
end

local function TryTakeDamage(prop: Types.Prop, params: Types.DamageParams, deferDeath: boolean?): boolean
    assert(prop.Round)

    local health = prop:GetHealth()
    if health and health <= 0 then
        return false
    end

    if prop.Round.Config.BeforeDamageProp then
        if not prop.Round.Config.BeforeDamageProp(prop.Round, prop, params) then
            return false
        end
    end

    if prop.Round.Gamemode.BeforeDamageProp then
        if not prop.Round.Gamemode.BeforeDamageProp(prop.Round, prop, params) then
            return false
        end
    end

    if prop.Interactable and prop.Interactable.BeforeTakeDamage then
        if not prop.Interactable.BeforeTakeDamage(prop, params) then
            return false
        end
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

function module.new(model: Types.MapObject, round: Types.Round?, interactable: Types.InteractableDefinition?): Types.Prop
    local health = model:GetAttribute("Health")
    assert((typeof(health) == "number") or typeof(health) == "nil")

    local prop: Types.Prop = {
        Kind = "Prop",
        Model = model,
        Extras = {},

        Interactable = interactable,

        Round = round,

        _health = health,

        GetHealth = GetHealth,
        SetHealth = SetHealth,
        TryTakeDamage = TryTakeDamage,
        OnBreak = interactable and interactable.OnBreakServer or OnBreak,
    }

    if interactable then
        ForEachPart(model, function(part)
            part.CollisionGroup = "Interactables"
        end)

        if RunService:IsClient() and interactable.OnLoadClient then
            task.defer(interactable.OnLoadClient, prop)
        elseif RunService:IsServer() and interactable.OnLoadServer then
            task.defer(interactable.OnLoadServer, prop)
        end
    end

    return prop
end

return table.freeze(module)