local function GetTaggedDescendants(instance: Instance, tag: string | {string}): {Instance}
	local tagged: {Instance} = {}

	if typeof(tag) == "string" then
		tag = {tag}
	end
	assert(typeof(tag) == "table")

	for _, v in instance:GetDescendants() do
		for _, tag in tag do
			if v:HasTag(tag) then
				table.insert(tagged, v)
				break
			end
		end
	end

	return tagged
end

return GetTaggedDescendants