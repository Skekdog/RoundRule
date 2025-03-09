local Replication = require(script.Parent.Replication)
local Types = require(script.Parent.Types)

local function RunOnHitClient(item: Types.AnyWeapon, participant: Types.Participant, hitPart: BasePart): ()
	Replication.RunOnHitClient(item, participant, hitPart)
end

return RunOnHitClient