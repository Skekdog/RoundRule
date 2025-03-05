local EventStrings = require(script.Parent.EventStrings)
local Types = require(script.Parent.Types)

local module = {}

local remotes = script.Parent.Remotes
local replicatedData = script.Parent.ReplicatedData

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

function module.SendMessage(player: Player, message: string, kind: Types.MessageKind?): ()
	remotes.SendMessage:FireClient(player, message, kind or "All")
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
	replicatedData:SetAttribute("Winner", if victor then if victor.Kind == "Role" then victor:GetFormattedRoleName() else victor:GetFormattedName() else nil)
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

return module