local HasTag = require(script.Parent.HasAnyTag)

local function GetTaggedDescendants(instance: Instance, tag: string | {string}): {Instance}
	local tagged: {Instance} = {}

	if typeof(tag) == "string" then
		tag = {tag}
	end
	assert(typeof(tag) == "table")

	for _, v in instance:GetDescendants() do
		if HasTag(v, tag) then
			table.insert(tagged, v)
		end
	end

	return tagged
end

return GetTaggedDescendants