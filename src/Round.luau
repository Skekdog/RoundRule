local Types = require(script.Parent.Types)
local module = {}

local function GetParticipant(round: Types.Round, name: string): Types.Participant?
    return round._participants[name]
end

local function GetParticipants(round: Types.Round): {Types.Participant}
    return round._participants :: {Types.Participant}
end

local function AddParticipant(round: Types.Round, participant: Types.Participant): ()
    assert(not round._participants[participant.Player.Name], "Participant already exists")
    round._participants[participant.Player.Name] = participant
end

local function RemoveParticipant(round: Types.Round, participant: Types.Participant): ()
    round._participants[participant.Player.Name] = nil
end

local function GetRoundPhase(round: Types.Round): Types.RoundPhase
    return round._roundPhase
end

local function SetRoundPhase(round: Types.Round, phase: Types.RoundPhase)
    round._roundPhase = phase
end

local function GetAdvanceTime(round: Types.Round): number
    return round._roundPhaseAdvanceTime
end

local function SetAdvanceTime(round: Types.Round, finishTime: number)
    round._roundPhaseAdvanceTime = finishTime
end

local function GetIsRoundPaused(round: Types.Round): boolean
    return round._isPaused
end

local function PauseRound(round: Types.Round, paused: boolean)
    round._isPaused = paused
end

local function StartRound(round: Types.Round): ()
    round._roundPhase = "Playing"
    round:SetAdvanceTime(workspace:GetServerTimeNow() + round.Gamemode.Duration(#round:GetParticipants()))
end

local function EndRound(round: Types.Round, victor: Types.Victor): ()
    round._roundPhase = "Highlights"
    round:SetAdvanceTime(workspace:GetServerTimeNow() + 5)
end

local function GetRoleFromRoleName(round: Types.Round, name: string): Types.Role
    return round.Gamemode.Roles[name] or error("Unknown role: " .. name)
end

local function GetParticipantsWithRole(round: Types.Round, role: Types.Role): {Types.Participant}
    local participants = {}
    
    for _, v in round:GetParticipants() do
        table.insert(participants, v)
    end

    return participants
end

local function GetFormattedRoleName(role: Types.Role): string
    return `<font color='#{role.Color}'>#{role.Name}</font>`
end

function module.new(gamemode: Types.Gamemode): Types.Round
    local round: Types.Round = {
        Gamemode = gamemode,

        _participants = {},
        _roundPhase = "Waiting",
        _isPaused = false,
        _roundPhaseAdvanceTime = 0,

        GetParticipant = GetParticipant,
        GetParticipants = GetParticipants,
        AddParticipant = AddParticipant,
        RemoveParticipant = RemoveParticipant,
        GetRoundPhase = GetRoundPhase,
        SetRoundPhase = SetRoundPhase,
        GetAdvanceTime = GetAdvanceTime,
        SetAdvanceTime = SetAdvanceTime,
        GetIsRoundPaused = GetIsRoundPaused,
        PauseRound = PauseRound,
        StartRound = StartRound,
        EndRound = EndRound,
        GetRoleFromRoleName = GetRoleFromRoleName,
        GetParticipantsWithRole = GetParticipantsWithRole,
        GetFormattedRoleName = GetFormattedRoleName,
    }
    return round
end

return module