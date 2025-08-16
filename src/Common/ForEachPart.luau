
local function ForEachPart(instance: Instance, callback: (BasePart) -> ()): ()
	if instance:IsA("BasePart") then
		callback(instance)
	end

	for _, part in instance:GetDescendants() do
		if part:IsA("BasePart") then
			callback(part)
		end
	end
end

return ForEachPart