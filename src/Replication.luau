local Types = require(script.Parent.Types)

local module = {}

local remotes = script.Parent.Remotes

function module.ReplicateRole(to: Types.Participant, roleOf: Types.Participant, replicateNil: boolean): ()
	local role = roleOf:GetRole()
	local roleName = if replicateNil or not role then nil else role.Definition.Name
    remotes.UpdatePlayerRole:FireClient(to.Player, roleOf.Player.Name, roleName)
end

function module.ReplicatePlayerStatus(to: Types.Participant, statusOf: Types.Participant, status: Types.ParticipantStatus): ()
	remotes.UpdatePlayerStatus:FireClient(to.Player, statusOf.Player.Name, status)
end

function module.ReplicateCredits(to: Types.Participant): ()
	remotes.UpdateCredits:FireClient(to.Player, to:GetCredits())
end

function module.ReplicateCorpse(to: Types.Participant, corpse: Types.Corpse): ()
	remotes.UpdatePlayerCorpse:FireClient(to.Player, corpse.CorpseView)
end

function module.UpdateInventory(player: Player, mode: "Add" | "Remove" | "Reset", item: string | Types.AnyItem?): ()
	if mode == "Add" or mode == "Remove" then
		assert(item, "Item must not be nil")
	elseif mode == "Reset" then
		assert(not item, "Item must be nil")
	end

	remotes.UpdateInventory:FireClient(player, mode, item)
end

function module.UpdateReserveAmmo(player: Player, mode: "Update" | "Reset", kind: string?, amount: number?): ()
	if mode == "Update" then
		assert(kind, "Kind must not be nil")
		assert(amount, "Amount must not be nil")
	elseif mode == "Reset" then
		assert(kind == nil, "Kind must be nil")
	end

	remotes.UpdateReserveAmmo:FireClient(player, mode, kind, amount)
end

function module.SlayVote(to: Types.Participant, against: Types.Participant): ()
	remotes.SlayVote:FireClient(to.Player, against.Player.Name)
end

return module