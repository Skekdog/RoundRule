local Item = require(script.Parent.Item)
local Participant = require(script.Parent.Participant)
local Types = require(script.Parent.Types)
local module = {}

local HIGHLIGHTS_TIME = 20
local PREPARING_TIME = 20

local function GetParticipant(round: Types.Round, name: string): Types.Participant?
    return round._participants[name]
end

local function GetParticipants(round: Types.Round): {Types.Participant}
    return round._participants :: {Types.Participant}
end

local function AddPlayer(round: Types.Round, player: Player): Types.Participant
    assert(not round._participants[player.Name], "Participant already exists")

    local participant = Participant.new(player, round)
    round._participants[player.Name] = participant

    for _, v in round.Gamemode.StartingItems do
        participant:AddItem(Item.new(v))
    end

    if #round:GetParticipants() == round.Gamemode.MinimumPlayers then
        round:SetRoundPhase("Preparing", PREPARING_TIME)
    end

    return participant
end

local function RemoveParticipant(round: Types.Round, participant: Types.Participant): ()
    round._participants[participant.Player.Name] = nil

    if #round:GetParticipants() < round.Gamemode.MinimumPlayers then
        round:SetRoundPhase("Waiting", math.huge)
    end
end

local function GetRoundPhase(round: Types.Round): Types.RoundPhase
    return round._roundPhase
end

local function SetRoundPhase(round: Types.Round, phase: Types.RoundPhase, duration: number): ()
    round._roundPhase = phase
    round:SetAdvanceTime(workspace:GetServerTimeNow() + duration)
end

local function GetAdvanceTime(round: Types.Round): number
    return round._roundPhaseAdvanceTime
end

local function SetAdvanceTime(round: Types.Round, finishTime: number): ()
    round._roundPhaseAdvanceTime = finishTime
end

local function AddEvent(round: Types.Round, data: Types.RoundEventData): ()
    table.insert(round._eventLog, {
        Timestamp = workspace:GetServerTimeNow(),
        Data = data,
    })
end

local function GetEventLog(round: Types.Round): {Types.RoundEvent}
    return round._eventLog
end

local function GetIsRoundPaused(round: Types.Round): boolean
    return round._isPaused
end

local function PauseRound(round: Types.Round, paused: boolean): ()
    round._isPaused = paused
end

local function StartRound(round: Types.Round): ()
    round:AddEvent({
        Kind = "StartRoundEvent",
    })

    round:SetRoundPhase("Playing", round.Gamemode.Duration(#round:GetParticipants()))
    round.Gamemode:AssignRoles(round:GetParticipants())
end

local function EndRound(round: Types.Round, victor: Types.Victor): ()
    local role: Types.Role
    if victor.Kind == "Role" then
        role = victor
    elseif victor.Kind == "Participant" then
        role = victor:GetRole() or error("Winning Participant has no assigned role")
    end

    local victorRole: Types.Role
    if role.Allegiance.Kind == "Role" then
        victorRole = round:GetRoleFromRoleName(role.Allegiance.Role)
    elseif role.Allegiance.Kind == "Solo" then
        victorRole = role :: Types.Role
    end

    assert(victorRole.VictoryText, "Victory role has no VictoryText")

    round:AddEvent({
        Kind = "EndRoundEvent",
        VictoryText = victorRole.VictoryText :: string,
    })
    round:SetRoundPhase("Highlights", HIGHLIGHTS_TIME)
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
    return `<font color='#{role.Color:ToHex()}'>#{role.Name}</font>`
end

local function IsRoleAlliedWithRole(role1: Types.Role, role2: Types.Role): boolean
    return table.find(role1.Allies or {} :: {string}, role2.Name) ~= nil
end

function module.new(gamemode: Types.Gamemode): Types.Round
    return {
        Gamemode = gamemode,

        _participants = {},
        _roundPhase = "Waiting",
        _isPaused = false,
        _roundPhaseAdvanceTime = 0,

        _eventLog = {},

        AddEvent = AddEvent,
        GetEventLog = GetEventLog,

        GetParticipant = GetParticipant,
        GetParticipants = GetParticipants,
        AddPlayer = AddPlayer,
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
        IsRoleAlliedWithRole = IsRoleAlliedWithRole,
    }
end

return module