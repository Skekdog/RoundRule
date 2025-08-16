local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function GetMapThingWithTag(descendant: Instance, tag: string): Types.MapThing?
	if descendant:HasTag(tag) then
		assert(descendant:IsA("BasePart") or descendant:IsA("Model"), "MapThing must be a BasePart or Model")
		return descendant
	end

	local thing = descendant.Parent
	assert(thing, "Can't get MapThing of unparented Instance")

	repeat
		if thing:HasTag(tag) then
			assert(thing:IsA("BasePart") or thing:IsA("Model"), "MapThing must be a BasePart or Model")
			return thing
		end
		thing = thing.Parent
	until thing == game

	return nil
end

return GetMapThingWithTag