local EventStrings = require(script.Parent.EventStrings)
local Types = require(script.Parent.Types)

local module = {}

export type ReplicationTarget = Player | {[string | number]: Player} | "All"

local function fireToTargets(remote: RemoteEvent, target: ReplicationTarget, ...): ()
	if target == "All" then
		remote:FireAllClients(...)
	else
		if typeof(target) == "Instance" then
			target = {target}
		end
		assert(typeof(target) == "table")
		for _, v in target do
			assert(v)
			remote:FireClient(v, ...)
		end
	end
end

local remotes = script.Parent.Remotes
local replicatedData = script.Parent.ReplicatedData

function module.ReplicateRole(target: ReplicationTarget, roleOf: Types.Participant, replicateNil: boolean): ()
	local role = roleOf:GetRole()
	local roleName = if replicateNil or not role then nil else role.Definition.Name
	fireToTargets(remotes.UpdatePlayerRole, target, roleOf.Player.Name, roleName)
end

function module.ReplicatePlayerStatus(target: ReplicationTarget, statusOf: Types.Participant, status: Types.ParticipantStatus): ()
	fireToTargets(remotes.UpdatePlayerStatus, target, statusOf.Player.Name, status)
end

function module.ReplicateCredits(target: Types.Participant): ()
	fireToTargets(remotes.UpdateCredits, target.Player, target:GetCredits())
end

function module.ReplicateCorpse(target: ReplicationTarget, corpse: Types.Corpse): ()
	fireToTargets(remotes.UpdatePlayerCorpse, target, corpse.CorpseView)
end

function module.UpdateInventory(target: ReplicationTarget, mode: "Add" | "Remove" | "Reset", item: string | Types.AnyItem?): ()
	if mode == "Add" or mode == "Remove" then
		assert(item, "Item must not be nil")
	elseif mode == "Reset" then
		assert(not item, "Item must be nil")
	end

	fireToTargets(remotes.UpdateInventory, target, mode, item)
end

function module.UpdateReserveAmmo(target: ReplicationTarget, mode: "Update" | "Reset", kind: string?, amount: number?): ()
	if mode == "Update" then
		assert(kind, "Kind must not be nil")
		assert(amount, "Amount must not be nil")
	elseif mode == "Reset" then
		assert(kind == nil, "Kind must be nil")
	end

	fireToTargets(remotes.UpdateReserveAmmo, target, mode, kind, amount)
end

function module.SlayVote(target: ReplicationTarget, against: Types.Participant): ()
	fireToTargets(remotes.SlayVote, target, against.Player.Name)
end

function module.SendMessage(target: ReplicationTarget, message: string, kind: Types.MessageKind?): ()
	fireToTargets(remotes.SendMessage, target, message, kind or "All")
end

function module.ReplicateAdvanceTime(target: number?): ()
	replicatedData:SetAttribute("AdvanceTime", target)
end

function module.ReplicateRoundPhase(target: Types.RoundPhase): ()
	replicatedData:SetAttribute("Phase", target)
end

function module.ReplicateRoundPause(target: boolean): ()
	replicatedData:SetAttribute("Paused", target)
end

function module.ReplicateStartTime(target: number?): ()
	replicatedData:SetAttribute("StartTime", target)
end

function module.ReplicateWinner(victor: Types.Victor?): ()
	replicatedData:SetAttribute("WinnerKind", if victor then victor.Kind else nil)
	replicatedData:SetAttribute("Winner", if victor then if victor.Kind == "Role" then victor.Definition.Name else victor.Player.Name else nil)
end

function module.ReplicateGamemode(gamemode: Types.Gamemode): ()
	replicatedData:SetAttribute("Gamemode", gamemode.Name)
end

function module.AddEvent(event: Types.RoundEvent): ()
	local value = Instance.new("StringValue")
	value.Name = tostring(event.Timestamp)
	value.Value = EventStrings(event)

	if event.Data.Kind == "DeathRoundEvent" then
		local corpse = event.Data.Victim:GetCorpse()
		assert(corpse, "Victim has no corpse")

		value:SetAttribute("WasSelfDefense", corpse.CorpseView.WasSelfDefense)
		value:SetAttribute("WasFreeKill", corpse.CorpseView.WasFreeKill)
		value:SetAttribute("WasCorrectKill", corpse.WasCorrectKill)
	end

	value.Parent = replicatedData.Events
end

function module.AddScore(participant: Types.Participant): ()
	local value = Instance.new("StringValue")
	value.Name = participant.Player.Name
	
	for reason, score in participant:GetScores() do
		assert(score)
		value:SetAttribute(reason:gsub(" ", "_"), score)
	end

	value.Parent = replicatedData.Scores
end

function module.ClearEvents(): ()
	replicatedData.Events:ClearAllChildren()
end

function module.ClearHighlights(): ()
	replicatedData.Highlights:ClearAllChildren()
end

function module.ClearScores(): ()
	replicatedData.Scores:ClearAllChildren()
end

function module.Reset(): ()
	remotes.Reset:FireAllClients()

	module.ClearEvents()
	module.ClearHighlights()
	module.ClearScores()

    module.ReplicateStartTime()
    module.ReplicateAdvanceTime()
    module.ReplicateWinner()
end

return module