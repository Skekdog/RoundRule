local ReplicatedStorage = game:GetService("ReplicatedStorage")
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

function module.CanInstanceReplicate(instance: Instance): boolean
	-- note: instances under ReplicatedFirst will not be nil if passed to the client, but they will not replicated either. That is, updating their properties on the server will have no effect on the client.
	return instance:IsDescendantOf(ReplicatedStorage) or instance:IsDescendantOf(workspace)
end

function module.GetItemReplicate(item: Types.Item, replicateModel: boolean, replicateComponents: {string}?): Types.ItemReplication
	local components
	if replicateComponents then
		components = {}
		for _, component in replicateComponents do
			components[component] = item.Components[component]
		end
	end

	return {
		Name = item.Name,
		Model = if replicateModel then item.Model else nil,
		Components = components or item.Components,
	}
end

local remotes = script.Parent.Remotes
local replicatedData = script.Parent.ReplicatedData

function module.ReplicateRole(target: ReplicationTarget, roleOf: Types.Participant, replicateNil: boolean): ()
	fireToTargets(remotes.UpdatePlayerRole, target, roleOf.Player.Name, if replicateNil then nil else roleOf:GetRole().Definition.Name)
end

function module.ReplicatePlayerStatus(target: ReplicationTarget, statusOf: Types.Participant, status: Types.ParticipantStatus?): ()
	fireToTargets(remotes.UpdatePlayerStatus, target, statusOf.Player.Name, status)
end

function module.ReplicateCredits(target: Types.Participant): ()
	fireToTargets(remotes.UpdateCredits, target.Player, target:GetCredits())
end

function module.ReplicateCorpse(target: ReplicationTarget, corpse: Types.Corpse, covert: boolean): ()
	local view: Types.ClientCorpseView
	if typeof(corpse.CorpseView.DamageSource) == "table" then
		local clientView: Types.ClientCorpseView = table.clone(corpse.CorpseView) :: any
		clientView.DamageSource = module.GetItemReplicate(corpse.CorpseView.DamageSource, false, {"IconContent"})
		view = clientView
	else
		view = (corpse.CorpseView :: Types.BaseCorpseView) :: Types.ClientCorpseView
	end

	fireToTargets(remotes.UpdatePlayerCorpse, target, view, covert)
end

function module.ClearCorpse(target: ReplicationTarget, participant: Types.Participant): ()
	fireToTargets(remotes.UpdatePlayerCorpse, target, participant.Player.Name)
end

function module.ReplicateRoundEndMusic(target: ReplicationTarget, music: Sound, startedAtServerTime: number): ()
	assert(module.CanInstanceReplicate(music), "Music must be parented to a replicatable service")
	fireToTargets(remotes.RoundEndMusic, target, music, startedAtServerTime)
end

function module.UpdateInventory(target: ReplicationTarget, mode: "Add" | "Remove", item: Types.Item): ()
	fireToTargets(remotes.UpdateInventory, target, mode, if mode == "Add" then module.GetItemReplicate(item, true) else item.Name)
end

function module.ResetInventory(target: ReplicationTarget): ()
	fireToTargets(remotes.UpdateInventory, target, "Reset")
end

function module.SetEquippedItem(target: ReplicationTarget, item: string?): ()
	fireToTargets(remotes.SetEquippedItem, target, item)
end

function module.DamageTaken(target: ReplicationTarget, amount: number, kind: Types.DamageSource): ()
	fireToTargets(remotes.DamageTaken, target, amount, if typeof(kind) == "string" then kind else kind.Name)
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

function module.InformFreeKill(target: ReplicationTarget, reason: string?): ()
	fireToTargets(remotes.FreeKill, target, reason)
end

function module.ReplicateAdvanceTime(target: number?): ()
	replicatedData:SetAttribute("AdvanceTime", target)
end

function module.ReplicateRoundPhase(target: Types.Phase): ()
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

function module.ReplicateGamemode(gamemode: Types.GamemodeDefinition): ()
	replicatedData:SetAttribute("Gamemode", gamemode.Name)
end

function module.ReplicateMap(): ()
	fireToTargets(remotes.MapLoaded, "All")
end

function module.AddEvent(event: Types.Event): ()
	local value = Instance.new("StringValue")
	value.Name = tostring(event.Timestamp)
	value.Value = EventStrings(event)

	if event.Data.Kind == "DeathRoundEvent" then
		local corpse = event.Data.Victim.Corpse
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

	for reason, score in participant.Scores do
		local scoreValue = Instance.new("IntValue")
		scoreValue.Name = reason
		scoreValue.Value = score or 0
		scoreValue.Parent = value
	end

	value.Parent = replicatedData.Scores
end

function module.AddHighlight(highlight: Types.Highlight): ()
	local value = Instance.new("StringValue")
	value.Name = highlight.Title
	value.Value = highlight.Description
	value:SetAttribute("Priority", highlight.Priority)
	value:SetAttribute("Group", highlight.Group)

	value.Parent = replicatedData.Highlights
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

function module.RunOnHitClient(item: Types.ItemComponents, participant: Types.Participant, hitPart: BasePart): ()
	remotes.RunOnHitClient:FireClient(participant.Player, item.Name, hitPart)
end

function module.CallRoleToCorpse(target: ReplicationTarget, model: Model): ()
	fireToTargets(remotes.CallToCorpse, target, model)
end

return table.freeze(module)