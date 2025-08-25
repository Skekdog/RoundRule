
local function HasAnyTag(instance: Instance, tag: string | {string}): boolean
	if typeof(tag) == "string" then
		tag = {tag}
	end
	assert(typeof(tag) == "table")

	for _, v in tag do
		if instance:HasTag(v) then
			return true
		end
	end

	return false
end

return HasAnyTag