local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function GetPrimaryPart(mapThing: Types.MapThing): BasePart
	if mapThing:IsA("BasePart") then
		return mapThing
	end
	return mapThing.PrimaryPart or mapThing:FindFirstChildWhichIsA("BasePart") or error("MapThing has no primary part")
end

return GetPrimaryPart