local Players = game:GetService("Players")
local Corpse = require(script.Parent.Corpse)
local Item = require(script.Parent.Item)
local Types = require(script.Parent.Types)

local SELF_DEFENSE_DURATION = 15

local module = {}

local function onDeath(participant: Types.Participant, params: Types.DamageParams): ()
    if participant._wasDeathProcessed then
        return
    end
    participant._wasDeathProcessed = true :: any

    local attacker = params.Attacker
    if attacker and not params.IgnoreKarma and not attacker:IsDamageJustifiedAgainstParticipant(participant) then
        attacker:SetFreeKill("Killed Teammate")
    end

    local role = participant:GetRole()
    if role then
        for otherRoleName, amount in role.AwardCreditsToRolesOnDeath do
            for _, otherParticipant in participant.Round:GetParticipantsWithRole(participant.Round:GetRoleFromRoleName(otherRoleName)) do
                otherParticipant:AddCredits(amount)
            end
        end
    end

    for _, v in participant:GetItems() do
        participant:DropItem(v)
    end

    participant:_setStatus("Missing")

    local corpse = Corpse.new(participant, params)
    participant._corpse = corpse

    participant.Round:AddEvent({
        Kind = "DeathRoundEvent",
        Corpse = corpse.CorpseView,
    })

    participant.Round.Gamemode:OnDeath(participant)
end

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

    return `<font color='#{role.Color:ToHex()}'>{participant.Player.Name}</font>`
end

local function GetCharacter(participant: Types.Participant): Model?
    return participant._character
end

local function GetCorpse(participant: Types.Participant): Types.Corpse?
    return participant._corpse
end

local function GetHumanoid(participant: Types.Participant): Humanoid?
    return participant._humanoid
end

local function GetRole(participant: Types.Participant): Types.Role?
    return participant._role
end

local function SetRole(participant: Types.Participant, role: Types.Role): ()
    tryAssignHumanoidPropertiesForRole(participant._humanoid, role)

    participant:AddCredits(role.StartingCredits or 0)
    if role.StartingItems then
        for _, v in role.StartingItems do
            participant:GiveItemFromItemDefinition(v)
        end
    end

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

local function GetKarma(participant: Types.Participant): number
    if participant.Round.Gamemode.EnableKarma then
        return participant._karma
    end
    return 1000
end

local function SetKarma(participant: Types.Participant, karma: number): ()
    if participant.Round.Gamemode.EnableKarma then
        participant._karma = math.clamp(karma, 1, 1000)
    else
        participant._karma = 1000
    end
end

local function GetKarmaDamageMultiplier(participant: Types.Participant): number
    return ((0.00005 * (participant:GetKarma() ^ 2)) + 50) / 100
end

local function IsDamageJustifiedAgainstParticipant(participant: Types.Participant, other: Types.Participant): boolean
    return participant:IsFreeKill() or participant:HasSelfDefenseAgainstParticipant(other) or not participant:IsAlliedWithParticipant(other)
end

local function IsFreeKill(participant: Types.Participant): boolean
    return participant._isFreeKill
end

local function SetFreeKill(participant: Types.Participant, reason: string?): ()
    participant._isFreeKill = not not reason
end

local function TryTakeDamage(participant: Types.Participant, params: Types.DamageParams): ()
    local hum = participant:GetHumanoid()
    if not hum then
        return
    end

    local damage = params.Amount
    local attacker = params.Attacker

    if attacker then
        if not participant.Round.Gamemode.EnableFriendlyFire and participant:IsAlliedWithParticipant(attacker) then
            return
        end

        if not params.IgnoreSelfDefense and not attacker:HasSelfDefenseAgainstParticipant(participant) then
            participant:AddSelfDefenseEntry({
                Against = attacker,
                Duration = SELF_DEFENSE_DURATION
            })
        end

        damage *= attacker:GetKarmaDamageMultiplier()

        local role = participant:GetRole()
        if role and not params.IgnoreKarma then
            local karma = participant:GetKarma()
            karma = karma + (params.Amount * role.DamageKarmaMultiplier) * (if attacker:IsDamageJustifiedAgainstParticipant(participant) then 1 else -1)
            participant:SetKarma(karma)
        end
    end

    local health = participant:GetHealth()
    hum:TakeDamage(damage)

    if health <= damage then
        onDeath(participant, params)
    end
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
    if params.Against == participant then
        return
    end

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

local function IsItemSlotOccupied(participant: Types.Participant, slot: number): boolean
    for _, v in participant:GetItems() do
        if v.Definition.Slot == slot then
            return true
        end
    end

    return false
end

local function GiveItemFromItemDefinition(participant: Types.Participant, itemDefinition: Types.ItemDefinition): ()
    local item: Types.Item
    if itemDefinition.Model then
        item = participant.Round:LoadItem(participant.Round:GetMap(), itemDefinition.Model)
    else
        item = Item.new(itemDefinition)
    end

    participant:AddItem(item)
end

local function DropItem(participant: Types.Participant, item: Types.Item): ()
    local char = participant:GetCharacter()

    participant:RemoveItem(item)
    if not char or not item.Model then
        return
    end

    item.Model:PivotTo(char:GetPivot())
    item.Model.Parent = participant.Round:GetMap().ItemSpawns
end

local function AddItem(participant: Types.Participant, item: Types.Item): ()
    if item.Definition.Slot then
        assert(not participant:IsItemSlotOccupied(item.Definition.Slot), "Item slot already occupied")
    end

    participant._items[item.Definition.Name] = item
end

local function RemoveItem(participant: Types.Participant, item: Types.Item): ()
    participant._items[item.Definition.Name] = nil
end

local function GetItems(participant: Types.Participant): {[string]: Types.Item}
    return participant._items :: {[string]: Types.Item}
end

local function GetItemPurchases(participant: Types.Participant): Types.EquipmentPurchases
    return participant._itemPurchases :: Types.EquipmentPurchases
end

local function PurchaseItem(participant: Types.Participant, itemDefinition: Types.ItemDefinition): Types.ItemPurchaseResult
    local role = participant:GetRole()

    if not role or not role.EquipmentShop or not table.find(role.EquipmentShop, itemDefinition) then
        return "InvalidItemForRole"
    end

    if participant:GetCredits() < itemDefinition.Cost then
        return "NotEnoughCredits"
    end

    if (participant._itemPurchases[itemDefinition.Name] or 0) >= itemDefinition.MaxStock then
        return "NotInStock"
    end

    if participant:IsItemSlotOccupied(itemDefinition.Slot) then
        return "SlotOccupied"
    end

    participant:SetCredits(participant:GetCredits() - itemDefinition.Cost)
    participant._itemPurchases[itemDefinition.Name] = (participant._itemPurchases[itemDefinition.Name] or 0) + 1

    participant:GiveItemFromItemDefinition(itemDefinition)

    return "Success"
end

local function SpawnCharacter(participant: Types.Participant): ()
    assert(not participant._isCharacterLoading, "Character is already loading")

    participant._isCharacterLoading = true :: any -- 'true' could not be converted into 'false' my arse

    participant._wasDeathProcessed = false

    participant.Player.CharacterAppearanceLoaded:Once(function(char)
        local hum = char:WaitForChild("Humanoid")
        assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid!?")

        while not char.Parent do
            if not participant.Player:IsDescendantOf(Players) then
                return
            end
            task.wait()
        end

        local spawns = participant.Round:GetMap().PlayerSpawns:GetChildren()
        local chosenSpawn = spawns[math.random(#spawns)]

        assert(chosenSpawn, "No spawn found")
        assert(chosenSpawn:IsA("BasePart"), "Spawn must be a BasePart")
        char:PivotTo(chosenSpawn:GetPivot())
    
        participant._humanoid = hum
        participant._character = char
    
        tryAssignHumanoidPropertiesForRole(hum, participant:GetRole())
    
        participant._isCharacterLoading = false

        hum.Died:Once(function()
            onDeath(participant, {
                Amount = 0,
                Source = "Other"
            })
        end)
    end)
    
    participant.Player:LoadCharacter()
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

local function IsAlliedWithParticipant(participant: Types.Participant, other: Types.Participant): boolean
    local role1, role2 = participant:GetRole(), other:GetRole()
    if not role1 or not role2 then
        return false
    end

    return participant.Round.IsRoleAlliedWithRole(role1, role2)
end

local function GetSlayVotes(participant: Types.Participant): {Types.Participant}
    return participant._slayVotes
end

local function TryAddSlayVote(participant: Types.Participant, other: Types.Participant): ()
    if not participant.Round.Gamemode.RequiredSlayVotes then
        return
    end

    if table.find(participant:GetSlayVotes(), other) then
        return
    end

    if not table.find(participant:GetKillList(), other) then
        return
    end

    other = other :: Types.Participant -- minor amount of type refinement nonsense here

    local corpse = other:GetCorpse()
    if not corpse or corpse.WasCorrectKill ~= false then
        return
    end

    table.insert(participant._slayVotes, other)

    if #participant._slayVotes >= participant.Round.Gamemode.RequiredSlayVotes then
        participant:TryTakeDamage({
            Amount = math.huge,
            Source = "Other"
        })
    end
end

function module.new(player: Player, round: Types.Round): Types.Participant
    return {
        Kind = "Participant",

        Player = player,
        Round = round,

        _slayVotes = {},
        GetSlayVotes = GetSlayVotes,
        TryAddSlayVote = TryAddSlayVote,

        _karma = 1000,
        _isFreeKill = false,

        _status = "Spectating",

        _isCharacterLoading = false,
        _selfDefenseList = {},
        _killList = {},
        _scores = {},

        _credits = 0,
        _itemPurchases = {},
        _items = {},

        GetCharacter = GetCharacter,
        GetHumanoid = GetHumanoid,

        GetRole = GetRole,
        SetRole = SetRole,

        GetCorpse = GetCorpse,

        IsFreeKill = IsFreeKill,
        SetFreeKill = SetFreeKill,

        SpawnCharacter = SpawnCharacter,
        UnspawnCharacter = UnspawnCharacter,

        IsAlliedWithParticipant = IsAlliedWithParticipant,
        IsDamageJustifiedAgainstParticipant = IsDamageJustifiedAgainstParticipant,
        GetKarmaDamageMultiplier = GetKarmaDamageMultiplier,

        GetKarma = GetKarma,
        SetKarma = SetKarma,
        GetFormattedName = GetFormattedName,
        GetHealth = GetHealth,
        SetHealth = SetHealth,
        TryTakeDamage = TryTakeDamage,
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
        GiveItemFromItemDefinition = GiveItemFromItemDefinition,
        AddItem = AddItem,
        RemoveItem = RemoveItem,
        DropItem = DropItem,
        GetItems = GetItems,        
        GetItemPurchases = GetItemPurchases,
        PurchaseItem = PurchaseItem,
        IsItemSlotOccupied = IsItemSlotOccupied,
    }
end

return module