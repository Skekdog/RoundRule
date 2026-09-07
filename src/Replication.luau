local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local EventStrings = require(script.Parent.EventStrings)
local Types = require(script.Parent.Types)

local module = {}

export type ReplicationTarget = Player | {[any]: Player} | "All"

function module.FireToTargets(remote: RemoteEvent, target: ReplicationTarget, ...): ()
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
	return instance:IsDescendantOf(ReplicatedStorage) or instance:IsDescendantOf(workspace) or instance:IsDescendantOf(SoundService)
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

module.ReplicatedData = replicatedData

function module.ReplicateRole(target: ReplicationTarget, roleOf: Types.Participant, replicateNil: boolean): ()
	module.FireToTargets(remotes.UpdatePlayerRole, target, roleOf.Player.Name, if replicateNil then nil else roleOf:GetRole().Definition.Name)
end

function module.ReplicatePlayerStatus(target: ReplicationTarget, statusOf: Types.Participant, status: Types.ParticipantStatus?): ()
	module.FireToTargets(remotes.UpdatePlayerStatus, target, statusOf.Player.Name, status)
end

function module.ReplicateCredits(target: Types.Participant): ()
	module.FireToTargets(remotes.UpdateCredits, target.Player, target:GetCredits())
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

	module.FireToTargets(remotes.UpdatePlayerCorpse, target, view, covert)
end

function module.ClearCorpse(target: ReplicationTarget, participant: Types.Participant): ()
	module.FireToTargets(remotes.UpdatePlayerCorpse, target, participant.Player.Name)
end

function module.ReplicateRoundEndMusic(target: ReplicationTarget, music: Sound, startedAtServerTime: number): ()
	assert(module.CanInstanceReplicate(music), "Music must be parented to a replicatable service")
	module.FireToTargets(remotes.RoundEndMusic, target, music, startedAtServerTime)
end

function module.UpdateInventory(target: ReplicationTarget, mode: "Add" | "Update" | "Remove", item: Types.Item): ()
	module.FireToTargets(remotes.UpdateInventory, target, mode, if mode == "Add" or mode == "Update" then module.GetItemReplicate(item, true) else item.Name)
end

function module.ResetInventory(target: ReplicationTarget): ()
	module.FireToTargets(remotes.UpdateInventory, target, "Reset")
end

function module.SetEquippedItem(target: ReplicationTarget, item: string?): ()
	module.FireToTargets(remotes.SetEquippedItem, target, item)
end

function module.DamageTaken(target: ReplicationTarget, amount: number, kind: Types.DamageSource): ()
	module.FireToTargets(remotes.DamageTaken, target, amount, if typeof(kind) == "string" then kind else kind.Name)
end

function module.UpdateReserveAmmo(target: ReplicationTarget, mode: "Update" | "Reset", kind: string?, amount: number?): ()
	if mode == "Update" then
		assert(kind, "Kind must not be nil")
		assert(amount, "Amount must not be nil")
	elseif mode == "Reset" then
		assert(kind == nil, "Kind must be nil")
	end

	module.FireToTargets(remotes.UpdateReserveAmmo, target, mode, kind, amount)
end

function module.SlayVote(target: ReplicationTarget, against: Types.Participant): ()
	module.FireToTargets(remotes.SlayVote, target, against.Player.Name)
end

function module.SendMessage(target: ReplicationTarget, message: string, kind: Types.MessageKind?): ()
	module.FireToTargets(remotes.SendMessage, target, message, kind or "All")
end

function module.InformFreeKill(target: ReplicationTarget, reason: string?): ()
	module.FireToTargets(remotes.FreeKill, target, reason)
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

function module.ReplicateGamemode(gamemode: Types.GamemodeDefinition): ()
	replicatedData:SetAttribute("Gamemode", gamemode.Name)
	module.FireToTargets(remotes.Gamemode, "All", gamemode.Name)
end

function module.ReplicateMap(): ()
	module.FireToTargets(remotes.MapLoaded, "All")
end

function module.Reset(): ()
	remotes.Reset:FireAllClients()
    module.ReplicateAdvanceTime()
end

function module.RunOnHitClient(item: Types.ItemComponents, participant: Types.Participant, hitPart: BasePart): ()
	remotes.RunOnHitClient:FireClient(participant.Player, item.Name, hitPart)
end

function module.CallRoleToCorpse(target: ReplicationTarget, model: Model): ()
	module.FireToTargets(remotes.CallToCorpse, target, model)
end

function module.ReplicateRoundFinish(round: Types.Round): ()
	local victory = round.VictoryData
	assert(victory)

	local victorKind: "Participant" | "Role" = victory.Victor.Kind
	local victorName = if victory.Victor.Kind == "Participant" then victory.Victor.Player.Name else victory.Victor.Definition.Name

	local highlights: {Types.Highlight} = {}
	for _, highlight in round.Highlights do
		local cutHighlight = table.clone(highlight)
		cutHighlight.Participants = nil

		table.insert(highlights, cutHighlight)
	end

	local events: {Types.ClientEventData} = {}
	for _, event in round:GetEventLog() do
		table.insert(events, {
			Timestamp = event.Timestamp,
			Description = EventStrings(event)
		})
	end

	local scores: {[string]: Types.ScoreTable} = {}
	for _, participant in round:GetParticipants() do
		scores[participant.Player.Name] = participant.Scores
	end

	local data: Types.ClientRoundFinishData = {
		VictorKind = victorKind,
		VictorName = victorName,

		StartTime = assert(round.StartTime),

		Highlights = highlights,
		Events = events,
		Scores = scores,
	}

	remotes.RoundFinishData:FireAllClients(data)
end

return table.freeze(module)