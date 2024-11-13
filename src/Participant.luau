local Types = require(script.Parent.Types)
local module = {}

local function tryAssignHumanoidPropertiesForRole(humanoid: Humanoid?, role: Types.Role?): ()
    if not humanoid or not role then
        return
    end

    humanoid.MaxHealth = role.Health
    humanoid.Health = role.Health

    humanoid.WalkSpeed = role.WalkSpeed
    humanoid.JumpPower = role.JumpPower
end

local function GetFormattedName(participant: Types.Participant): string
    local role = participant:GetRole()
    if not role then
        return participant.Player.Name
    end

    return `<font color='{role.Color:ToHex()}'>{participant.Player.Name}</font>`
end

local function GetCharacter(participant: Types.Participant): Model?
    return participant._character
end

local function GetHumanoid(participant: Types.Participant): Humanoid?
    return participant._humanoid
end

local function GetRole(participant: Types.Participant): Types.Role?
    return participant._role
end

local function SetRole(participant: Types.Participant, role: Types.Role): ()
    tryAssignHumanoidPropertiesForRole(participant._humanoid, role)
    participant._role = role
end

local function GetHealth(participant: Types.Participant): number
    local hum = participant:GetHumanoid()
    if not hum then
        return 0
    end

    return hum.Health
end

local function SetHealth(participant: Types.Participant, health: number): ()
    local hum = participant:GetHumanoid()
    if not hum then
        return
    end

    hum.Health = health
end

local function TakeDamage(participant: Types.Participant, params: Types.DamageParams): ()
    local hum = participant:GetHumanoid()
    if not hum then
        return
    end

    hum:TakeDamage(params.Amount)
end

local function IsAlive(participant: Types.Participant): boolean
    return participant:GetHealth() > 0
end

local function GetStatus(participant: Types.Participant): Types.ParticipantStatus
    return participant._status
end

local function _setStatus(participant: Types.Participant, status: Types.ParticipantStatus): ()
    participant._status = status
end

local function GetKillList(participant: Types.Participant): {Types.Participant}
    return participant._killList
end

local function _addToKillList(participant: Types.Participant): ()
    assert(not table.find(participant._killList, participant), "Participant already on kill list")
    table.insert(participant._killList, participant)
end

local function GetScores(participant: Types.Participant): Types.ScoreTable
    return participant._scores :: Types.ScoreTable
end

local function AddScore(participant: Types.Participant, reason: string, amount: number): ()
    participant._scores[reason] = (participant._scores[reason] or 0) + amount
end

local function GetCredits(participant: Types.Participant): number
    return participant._credits
end

local function SetCredits(participant: Types.Participant, amount: number): ()
    participant._credits = amount
end

local function AddCredits(participant: Types.Participant, amount: number): ()
    participant:SetCredits(participant:GetCredits() + amount)
end

local function AddSelfDefenseEntry(participant: Types.Participant, params: Types.SelfDefenseParams): ()
    table.insert(participant._selfDefenseList, {
        Against = params.Against,
        Until = workspace:GetServerTimeNow() + params.Duration
    })
end

local function HasSelfDefenseAgainstParticipant(participant: Types.Participant, against: Types.Participant): boolean
    for _, v in participant._selfDefenseList do
        if v.Against == against and v.Until > workspace:GetServerTimeNow() then
            return true
        end
    end

    return false
end

local function AddItem(participant: Types.Participant, item: Types.Item): ()
    participant._items[item.Name] = item
end

local function RemoveItem(participant: Types.Participant, item: Types.Item): ()
    participant._items[item.Name] = nil
end

local function GetItems(participant: Types.Participant): {Types.Item}
    return participant._items :: {Types.Item}
end

local function GetEquipmentPurchases(participant: Types.Participant): Types.EquipmentPurchases
    return participant._equipmentPurchases :: Types.EquipmentPurchases
end

local function AddEquipmentPurchase(participant: Types.Participant, item: Types.Item): ()
    participant._equipmentPurchases[item.Name] = (participant._equipmentPurchases[item.Name] or 0) + 1
end

local function SpawnCharacterBlocking(participant: Types.Participant): Model
    assert(not participant._isCharacterLoading, "Character is already loading")

    participant._isCharacterLoading = true :: any -- 'true' could not be converted into 'false' my arse
    
    participant.Player:LoadCharacter()
    local char = participant.Player.CharacterAdded:Wait()

    local hum = char:WaitForChild("Humanoid")
    assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid!?")

    participant._humanoid = hum
    participant._character = char

    tryAssignHumanoidPropertiesForRole(hum, participant:GetRole())

    participant._isCharacterLoading = false

    return char
end

local function UnspawnCharacter(participant: Types.Participant): ()
    assert(not participant._isCharacterLoading, "Character is loading")

    local char = participant:GetCharacter()
    if not char then
        return
    end

    participant._humanoid = nil
    participant._character = nil
    participant.Player.Character = nil
    char:Destroy()
end

function module.new(player: Player, round: Types.Round): Types.Participant
    return {
        Player = player,
        Round = round,

        _status = "Spectating",

        _isCharacterLoading = false,
        _selfDefenseList = {},
        _killList = {},
        _scores = {},

        _credits = 0,
        _equipmentPurchases = {},
        _items = {},

        GetCharacter = GetCharacter,
        GetHumanoid = GetHumanoid,

        GetRole = GetRole,
        SetRole = SetRole,

        SpawnCharacterBlocking = SpawnCharacterBlocking,
        UnspawnCharacter = UnspawnCharacter,

        GetFormattedName = GetFormattedName,
        GetHealth = GetHealth,
        SetHealth = SetHealth,
        TakeDamage = TakeDamage,
        IsAlive = IsAlive,
        GetStatus = GetStatus,
        _setStatus = _setStatus,
        GetKillList = GetKillList,
        _addToKillList = _addToKillList,
        GetScores = GetScores,
        AddScore = AddScore,
        GetCredits = GetCredits,
        SetCredits = SetCredits,
        AddCredits = AddCredits,
        AddSelfDefenseEntry = AddSelfDefenseEntry,
        HasSelfDefenseAgainstParticipant = HasSelfDefenseAgainstParticipant,
        AddItem = AddItem,
        RemoveItem = RemoveItem,
        GetItems = GetItems,        
        GetEquipmentPurchases = GetEquipmentPurchases,
        AddEquipmentPurchase = AddEquipmentPurchase,
    }
end

return module