export type ParticipantStatus = "Alive" | "Missing" | "Dead" | "Spectating"

export type Victor = Participant | Role
export type VictorType = {Kind: "Role", Role: string} | {Kind: "Solo"}

export type ScoreTable = {[string]: number?}
export type EquipmentPurchases = {[string]: number?}

export type ItemPurchaseResult = "Success" | "NotEnoughCredits" | "SlotOccupied" | "NotInStock" | "InvalidItemForRole" | "NotInRound"

export type GeneralDamageSource = "Fall" | "Drown" | "Explode" | "Burn" | "Stab" | "Shot" | "Bludgeon" | "Crush" | "Magic" | "Other" | "Poison"
export type NamedDamageSource = GeneralDamageSource | string
export type DamageSource = AnyItem | GeneralDamageSource

export type Bound = BasePart

-- todo: when recursive generic types are supported, do that
export type ItemBeforeHit = AnyWeapon | ExplosionParams
export type BeforeHitAnything = (item: ItemBeforeHit, round: Round, hitPart: BasePart, params: DamageParams) -> boolean
export type BeforeHitParticipant = (item: ItemBeforeHit, round: Round, hitParticipant: Participant, params: DamageParams) -> boolean
export type BeforeHitProp = (item: ItemBeforeHit, round: Round, hitProp: Prop, params: DamageParams) -> boolean

export type RunBeforeHit = (item: ItemBeforeHit, round: Round, hitPart: BasePart, params: DamageParams) -> boolean

export type ItemDefinitionOnHitClient = GunWeaponDefinition | MeleeWeaponDefinition | GrenadeWeaponDefinition
export type OnHitClient = (item: ItemDefinitionOnHitClient, hitPart: BasePart?) -> ()

export type RunOnHitClient = (item: AnyWeapon, participant: Participant, hitPart: BasePart) -> ()

export type Extras = {[any]: any}

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

export type CorpseIcon = {
    Name: string,
    DisplayText: string?,
    Description: string,
    Icon: string,
}

export type ExplosionParams = {
    Kind: "ExplosionParams",

    Definition: ExplosionInfo,
    Attacker: Participant?,
    Position: Vector3,

    RunBeforeHit: RunBeforeHit,
}

export type DamageParams = {
    Amount: number,

    Origin: Vector3?,
    HitPosition: Vector3?,
    HitPart: BasePart?,

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
export type DataModelInteractable = BasePart
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

    TimeoutVictor: (Gamemode, Round) -> Victor,
    
    GetRoundEndMusic: (Gamemode, Round, victor: Victor, isTimeout: boolean) -> Sound?,

    EnableFriendlyFire: boolean?,
    EnableKarma: boolean?,

    AvailableItems: {[string]: AnyItemDefinition},
    AvailableAmmo: {[string]: AmmoDefinition},

    InteractableDefinitions: {[string]: InteractableDefinition},

    StartingItems: {AnyItemDefinition},

    Duration: (numParticipants: number) -> number,

    AssignRoles: (Gamemode, {Participant}) -> (),
    
    Roles: {[string]: RoleDefinition},

    DeathSounds: {string},

    OnDeath: (Gamemode, Participant, deferVictoryCheck: boolean) -> (),
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

	IsBadGuys: boolean?,

    Allegiance: VictorType,
    VictoryText: string?,

    StartingItems: {AnyItemDefinition}?,
    StartingCredits: number?,
    EquipmentShop: {AnyItemDefinition}?,

    ShouldAnnounceDisconnect: boolean?,
    CanStealCreditsFromCorpses: boolean?,
    CanSeeMissingInAction: boolean?,
    CanTeamChat: boolean?,

    AwardCreditsToRolesOnDeath: {[string]: number}?,

    CorpseSearchResultsPublicised: boolean?,
    ScoreForFindingBodies: number?,

    WalkSpeed: number?,
    JumpPower: number?,
    Health: number?,

    Accessories: {string}?,

    DamageKarmaMultiplier: number?,

    Allies: {string}?,
    RevealedRoles: {string}?,
    HighlightedRoles: {string}?,
}

export type InteractableDefinition = {
    Name: string,
    DisplayName: string?,

    NoActionHint: boolean?,

    Model: BasePart,

    IsContinuousInteraction: boolean,
    InteractionRange: number,

    OnInteractClient: ((object: Interactable) -> ())?,
    OnInteractServer: ((object: Interactable, participant: Participant) -> ())?,

    OnLoadClient: ((object: Interactable) -> ())?,
    OnLoadServer: ((object: Interactable) -> ())?,

    OnBreakServer: ((object: Interactable, params: DamageParams?) -> ())?,

    BeforeTakeDamage: ((object: Interactable, params: DamageParams) -> boolean)?,
}

export type Interactable = {
    Kind: "Interactable",
    Definition: InteractableDefinition,
    Object: BasePart,

    Round: Round?,
    Extras: Extras,

    HintTextClient: string?,

    _health: number?,
    GetHealth: (Interactable) -> number?,
    SetHealth: (Interactable, health: number) -> (),
    TryTakeDamage: (Interactable, params: DamageParams, deferDeath: boolean?) -> boolean,
}

export type CommonItemDefinition = {
    Name: string,
    DisplayName: string?,
    Description: string?,
    
    Icon: string?,
    IsPixelIcon: boolean?,

	IsBadGuyItem: boolean?,

    Model: BasePart?,
    HoldAnimation: string?,

    Slot: number?,
    CanDrop: boolean?,

    CreditCost: number?,
    MaxStock: number?,
}

export type CommonWeaponDefinition = CommonItemDefinition & {
    HoldAnimation: string,
}

export type FireActionClient = (item: Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3) -> ()
export type FireActionServer = (item: Item, mode: "Primary" | "Alternate", origin: Vector3, direction: Vector3, participant: Participant) -> ()

export type SchedulerCallback = (item: AnyItem, dt: number) -> ()
export type ItemDefinition = CommonItemDefinition & {
    Kind: "Item",

    PrimaryHint: string?,
    AlternateHint: string?,

    HeartbeatClient: SchedulerCallback?,
    PreSimulationClient: SchedulerCallback?,
    PostSimulationClient: SchedulerCallback?,
    PreRenderClient: SchedulerCallback?,
    PreAnimationClient: SchedulerCallback?,

    PrimaryFireClient: FireActionClient?,
    AlternateFireClient: FireActionClient?,

    PrimaryFireServer: FireActionServer?,
    AlternateFireServer: FireActionServer?,

    PrimaryToggled: boolean?,
    AlternateToggled: boolean?,

    OnPurchase: ((item: Item, participant: Participant) -> ())?,

    OnUnequipClient: ((item: Item) -> ())?,
    OnUnequipServer: ((item: Item, participant: Participant) -> ())?,

    OnEquipClient: ((item: Item) -> ())?,
    OnEquipServer: ((item: Item, participant: Participant) -> ())?,
}

export type BeforeGunPrimaryFireClient = (item: GunWeapon, targettedParts: {BasePart}) -> boolean
export type GunWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Gun",

    AimAnimation: string?,

    ReloadTime: number,
    AttackInterval: number,

    AttackSound: Sound?,
    ReloadSound: Sound?,

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

    OnHitClient: OnHitClient?,

    HeartbeatClient: SchedulerCallback?,
    PreSimulationClient: SchedulerCallback?,
    PostSimulationClient: SchedulerCallback?,
    PreRenderClient: SchedulerCallback?,
    PreAnimationClient: SchedulerCallback?,

    BeforePrimaryFireClient: BeforeGunPrimaryFireClient?,
}

export type GrenadeWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Grenade",

    FuseTime: number,

    AttackSound: Sound?,

    Projectile: BasePart,
    ProjectileForce: number,

    ExplosionInfo: ExplosionInfo,

    OnExplode: ((item: GrenadeWeapon, attacker: Participant, projectile: BasePart) -> ())?,
    OnHitClient: OnHitClient?,
}

export type MeleeWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Melee",

    DamageKind: "Bludgeon" | "Stab",
    AttackAnimation: string,

    AttackInterval: number,
    AttackSound: Sound?,

    Damage: DamageInfo,

    MaxDistance: number,

    BeforeHitAnything: BeforeHitAnything?,
    BeforeHitParticipant: BeforeHitParticipant?,
    BeforeHitProp: BeforeHitProp?,

    OnHitClient: OnHitClient?,

    AlternateFireServer: (item: MeleeWeapon, _: never, origin: Vector3, direction: Vector3, attacker: Participant) -> ()?,
    AlternateFireClient: (item: MeleeWeapon, _: never, origin: Vector3, direction: Vector3) -> ()?,
    AlternateToggled: boolean?,
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

    InteractableDefinitions: {[string]: InteractableDefinition},

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
    Interactables: Folder,

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

export type BaseWeapon = {
    Model: BasePart,
    Extras: Extras,

    RunBeforeHit: RunBeforeHit,
    RunOnHitClient: RunOnHitClient,
}

export type GunWeapon = BaseWeapon & {
    Kind: "Gun",
    Definition: GunWeaponDefinition,

    Ammo: number,
    LastAttackTime: number,

    IsReloading: boolean,
}

export type GrenadeWeapon = BaseWeapon & {
    Kind: "Grenade",
    Definition: GrenadeWeaponDefinition,
}

export type MeleeWeapon = BaseWeapon & {
    Kind: "Melee",
    Definition: MeleeWeaponDefinition,

    LastAttackTime: number,
}

export type Item = {
    Kind: "Item",
    Definition: ItemDefinition,
    Model: BasePart?,

    Extras: Extras,
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

    AdditionalIcons: {CorpseIcon},

    WasFreeKill: boolean?,
    WasHeadshot: boolean?,
    WasSelfDefense: boolean?,

    KillList: {string},
    EquipmentList: {string},

    DeathTime: number,

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

export type ParticipantLastDamaged = {
    By: Participant,
    ExpiresAt: number,
}

export type Participant = {
    Kind: "Participant",

    Extras: Extras,

    Player: Player,
    Round: Round,

    DidParticipate: boolean,

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
    GetRole: (Participant) -> Role,
    SetRole: (Participant, role: RoleDefinition?) -> (),

    IsAlliedWithParticipant: (Participant, other: Participant) -> boolean,
    IsDamageJustifiedAgainstParticipant: (Participant, other: Participant) -> boolean,

    GetFormattedName: (Participant) -> string,

    _corpse: Corpse?,
    GetCorpse: (Participant) -> Corpse?,

    _additionalCorpseIcons: {CorpseIcon},
    AddCorpseIcon: (Participant, icon: CorpseIcon) -> (),
    GetAdditionalCorpseIcons: (Participant) -> {CorpseIcon},

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

    _lastDamaged: ParticipantLastDamaged?,
    SetLastDamaged: (Participant, by: Participant, duration: number) -> (),
    GetLastDamagedBy: (Participant) -> Participant?,

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
    TryTakeDamage: (Participant, params: DamageParams, deferDeath: boolean?) -> boolean,
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

    TryTakeDamage: (MapProp, params: DamageParams, deferDeath: boolean?) -> boolean,
}

export type Prop = CorpseProp | ItemProp | MapProp | AmmoProp

export type Round = {
    Gamemode: Gamemode,

    Extras: Extras,

    GetItemDefinition: (Round, item: string) -> AnyItemDefinition?,
    GetAmmoDefinition: (Round, ammo: string) -> AmmoDefinition?,
    GetInteractableDefinition: (Round, interactable: string) -> InteractableDefinition?,

    _map: Map?,
    LoadMap: (Round, mapScript: ModuleScript) -> (),
    GetMap: (Round) -> Map,

    _items: {[DataModelItem]: AnyItem?},
    GetItems: (Round) -> {[DataModelItem]: AnyItem?},
    GetItem: (Round, part: DataModelItem) -> AnyItem?,

    LoadItem: (Round, model: DataModelItem) -> ItemProp,

    _ammoBoxes: {[DataModelItem]: AmmoBox?},
    GetAmmoBoxes: (Round) -> {[DataModelItem]: AmmoBox?},
    GetAmmoBox: (Round, part: DataModelItem) -> AmmoBox?,

    _interactables: {[DataModelInteractable]: Interactable?},
    GetInteractables: (Round) -> {[DataModelInteractable]: Interactable?},
    GetInteractable: (Round, part: DataModelInteractable) -> Interactable?,

    _props: {[DataModelProp]: Prop?},
    GetProps: (Round) -> {[DataModelProp]: Prop?},
    GetProp: (Round, model: DataModelProp) -> Prop?,
    LoadProp: (Round, model: DataModelProp, kind: "MapProp" | "CorpseProp" | "ItemProp" | "AmmoProp") -> Prop,

    AddInteractable: (Round, definition: InteractableDefinition, object: DataModelInteractable?) -> Interactable,

    _participants: {[string]: Participant?},
    GetParticipant: (Round, name: string) -> Participant?,
    GetParticipants: (Round) -> {[string]: Participant?},
    AddPlayer: (Round, player: Player, addAsSpectator: boolean?, karma: number?) -> Participant,
    RemoveParticipant: (Round, participant: Participant, isRejoining: boolean) -> (),

    RoundEndMusic: {
        Music: Sound,
        StartedAt: number,
    }?,

    _eventLog: {RoundEvent},
    AddEvent: (Round, data: RoundEventData) -> (),
    GetEventLog: (Round) -> {RoundEvent},

    ElapsedPhaseTime: number,
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