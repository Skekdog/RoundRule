local SoundService = game:GetService("SoundService")
local CreateEmptyPart = require(script.Parent.CreateEmptyPart)

export type SoundId = number | Sound | string

export type SoundProperties = {
	Volume: number?,
	RollOffMinDistance: number?,
	RollOffMaxDistance: number?,
	SoundGroup: SoundGroup?,
	PlaybackRegion: NumberRange?,
}

local module = {}

module.DefaultSoundGroup = nil :: SoundGroup?

function module.PlaySound(sound: SoundId | {SoundId}, position: Vector3?, parent: Instance?, props: SoundProperties?): Sound
	assert(not parent or not position, "Position and parent are mutually exclusive")

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

	if props.RollOffMinDistance then
		soundObject.RollOffMode = Enum.RollOffMode.Linear
		soundObject.RollOffMinDistance = props.RollOffMinDistance
	end

	if props.RollOffMaxDistance then
		soundObject.RollOffMode = Enum.RollOffMode.Linear
		soundObject.RollOffMaxDistance = props.RollOffMaxDistance
	end

	if props.Volume then
		soundObject.Volume = props.Volume
	end

	if module.DefaultSoundGroup and not props.SoundGroup then
		soundObject.SoundGroup = props.SoundGroup
	elseif props.SoundGroup then
		soundObject.SoundGroup = props.SoundGroup
	end

	if props.PlaybackRegion then
		soundObject.PlaybackRegionsEnabled = true
		soundObject.PlaybackRegion = props.PlaybackRegion
	end

	soundObject.PlayOnRemove = false

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
	__call = function(self, sound: SoundId | {SoundId}, position: Vector3?, parent: Instance?, props: SoundProperties?): Sound
		return module.PlaySound(sound, position, parent, props)
	end
})

return module