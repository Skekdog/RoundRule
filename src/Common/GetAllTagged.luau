local CollectionService = game:GetService("CollectionService")

local function GetAllTagged(tags: string | {string}): {Instance}
	if typeof(tags) == "string" then
		tags = {tags}
	end
	assert(typeof(tags) == "table")

	local tagged: {Instance} = {}

	for _, tag in tags do
		for _, v in CollectionService:GetTagged(tag) do
			if not table.find(tagged, v) then
				table.insert(tagged, v)
			end
		end
	end

	return tagged
end

return GetAllTagged