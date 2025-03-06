export type ParticipantStatus = "Alive" | "Missing" | "Dead" | "Spectating"

export type Victor = Participant | Role
export type VictorType = {Kind: "Role", Role: string} | {Kind: "Solo"}

export type ScoreTable = {[string]: number?}
export type EquipmentPurchases = {[string]: number?}

export type ItemPurchaseResult = "Success" | "NotEnoughCredits" | "SlotOccupied" | "NotInStock" | "InvalidItemForRole" | "NotInRound"

export type GeneralDamageSource = "Fall" | "Drown" | "Explode" | "Burn" | "Stab" | "Shot" | "Bludgeon" | "Crush" | "Magic" | "Other"
export type NamedDamageSource = GeneralDamageSource | string
export type DamageSource = AnyItem | GeneralDamageSource

export type Bound = BasePart
export type InteractionCallback = (object: Bound, participant: Participant) -> ()

export type ExplosionInfo = {
    Damage: number,
    FalloffBegin: number,
    FalloffEnd: number,
    Pressure: number,
    VisualRadius: number,

    IgnoreSelfDefense: boolean?,
    IgnoreKarma: boolean?,
    IgnoreScore: boolean?,

    BeforeHitAnything: BeforeHitAnything?,
    BeforeHitProp: BeforeHitProp?,
    BeforeHitParticipant: BeforeHitParticipant?,
}

export type ExplosionParams = {
    Kind: "ExplosionParams",
    Definition: ExplosionInfo,
    Attacker: Participant?,
    Position: Vector3,
}

export type DamageParams = {
    Amount: number,

    IsHeadshot: boolean?,
    Source: DamageSource,

    Attacker: Participant?,
    
    IgnoreKarma: boolean?,
    IgnoreSelfDefense: boolean?,
    IgnoreScore: boolean?,
}

export type DamageInfo = number | {
    Head: number,
    Body: number,
    Limb: number,
}

export type RoundPhase = "Waiting" | "Preparing" | "Playing" | "Highlights" | "Intermission"

export type DataModelMapProp = BasePart
export type DataModelItem = BasePart
export type DataModelCorpse = Model
export type DataModelAmmo = BasePart
export type DataModelProp = DataModelMapProp | DataModelItem | DataModelCorpse | DataModelAmmo

export type MessageKind = "Chat" | "Team" | "All"

export type Gamemode = {
    Name: string,
    DisplayName: string?,
    Description: string,
    Authors: string,

    MinimumPlayers: number,
    
    RequiredSlayVotes: number?,

    DefaultVictor: (Gamemode, Round) -> Victor,
    TimeoutVictor: (Gamemode, Round) -> Victor,
    TimeoutMusic: {Sound}?,

    EnableFriendlyFire: boolean?,
    EnableKarma: boolean?,

    AvailableItems: {[string]: AnyItemDefinition},
    AvailableAmmo: {[string]: AmmoDefinition},

    StartingItems: {AnyItemDefinition},

    Duration: (numParticipants: number) -> number,

    AssignRoles: (Gamemode, {Participant}) -> (),
    
    Roles: {[string]: RoleDefinition},

    OnDeath: (Gamemode, Participant) -> (),
    OnCharacterAdded: (Gamemode, Participant) -> (),
}

export type RoleDefinition = {
    Kind: "RoleDefinition",

    Name: string,
    DisplayName: string?,
    Description: string,
    Color: Color3,
    Sound: string,
    IsExclamatory: boolean?,

    Allegiance: VictorType,
    VictoryText: string?,
    VictoryMusic: {Sound}?,

    StartingItems: {AnyItemDefinition}?,
    StartingCredits: number?,
    EquipmentShop: {AnyItemDefinition}?,

    ShouldAnnounceDisconnect: boolean?,
    CanStealCreditsFromCorpses: boolean?,
    CanSeeMissingInAction: boolean?,
    CanTeamChat: boolean?,

    AwardCreditsToRolesOnDeath: {[string]: number},

    CorpseSearchResultsPublicised: boolean?,
    ScoreForFindingBodies: number?,

    WalkSpeed: number,
    JumpPower: number,
    Health: number,

    Accessories: {string},

    DamageKarmaMultiplier: number,

    Allies: {string}?,
    RevealedRoles: {string}?,
    HighlightedRoles: {string}?,
}

export type InteractableObjectDefinition = {
    Name: string,
    Description: string,

    Model: BasePart,

    IsContinuousInteraction: boolean,
    InteractionRange: number,

    OnInteractClient: (object: InteractableObject) -> (),
    OnInteractServer: (object: InteractableObject, participant: Participant) -> (),
}

export type InteractableObject = {
    Definition: InteractableObjectDefinition,
    Object: BasePart,

    Extras: {[string]: any},
}

export type CommonItemDefinition = {
    Name: string,
    DisplayName: string?,
    Description: string?,
    Icon: string?,

    Model: BasePart?,
    HoldAnimation: string?,

    Slot: number?,
    CanDrop: boolean?,

    CreditCost: number?,
    MaxStock: number?,

    AllowFreeKill: boolean?,
}

export type CommonWeaponDefinition = CommonItemDefinition & {
    HoldAnimation: string,
}

export type ItemDefinition = CommonItemDefinition & {
    Kind: "Item",

    PrimaryHint: string?,
    AlternateHint: string?,

    HeartbeatClient: ((Item) -> ())?,

    PrimaryFire: ((item: Item, participant: Participant, direction: Vector3) -> ())?,
    AlternateFire: ((item: Item, participant: Participant, direction: Vector3) -> ())?,

    OnPurchase: ((item: Item, participant: Participant) -> ())?,
}

-- todo: when recursive generic types are supported, do that
export type ItemBeforeHit = AnyWeapon | ExplosionParams
export type BeforeHitAnything = (item: ItemBeforeHit, hitPart: BasePart, params: DamageParams) -> ()
export type BeforeHitParticipant = (item: ItemBeforeHit, hitParticipant: Participant, params: DamageParams) -> boolean
export type BeforeHitProp = (item: ItemBeforeHit, hitProp: Prop, params: DamageParams) -> boolean

export type GunWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Gun",

    AimAnimation: string?,

    ReloadTime: number,
    AttackInterval: number,

    AttackSound: string,
    ReloadSound: string,

    Damage: DamageInfo,

    AmmoType: AmmoDefinition,

    AimFOV: number?,
    HasScope: boolean?,
    HasMuzzleFlash: boolean?,
    ScopeRequired: boolean?,
    AimSpreadMultiplier: number?,

    LaserColor: Color3?,

    Projectile: BasePart?,
    ProjectileSpeed: number?,
    
    BulletsPerShot: number?,

    Spread: number,
    RecoilX: number,
    RecoilY: number,

    BeforeHitAnything: BeforeHitAnything?,
    BeforeHitParticipant: BeforeHitParticipant?,
    BeforeHitProp: BeforeHitProp?,
}

export type GrenadeWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Grenade",

    FuseTime: number,

    AttackSound: string,

    Projectile: BasePart,
    ProjectileForce: number,

    ExplosionInfo: ExplosionInfo,

    OnExplode: ((item: GrenadeWeapon, attacker: Participant, projectile: BasePart) -> ())?,
}

export type MeleeWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Melee",

    DamageKind: "Bludgeon" | "Stab",
    AttackAnimation: string,

    AttackInterval: number,
    AttackSound: string,

    Damage: DamageInfo,

    MaxDistance: number,

    BeforeHitAnything: BeforeHitAnything?,
    BeforeHitParticipant: BeforeHitParticipant?,
    BeforeHitProp: BeforeHitProp?,
}

export type AmmoDefinition = {
    Kind: "Ammo",
    Name: string,
    DisplayName: string?,
    Capacity: number,
    ReserveCapacity: number,
    Model: BasePart,
    CanDrop: boolean,
}

export type AnyItemDefinition = ItemDefinition | GunWeaponDefinition | GrenadeWeaponDefinition | MeleeWeaponDefinition

export type MapDefinition = {
    Name: string,
    DisplayName: string?,
    Description: string,
    Authors: string,

    MapIcons: {
        ["16:9"]: string?,
        ["4:3"]: string?,
        ["1:1"]: string?,
    },

    AvailableItems: {[string]: AnyItemDefinition},
    AvailableAmmo: {[string]: AmmoDefinition},

    Gravity: number,

    LightingSettings: {[string]: any},
    FutureLightingSettings: {[string]: any},

    WaterSettings: {[string]: any},
    TerrainColors: {[string]: any},
}

export type Map = MapDefinition & {
    PlayerSpawns: Folder,

    TerrainRegion: TerrainRegion,
    StaticMap: Folder,
    Bounds: Folder,

    LightingModifiers: Folder,
    FutureLightingModifiers: Folder,
    
    DynamicMap: Folder,
    Props: Folder,
    Windows: Folder,
    ItemSpawns: Folder,
    AmmoSpawns: Folder,
    InteractableObjects: Folder,

    MaterialVariants: Folder,
}

export type Role = {
    Kind: "Role",
    Definition: RoleDefinition,
    
    IsAlliedWith: (Role, other: Role) -> boolean,
    GetFormattedRoleName: (Role) -> string,
    GetExclamatoryString: (Role) -> string,
    GetFormattedString: (Role, str: string) -> string,
}

export type OnMapPropBreak = (prop: MapProp, params: DamageParams?) -> () 

export type RoundEvent = {
    Timestamp: number,
    Data: RoundEventData,
}

export type RoundEventData = DeathEventData | CorpseSearchedEventData | StartRoundEventData | EndRoundEventData | DeathConfirmedEventData

export type DeathEventData = {
    Kind: "DeathRoundEvent",

    Victim: Participant,
}

export type CorpseSearchedEventData = {
    Kind: "CorpseSearchedRoundEvent",
    
    SearchedBy: Participant,
    Victim: Participant,
    FoundCredits: number?,
}

export type DeathConfirmedEventData = {
    Kind: "DeathConfirmedRoundEvent",
    Victim: Participant,
    ConfirmedBy: Participant,
}

export type StartRoundEventData = {
    Kind: "StartRoundEvent",
}

export type EndRoundEventData = {
    Kind: "EndRoundEvent",
    VictoryText: string,
}

export type SelfDefenseParams = {
    Against: Participant,
    Duration: number,
}

export type GunWeapon = {
    Kind: "Gun",
    Definition: GunWeaponDefinition,
    Model: BasePart,

    Ammo: number,
    LastAttackTime: number,

    IsReloading: boolean,

    Extras: {[string]: any},
}

export type GrenadeWeapon = {
    Kind: "Grenade",
    Definition: GrenadeWeaponDefinition,
    Model: BasePart,

    Extras: {[string]: any},
}

export type MeleeWeapon = {
    Kind: "Melee",
    Definition: MeleeWeaponDefinition,
    Model: BasePart,

    LastAttackTime: number,

    Extras: {[string]: any},
}

export type Item = {
    Kind: "Item",
    Definition: ItemDefinition,
    Model: BasePart?,

    Extras: {[string]: any},
}

export type AnyItem = Item | AnyWeapon
export type AnyWeapon = GunWeapon | GrenadeWeapon | MeleeWeapon
export type GunMeleeWeapon = GunWeapon | MeleeWeapon

export type AmmoBox = {
    Kind: "AmmoBox",
    Definition: AmmoDefinition,
    Model: BasePart,
    Ammo: number,

    SetAmmo: (AmmoBox, amount: number) -> (),
}

export type SelfDefenseEntry = {
    Against: Participant,
    Until: number,
}

export type CorpseView = {
    Name: string,
    UserId: number,

    WasFreeKill: boolean?,
    WasHeadshot: boolean?,
    WasSelfDefense: boolean?,

    KillList: {string},
    EquipmentList: {string},

    DeathTime: number,
    DNAExpiry: number?,

    DamageSource: NamedDamageSource,
}

export type Corpse = {
    Participant: Participant,

    CorpseView: CorpseView,
    WasCorrectKill: boolean?, -- Not in CorpseView, as we don't want clients to see this

    Model: Model?,

    _searchedBy: {Participant},
    GetSearchedBy: (Corpse) -> {Participant},

    UpdateKillList: (Corpse) -> (),

    Search: (Corpse, searcher: Participant, covert: boolean) -> boolean,

    Killer: Participant?,
}

export type Participant = {
    Kind: "Participant",

    Extras: {[string]: any},
    
    Player: Player,
    Round: Round,

    _slayVotes: {Participant},
    GetSlayVotes: (Participant) -> {Participant},
    TryAddSlayVote: (Participant, participant: Participant) -> boolean,

    TryPlayAnimation: (Participant, id: number, name: string) -> (),
    TryStopAnimation: (Participant, name: string) -> (),

    _karma: number,
    GetKarma: (Participant) -> number,
    SetKarma: (Participant, karma: number) -> (),

    _isFreeKill: boolean,
    IsFreeKill: (Participant) -> boolean,
    SetFreeKill: (Participant, reason: string?) -> (),

    GetKarmaDamageMultiplier: (Participant) -> number,

    _role: Role?,
    GetRole: (Participant) -> Role?,
    SetRole: (Participant, role: RoleDefinition?) -> (),

    IsAlliedWithParticipant: (Participant, other: Participant) -> boolean,
    IsDamageJustifiedAgainstParticipant: (Participant, other: Participant) -> boolean,

    GetFormattedName: (Participant) -> string,

    _corpse: Corpse?,
    GetCorpse: (Participant) -> Corpse?,

    _isCharacterLoading: boolean,
    _character: Model?,
    GetCharacter: (Participant) -> Model?,

    _humanoid: Humanoid?,
    GetHumanoid: (Participant) -> Humanoid?,
    
    SpawnCharacter: (Participant) -> (),
    UnspawnCharacter: (Participant) -> (),

    _selfDefenseList: {SelfDefenseEntry},
    AddSelfDefenseEntry: (Participant, params: SelfDefenseParams) -> (),
    HasSelfDefenseAgainstParticipant: (Participant, against: Participant) -> boolean,

    _killList: {Participant},
    _addToKillList: (Participant, toAdd: Participant) -> (),
    GetKillList: (Participant) -> {Participant},

    _scores: ScoreTable,
    GetScores: (Participant) -> ScoreTable,
    AddScore: (Participant, reason: string, amount: number) -> (),

    _credits: number,
    AddCredits: (Participant, amount: number) -> (),
    SetCredits: (Participant, amount: number) -> (),
    GetCredits: (Participant) -> number,

    _items: {[string]: AnyItem?},
    _ammo: {[string]: number?},

    DropAmmoBoxForCurrentItem: (Participant) -> (),

    GetEquippedItem: (Participant) -> AnyItem?,
    SetEquippedItem: (Participant, item: AnyItem?) -> (),
    _equippedItem: AnyItem?,

    GetItems: (Participant) -> {[string]: AnyItem?},
    GiveItemFromItemDefinition: (Participant, itemDefinition: AnyItemDefinition) -> AnyItem,
    DropItem: (Participant, item: AnyItem, throwDirection: Vector3?) -> (),

    AddItem: (Participant, item: AnyItem) -> (),
    RemoveItem: (Participant, item: AnyItem) -> (),
    TryDropItem: (Participant, item: AnyItem, throw: boolean?) -> boolean,

    IsItemSlotOccupied: (Participant, slot: number) -> boolean,

    GetAmmo: (Participant, kind: string) -> number,
    SetAmmo: (Participant, kind: string, amount: number) -> (),
    GetAllAmmo: (Participant) -> {[string]: number},
    HasWeaponOfAmmoType: (Participant, ammoType: string) -> boolean,

    _itemPurchases: EquipmentPurchases,
    GetItemPurchases: (Participant) -> EquipmentPurchases,
    PurchaseItem: (Participant, itemDefinition: AnyItemDefinition) -> ItemPurchaseResult,

    _status: ParticipantStatus,
    _setStatus: (Participant, status: ParticipantStatus) -> (),
    GetStatus: (Participant) -> ParticipantStatus,

    _wasDeathProcessed: boolean?,
    IsAlive: (Participant) -> boolean,
    TryTakeDamage: (Participant, params: DamageParams) -> boolean,
    GetHealth: (Participant) -> number,
    SetHealth: (Participant, health: number) -> (),

    MoveToSpawn: (Participant) -> (),

    TryThrowAssembly: (Participant, assemblyRoot: BasePart, force: number, parent: Instance?, position: Vector3?, direction: Vector3?, noForward: boolean?) -> boolean,
}

export type CorpseProp = {
    Kind: "CorpseProp",
    Model: DataModelCorpse,
    Participant: Participant,
}

export type ItemProp = {
    Kind: "ItemProp",
    Model: DataModelItem,
    Item: AnyItem,
}

export type AmmoProp = {
    Kind: "AmmoProp",
    Model: DataModelAmmo,
    AmmoBox: AmmoBox,
}

export type MapProp = {
    Kind: "MapProp",
    Model: DataModelMapProp,

    Round: Round,

    _health: number?,
    GetHealth: (MapProp) -> number?,
    SetHealth: (MapProp, health: number) -> (),

    TryTakeDamage: (MapProp, params: DamageParams) -> boolean,
}

export type Prop = CorpseProp | ItemProp | MapProp | AmmoProp

export type Round = {
    Gamemode: Gamemode,

    GetItemDefinition: (Round, item: string) -> AnyItemDefinition?,
    GetAmmoDefinition: (Round, ammo: string) -> AmmoDefinition?,

    _map: Map?,
    LoadMap: (Round, mapScript: ModuleScript) -> (),
    GetMap: (Round) -> Map,

    _items: {[DataModelItem]: AnyItem?},
    GetItems: (Round) -> {[DataModelItem]: AnyItem?},
    GetItem: (Round, part: DataModelItem) -> AnyItem?,

    _ammoBoxes: {[DataModelItem]: AmmoBox?},
    GetAmmoBoxes: (Round) -> {[DataModelItem]: AmmoBox?},
    GetAmmoBox: (Round, part: DataModelItem) -> AmmoBox?,

    _props: {[DataModelProp]: Prop?},
    GetProps: (Round) -> {[DataModelProp]: Prop?},
    GetProp: (Round, model: DataModelProp) -> Prop?,
    LoadProp: (Round, model: DataModelProp, kind: "MapProp" | "CorpseProp" | "ItemProp" | "AmmoProp") -> Prop,

    _participants: {[string]: Participant?},
    GetParticipant: (Round, name: string) -> Participant?,
    GetParticipants: (Round) -> {[string]: Participant?},
    AddPlayer: (Round, player: Player, addAsSpectator: boolean?) -> Participant,
    RemoveParticipant: (Round, participant: Participant) -> (),

    _eventLog: {RoundEvent},
    AddEvent: (Round, data: RoundEventData) -> (),
    GetEventLog: (Round) -> {RoundEvent},

    _heartbeat: RBXScriptConnection?,
    _roundPhase: RoundPhase,
    GetRoundPhase: (Round) -> RoundPhase,
    SetRoundPhase: (Round, phase: RoundPhase, duration: number) -> (),

    IsPreGame: (Round) -> boolean,
    IsPostGame: (Round) -> boolean,
    IsInProgress: (Round) -> boolean,

    _isPaused: boolean,
    PauseRound: (Round, paused: boolean) -> (),
    GetIsRoundPaused: (Round) -> boolean,

    StartRound: (Round) -> (),
    EndRound: (Round, victor: Victor, isTimeout: boolean?) -> (),

    _roles: {[string]: Role?},

    GetRoleFromRoleName: (Round, name: string) -> Role,
    GetParticipantsWithRole: (Round, role: Role) -> {Participant},

    SendMessage: (Round, to: {Player} | Player, message: string, kind: MessageKind?) -> (),
}

return nil