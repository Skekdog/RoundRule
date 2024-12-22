export type ParticipantStatus = "Alive" | "Missing" | "Dead" | "Spectating"

export type Victor = Participant | Role
export type VictorType = {Kind: "Role", Role: string} | {Kind: "Solo"}

export type ScoreTable = {[string]: number?}
export type EquipmentPurchases = {[string]: number?}

export type ItemPurchaseResult = "Success" | "NotEnoughCredits" | "SlotOccupied" | "NotInStock" | "InvalidItemForRole"

export type GeneralDamageSource = "Fall" | "Drown" | "Explode" | "Burn" | "Stab" | "Shot" | "Bludgeon" | "Crush" | "Magic" | "Other"
export type DamageSource = AnyItem | GeneralDamageSource

export type RoundPhase = "Waiting" | "Preparing" | "Playing" | "Highlights" | "Intermission"
export type RoundAdvanceCallback = (Round) -> ()

export type DataModelProp = BasePart
export type DataModelItem = BasePart

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
    
    Roles: {[string]: Role},

    OnDeath: (Gamemode, Participant) -> (),
    OnCharacterAdded: (Gamemode, Participant) -> (),
}

export type Role = {
    Kind: "Role",

    Name: string,
    DisplayName: string?,
    Description: string,
    Color: Color3,
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

export type ItemDamageInfo = number | {
    Head: number,
    Body: number,
    Limb: number,
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
    Damage: ItemDamageInfo,

    HoldAnimation: string,
}

export type ItemDefinition = CommonItemDefinition & {
    Kind: "Item",

    PrimaryHint: string?,
    AlternateHint: string?,

    PrimaryFireClient: ((Item) -> ())?,
    AlternateFireClient: ((Item) -> ())?,

    HeartbeatClient: ((Item) -> ())?,

    PrimaryFireServer: ((Item, Participant) -> ())?,
    AlternateFireServer: ((Item, Participant) -> ())?,
}

export type GunWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Gun",

    AimAnimation: string?,

    ReloadTime: number,
    FireTime: number,

    FiredSound: string,
    ReloadSound: string,

    AmmoType: AmmoDefinition,

    AimFOV: number?,
    HasScope: boolean?,
    ScopeRequired: boolean?,
    AimSpreadMultiplier: number?,

    Projectile: string?,
    
    BulletsPerShot: number?,

    Spread: number,
    RecoilX: number,
    RecoilY: number,

    BeforeHitParticipant: ((GunWeapon, Participant, Participant, DamageParams) -> ())?,
    BeforeHitProp: ((GunWeapon, Participant, Prop, DamageParams) -> ())?,
}

export type GrenadeWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Grenade",

    FuseTime: number,

    Projectile: string,
    ProjectileForce: number,

    BeforeHitParticipant: ((GrenadeWeapon, Participant, Participant, DamageParams) -> ())?,
    BeforeHitProp: ((GrenadeWeapon, Participant, Prop, DamageParams) -> ())?,

    OnExplode: ((GrenadeWeapon, Participant, BasePart) -> ())?,
}

export type MeleeWeaponDefinition = CommonWeaponDefinition & {
    Kind: "Melee",

    AttackAnimation: string,

    AttackInterval: number,

    MaxDistance: number,

    BeforeHitParticipant: ((MeleeWeapon, Participant, Participant, DamageParams) -> ())?,
    BeforeHitProp: ((MeleeWeapon, Participant, Prop, DamageParams) -> ())?,
}

export type AmmoDefinition = {
    Kind: "Ammo",
    Name: string,
    DisplayName: string?,
    Capacity: number,
    ReserveCapacity: number,
    Model: BasePart,
}

export type AnyItemDefinition = ItemDefinition | GunWeaponDefinition | GrenadeWeaponDefinition | MeleeWeaponDefinition

export type Map = {
    Name: string,
    DisplayName: string?,
    Description: string,
    Authors: string,

    MapIcons: {
        ["16:9"]: string?,
        ["4:3"]: string?,
        ["1:1"]: string?,
    },

    PlayerSpawns: Folder,

    StaticMap: Folder,
    Bounds: Folder?,
    
    DynamicMap: Folder?,
    Props: Folder?,
    Windows: Folder?,
    ItemSpawns: Folder?,
    AmmoSpawns: Folder?,

    Gravity: number,

    MaterialVariants: Folder?,

    LightingSettings: Folder,
    FutureLightingSettings: Folder?,

    WaterSettings: Folder,

    TerrainRegion: TerrainRegion?,
    TerrainColors: Folder,

    AvailableItems: {[string]: AnyItemDefinition},
    AvailableAmmo: {[string]: AmmoDefinition},
}

export type OnPropBreak = (Prop, params: DamageParams?) -> () 

export type RoundEvent = {
    Timestamp: number,
    Data: RoundEventData,
}

export type RoundEventData = DeathEventData | CorpseSearchedEventData | StartRoundEventData | EndRoundEventData

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

export type StartRoundEventData = {
    Kind: "StartRoundEvent",
}

export type EndRoundEventData = {
    Kind: "EndRoundEvent",
    VictoryText: string,
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

export type SelfDefenseParams = {
    Against: Participant,
    Duration: number,
}

export type GunWeapon = {
    Kind: "Gun",
    Definition: GunWeaponDefinition,
    Model: BasePart,

    Ammo: number,
    LastFireTime: number,

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

export type AnyItem = Item | GunWeapon | GrenadeWeapon | MeleeWeapon

export type AmmoBox = {
    Kind: "AmmoBox",
    Definition: AmmoDefinition,
    Model: BasePart,
    Ammo: number,
}

export type SelfDefenseEntry = {
    Against: Participant,
    Until: number,
}

export type CorpseView = {
    WasFreeKill: boolean?,
    WasHeadshot: boolean?,
    WasSelfDefense: boolean?,

    DeathTime: number,
    DNAExpiry: number?,

    DamageSource: GeneralDamageSource,
}

export type Corpse = {
    CorpseView: CorpseView,
    WasCorrectKill: boolean?, -- Not in CorpseView, as we don't want clients to see this

    Model: Model?,

    _searchedBy: {Participant},
    GetSearchedBy: (Corpse) -> {Participant},
    AddSearchedBy: (Corpse, participant: Participant) -> (),

    Killer: Participant?,
}

export type Participant = {
    Kind: "Participant",

    Extras: {[string]: any},
    
    Player: Player,
    Round: Round,

    _slayVotes: {Participant},
    GetSlayVotes: (Participant) -> {Participant},
    TryAddSlayVote: (Participant, participant: Participant) -> (),

    _karma: number,
    GetKarma: (Participant) -> number,
    SetKarma: (Participant, karma: number) -> (),

    _isFreeKill: boolean,
    IsFreeKill: (Participant) -> boolean,
    SetFreeKill: (Participant, reason: string?) -> (),

    GetKarmaDamageMultiplier: (Participant) -> number,

    _role: Role?,
    GetRole: (Participant) -> Role?,
    SetRole: (Participant, role: Role) -> (),

    IsAlliedWithParticipant: (Participant, other: Participant) -> boolean,
    IsDamageJustifiedAgainstParticipant: (Participant, other: Participant) -> boolean,

    GetFormattedName: (Participant) -> string,

    _corpse: Corpse?,
    GetCorpse: (Participant) -> Corpse?,

    TryViewOtherParticipantCorpse: (Participant, other: Participant, covert: boolean?) -> (),

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
    _addToKillList: (Participant) -> (),
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
    GiveItemFromItemDefinition: (Participant, itemDefinition: AnyItemDefinition) -> (),
    DropItem: (Participant, item: AnyItem, throw: boolean?) -> (),

    AddItem: (Participant, item: AnyItem) -> (),
    RemoveItem: (Participant, item: AnyItem) -> (),    

    IsItemSlotOccupied: (Participant, slot: number) -> boolean,

    GetAmmo: (Participant, kind: string) -> number,
    SetAmmo: (Participant, kind: string, amount: number) -> (),
    GetAllAmmo: (Participant) -> {[string]: number},

    _itemPurchases: EquipmentPurchases,
    GetItemPurchases: (Participant) -> EquipmentPurchases,
    PurchaseItem: (Participant, itemDefinition: AnyItemDefinition) -> ItemPurchaseResult,

    _status: ParticipantStatus,
    _setStatus: (Participant, status: ParticipantStatus) -> (),
    GetStatus: (Participant) -> ParticipantStatus,

    _wasDeathProcessed: boolean?,
    IsAlive: (Participant) -> boolean,
    TryTakeDamage: (Participant, params: DamageParams) -> (),
    GetHealth: (Participant) -> number,
    SetHealth: (Participant, health: number) -> (),
}

export type Prop = {
    Kind: "Prop",
    Model: DataModelProp,

    _health: number?,
    GetHealth: (Prop) -> number?,
    SetHealth: (Prop, health: number) -> (),

    TryTakeDamage: (Prop, params: DamageParams) -> (),
}

export type Round = {
    Gamemode: Gamemode,

    GetItemDefinition: (Round, item: string) -> AnyItemDefinition?,
    GetAmmoDefinition: (Round, ammo: string) -> AmmoDefinition?,

    _map: Map?,
    LoadMap: (Round, map: Map) -> (),
    GetMap: (Round) -> Map,

    _items: {[DataModelItem]: AnyItem?},
    GetItems: (Round) -> {[DataModelItem]: AnyItem?},
    GetItem: (Round, part: DataModelItem) -> AnyItem?,
    LoadItem: (Round, map: Map, part: DataModelItem) -> AnyItem,

    _ammoBoxes: {[DataModelItem]: AmmoBox?},
    GetAmmoBoxes: (Round) -> {[DataModelItem]: AmmoBox?},
    GetAmmoBox: (Round, part: DataModelItem) -> AmmoBox?,
    LoadAmmoBox: (Round, map: Map, part: DataModelItem) -> AmmoBox,

    _props: {[DataModelProp]: Prop?},
    GetProps: (Round) -> {[DataModelProp]: Prop?},
    GetProp: (Round, model: DataModelProp) -> Prop?,
    LoadProp: (Round, model: DataModelProp) -> Prop,

    _participants: {[string]: Participant?},
    GetParticipant: (Round, name: string) -> Participant?,
    GetParticipants: (Round) -> {[string]: Participant?},
    AddPlayer: (Round, player: Player, addAsSpectator: boolean?) -> Participant,
    RemoveParticipant: (Round, participant: Participant) -> (),

    _eventLog: {RoundEvent},
    AddEvent: (Round, data: RoundEventData) -> (),
    GetEventLog: (Round) -> {RoundEvent},

    _roundPhase: RoundPhase,
    GetRoundPhase: (Round) -> RoundPhase,
    SetRoundPhase: (Round, phase: RoundPhase, duration: number) -> (),

    IsPreGame: (Round) -> boolean,
    IsPostGame: (Round) -> boolean,
    IsInProgress: (Round) -> boolean,

    _lastAdvanceCallback: RoundAdvanceCallback?,
    _activeAdvanceThread: thread?,
    SetAdvanceTime: (Round, finishTime: number, callback: false | "preserve" | RoundAdvanceCallback) -> (),

    _isPaused: boolean,
    PauseRound: (Round, paused: boolean) -> (),
    GetIsRoundPaused: (Round) -> boolean,

    StartRound: (Round) -> (),
    EndRound: (Round, victor: Victor) -> (),

    GetRoleFromRoleName: (Round, name: string) -> Role,
    GetParticipantsWithRole: (Round, role: Role) -> {Participant},

    GetFormattedRoleName: (role: Role) -> string,
    GetExclamatoryString: (role: Role) -> string,

    IsRoleAlliedWithRole: (role1: Role, role2: Role) -> boolean,

    SendMessage: (Round, to: {Player} | Player, message: string) -> (),
}

return nil