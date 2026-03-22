local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Replication = require(ReplicatedStorage.Shared.RoundRule.Replication)
local CreateEmptyPart = require(script.Parent.CreateEmptyPart)

export type SoundId = number | Sound | string

export type SoundProperties = {
	Volume: number?,
	RollOffMinDistance: number?,
	RollOffMaxDistance: number?,
	SoundGroup: SoundGroup?,
	PlaybackRegion: NumberRange?,
	TimePosition: number?,
	Looped: boolean?,
}

local module = {}

local defaultSoundGroup: SoundGroup?

function module.SetDefaultSoundGroup(soundGroup: SoundGroup): ()
	defaultSoundGroup = soundGroup
end

function module.MakeSound(sound: SoundId | {SoundId}, props: SoundProperties?): Sound
	props = props or {}
	assert(props)

	local soundObject: Sound

	if typeof(sound) == "table" then
		assert(#sound > 0, "Sound table must not be empty")
		sound = sound[math.random(#sound)]
	end

    if typeof(sound) == "Instance" then
        soundObject = sound:Clone()
    else
        local soundId: string
        if typeof(sound) == "number" then
            soundId = "rbxassetid://" .. sound
        elseif typeof(sound) == "string" then
            soundId = sound
        end

        soundObject = Instance.new("Sound")
        soundObject.SoundId = soundId
    end

	props.RollOffMinDistance = if props.RollOffMinDistance then math.max(1, props.RollOffMinDistance) else 1

	soundObject.RollOffMode = Enum.RollOffMode.InverseTapered
	if props.RollOffMinDistance then
		soundObject.RollOffMinDistance = props.RollOffMinDistance
	end

	if props.RollOffMaxDistance then
		soundObject.RollOffMaxDistance = props.RollOffMaxDistance
	end

	if props.Volume then
		soundObject.Volume = props.Volume
	end

	if defaultSoundGroup and not props.SoundGroup then
		soundObject.SoundGroup = props.SoundGroup
	elseif props.SoundGroup then
		soundObject.SoundGroup = props.SoundGroup
	end

	if props.PlaybackRegion then
		soundObject.PlaybackRegionsEnabled = true
		soundObject.PlaybackRegion = props.PlaybackRegion
	end

	if props.TimePosition then
		soundObject.TimePosition = props.TimePosition
	end

	if props.Looped then
		soundObject.Looped = true
	end

	soundObject.PlayOnRemove = false

	return soundObject
end

function module.PlaySound(sound: SoundId | {SoundId}, position: Vector3?, parent: Instance?, props: SoundProperties?, to: Player?): Sound?
	assert(not parent or not position, "Position and parent are mutually exclusive")

	if to then
		assert(RunService:IsServer(), "to must only be specified on the server")

		if typeof(sound) == "table" then
			for _, v in sound do
				if typeof(v) == "Instance" then
					assert(Replication.CanInstanceReplicate(v), "Attempt to play non-replicated sound to client")
				end
			end
		elseif typeof(sound) == "Instance" then
			assert(Replication.CanInstanceReplicate(sound), "Attempt to play non-replicated sound to client")
		end

		script.Parent.Parent.Remotes.PlaySound:FireClient(to, sound, position, parent, props)
		return
	end

	local soundObject = module.MakeSound(sound, props)

	if parent then
		soundObject.Parent = parent

		soundObject.Ended:Once(function()
			soundObject:Destroy()
		end)
	elseif position then
		local part = CreateEmptyPart(CFrame.new(position), {soundObject :: Instance})
		part.Parent = workspace.Projectiles

		soundObject.Ended:Once(function()
			part:Destroy()
		end)
	else
		soundObject.Parent = SoundService

		soundObject.Ended:Once(function()
			soundObject:Destroy()
		end)
	end

	soundObject:Play()

	return soundObject
end

setmetatable(module, {
	__call = function(self, sound: SoundId | {SoundId}, position: Vector3?, parent: Instance?, props: SoundProperties?, to: Player?): Sound?
		return module.PlaySound(sound, position, parent, props, to)
	end
})

return table.freeze(module)