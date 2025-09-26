local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HasTag = require(script.Parent.HasAnyTag)
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function GetMapObjectWithTag(descendant: Instance, tag: string | {string}): Types.MapObject?
	if HasTag(descendant, tag) then
		assert(descendant:IsA("BasePart") or descendant:IsA("Model"), "MapObject must be a BasePart or Model")
		return descendant
	end

	local thing = descendant.Parent
	assert(thing, "Can't get MapObject of unparented Instance")

	repeat
		if HasTag(thing, tag) then
			assert(thing:IsA("BasePart") or thing:IsA("Model"), "MapObject must be a BasePart or Model")
			return thing
		end
		thing = thing.Parent
	until thing == game

	return nil
end

return GetMapObjectWithTag