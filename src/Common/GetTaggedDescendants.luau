local CollectionService = game:GetService("CollectionService")

local function GetTaggedDescendants(instance: Instance, tag: string): {Instance}
	local tagged: {Instance} = {}

	for _, v in CollectionService:GetTagged(tag) do
		if v:IsDescendantOf(instance) then
			table.insert(tagged, v)
		end
	end

	return tagged
end

return GetTaggedDescendants