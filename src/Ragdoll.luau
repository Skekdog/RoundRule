local Types = require(script.Parent.Types)

local Ragdoll = {}

function Ragdoll.Ragdoll(char: Model): ()
	char:SetAttribute("IsRagdolled", true)

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
		if part:FindFirstAncestorWhichIsA("Accessory") then
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
	Ragdoll.Ragdoll(char)
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
		if part:FindFirstAncestorWhichIsA("Accessory") then
			continue
		end

		assert(part:IsA("BasePart"))

		part.CollisionGroup = "PlayerCharacterParts"
		part.CanCollide = true
	end

	char:SetAttribute("IsRagdolled", nil)
end

return Ragdoll