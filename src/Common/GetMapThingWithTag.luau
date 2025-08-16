local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function hasTag(instance: Instance, tag: string | {string}): boolean
	if typeof(tag) == "string" then
		return instance:HasTag(tag)
	end

	for _, t in tag do
		if instance:HasTag(t) then
			return true
		end
	end

	return false
end

local function GetMapThingWithTag(descendant: Instance, tag: string | {string}): Types.MapThing?
	if hasTag(descendant, tag) then
		assert(descendant:IsA("BasePart") or descendant:IsA("Model"), "MapThing must be a BasePart or Model")
		return descendant
	end

	local thing = descendant.Parent
	assert(thing, "Can't get MapThing of unparented Instance")

	repeat
		if hasTag(thing, tag) then
			assert(thing:IsA("BasePart") or thing:IsA("Model"), "MapThing must be a BasePart or Model")
			return thing
		end
		thing = thing.Parent
	until thing == game

	return nil
end

return GetMapThingWithTag