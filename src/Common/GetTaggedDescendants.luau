local GetAllTagged = require(script.Parent.GetAllTagged)

local function GetTaggedDescendants(instance: Instance, tag: string | {string}): {Instance}
	local tagged: {Instance} = {}

	for _, v in GetAllTagged(tag) do
		if v:IsDescendantOf(instance) then
			table.insert(tagged, v)
		end
	end

	return tagged
end

return GetTaggedDescendants