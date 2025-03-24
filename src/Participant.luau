local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local AmmoBox = require(script.Parent.AmmoBox)
local Corpse = require(script.Parent.Corpse)
local Item = require(script.Parent.Item)
local MakeRagdoll = require(script.Parent.MakeRagdoll)
local Replication = require(script.Parent.Replication)
local Types = require(script.Parent.Types)

local SELF_DEFENSE_DURATION = 15

local module = {}

local function rejoinRound(participant: Types.Participant): ()
    participant.Round:RemoveParticipant(participant, true)
    participant.Round:AddPlayer(participant.Player)
end

local function onDeath(participant: Types.Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
    if participant.Round:IsPreGame() then
        return rejoinRound(participant)
    end

    local attacker = params.Attacker
    if attacker then
        attacker:_addToKillList(participant)
    end

    if attacker and not params.IgnoreKarma and not attacker:IsDamageJustifiedAgainstParticipant(participant) then
        attacker:SetFreeKill("Killed Teammate")
        Replication.SlayVote(participant.Player, attacker)
    end

    local role = participant:GetRole()
    if role then
        for otherRoleName, amount in role.Definition.AwardCreditsToRolesOnDeath do
            for _, otherParticipant in participant.Round:GetParticipantsWithRole(participant.Round:GetRoleFromRoleName(otherRoleName)) do
                otherParticipant:AddCredits(amount)
            end
        end
    end

    for _, v in participant:GetItems() do
        assert(v)
        participant:TryDropItem(v)
    end

    participant:_setStatus("Missing")

    local corpse = Corpse.new(participant, params)
    participant._corpse = corpse

    participant.Round:AddEvent({
        Kind = "DeathRoundEvent",
        Victim = participant,
    })

    local corpseFolder = workspace:FindFirstChild("Corpses") :: Folder or Instance.new("Folder", workspace)
    corpseFolder.Name = "Corpses"

    local ragdoll = MakeRagdoll(participant, corpseFolder)
    if ragdoll then
        participant.Round:LoadProp(ragdoll, "CorpseProp")
        ragdoll:SetAttribute("Unidentified", true)
    end

    if participant.Round:IsInProgress() then
        participant.Round.Gamemode:OnDeath(participant, deferVictoryCheck)
    end
end

local function tryAssignHumanoidPropertiesForRole(humanoid: Humanoid?, role: Types.Role?): ()
    if not humanoid or not role then
        return
    end

    humanoid.MaxHealth = role.Definition.Health
    humanoid.Health = role.Definition.Health

    humanoid.WalkSpeed = role.Definition.WalkSpeed
    humanoid.JumpPower = role.Definition.JumpPower

    for _, v in role.Definition.Accessories do
        local id = tonumber(v:split("//")[2])
        if not id then
            continue
        end

        local success, accessory = pcall(function()
            return InsertService:LoadAsset(id):FindFirstChildOfClass("Accessory")
        end)
        if not success or not accessory then
            continue
        end

        humanoid:AddAccessory(accessory)
    end
end

local function GetFormattedName(participant: Types.Participant): string
    local role = participant:GetRole()
    if not role then
        return participant.Player.Name
    end

    return role:GetFormattedString(participant.Player.Name)
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

local function SetRole(participant: Types.Participant, role: Types.RoleDefinition?): ()
    if not role then
        participant._role = nil
        Replication.ReplicateRole("All", participant, true)
        return
    end
    
    participant._role = participant.Round:GetRoleFromRoleName(role.Name)
    tryAssignHumanoidPropertiesForRole(participant._humanoid, participant._role)

    participant:AddCredits(role.StartingCredits or 0)
    if role.StartingItems then
        for _, v in role.StartingItems do
            participant:GiveItemFromItemDefinition(v)
        end
    end

    if not participant.Round:IsInProgress() then
        Replication.ReplicateRole("All", participant, false)
    else
        for _, v in participant.Round:GetParticipants() do
            assert(v)

            if v == participant then
                Replication.ReplicateRole(participant.Player, participant, false)
            end

            if v:GetStatus() == "Missing" then
                if role.CanSeeMissingInAction then
                    Replication.ReplicatePlayerStatus(v.Player, participant, "Missing")
                else
                    Replication.ReplicatePlayerStatus(v.Player, participant, "Alive")
                end
            end

            if v ~= participant then
                local otherRole = v:GetRole()
                if otherRole then
                    if otherRole.Definition.RevealedRoles and table.find(otherRole.Definition.RevealedRoles, role.Name) then
                        Replication.ReplicateRole(v.Player, participant, false)
                    else
                        Replication.ReplicateRole(v.Player, participant, true)
                    end

                    if role.RevealedRoles and table.find(role.RevealedRoles, otherRole.Definition.Name) then
                        Replication.ReplicateRole(participant.Player, v, false)
                    else
                        Replication.ReplicateRole(participant.Player, v, true)
                    end
                end
            end
        end
    end
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
    local lastItem = participant:GetEquippedItem()
    if lastItem and lastItem.Kind == "Item" and lastItem.Definition.OnUnequipServer then
        lastItem.Definition.OnUnequipServer(lastItem, participant)
    end
    
    participant:TryStopAnimation("HoldItem")

    local char = participant:GetCharacter()
    if char then
        local lastModel = char:FindFirstChild("Item")
        if lastModel then
            lastModel:Destroy()
        end
    end

    if item and item.Definition.HoldAnimation then
        local id = assert(tonumber((item.Definition.HoldAnimation :: string):split("://")[2]), "Invalid hold animation: " .. tostring(item.Definition.HoldAnimation))
        participant:TryPlayAnimation(id, "HoldItem")
    end

    if item and item.Model and char then
        local model = item.Model:Clone()
        model.Name = "Item"

        local motor = Instance.new("Motor6D")
        motor.Part0 = char:FindFirstChild("RightHand") :: BasePart?
        motor.Part1 = model

        local c1 = model:GetAttribute("AnimC1")
        if typeof(c1) == "CFrame" then
            motor.C1 = c1
        end

        motor.Parent = model

        model.Massless = true
        model.CanCollide = false
        model.CanTouch = false
        model.CanQuery = false
        model.Parent = char
    end

    participant._equippedItem = item

    if item and item.Kind == "Item" and item.Definition.OnEquipServer then
        item.Definition.OnEquipServer(item, participant)
    end
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

local function TryTakeDamage(participant: Types.Participant, params: Types.DamageParams, deferDeath: boolean?): boolean
    if participant._wasDeathProcessed then
        return false
    end

    local hum = participant:GetHumanoid()
    if not hum then
        return false
    end

    local damage = params.Amount
    local attacker = params.Attacker

    if attacker then
        if not participant.Round.Gamemode.EnableFriendlyFire and participant:IsAlliedWithParticipant(attacker) then
            return false
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
            karma = karma + (params.Amount * role.Definition.DamageKarmaMultiplier) * (if attacker:IsDamageJustifiedAgainstParticipant(participant) then 1 else -1)
            participant:SetKarma(karma)
        end
    end

    local health = participant:GetHealth()

    local dead = health <= damage

    if dead then
        participant._wasDeathProcessed = true
    end

    hum:TakeDamage(damage)
    if dead then
        onDeath(participant, params, deferDeath or false)
    end

    return true
end

local function IsAlive(participant: Types.Participant): boolean
    return participant:GetHealth() > 0
end

local function GetStatus(participant: Types.Participant): Types.ParticipantStatus
    return participant._status
end

local function _setStatus(participant: Types.Participant, status: Types.ParticipantStatus): ()
    participant._status = status

    if status == "Missing" and participant.Round:IsInProgress() then
        for _, v in participant.Round:GetParticipants() do
            assert(v)
            local role = v:GetRole()
            if not v:IsAlive() or (role and role.Definition.CanSeeMissingInAction) then
                if v:GetStatus() == "Missing" then
                    Replication.ReplicatePlayerStatus(participant.Player, v, "Missing")
                end
                Replication.ReplicatePlayerStatus(v.Player, participant, status)
            end
        end
    else
        Replication.ReplicatePlayerStatus("All", participant, status)
    end
end

local function GetKillList(participant: Types.Participant): {Types.Participant}
    return participant._killList
end

local function _addToKillList(participant: Types.Participant, toAdd: Types.Participant): ()
    assert(not table.find(participant._killList, toAdd), "Participant already on kill list")
    table.insert(participant._killList, toAdd)

    local corpse = participant:GetCorpse()
    if not corpse then
        return
    end

    corpse:UpdateKillList()
end

local function GetScores(participant: Types.Participant): Types.ScoreTable
    return participant._scores
end

local function AddScore(participant: Types.Participant, reason: string, amount: number): ()
    if amount == 0 then
        return
    end
    participant._scores[reason] = (participant._scores[reason] or 0) + amount
end

local function GetCredits(participant: Types.Participant): number
    return participant._credits
end

local function SetCredits(participant: Types.Participant, amount: number): ()
    participant._credits = amount
    Replication.ReplicateCredits(participant)
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

local function GiveItemFromItemDefinition(participant: Types.Participant, itemDefinition: Types.AnyItemDefinition): Types.AnyItem
    local item: Types.AnyItem
    if itemDefinition.Model then
        assert(typeof(itemDefinition.Model) == "Instance" and itemDefinition.Model:IsA("BasePart"))
        local prop = participant.Round:LoadProp(itemDefinition.Model:Clone(), "ItemProp")
        assert(prop.Kind == "ItemProp")
        item = prop.Item
    else
        item = Item.new(itemDefinition)
    end

    participant:AddItem(item)

    return item
end

local function DropItem(participant: Types.Participant, item: Types.AnyItem, throwDirection: Vector3?): ()
    if not item.Definition.CanDrop then
        return
    end
    
    local char = participant:GetCharacter()

    if not char or not item.Model then
        return
    end

    item.Model:SetAttribute("AmmoType", if item.Kind == "Gun" then item.Definition.AmmoType.Name else nil)
    item.Model:SetAttribute("StoredAmmo", if item.Kind == "Gun" then item.Ammo else nil)

    local parent = participant.Round:GetMap().ItemSpawns
    if throwDirection then
        if participant:TryThrowAssembly(item.Model, 15, parent, nil, throwDirection) then
            participant:RemoveItem(item)
        end
        return
    end

    participant:RemoveItem(item)
    item.Model:PivotTo(char:GetPivot())
    item.Model.Parent = parent
end

local function isObscured(participant: Types.Participant, origin: Vector3, target: Vector3): boolean
    local char = assert(participant:GetCharacter())

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char, participant.Round:GetMap().Bounds}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, target - origin, params)
    return not not result
end

local function TryThrowAssembly(participant: Types.Participant, assemblyRoot: BasePart, force: number, parent: Instance?, position: Vector3?, direction: Vector3?, noForward: boolean?): boolean
    local char = participant:GetCharacter()
    if not char then
        return false
    end

    local head = char:FindFirstChild("Head")
    if not head or not head:IsA("BasePart") then
        return false
    end

    position = position or head.Position
    direction = direction or char:GetPivot().LookVector

    assert(position and direction)

    local startPosition = if noForward then position else position + (direction * 3.5)
    if isObscured(participant, startPosition, position) then
        return false
    end

    if parent then
        assemblyRoot.Parent = parent
    end

    assemblyRoot.CFrame = CFrame.lookAlong(startPosition, direction)
	assemblyRoot:ApplyImpulse(direction * (assemblyRoot.AssemblyMass * force))

    return true
end

local function TryDropItem(participant: Types.Participant, item: Types.AnyItem, throw: boolean?): boolean
    if item.Definition.CanDrop then
        participant:DropItem(item)
        return true
    end

    participant:RemoveItem(item)
    return false
end

local function AddItem(participant: Types.Participant, item: Types.AnyItem): ()
    if item.Definition.Slot then
        assert(typeof(item.Definition.Slot) == "number")
        assert(not participant:IsItemSlotOccupied(item.Definition.Slot), "Item slot already occupied")
    end

    participant._items[item.Definition.Name] = item
    Replication.UpdateInventory(participant.Player, "Add", item)
end

local function RemoveItem(participant: Types.Participant, item: Types.AnyItem): ()
    participant._items[item.Definition.Name] = nil
    Replication.UpdateInventory(participant.Player, "Remove", item.Definition.Name)
end

local function GetItems(participant: Types.Participant): {[string]: Types.AnyItem?}
    return participant._items
end

local function GetItemPurchases(participant: Types.Participant): Types.EquipmentPurchases
    return participant._itemPurchases
end

local function PurchaseItem(participant: Types.Participant, itemDefinition: Types.AnyItemDefinition): Types.ItemPurchaseResult
    if participant:GetStatus() ~= "Alive" then
        return "NotInRound"
    end
    
    local role = participant:GetRole()

    if not role or not role.Definition.EquipmentShop or not table.find(role.Definition.EquipmentShop, itemDefinition) then
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

    local item = participant:GiveItemFromItemDefinition(itemDefinition)

    if itemDefinition.Kind == "Item" and itemDefinition.OnPurchase then
        itemDefinition.OnPurchase(item :: Types.Item, participant)
    end

    return "Success"
end

local function onCharacterPartAdded(part: Instance): ()
    if not part:IsA("BasePart") then
        return
    end

    part.CollisionGroup = if part:FindFirstAncestorOfClass("Accessory") then "PlayerAccessories" else "PlayerCharacterParts"
end

local function MoveToSpawn(participant: Types.Participant): ()
    local char = participant:GetCharacter()
    if not char then
        return
    end

    local spawns = participant.Round:GetMap().PlayerSpawns:GetChildren()
    local chosenSpawn = spawns[math.random(#spawns)]

    assert(chosenSpawn, "No spawn found")
    assert(chosenSpawn:IsA("BasePart"), "Spawn must be a BasePart")
    char:PivotTo(chosenSpawn:GetPivot())
end

local function SpawnCharacter(participant: Types.Participant): ()
    assert(not participant._isCharacterLoading, "Character is already loading")

    participant._isCharacterLoading = true

    participant.Player.CharacterAppearanceLoaded:Once(function(char)
        local hum = char:WaitForChild("Humanoid")
        assert(hum:IsA("Humanoid"), "Humanoid is not a Humanoid!?")

        while not char.Parent do
            if not participant.Player:IsDescendantOf(Players) then
                return
            end
            task.wait()
        end

        char.DescendantAdded:Connect(onCharacterPartAdded)
        for _, v in char:GetDescendants() do
            onCharacterPartAdded(v)
        end
    
        participant._humanoid = hum
        participant._character = char

        participant:MoveToSpawn()
    
        tryAssignHumanoidPropertiesForRole(hum, participant:GetRole())

        local healthScript = char:FindFirstChild("Health")
        if healthScript then
            healthScript:Destroy()
        end
    
        participant._isCharacterLoading = false

        hum.Died:Once(function()
            if not participant._wasDeathProcessed then
                onDeath(participant, {
                    Amount = 0,
                    Source = "Other",
                    Attacker = participant,
                }, false)
            end
        end)

        local charsFolder = workspace:FindFirstChild("Characters") :: Folder or Instance.new("Folder", workspace)
        charsFolder.Name = "Characters"
        char.Parent = charsFolder
    end)
    
    participant.Player:LoadCharacter()
end

local function UnspawnCharacter(participant: Types.Participant): ()
    assert(not participant._isCharacterLoading, "Character is loading")

    local char = participant:GetCharacter()
    if not char then
        return
    end

    for _, v in participant:GetItems() do
        assert(v)
        participant:TryDropItem(v)
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

    return role1:IsAlliedWith(role2)
end

local function GetSlayVotes(participant: Types.Participant): {Types.Participant}
    return participant._slayVotes
end

local function TryAddSlayVote(participant: Types.Participant, other: Types.Participant): boolean
    if not participant.Round.Gamemode.RequiredSlayVotes then
        return false
    end

    if table.find(participant:GetSlayVotes(), other) then
        return false
    end

    if not table.find(participant:GetKillList(), other) then
        return false
    end

    local corpse = other:GetCorpse()
    if not corpse or corpse.WasCorrectKill ~= false then
        return false
    end

    table.insert(participant._slayVotes, other)

    if #participant._slayVotes >= participant.Round.Gamemode.RequiredSlayVotes then
        participant:TryTakeDamage({
            Amount = math.huge,
            Source = "Other"
        })
    end

    return true
end

local function GetAllAmmo(participant: Types.Participant): {[string]: number}
    return participant._ammo :: {[string]: number}
end

local function GetAmmo(participant: Types.Participant, kind: string): number
    return participant._ammo[kind] or 0
end

local function SetAmmo(participant: Types.Participant, kind: string, amount: number): ()
    Replication.UpdateReserveAmmo(participant.Player, "Update", kind, amount)
    participant._ammo[kind] = amount
end

local function HasWeaponOfAmmoType(participant: Types.Participant, ammoType: string): boolean
    for _, v in participant:GetItems() do
        assert(v)
        if v.Definition.Kind == "Gun" and v.Definition.AmmoType.Name == ammoType then
            return true
        end
    end

    return false
end

local function DropAmmoBoxForCurrentItem(participant: Types.Participant): ()
    local item = participant:GetEquippedItem()
    if not item or item.Kind ~= "Gun" then
        return
    end

    local definition = item.Definition.AmmoType
    local ammo = item.Ammo

    if ammo < (definition.Capacity / 4) then
        return
    end

    local subtractAmount = math.min(ammo, definition.Capacity)
    item.Ammo -= subtractAmount

    local ammoBox = AmmoBox.new(definition, item.Model, subtractAmount)
    ammoBox.Model.Parent = participant.Round:GetMap().AmmoSpawns
end

local function tryGetAnimator(participant: Types.Participant): Animator?
    local hum = participant:GetHumanoid()
    if not hum then
        return nil
    end

    return hum:FindFirstChildOfClass("Animator")
end

local function TryPlayAnimation(participant: Types.Participant, id: number, name: string): ()
    local animator = tryGetAnimator(participant)
    if not animator then
        return
    end

    local animation = Instance.new("Animation")
    animation.AnimationId = "rbxassetid://" .. tostring(id)

    local track = animator:LoadAnimation(animation)
    track.Name = name

    track:Play()
end

local function TryStopAnimation(participant: Types.Participant, name: string): ()
    local animator = tryGetAnimator(participant)
    if not animator then
        return
    end

    for _, v in animator:GetPlayingAnimationTracks() do
        if v.Name == name and v.IsPlaying then
            v:Stop()
        end
    end
end

function module.new(player: Player, round: Types.Round): Types.Participant
    Replication.UpdateInventory(player, "Reset")
    Replication.UpdateReserveAmmo(player, "Reset")

    return {
        Kind = "Participant",

        Extras = {},

        Player = player,
        Round = round,

        TryPlayAnimation = TryPlayAnimation,
        TryStopAnimation = TryStopAnimation,

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
        _ammo = {},

        DropAmmoBoxForCurrentItem = DropAmmoBoxForCurrentItem,

        GetAllAmmo = GetAllAmmo,
        GetAmmo = GetAmmo,
        SetAmmo = SetAmmo,
        HasWeaponOfAmmoType = HasWeaponOfAmmoType,

        GetEquippedItem = GetEquippedItem,
        SetEquippedItem = SetEquippedItem,

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
        TryDropItem = TryDropItem,

        TryThrowAssembly = TryThrowAssembly,

        MoveToSpawn = MoveToSpawn,
    }
end

return module