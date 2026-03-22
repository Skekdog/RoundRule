export type ParticipantStatus = "Alive" | "Missing" | "Dead"

export type Victor = Participant | Role
export type VictorType = {Kind: "Role", Role: string} | {Kind: "Solo"}

export type ScoreTable = {[string]: number?}
export type ItemPurchases = {[string]: number?}

export type ItemPurchaseResult = "Success" | "NotEnoughCredits" | "SlotOccupied" | "NotInStock" | "InvalidItemForRole" | "NotInRound"

export type GeneralDamageSource = "Fall" | "Drown" | "Explode" | "Burn" | "Stab" | "Shot" | "Bludgeon" | "Crush" | "Magic" | "Other" | "Poison" | "Stomp"
export type DamageSource = Item | GeneralDamageSource

export type ItemSchedulerCallback = (item: Item, dt: number) -> ()

export type BeforeHitAnything = (item: Item, params: DamageParams, round: Round) -> boolean
export type BeforeHitParticipant = (item: Item, params: DamageParams, participant: Participant) -> boolean
export type BeforeHitProp = (item: Item, params: DamageParams, prop: Prop) -> boolean

export type BeforeHitAnythingExplosionInfo = (info: ExplosionInfo, params: DamageParams) -> ()
export type BeforeHitParticipantExplosionInfo = (info: ExplosionInfo, params: DamageParams, participant: Participant) -> ()
export type BeforeHitPropExplosionInfo = (info: ExplosionInfo, params: DamageParams, prop: Prop) -> ()

export type MapObject = BasePart | Model -- type is weird because Model | BasePart will lead to errorneous type errors when doing MapObject.Name = "blah"

export type Extras = {[any]: any}

export type Highlight = {
    Title: string,
    Description: string,
    Priority: number,
    Group: string,
    ScoreBonus: number?,
    Participants: {Participant}?,
}

export type ExplosionInfo = {
    Damage: number,
    FalloffStart: number,
    FalloffEnd: number,
    Pressure: number,
    VisualRadius: number,

    IgnoreSelfDefense: boolean?,
    IgnoreKarma: boolean?,
    IgnoreScore: boolean?,

    BeforeHitAnything: BeforeHitAnythingExplosionInfo?,
    BeforeHitParticipant: BeforeHitParticipantExplosionInfo?,
    BeforeHitProp: BeforeHitPropExplosionInfo?,

    FilterImpulse: ((ExplosionInfo, participant: Participant) -> boolean?)?,
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
    SourceItem: ItemComponents?,
}

export type DamageParams = {
    Amount: number,

    TimeOrigin: number?,
    Origin: Vector3?,
    HitPosition: Vector3?,
    HitPart: BasePart?,
    Direction: Vector3?,

    IsHeadshot: boolean?,
    Source: DamageSource,

    Projectile: MapObject?,

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

export type Phase = "Waiting" | "Preparing" | "Playing" | "Highlights" | "Intermission"

export type MessageKind = "Chat" | "Team" | "All"

export type GamemodeDefinition = {
    Name: string,
    DisplayName: string?,
    Description: string,
    Authors: string,

    MinimumPlayers: number | () -> number,

    RequiredSlayVotes: number?,

    TimeoutVictor: (round: Round) -> Victor,

    GetRoundEndMusic: (round: Round, victor: Victor, isTimeout: boolean) -> Sound?,
    GetVictoryEventText: ((round: Round, victor: Victor, isTimeout: boolean) -> string?)?,

    EnableFriendlyFire: boolean?,
    EnableKarma: boolean?,

    IsSlotless: boolean?,
    AvailableItems: {[string]: ItemComponents},
    AvailableAmmo: {[string]: AmmoDefinition},

    InteractableDefinitions: {[string]: InteractableDefinition},

    StartingItems: {ItemComponents},

    Duration: (round: Round, numParticipants: number) -> number,

    AssignRoles: (round: Round, {Participant}) -> ()?,

    Roles: {[string]: RoleDefinition},

    RoleCanCallToCorpse: RoleDefinition?,
    -- Okay so, this is honestly a stupid property to have
    -- but there's currently no good way for gamemodes / items / whatever to do UI stuff, so this
    -- is what we have to do, unless we want a lot more work.

    OnDeath: (round: Round, Participant, deferVictoryCheck: boolean) -> ()?,
    OnCharacterAdded: (round: Round, Participant) -> ()?,
    OnIdentifyCorpse: (round: Round, corpse: Corpse, searcher: Participant) -> ()?,
    AddFinishHighlights: (round: Round) -> ()?,
    OnFinish: (round: Round) -> ()?,
    OnStart: (round: Round) -> ()?,

    Heartbeat: (round: Round, dt: number) -> ()?,

    OnItemEquipped: (round: Round, participant: Participant, item: Item, equipped: boolean) -> ()?,
    BeforeDamageParticipant: ((round: Round, participant: Participant, params: DamageParams) -> boolean)?,
    BeforeDamageProp: ((round: Round, prop: Prop, params: DamageParams) -> boolean)?,

    IsValidOnMap: ((map: MapStructure) -> boolean)?,

    UnloadGamemode: (round: Round) -> ()?,
}

export type RoleDefinition = {
    Kind: "RoleDefinition",

    Name: string,
    DisplayName: string?,
    Description: string,
    Color: Color3,
    Sound: string,
    IsExclamatory: boolean?,

    PluralName: string?,

	IsEvil: boolean?,

    Allegiance: VictorType,

    StartingItems: {ItemComponents}?,
    StartingCredits: number?,
    EquipmentShop: {ItemComponents}?,

    ShouldAnnounceDisconnect: boolean?,
    CanStealCreditsFromCorpses: boolean?,
    CanSeeMissingInAction: boolean?,
    CanTeamChat: boolean?,

    AwardCreditsToRolesOnDeath: {[string]: number}?,
    CorpseHidesSelfDefense: boolean?,

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
    HideName: boolean?,

    DefaultHintText: string?,

    Model: MapObject?,

    IsContinuousInteraction: boolean,
    InteractionRange: number,

    OnInteractClient: ((object: Prop) -> ())?,
    OnInteractServer: ((object: Prop, participant: Participant) -> ())?,

    OnLoadClient: ((object: Prop) -> ())?,
    OnLoadServer: ((object: Prop) -> ())?,

    OnBreakServer: ((object: Prop, params: DamageParams) -> ())?,

    BeforeTakeDamage: ((object: Prop, params: DamageParams) -> boolean)?,
}

export type ItemGroup = {
    PreferredSlot: number?,
}

export type FireClient = (item: Item, origin: Vector3, direction: Vector3) -> string | {string} | boolean
export type FireServer = (item: Item, origin: Vector3, direction: Vector3, participant: Participant, data: unknown) -> {string} | string?

export type Item = {
    Kind: "Item",
    Extras: Extras,

    _additionalPrimaryServerData: unknown,
    _additionalAlternateServerData: unknown,

    SetServerData: (item: Item, action: "Primary" | "Alternate", data: unknown) -> (),
    GetServerData: (item: Item, action: "Primary" | "Alternate") -> unknown,

    ResetLastUse: (item: Item, action: "Primary" | "Alternate") -> (),

    Base: ItemComponents,
    Components: ItemComponents,
} & ItemComponents

export type ItemReplication = {
    Name: string,
    Model: MapObject?, -- model is replicated separately
    Components: ItemComponents,
}

export type ItemComponents = {
    Name: string,
    DisplayName: string?,

    Description: string,
    IconContent: Content,
    IsPixelIcon: boolean?,

    Spread: number?,
    RecoilX: number?,
    RecoilY: number?,

    Cost: number?,
    MaxStock: number?,

    DoNotShowInEquipmentList: boolean?,
    IsEvilItem: boolean?,

    Model: MapObject?,
    HoldAnimation: Content?,

    UnequipDisabled: boolean?,
    DropDisabled: boolean?,
    ItemGroup: ItemGroup?,

    IsSilent: boolean?,
    CanHeadshot: boolean?,

    AmmoDefinition: AmmoDefinition?,
    Ammo: number?,

    ReloadDuration: number?,
    ReloadAnimation: Content?,
    ReloadSound: Sound?,
    IsReloading: boolean?,

    Damage: DamageInfo | number?,
    DamageKind: GeneralDamageSource?,

    ImpulseForce: number?,

    Projectile: MapObject?,
    ProjectileCount: number?,
    ProjectileSpeed: number?,
    IsProjectileSimulated: boolean?,

    IsAimable: boolean?,
    AimFOV: number?,
    AimSpreadMultiplier: number?,
    AimAnimation: Content?,

    IsScopable: boolean?,
    IsScopeRequired: boolean?,

    HasMuzzleFlash: boolean?,

    LaserColor: Color3?,

    PregameDisable: boolean?,

    FalloffStart: number?,
    FalloffEnd: number?,

    OnHitClient: (part: BasePart?) -> ()?,

    MaxBounces: number?,
    ShouldPlayersStopBounces: boolean?,

    MaxDistance: number?,
    CheckInitialIntersection: boolean?,

    FuseTime: number?,
    ExplosionInfo: ExplosionInfo?,
    OnExplode: (params: ExplosionParams) -> ()?,

    IsSingleUse: boolean?,

    PrimaryAnimation: Content?,
    PrimarySound: Sound?,
    HitSound: Sound?,

    PrimaryDisabled: boolean?,
    PrimaryHint: string?,

    PrimaryInterval: number?,
    PrimaryLastUse: number?,

    PrimaryToggled: boolean?,

    PrimaryFireClient: FireClient?,
    PrimaryFireServer: FireServer?,
    PrimaryActivatedClient: (item: Item) -> ()?,
    PrimaryDeactivatedClient: (item: Item) -> ()?,

    BeforeHitAnything: BeforeHitAnything?,
    BeforeHitParticipant: BeforeHitParticipant?,
    BeforeHitProp: BeforeHitProp?,

    AlternateAnimation: Content?,
    AlternateSound: Sound?,

    AlternateDisabled: boolean?,
    AlternateHint: string?,

    AlternateInterval: number?,
    AlternateLastUse: number?,

    AlternateToggled: boolean?,

    AlternateFireClient: FireClient?,
    AlternateFireServer: FireServer?,
    AlternateActivatedClient: (item: Item) -> ()?,
    AlternateDeactivatedClient: (item: Item) -> ()?,

    HeartbeatClient: ItemSchedulerCallback?,
    PreSimulationClient: ItemSchedulerCallback?,
    PostSimulationClient: ItemSchedulerCallback?,
    PreRenderClient: ItemSchedulerCallback?,
    PreAnimationClient: ItemSchedulerCallback?,

    OnEquipServer: (item: Item, participant: Participant) -> ()?,
    OnEquipClient: (item: Item) -> ()?,

    OnUnequipServer: (item: Item, participant: Participant) -> ()?,
    OnUnequipClient: (item: Item) -> ()?,

    OnProjectileSpawn: (item: Item, projectile: MapObject, participant: Participant) -> ()?,
    OnProjectileDespawn: (item: Item, projectile: MapObject, participant: Participant) -> ()?,
}

export type AmmoDefinition = {
    Kind: "Ammo",
    Name: string,
    DisplayName: string?,
    Capacity: number,
    ReserveCapacity: number,
    Model: MapObject?,
    CanDrop: boolean,
}

export type BossDefinition = {
    Name: string,
    DisplayName: string?,
    GamepassId: number?,
    Model: MapObject,

    Gamemode: GamemodeDefinition,

    OnSummon: (boss: BossDefinition, model: Prop) -> (),
}

export type MapStructure = Instance & {
    Static: Instance,
    Dynamic: Instance,
    PlayerSpawns: Instance,

    Terrain: TerrainRegion?,
    Clouds: Clouds?,

    LightingSettings: Instance?,
    WaterSettings: Instance?,
    TerrainColors: Instance?,

    InteractableDefinitions: Instance?,
    ItemDefinitions: Instance?,
    AmmoDefinitions: Instance?,
    Bosses: Instance?,

    MaterialVariants: Instance?,
}

export type Map = {
    Structure: MapStructure,

    Name: string,
    DisplayName: string?,
    Description: string,
    Authors: string,
    Icon: string,

    Gravity: number,

    InteractableDefinitions: {[string]: InteractableDefinition},
    ItemDefinitions: {[string]: ItemComponents},
    AmmoDefinitions: {[string]: AmmoDefinition},

    Bosses: {[string]: BossDefinition},
}

export type Role = {
    Kind: "Role",
    Definition: RoleDefinition,

    IsAlliedWith: (Role, other: Role) -> boolean,
    GetFormattedName: (Role) -> string,
    GetPluralName: (Role) -> string,
    GetExclamatoryString: (Role) -> string,
    FormatString: (Role, str: string) -> string,
}

export type OnPropBreak = (prop: Prop, params: DamageParams) -> ()
export type OnPropDamage = (prop: Prop, params: DamageParams) -> boolean?

export type Event = {
    Timestamp: number,
    Data: RoundEventData,
}

export type RoundEventData = GenericEventData | DeathEventData | CorpseSearchedEventData | StartRoundEventData | EndRoundEventData | DeathConfirmedEventData

export type GenericEventData = {
    Kind: "GenericRoundEvent",
    Text: string,
}

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

export type AmmoBox = {
    Kind: "AmmoBox",
    Definition: AmmoDefinition,
    Model: MapObject,
    Ammo: number,

    SetAmmo: (AmmoBox, amount: number) -> (),
}

export type SelfDefenseEntry = {
    Against: Participant,
    Until: number,
}

export type BaseCorpseView = {
    Name: string,
    UserId: number,

    AdditionalIcons: {CorpseIcon},

    WasFreeKill: boolean?,
    WasHeadshot: boolean?,
    WasSelfDefense: boolean?,

    KillList: {string},
    EquipmentList: {string},

    DeathTime: number,
}

export type ServerCorpseView = BaseCorpseView & {
    DamageSource: DamageSource,
}

export type ClientCorpseView = BaseCorpseView & {
    DamageSource: GeneralDamageSource | ItemReplication,
}

export type Corpse = {
    Participant: Participant,

    DamageParams: DamageParams,

    CorpseView: ServerCorpseView,
    WasCorrectKill: boolean?, -- Not in CorpseView, as we don't want clients to see this

    Model: Model?,

    _searchedBy: {Participant},
    GetSearchedBy: (Corpse) -> {Participant},

    UpdateKillList: (Corpse) -> (),

    Search: (Corpse, searcher: Participant?, covert: boolean, player: Player?) -> boolean,
    SearchAsAlive: (Corpse, searcher: Participant, covert: boolean) -> boolean,

    _hasBeenCalledTo: boolean?,
    CallRole: (Corpse, caller: Participant) -> (),

    Killer: Participant?,
}

export type ParticipantLastDamagedBy = {
    By: Participant,
    ExpiresAt: number,
}

export type Participant = {
    Kind: "Participant",

    Extras: Extras,

    Player: Player,
    Round: Round,

    SlayVotes: {Participant},
    TryAddSlayVote: (Participant, participant: Participant) -> boolean,

    TryPlayAnimation: (Participant, content: Content, name: string) -> AnimationTrack?,
    TryStopAnimation: (Participant, name: string) -> (),

    _karma: number,
    GetKarma: (Participant) -> number,
    SetKarma: (Participant, karma: number) -> (),

    _isFreeKill: boolean,
    IsFreeKill: (Participant, attacker: Participant?) -> boolean,
    SetFreeKill: (Participant, reason: string?) -> (),

    GetKarmaDamageMultiplier: (Participant) -> number,

    _role: Role?,
    GetRole: (Participant) -> Role,
    SetRole: (Participant, role: RoleDefinition?) -> (),

    IsEvil: (Participant) -> boolean,

    IsAlliedWithParticipant: (Participant, other: Participant) -> boolean,
    IsDamageJustifiedAgainstParticipant: (Participant, other: Participant) -> boolean,

    GetFormattedName: (Participant) -> string,

    Corpse: Corpse?,

    ExtraCorpseIcons: {CorpseIcon},
    AddCorpseIcon: (Participant, icon: CorpseIcon) -> (),
    HasCorpseIcon: (Participant, name: string) -> boolean,

    _isCharacterLoading: boolean,
    _character: Model?,
    GetCharacter: (Participant) -> Model?,

    _humanoid: Humanoid?,
    GetHumanoid: (Participant) -> Humanoid?,

    CorpseSearchDistance: number,

    SpawnCharacter: (Participant, morph: Model?, preserve: boolean?) -> (),
    DespawnCharacter: (Participant, preserve: boolean?) -> (),

    _selfDefenseList: {SelfDefenseEntry},
    AddSelfDefenseEntry: (Participant, params: SelfDefenseParams) -> (),
    HasSelfDefenseAgainstParticipant: (Participant, against: Participant) -> boolean,

    _lastDamaged: ParticipantLastDamagedBy?,
    SetLastDamagedBy: (Participant, by: Participant, duration: number) -> (),
    GetLastDamagedBy: (Participant) -> Participant?,

    KillList: {Participant},
    _addToKillList: (Participant, toAdd: Participant) -> (),

    Scores: ScoreTable,
    AddScore: (Participant, reason: string, amount: number) -> (),

    _credits: number,
    AddCredits: (Participant, amount: number) -> (),
    SetCredits: (Participant, amount: number) -> (),
    GetCredits: (Participant) -> number,

    _items: {[string]: Item?},
    _ammo: {[string]: number?},

    DropAmmoBoxForCurrentItem: (Participant) -> (),

    GetEquippedItem: (Participant) -> Item?,
    SetEquippedItem: (Participant, item: Item?, force: boolean?) -> (),
    _equippedItem: Item?,

    GetItems: (Participant) -> {[string]: Item?},
    DropItem: (Participant, item: Item, throwDirection: Vector3?) -> (),

    AddItem: (Participant, item: Item) -> (),
    RemoveItem: (Participant, item: Item) -> (),
    TryDropItem: (Participant, item: Item, throw: Vector3?) -> boolean,

    GetItemOccupyingGroup: (Participant, group: ItemGroup?) -> Item?,

    GetAmmo: (Participant, kind: string) -> number,
    SetAmmo: (Participant, kind: string, amount: number) -> (),
    GetAllAmmo: (Participant) -> {[string]: number},
    HasWeaponOfAmmoType: (Participant, ammoType: string) -> boolean,

    ItemPurchases: ItemPurchases,
    PurchaseItem: (Participant, itemDefinition: ItemComponents) -> ItemPurchaseResult,

    _status: ParticipantStatus,
    _setStatus: (Participant, status: ParticipantStatus) -> (),
    GetStatus: (Participant) -> ParticipantStatus,

    _wasDeathProcessed: boolean?,
    IsAlive: (Participant) -> boolean,
    TryTakeDamage: (Participant, params: DamageParams, deferDeath: boolean?) -> boolean,
    GetHealth: (Participant) -> number,
    SetHealth: (Participant, health: number) -> (),

    MoveToSpawn: (Participant, spawnCFrame: CFrame?) -> (),

    TryThrowAssembly: (Participant, assembly: MapObject, force: number, parent: Instance?, position: Vector3?, direction: Vector3?, noForward: boolean?, noAngularImpulse: boolean?) -> boolean,

    OnCharacterPartAdded: (Participant, part: Instance) -> (),
}

export type Prop = {
    Kind: "Prop",
    Model: MapObject,
    Extras: Extras,

    Interactable: InteractableDefinition?,
    HintTextClient: string?,

    Round: Round?,

    _health: number?,
    GetHealth: (Prop) -> number?,
    SetHealth: (Prop, health: number) -> (),

    TryTakeDamage: (Prop, params: DamageParams, deferDeath: boolean?) -> boolean,
    OnBreak: OnPropBreak,
}

export type GameConfig = {
    DeathSounds: {string},
    OnDeath: (Round, Participant, boolean) -> ()?,
    OnCharacterAdded: (Round, Participant) -> ()?,
    BeforeDamageProp: ((Round, Prop, DamageParams) -> boolean)?,
    BeforeDamageParticipant: ((Round, Participant, DamageParams) -> boolean)?,
    OnRoleAssigned: (Round, Participant) -> ()?,
    OnItemDropped: (Round, Participant, Item) -> ()?,
}

export type Round = {
    Config: GameConfig,
    Gamemode: GamemodeDefinition,

    LoadBoss: (Round, definition: BossDefinition) -> (),

    LoadGamemode: (Round, gamemode: GamemodeDefinition) -> (),

    MinimumRequiredPlayers: number,

    Extras: Extras,

    GetItemDefinition: (Round, item: string) -> ItemComponents?,
    GetAmmoDefinition: (Round, ammo: string) -> AmmoDefinition?,
    GetInteractableDefinition: (Round, interactable: string) -> InteractableDefinition?,

    _map: Map?,
    LoadMap: (Round, structure: MapStructure) -> (),
    GetMap: (Round) -> Map,

    _items: {[MapObject]: Item?},
    GetItems: (Round) -> {[MapObject]: Item},
    GetItem: (Round, part: MapObject) -> Item?,
    LoadItemFromMapObject: (Round, model: MapObject) -> Item,
    LoadItem: (Round, components: ItemComponents, model: MapObject?) -> Item,

    _ammoBoxes: {[MapObject]: AmmoBox?},
    GetAmmoBoxes: (Round) -> {[MapObject]: AmmoBox},
    GetAmmoBox: (Round, part: MapObject) -> AmmoBox?,

    _props: {[MapObject]: Prop?},
    GetProps: (Round) -> {[MapObject]: Prop},
    GetProp: (Round, model: MapObject) -> Prop?,
    LoadProp: (Round, model: MapObject) -> Prop,

    _participants: {[string]: Participant?},
    GetParticipant: (Round, identifier: string | Player | Model) -> Participant?,
    GetParticipants: (Round) -> {[string]: Participant},
    AddPlayer: (Round, player: Player, karma: number?) -> Participant,
    RemoveParticipant: (Round, participant: Participant, isRejoining: boolean) -> (),

    _eventLog: {Event},
    AddEvent: (Round, data: RoundEventData) -> (),
    GetEventLog: (Round) -> {Event},

    Highlights: {[string]: Highlight},
    AddHighlight: (Round, roundHighlight: Highlight) -> (),

    ElapsedPhaseTime: number,
    PhaseLength: number,
    _heartbeat: RBXScriptConnection?,
    _phase: Phase,
    GetPhase: (Round) -> Phase,
    SetPhase: (Round, phase: Phase, duration: number, callback: false | () -> ()?) -> (),

    IsPreGame: (Round) -> boolean,
    IsPostGame: (Round) -> boolean,
    IsInProgress: (Round) -> boolean,

    _isPaused: boolean,
    Pause: (Round, paused: boolean) -> (),
    IsPaused: (Round) -> boolean,

    _start: (Round) -> (),
    Finish: (Round, victor: Victor, isTimeout: boolean?) -> (),

    VictoryData: {
        Victor: Victor,
        DidTimeout: boolean,
        EndedAt: number,
        Music: Sound?,
    }?,

    _roles: {[string]: Role?},

    GetRoleFromRoleName: (Round, name: string) -> Role,
    GetParticipantsWithRole: (Round, role: Role) -> {Participant},

    SendMessage: (Round, to: {Player} | Player?, message: string, kind: MessageKind?) -> (),
}

return nil