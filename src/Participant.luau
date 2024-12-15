local Players = game:GetService("Players")
local Corpse = require(script.Parent.Corpse)
local Item = require(script.Parent.Item)
local Types = require(script.Parent.Types)

local SELF_DEFENSE_DURATION = 15

local remotes = script.Parent.Remotes

local module = {}

local function rejoinRound(participant: Types.Participant): ()
    participant.Round:RemoveParticipant(participant)
    participant.Round:AddPlayer(participant.Player)
end

local function onDeath(participant: Types.Participant, params: Types.DamageParams): ()
    if participant._wasDeathProcessed then
        return
    end
    participant._wasDeathProcessed = true :: any

    if participant.Round:IsPreGame() then
        participant = participant :: Types.Participant
        return rejoinRound(participant)
    end

    participant = participant :: Types.Participant

    local attacker = params.Attacker
    if attacker and not params.IgnoreKarma and not attacker:IsDamageJustifiedAgainstParticipant(participant) then
        attacker:SetFreeKill("Killed Teammate")
        remotes.SlayVote:FireClient(participant.Player, attacker.Player.Name)
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
        assert(v)
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

    for _, v in participant.Round:GetParticipants() do
        assert(v)
        if v:GetStatus() == "Missing" then
            if role.CanSeeMissingInAction then
                remotes.UpdatePlayerStatus:FireClient(v.Player, participant.Player.Name, "Missing")
            else
                remotes.UpdatePlayerStatus:FireClient(v.Player, participant.Player.Name, "Alive")
            end
        end

        local otherRole = v:GetRole()
        if otherRole then
            if otherRole.RevealedRoles and table.find(otherRole.RevealedRoles, role.Name) then
                remotes.UpdatePlayerRole:FireClient(v.Player, participant.Player.Name, role.Name)
            else
                remotes.UpdatePlayerRole:FireClient(v.Player, participant.Player.Name, nil)
            end

            if role.RevealedRoles and table.find(role.RevealedRoles, otherRole.Name) then
                remotes.UpdatePlayerRole:FireClient(participant.Player, v.Player.Name, otherRole.Name)
            else
                remotes.UpdatePlayerRole:FireClient(participant.Player, v.Player.Name, nil)
            end
        end
    end

    remotes.AssignRole:FireClient(participant.Player, role.Name)
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

local function GetEquippedItem(participant: Types.Participant): Types.AnyItem?
    return participant._equippedItem
end

local function SetEquippedItem(participant: Types.Participant, item: Types.AnyItem?): ()
    participant._equippedItem = item
end

local function GetKarmaDamageMultiplier(participant: Types.Participant): number
    return ((0.00005 * (participant:GetKarma() ^ 2)) + 50) / 100
end

local function IsDamageJustifiedAgainstParticipant(participant: Types.Participant, other: Types.Participant): boolean
    return participant:IsFreeKill() or participant:HasSelfDefenseAgainstParticipant(other) or not participant:IsAlliedWithParticipant(other)
end

local function IsFreeKill(participant: Types.Participant): boolean
    local item = participant:GetEquippedItem()
    if item and item.Definition.AllowFreeKill then
        return true
    end
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

    if status == "Missing" then
        for _, v in participant.Round:GetParticipants() do
            assert(v)
            local role = v:GetRole()
            if role and role.CanSeeMissingInAction then
                remotes.UpdatePlayerStatus:FireClient(v.Player, participant.Player.Name, status)
            end
        end
    else
        for _, v in participant.Round:GetParticipants() do
            assert(v)
            remotes.UpdatePlayerStatus:FireAllClients(participant.Player.Name, status)
        end
    end
end

local function GetKillList(participant: Types.Participant): {Types.Participant}
    return participant._killList
end

local function _addToKillList(participant: Types.Participant): ()
    assert(not table.find(participant._killList, participant), "Participant already on kill list")
    table.insert(participant._killList, participant)
end

local function GetScores(participant: Types.Participant): Types.ScoreTable
    return participant._scores
end

local function AddScore(participant: Types.Participant, reason: string, amount: number): ()
    participant._scores[reason] = (participant._scores[reason] or 0) + amount
end

local function GetCredits(participant: Types.Participant): number
    return participant._credits
end

local function SetCredits(participant: Types.Participant, amount: number): ()
    participant._credits = amount
    remotes.UpdateCredits:FireClient(participant.Player, amount)
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
        assert(v)
        if v.Definition.Slot == slot then
            return true
        end
    end

    return false
end

local function GiveItemFromItemDefinition(participant: Types.Participant, itemDefinition: Types.AnyItemDefinition): ()
    local item: Types.AnyItem
    if itemDefinition.Model then
        assert(typeof(itemDefinition.Model) == "Instance" and itemDefinition.Model:IsA("BasePart"))
        item = participant.Round:LoadItem(participant.Round:GetMap(), itemDefinition.Model)
    else
        item = Item.new(itemDefinition :: Types.AnyItemDefinition)
    end

    participant:AddItem(item)
end

local function DropItem(participant: Types.Participant, item: Types.AnyItem): ()
    if not item.Definition.CanDrop then
        return
    end
    
    local char = participant:GetCharacter()

    participant:RemoveItem(item)
    if not char or not item.Model then
        return
    end

    item.Model:PivotTo(char:GetPivot())
    item.Model.Parent = participant.Round:GetMap().ItemSpawns
end

local function AddItem(participant: Types.Participant, item: Types.AnyItem): ()
    if item.Definition.Slot then
        assert(typeof(item.Definition.Slot) == "number")
        assert(not participant:IsItemSlotOccupied(item.Definition.Slot), "Item slot already occupied")
    end

    participant._items[item.Definition.Name] = item

    remotes.UpdateInventory:FireClient(participant.Player, "Add", item)
end

local function RemoveItem(participant: Types.Participant, item: Types.AnyItem): ()
    participant._items[item.Definition.Name] = nil

    remotes.UpdateInventory:FireClient(participant.Player, "Remove", item)
end

local function GetItems(participant: Types.Participant): index<Types.Participant, "_items">
    return participant._items
end

local function GetItemPurchases(participant: Types.Participant): Types.EquipmentPurchases
    return participant._itemPurchases
end

local function PurchaseItem(participant: Types.Participant, itemDefinition: Types.AnyItemDefinition): Types.ItemPurchaseResult
    local role = participant:GetRole()

    if not role or not role.EquipmentShop or not table.find(role.EquipmentShop, itemDefinition) then
        return "InvalidItemForRole"
    end

    assert(itemDefinition.CreditCost and itemDefinition.CreditCost > 0, "Item cost must be greater than 0")

    if participant:GetCredits() < itemDefinition.CreditCost then
        return "NotEnoughCredits"
    end

    if (participant._itemPurchases[itemDefinition.Name] or 0) >= (itemDefinition.MaxStock or math.huge) then
        return "NotInStock"
    end

    if itemDefinition.Slot and participant:IsItemSlotOccupied(itemDefinition.Slot) then
        return "SlotOccupied"
    end

    participant:SetCredits(participant:GetCredits() - itemDefinition.CreditCost)
    participant._itemPurchases[itemDefinition.Name] = (participant._itemPurchases[itemDefinition.Name] or 0) + 1

    participant:GiveItemFromItemDefinition(itemDefinition :: Types.AnyItemDefinition)

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

local function TryViewOtherParticipantCorpse(participant: Types.Participant, other: Types.Participant, covert: boolean?): ()
    local corpse = other:GetCorpse()
    if not corpse then
        return
    end

    if table.find(corpse:GetSearchedBy(), participant) then
        return
    end

    local ownChar = participant:GetCharacter()
    if not ownChar or not ownChar.PrimaryPart then
        return
    end

    local otherChar = other:GetCharacter()
    if not otherChar or not otherChar.PrimaryPart then
        return
    end

    local ownRole = participant:GetRole()
    if ownRole and ownRole.CanStealCreditsFromCorpses then
        participant:AddCredits(math.max(other:GetCredits(), 0))
    end

    if other:GetStatus() == "Missing" and not covert then
        other:_setStatus("Dead")

        local round = participant.Round

        if ownRole then
            if ownRole.ScoreForFindingBodies then
                participant:AddScore("Bodies Found", ownRole.ScoreForFindingBodies)
            end

            if ownRole.CorpseSearchResultsPublicised then
                for _, v in round:GetParticipants() do
                    assert(v)
                    corpse:AddSearchedBy(v)
                end
                remotes.UpdatePlayerCorpse:FireAllClients(other.Player.Name, corpse)
            end
        end

        local msg = participant:GetFormattedName() .. " found the body of " .. other:GetFormattedName() .. "."
        local otherRole = other:GetRole()
        if otherRole then
            msg ..= " They were a " .. round.GetFormattedRoleName(otherRole) .. round.GetExclamatoryString(otherRole)
        end

        round:SendMessage(Players:GetPlayers(), msg)

        participant.Round:AddEvent({
            Kind = "CorpseSearchedRoundEvent",
            SearchedBy = participant,
            Corpse = corpse.CorpseView
        })
    end

    corpse:AddSearchedBy(participant)

    if not participant:IsAlive() or (participant:IsAlive() and (otherChar.PrimaryPart.Position - ownChar.PrimaryPart.Position).Magnitude < 10) then
        remotes.UpdatePlayerCorpse:FireClient(participant.Player, other.Player.Name, corpse)
    end
end

function module.new(player: Player, round: Types.Round): Types.Participant
    return {
        Kind = "Participant",

        Extras = {},

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

        GetEquippedItem = GetEquippedItem,
        SetEquippedItem = SetEquippedItem,

        GetCharacter = GetCharacter,
        GetHumanoid = GetHumanoid,

        GetRole = GetRole,
        SetRole = SetRole,

        GetCorpse = GetCorpse,

        TryViewOtherParticipantCorpse = TryViewOtherParticipantCorpse,

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