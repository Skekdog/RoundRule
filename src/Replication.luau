local Types = require(script.Parent.Types)

local module = {}

local remotes = script.Parent.Remotes

function module.ReplicateRole(to: Types.Participant, roleOf: Types.Participant, replicateNil: boolean): ()
	local role = roleOf:GetRole()
	local roleName = if replicateNil or not role then nil else role.Definition.Name
    remotes.UpdatePlayerRole:FireClient(to.Player, roleOf.Player.Name, roleName)
end

return module