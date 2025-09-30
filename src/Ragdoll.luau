local Players = game:GetService("Players")

type HingeJoint = {
	Kind: "Hinge",
	Part0: string,
	Part1: string,
	LowerAngle: number,
	UpperAngle: number,
}

type BallJoint = {
	Kind: "Ball",
	Part0: string,
	Part1: string,
	UpperAngle: number,
	TwistLowerAngle: number,
	TwistUpperAngle: number,
	MaxFrictionTorque: number?,
}

type Joint = HingeJoint | BallJoint

local jointInfo: {[string]: Joint} = {
	LeftAnkle = {Kind = "Hinge", Part0 = "LeftLowerLeg", Part1 = "LeftFoot", LowerAngle = -10, UpperAngle = 10},
	RightAnkle = {Kind = "Hinge", Part0 = "RightLowerLeg", Part1 = "RightFoot", LowerAngle = -10, UpperAngle = 10},
	LeftKnee = {Kind = "Hinge", Part0 = "LeftUpperLeg", Part1 = "LeftLowerLeg", LowerAngle = -90, UpperAngle = 10},
	RightKnee = {Kind = "Hinge", Part0 = "RightUpperLeg", Part1 = "RightLowerLeg", LowerAngle = -90, UpperAngle = 10},
	LeftHip = {Kind = "Ball", Part0 = "LowerTorso", Part1 = "LeftUpperLeg", UpperAngle = 0, TwistLowerAngle = -30, TwistUpperAngle = 10},
	RightHip = {Kind = "Ball", Part0 = "LowerTorso", Part1 = "RightUpperLeg", UpperAngle = 0, TwistLowerAngle = -30, TwistUpperAngle = 10},

	LeftWrist = {Kind = "Hinge", Part0 = "LeftLowerArm", Part1 = "LeftHand", LowerAngle = -20, UpperAngle = 20},
	RightWrist = {Kind = "Hinge", Part0 = "RightLowerArm", Part1 = "RightHand", LowerAngle = -20, UpperAngle = 20},
	LeftElbow = {Kind = "Hinge", Part0 = "LeftUpperArm", Part1 = "LeftLowerArm", LowerAngle = -45, UpperAngle = 45},
	RightElbow = {Kind = "Hinge", Part0 = "RightUpperArm", Part1 = "RightLowerArm", LowerAngle = -45, UpperAngle = 45},
	LeftShoulder = {Kind = "Ball", Part0 = "UpperTorso", Part1 = "LeftUpperArm", UpperAngle = 90, TwistLowerAngle = 45, TwistUpperAngle = 90},
	RightShoulder = {Kind = "Ball", Part0 = "UpperTorso", Part1 = "RightUpperArm", UpperAngle = 90, TwistLowerAngle = -45, TwistUpperAngle = 90},

	Neck = {Kind = "Ball", Part0 = "UpperTorso", Part1 = "Head", UpperAngle = 15, TwistLowerAngle = 15, TwistUpperAngle = 25, MaxFrictionTorque = 5},
	Waist = {Kind = "Hinge", Part0 = "LowerTorso", Part1 = "UpperTorso", LowerAngle = -45, UpperAngle = 45},
}

local noCollisionLimbs = {"LeftUpperArm", "RightUpperArm", "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "HumanoidRootPart"}

local function Ragdoll(char: Model, inPlace: boolean?): Model
	if not char:IsDescendantOf(workspace) then
		return char
	end

	local plr = Players:GetPlayerFromCharacter(char)
	if plr and not inPlace then
		char.Archivable = true
		char = char:Clone()
		char.Parent = workspace.Characters
		plr.Character = nil
	end

	local root = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = char:FindFirstChildOfClass("Humanoid")

	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		hum.EvaluateStateMachine = false
	end
	if root then
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
	end

	for i, v in jointInfo do
		local constraint = Instance.new(if v.Kind == "Ball" then "BallSocketConstraint" else "HingeConstraint") :: Constraint
		local part0 = char:FindFirstChild(v.Part0)
		if not part0 then
			continue
		end

		local attachment0 = part0:FindFirstChild(i .. "RigAttachment", true)
		if not attachment0 or not attachment0:IsA("Attachment") then
			continue
		end
		constraint.Attachment0 = attachment0
		attachment0.Name = i .. "RigAttach"

		local part1 = char:FindFirstChild(v.Part1)
		if not part1 then
			continue
		end

		local attachment1 = part1:FindFirstChild(i .. "RigAttachment", true)
		if not attachment1 or not attachment1:IsA("Attachment") then
			continue
		end
		constraint.Attachment1 = attachment1
		attachment1.Name = i .. "RigAttach"

		constraint.Name = i

		if v.Kind == "Ball" then
			local ballSocketConstraint = constraint :: BallSocketConstraint
			ballSocketConstraint.LimitsEnabled = true
			ballSocketConstraint.TwistLimitsEnabled = true

			ballSocketConstraint.UpperAngle = v.UpperAngle
			ballSocketConstraint.TwistUpperAngle = v.TwistUpperAngle
			ballSocketConstraint.TwistLowerAngle = v.TwistLowerAngle
			ballSocketConstraint.MaxFrictionTorque = v.MaxFrictionTorque or 0
		elseif v.Kind == "Hinge" then
			local hingeConstraint = constraint :: HingeConstraint

			hingeConstraint.LimitsEnabled = true
			hingeConstraint.LowerAngle = v.LowerAngle
			hingeConstraint.UpperAngle = v.UpperAngle
		end

		constraint.Parent = char:FindFirstChild(v.Part1)
	end

	local lowerTorso = char:FindFirstChild("LowerTorso")
	assert(not lowerTorso or lowerTorso:IsA("BasePart"))
	char.PrimaryPart = lowerTorso

	if lowerTorso then
		if root then
			local weld = Instance.new("WeldConstraint")
			weld.Part1 = root
			weld.Part0 = lowerTorso
			weld.Parent = root
		end
	end

	for _, v in char:GetDescendants() do
		if v:IsA("Motor6D") or v:IsA("BaseScript") or v:IsA("Fire") or (v.Name == "Item" and v.Parent == char) then
			v:Destroy()
		elseif v:IsA("BasePart") and not v:FindFirstAncestorOfClass("Accessory") then
			v.CollisionGroup = "Corpses"
			v.CanCollide = table.find(noCollisionLimbs, v.Name) == nil
		end
	end

	char:AddTag("Prop")
	char:AddTag("Corpse")
	char:RemoveTag("Character")

	return char
end

return Ragdoll