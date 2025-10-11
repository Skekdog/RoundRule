local CollectionService = game:GetService("CollectionService")

local function GetTaggedDescendants(instance: Instance, tags: string | {string}): {Instance}
	assert(instance:IsDescendantOf(game), "GetTaggedDescendants must be called on a descendant of game")
	local tagged: {Instance} = {}

	if typeof(tags) == "string" then
		tags = {tags}
	end
	assert(typeof(tags) == "table")

	for _, tag in tags do
		for _, v in CollectionService:GetTagged(tag) do
			if v:IsDescendantOf(instance) then
				table.insert(tagged, v)
			end
		end
	end

	return tagged
end

return GetTaggedDescendants