local Types = require(script.Parent.Types)

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

	Neck = {Kind = "Ball", Part0 = "UpperTorso", Part1 = "Head", UpperAngle = 15, TwistLowerAngle = 15, TwistUpperAngle = 25},
	Waist = {Kind = "Hinge", Part0 = "LowerTorso", Part1 = "UpperTorso", LowerAngle = -45, UpperAngle = 45},
}

local function MakeRagdoll(participant: Types.Participant, parent: Instance): Model?
	local char = participant:GetCharacter()
	if not char then
		return
	end

	local plr = participant.Player

	if not char:IsDescendantOf(workspace) then
		return
	end

	char.Archivable = true
	local clone = char:Clone()

	local root = clone:FindFirstChild("HumanoidRootPart") :: BasePart?
	local hum = clone:FindFirstChildOfClass("Humanoid")

	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Physics)
		hum.EvaluateStateMachine = false
	end
	if root then
		root.CanCollide = false
		root.CanTouch = false
		root.CanQuery = false
	end

	plr.Character = nil
	char:Destroy()
	clone:SetAttribute("Unidentified", true)

	for i, v in jointInfo do
		local constraint = Instance.new(if v.Kind == "Ball" then "BallSocketConstraint" else "HingeConstraint") :: Constraint
		local part0 = clone:FindFirstChild(v.Part0)
		assert(part0)
		if not part0 then
			continue
		end

		constraint.Attachment0 = part0:FindFirstChild(i .. "RigAttachment", true) :: Attachment
		(constraint.Attachment0 :: Attachment).Name = i .. "RigAttach"

		local part1 = clone:FindFirstChild(v.Part1)
		assert(part1)
		if not part1 then
			continue
		end

		constraint.Attachment1 = part1:FindFirstChild(i .. "RigAttachment", true) :: Attachment
		(constraint.Attachment1 :: Attachment).Name = i .. "RigAttach"

		constraint.Name = i

		if v.Kind == "Ball" then
			local ballSocketConstraint = constraint :: BallSocketConstraint
			ballSocketConstraint.LimitsEnabled = true
			ballSocketConstraint.TwistLimitsEnabled = true

			ballSocketConstraint.UpperAngle = v.UpperAngle
			ballSocketConstraint.TwistUpperAngle = v.TwistUpperAngle
			ballSocketConstraint.TwistLowerAngle = v.TwistLowerAngle
		elseif v.Kind == "Hinge" then
			local hingeConstraint = constraint :: HingeConstraint

			hingeConstraint.LimitsEnabled = true
			hingeConstraint.LowerAngle = v.LowerAngle
			hingeConstraint.UpperAngle = v.UpperAngle
		end
		
		constraint.Parent = clone:FindFirstChild(v.Part1)
	end

	clone.Parent = parent
	for _, v in clone:GetDescendants() do
		if v:IsA("Motor6D") or v:IsA("BaseScript") or v:IsA("Fire") then
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.CollisionGroup = "Corpses"
		elseif v.Name == "DeathSound" and v:IsA("Sound") then
			v:Play()
		end
	end

	task.spawn(function()
		while clone.Parent do
			for _, v in clone:GetDescendants() do
				if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
					v.CanCollide = true
				end
			end
			task.wait()
		end
	end)

	if root then
		root:SetNetworkOwner()
	end

	participant._character = clone
	return clone
end

return MakeRagdoll