local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Types = require(ReplicatedStorage.Shared.RoundRule.Types)

local function GetPrimaryPart(MapObject: Types.MapObject): BasePart
	if MapObject:IsA("BasePart") then
		return MapObject
	end
	return MapObject.PrimaryPart or MapObject:FindFirstChildWhichIsA("BasePart") or error("MapObject has no primary part")
end

return GetPrimaryPart