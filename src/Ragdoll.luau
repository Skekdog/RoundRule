local Replication = require(script.Parent.Replication)
local Types = require(script.Parent.Types)

local Ragdoll = {}

function Ragdoll.Ragdoll(participant: Types.Participant, char: Model): ()
	char:SetAttribute("IsRagdolled", true)
	char:AddTag("Ragdoll")

	participant:SetEquippedItem(nil)
	Replication.SetEquippedItem(participant.Player, nil)

	for _, constraint in char:QueryDescendants("AnimationConstraint:not(#Root)") do
		assert(constraint:IsA("AnimationConstraint"))
		constraint.Enabled = false
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		hum.EvaluateStateMachine = false
		hum.AutoRotate = false
	end

	for _, part in char:QueryDescendants("BasePart") do
		if part:FindFirstAncestorWhichIsA("Accessory") or part:FindFirstAncestor("Item") or part.Name == "Item" then
			continue
		end

		assert(part:IsA("BasePart"))

		part.CollisionGroup = "Corpses"
		part.CanCollide = part.Name ~= "HumanoidRootPart"
	end
end

function Ragdoll.MakeCorpse(participant: Types.Participant, char: Model): Model
	char.Archivable = true
	char = char:Clone()
	char:RemoveTag("Character")
	char:AddTag("Corpse")
	char:AddTag("Prop")
	char.Parent = workspace.Characters
	participant.Player.Character = nil
	Ragdoll.Ragdoll(participant, char)
	participant._character = nil
	participant.Round:LoadProp(char)
	char:SetAttribute("Unidentified", true)
	return char
end

function Ragdoll.Unragdoll(char: Model): ()
	for _, constraint in char:QueryDescendants("AnimationConstraint:not(#Root)") do
		assert(constraint:IsA("AnimationConstraint"))
		constraint.Enabled = true
	end

	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		hum.EvaluateStateMachine = true
		hum.AutoRotate = true
	end

	for _, part in char:QueryDescendants("BasePart") do
		if part:FindFirstAncestorWhichIsA("Accessory") or part:FindFirstAncestor("Item") or part.Name == "Item" then
			continue
		end

		assert(part:IsA("BasePart"))

		part.CollisionGroup = "PlayerCharacterParts"
		part.CanCollide = true
	end

	char:SetAttribute("IsRagdolled", nil)
	char:RemoveTag("Ragdoll")
end

return Ragdoll