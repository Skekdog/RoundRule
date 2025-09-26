local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ForEachPart = require(ReplicatedStorage.Shared.RoundRule.Common.ForEachPart)
local GetPrimaryPart = require(ReplicatedStorage.Shared.RoundRule.Common.GetPrimaryPart)
local AmmoBox = require(script.Parent.AmmoBox)
local Corpse = require(script.Parent.Corpse)
local Defaults = require(script.Parent.Defaults)
local IsPassiveDamageSource = require(script.Parent.IsPassiveDamageSource)
local Item = require(script.Parent.Item)
local MakeRagdoll = require(script.Parent.MakeRagdoll)
local Replication = require(script.Parent.Replication)
local Types = require(script.Parent.Types)

local SELF_DEFENSE_DURATION = 15

local module = {}

local function rejoinRound(participant: Types.Participant): ()
    participant.Round:RemoveParticipant(participant, true)
    participant.Round:AddPlayer(participant.Player, participant:GetKarma())
end

local function randomElementFromArray<T>(array: {T}): T?
    if #array == 0 then
        return nil
    end

    return array[math.random(#array)]
end

function module.OnDeath(participant: Types.Participant, params: Types.DamageParams, deferVictoryCheck: boolean): ()
    local round = participant.Round
    if round:IsPreGame() then
        return rejoinRound(participant)
    end

    local attacker = params.Attacker
    if not attacker and IsPassiveDamageSource(params.Source) then
        attacker = participant:GetLastDamagedBy()
    end
    params.Attacker = attacker

    if attacker then
        attacker:_addToKillList(participant)
    end

    if attacker and not params.IgnoreKarma and not attacker:IsDamageJustifiedAgainstParticipant(participant) then
        attacker:SetFreeKill("killed a teammate")
        Replication.SlayVote(participant.Player, attacker)
    end

    local role = participant:GetRole()
    if role.Definition.AwardCreditsToRolesOnDeath then
        for otherRoleName, amount in role.Definition.AwardCreditsToRolesOnDeath do
            local otherRole = round:GetRoleFromRoleName(otherRoleName)
            local otherRoleParticipants = round:GetParticipantsWithRole(otherRole)
            for _, otherParticipant in otherRoleParticipants do
                otherParticipant:AddCredits(amount)
                round:SendMessage(otherParticipant.Player, `{otherRoleName}{if #otherRoleParticipants == 1 then "" else "s"}, you have been awarded {amount} credit{if amount == 1 then "" else "s"} for your work.`, "Team")
            end
        end
    end

    local isFreeKill = participant:IsFreeKill()
    -- important to do here, otherwise someone holding a free kill item will not be a free kill
    -- because now the item is unequipped.

    for _, v in participant:GetItems() do
        assert(v)
        participant:TryDropItem(v)
    end

    round:AddEvent({
        Kind = "DeathRoundEvent",
        Victim = participant,
    })

    local ragdoll = MakeRagdoll(participant, workspace.Characters)
    if ragdoll then
        round:LoadProp(ragdoll)
        ragdoll:SetAttribute("Unidentified", true)

        local deathSound = ragdoll:FindFirstChild("DeathSound", true)
        if not params.IsHeadshot and deathSound and deathSound:IsA("Sound") then
            if typeof(params.Source) ~= "table" or (params.Source.Kind == "Gun" and not params.Source.Definition.IsSilent) then
                deathSound:Play()
            end
        end
    end

    participant:_setStatus("Missing")

    local corpse = Corpse.new(participant, params, ragdoll, isFreeKill)
    participant.Corpse = corpse

    if round:IsInProgress() then
        round.Gamemode:OnDeath(participant, deferVictoryCheck)
    end
end

local function tryAssignHumanoidPropertiesForRole(humanoid: Humanoid?, role: Types.Role?): ()
    if not humanoid or not role then
        return
    end

    humanoid.MaxHealth = role.Definition.Health or Defaults.Health
    humanoid.Health = role.Definition.Health or Defaults.Health

    humanoid.WalkSpeed = role.Definition.WalkSpeed or Defaults.WalkSpeed
    humanoid.JumpPower = role.Definition.JumpPower or Defaults.JumpPower

    if role.Definition.Accessories then
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
end

local function GetFormattedName(participant: Types.Participant): string
    local role = participant:GetRole()
    if role == Defaults.Role then
        return participant.Player.Name
    end

    return role:FormatString(participant.Player.Name)
end

local function GetCharacter(participant: Types.Participant): Model?
    return participant._character
end

local function GetHumanoid(participant: Types.Participant): Humanoid?
    return participant._humanoid
end

local function GetRole(participant: Types.Participant): Types.Role
    return participant._role or Defaults.Role
end

function module.SetRole(participant: Types.Participant, role: Types.RoleDefinition?): ()
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
            if v.Slot and participant:IsItemSlotOccupied(v.Slot) then
                continue
            end
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

    hum.Health = math.min(health, hum.MaxHealth)
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

local function SetEquippedItem(participant: Types.Participant, item: Types.AnyItem?, force: boolean?): ()
    local round = participant.Round
    local lastItem = participant:GetEquippedItem()
    if not force and lastItem and lastItem.Definition.PreventUnequip then
        return
    end

    if lastItem and round.Gamemode.OnItemEquipped then
        round.Gamemode.OnItemEquipped(round.Gamemode, participant, lastItem, false)
    end

    if lastItem and lastItem.Definition.OnUnequipServer then
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
        local model = item.Model:Clone();
        (model :: Instance).Name = "Item"

        local motor = Instance.new("Motor6D")
        motor.Part0 = char:FindFirstChild("RightHand") :: BasePart?
        motor.Part1 = if model:IsA("Model") then model.PrimaryPart else model

        local c1 = model:GetAttribute("AnimC1")
        if typeof(c1) == "CFrame" then
            motor.C1 = c1
        end

        motor.Parent = model

        ForEachPart(model, function(part)
            part.Massless = true
            part.CanCollide = false
            part.CanTouch = false
            part.CanQuery = false
        end);

        (model :: Instance).Parent = char
    end

    participant._equippedItem = item

    if item and round.Gamemode.OnItemEquipped then
        round.Gamemode.OnItemEquipped(round.Gamemode, participant, item, true)
    end

    if item and item.Definition.OnEquipServer then
        item.Definition.OnEquipServer(item, participant)
    end
end

local function GetKarmaDamageMultiplier(participant: Types.Participant): number
    return ((0.00005 * (participant:GetKarma() ^ 2)) + 50) / 100
end

local function IsDamageJustifiedAgainstParticipant(participant: Types.Participant, other: Types.Participant): boolean
    return participant.Player == other.Player or other:IsFreeKill() or participant:HasSelfDefenseAgainstParticipant(other) or not participant:IsAlliedWithParticipant(other)
end

local function IsFreeKill(participant: Types.Participant): boolean
    if participant._isFreeKill then
        return true
    end

    local item = participant:GetEquippedItem()
    if item and item.Definition.IsBadGuyItem then
        if not participant:GetRole().Definition.IsBadGuys then
            return true
        end
    end

    return false
end

local function SetFreeKill(participant: Types.Participant, reason: string?): ()
    participant._isFreeKill = not not reason
    Replication.InformFreeKill(participant.Player, reason)
end

local function IsBadGuy(participant: Types.Participant): boolean
    return participant:GetRole().Definition.IsBadGuys or false
end

function module.TryTakeDamage(participant: Types.Participant, params: Types.DamageParams, deferDeath: boolean?): boolean
    if participant._wasDeathProcessed then
        return false
    end

    local hum = participant:GetHumanoid()
    if not hum then
        return false
    end

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

        params.Amount *= attacker:GetKarmaDamageMultiplier()

        if not params.IgnoreKarma then
            local karma = participant:GetKarma()
            karma = karma + (params.Amount * (participant:GetRole().Definition.DamageKarmaMultiplier or 1)) * (if attacker:IsDamageJustifiedAgainstParticipant(participant) then 1 else -1)
            participant:SetKarma(karma)
        end
    end

    if participant.Round.Gamemode.BeforeDamageParticipant then
        if not participant.Round.Gamemode.BeforeDamageParticipant(participant.Round.Gamemode, participant, params) then
            return false
        end
    end

    local health = participant:GetHealth()

    local dead = health <= params.Amount

    if dead then
        participant._wasDeathProcessed = true
    end

    hum:TakeDamage(params.Amount)

    if typeof(params.Source) ~= "table" or params.Source.Kind ~= "Gun" or (params.Source.Kind == "Gun" and not params.Source.Definition.IsSilent) then
        Replication.DamageTaken(participant.Player, params.Amount, params.Source)
    end

    if dead then
        module.OnDeath(participant, params, deferDeath or false)
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
            if not v:IsAlive() or (v:GetRole().Definition.CanSeeMissingInAction) then
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

local function _addToKillList(participant: Types.Participant, toAdd: Types.Participant): ()
    assert(not table.find(participant.KillList, toAdd), "Participant already on kill list")
    table.insert(participant.KillList, toAdd)

    local corpse = participant.Corpse
    if not corpse then
        return
    end

    corpse:UpdateKillList()
end

local function AddScore(participant: Types.Participant, reason: string, amount: number): ()
    if amount == 0 then
        return
    end
    participant.Scores[reason] = (participant.Scores[reason] or 0) + amount
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
    if participant.Round:IsPreGame() then
        return
    end

    if params.Against == participant then
        return
    end

    if params.Against:HasSelfDefenseAgainstParticipant(participant) then
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
    local item = if itemDefinition.Model then participant.Round:LoadItem(itemDefinition.Model:Clone()) else Item.new(itemDefinition)
    participant:AddItem(item)
    return item
end

function module.DropItem(participant: Types.Participant, item: Types.AnyItem, throwDirection: Vector3?): ()
    if not item.Definition.CanDrop then
        return
    end

    local char = participant:GetCharacter()

    if not char or not item.Model then
        return
    end

    item.Model:SetAttribute("AmmoType", if item.Kind == "Gun" then item.Definition.AmmoType.Name else nil)
    item.Model:SetAttribute("StoredAmmo", if item.Kind == "Gun" then item.Ammo else nil)

    local parent = participant.Round:GetMap().Dynamic
    if throwDirection then
        if participant:TryThrowAssembly(GetPrimaryPart(item.Model), 15, parent, nil, throwDirection) then
            participant:RemoveItem(item)
        end
        return
    end

    participant:RemoveItem(item)
    item.Model:PivotTo(char:GetPivot());
    (item.Model :: Instance).Parent = parent
end

local function isObscured(participant: Types.Participant, origin: Vector3, target: Vector3): boolean
    local char = assert(participant:GetCharacter())

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, target - origin, params)
    return not not result
end

local function TryThrowAssembly(participant: Types.Participant, assembly: Types.MapObject, force: number, parent: Instance?, position: Vector3?, direction: Vector3?, noForward: boolean?): boolean
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

    local startPosition = if noForward then position else position + (direction * 5.5)
    if isObscured(participant, position, startPosition) then
        return false
    end

    if parent then
        (assembly :: PVInstance).Parent = parent
    end

    local assemblyRoot = GetPrimaryPart(assembly)
    assemblyRoot.AssemblyLinearVelocity = Vector3.zero
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

    if not item.Definition.Slot and item.Definition.OnEquipServer then
        item.Definition.OnEquipServer(item, participant)
    end

    Replication.UpdateInventory(participant.Player, "Add", item)
end

local function RemoveItem(participant: Types.Participant, item: Types.AnyItem): ()
    participant._items[item.Definition.Name] = nil
    if participant:GetEquippedItem() == item then
        participant:SetEquippedItem(nil, true)
    end

    if not item.Definition.Slot and item.Definition.OnUnequipServer then
        item.Definition.OnUnequipServer(item, participant)
    end

    Replication.UpdateInventory(participant.Player, "Remove", item.Definition.Name)
end

local function GetItems(participant: Types.Participant): {[string]: Types.AnyItem?}
    return participant._items
end

local function PurchaseItem(participant: Types.Participant, itemDefinition: Types.AnyItemDefinition): Types.ItemPurchaseResult
    if participant:GetStatus() ~= "Alive" then
        return "NotInRound"
    end

    local role = participant:GetRole()

    if not role.Definition.EquipmentShop or not table.find(role.Definition.EquipmentShop, itemDefinition) then
        return "InvalidItemForRole"
    end

    assert(itemDefinition.CreditCost and itemDefinition.CreditCost > 0, "Item cost must be greater than 0")

    if participant:GetCredits() < itemDefinition.CreditCost then
        return "NotEnoughCredits"
    end

    if (participant.ItemPurchases[itemDefinition.Name] or 0) >= (itemDefinition.MaxStock or math.huge) then
        return "NotInStock"
    end

    if itemDefinition.Slot and participant:IsItemSlotOccupied(itemDefinition.Slot) then
        return "SlotOccupied"
    end

    participant:SetCredits(participant:GetCredits() - itemDefinition.CreditCost)
    participant.ItemPurchases[itemDefinition.Name] = (participant.ItemPurchases[itemDefinition.Name] or 0) + 1

    local item = participant:GiveItemFromItemDefinition(itemDefinition)

    if itemDefinition.OnPurchase then
        itemDefinition.OnPurchase(item :: Types.Item, participant)
    end

    return "Success"
end

function module.OnCharacterPartAdded(part: Instance): ()
    if not part:IsA("BasePart") then
        return
    end

    if part:FindFirstAncestorOfClass("Accessory") then
        part.CanCollide = false
        part.CanTouch = false
        part.CanQuery = false
        return
    elseif part.Name == "Head" then
        part.CanCollide = true
    end

    part.CollisionGroup = "PlayerCharacterParts"
end

local function MoveToSpawn(participant: Types.Participant, spawnCFrame: CFrame?): ()
    local char = participant:GetCharacter()
    if not char then
        return
    end

    if not spawnCFrame then
        local spawns = participant.Round:GetMap().Map.PlayerSpawns:GetChildren()
        local chosenSpawn = spawns[math.random(#spawns)]

        assert(chosenSpawn, "No spawn found")
        assert(chosenSpawn:IsA("BasePart"), "Spawn must be a BasePart")
        spawnCFrame = chosenSpawn.CFrame
    end
    char:PivotTo(assert(spawnCFrame))
end

local function SpawnCharacter(participant: Types.Participant): ()
    assert(not participant._isCharacterLoading, "Character is already loading")

    participant.Round:SendMessage(participant.Player, "The round will begin soon. Prepare yourself.", "All")

    if participant.Round.Gamemode.EnableKarma then
        local msg: string
        local dmgMult = participant:GetKarmaDamageMultiplier()
        if dmgMult == 1 then
            msg = "Your karma is 100%. You will deal full damage this round."
        else
            msg = string.format("Your karma is %d. You will deal %.1f%% damage this round.", participant:GetKarma(), dmgMult * 100)
        end
        participant.Round:SendMessage(participant.Player, msg, "All")
    end

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

        char.DescendantAdded:Connect(module.OnCharacterPartAdded)
        for _, v in char:GetDescendants() do
            module.OnCharacterPartAdded(v)
        end

        participant._humanoid = hum
        participant._character = char

        participant:MoveToSpawn()

        tryAssignHumanoidPropertiesForRole(hum, participant:GetRole())

        local healthScript = char:FindFirstChild("Health")
        if healthScript then
            healthScript:Destroy()
        end

        local deathSoundId = randomElementFromArray(participant.Round.Gamemode.DeathSounds)
        if deathSoundId then
            local deathSound = Instance.new("Sound")
            deathSound.Name = "DeathSound"
            deathSound.SoundId = deathSoundId
            deathSound.RollOffMinDistance = 20
            deathSound.RollOffMaxDistance = 50
            deathSound.Parent = char.PrimaryPart
        end

        participant._isCharacterLoading = false

        hum.Died:Once(function()
            if not participant._wasDeathProcessed then
                module.OnDeath(participant, {
                    Amount = 0,
                    Source = "Other",
                    Attacker = participant,
                }, false)
            end
        end)

        char:AddTag("Character")

        local charsFolder = workspace.Characters
        char.Parent = charsFolder
    end)

    participant.Player:LoadCharacter()
end

local function UnspawnCharacter(participant: Types.Participant): ()
    assert(not participant._isCharacterLoading, "Character is loading")

    local corpse = participant.Corpse
    local char = participant:GetCharacter() or if corpse then corpse.Model else nil
    if not char then
        return print("no char", corpse)
    end

    for _, v in participant:GetItems() do
        assert(v)
        participant:TryDropItem(v)
    end

    participant._humanoid = nil
    participant._character = nil
    participant.Player.Character = nil
    char:Destroy()

    Replication.ReplicatePlayerStatus("All", participant, nil)
end

local function SetLastDamagedBy(participant: Types.Participant, by: Types.Participant, duration: number): ()
    participant._lastDamaged = {
        By = by,
        ExpiresAt = workspace:GetServerTimeNow() + duration,
    }
end

local function GetLastDamagedBy(participant: Types.Participant): Types.Participant?
    local lastDamaged = participant._lastDamaged
    if not lastDamaged or lastDamaged.ExpiresAt < workspace:GetServerTimeNow() then
        return nil
    end

    return lastDamaged.By
end

local function IsAlliedWithParticipant(participant: Types.Participant, other: Types.Participant): boolean
    local role1, role2 = participant:GetRole(), other:GetRole()
    return role1:IsAlliedWith(role2)
end

local function AddCorpseIcon(participant: Types.Participant, icon: Types.CorpseIcon): ()
    local toRemove: number?
    for i, v in participant.ExtraCorpseIcons do
        if v.Name == icon.Name then
            toRemove = i
            break
        end
    end

    if toRemove then
        table.remove(participant.ExtraCorpseIcons, toRemove)
    end

    table.insert(participant.ExtraCorpseIcons, icon)
end

local function trySlay(participant: Types.Participant): ()
    if not participant:IsAlive() then
        return
    end

    participant.Round:SendMessage(Players:GetPlayers(), `[PLAYER-{participant.Player.Name}] was slain for RDM.`, "All")

    participant:TryTakeDamage({
        Amount = math.huge,
        Source = "Other"
    })
end

local function TryAddSlayVote(participant: Types.Participant, other: Types.Participant): boolean
    if not participant.Round.Gamemode.RequiredSlayVotes then
        return false
    end

    if table.find(participant.SlayVotes, other) then
        return false
    end

    if not table.find(participant.KillList, other) then
        return false
    end

    local corpse = other.Corpse
    if not corpse or corpse.WasCorrectKill ~= false then
        return false
    end

    table.insert(participant.SlayVotes, other)

    if #participant.SlayVotes >= participant.Round.Gamemode.RequiredSlayVotes then
        trySlay(participant)
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

    local ammoBox = AmmoBox.new(definition, item.Model, subtractAmount);
    (ammoBox.Model :: PVInstance).Parent = participant.Round:GetMap().Dynamic
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

        CorpseSearchDistance = 10,

        DidParticipate = false,

        Extras = {},

        Player = player,
        Round = round,

        TryPlayAnimation = TryPlayAnimation,
        TryStopAnimation = TryStopAnimation,

        SlayVotes = {},
        TryAddSlayVote = TryAddSlayVote,

        _karma = 1000,
        _isFreeKill = false,

        _status = "Alive",

        _isCharacterLoading = false,
        _selfDefenseList = {},
        KillList = {},
        Scores = {},

        _credits = 0,
        ItemPurchases = {},
        _items = {},
        _ammo = {},

        ExtraCorpseIcons = {},
        AddCorpseIcon = AddCorpseIcon,

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
        SetRole = module.SetRole,

        IsBadGuy = IsBadGuy,

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
        TryTakeDamage = module.TryTakeDamage,
        IsAlive = IsAlive,
        GetStatus = GetStatus,
        _setStatus = _setStatus,
        _addToKillList = _addToKillList,
        AddScore = AddScore,
        GetCredits = GetCredits,
        SetCredits = SetCredits,
        AddCredits = AddCredits,
        AddSelfDefenseEntry = AddSelfDefenseEntry,
        HasSelfDefenseAgainstParticipant = HasSelfDefenseAgainstParticipant,
        GiveItemFromItemDefinition = GiveItemFromItemDefinition,
        AddItem = AddItem,
        RemoveItem = RemoveItem,
        DropItem = module.DropItem,
        GetItems = GetItems,
        PurchaseItem = PurchaseItem,
        IsItemSlotOccupied = IsItemSlotOccupied,
        TryDropItem = TryDropItem,

        TryThrowAssembly = TryThrowAssembly,

        MoveToSpawn = MoveToSpawn,

        GetLastDamagedBy = GetLastDamagedBy,
        SetLastDamagedBy = SetLastDamagedBy,
    }
end

return module