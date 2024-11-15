export type ParticipantStatus = "Alive" | "Missing" | "Dead" | "Spectating"

export type GeneralDamageSource = "Fall" | "Drown" | "Explode" | "Burn" | "Stab" | "Shot" | "Bludgeon" | "Crush" | "Magic" | "Other"
export type DamageSource = Item | GeneralDamageSource

export type RoundPhase = "Waiting" | "Preparing" | "Playing" | "Highlights" | "Intermission" 

export type ScoreTable = {[string]: number}
export type EquipmentPurchases = {[string]: number}

export type Victor = Participant | Role
export type VictorType = {Kind: "Role", Role: string} | {Kind: "Solo"}

export type RoundAdvanceCallback = () -> ()

type Nillable<T> = {[keyof<T>]: index<T, "">?}

export type Role = {
    Kind: "Role",

    Name: string,
    Description: string,
    Color: Color3,

    Allegiance: VictorType,
    VictoryText: string?,
    VictoryMusic: {Sound}?,

    StartingItems: {ItemDefinition}?,
    StartingCredits: number?,
    EquipmentShop: {ItemDefinition}?,

    ShouldAnnounceDisconnect: boolean?,
    CanStealCreditsFromCorpses: boolean?,
    CanSeeMissingInAction: boolean?,
    CanTeamChat: boolean?,

    AwardCreditsToRolesOnDeath: {[string]: number},

    WalkSpeed: number,
    JumpPower: number,
    Health: number,

    Allies: {string}?,
    RevealedRoles: {string}?,
    HighlightedRoles: {string}?,
}

export type Gamemode = {
    Name: string,
    Description: string,
    Authors: string,

    MinimumPlayers: number,

    DefaultVictor: (Gamemode, Role) -> Role,
    TimeoutVictor: (Gamemode, Role) -> Role,
    TimeoutMusic: {Sound}?,

    EnableFriendlyFire: boolean?,

    AvailableItems: {[string]: ItemDefinition},
    StartingItems: {ItemDefinition},

    Duration: (numParticipants: number) -> number,

    AssignRoles: (Gamemode, {Participant}) -> (),
    
    Roles: {[string]: Role},

    OnDeath: (Gamemode, Participant) -> (),
    OnCharacterAdded: (Gamemode, Participant) -> (),
}

export type ItemDefinition = {
    Name: string,
    Description: string?,
    Icon: string?,

    CreditCost: number?,
    MaxStock: number?,

    AllowFreeKill: boolean,
}

export type Item = {
    Definition: ItemDefinition,
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

    Model: Model?,

    _searchedBy: {Participant},
    GetSearchedBy: (Corpse) -> {Participant},
    AddSearchedBy: (Corpse, participant: Participant) -> (),

    Killer: Participant?,
}

export type ParticipantView = {
    Name: string,
    FormattedName: string,

    Role: string?,
    Status: ParticipantStatus,
}

export type OwnParticipantView = ParticipantView & {
    Credits: number,
    EquipmentPurchases: EquipmentPurchases,
}

export type Participant = {
    Kind: "Participant",
    
    read Player: Player,
    read Round: Round,

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

    _isCharacterLoading: boolean,
    _character: Model?,
    GetCharacter: (Participant) -> Model?,

    _humanoid: Humanoid?,
    GetHumanoid: (Participant) -> Humanoid?,
    
    SpawnCharacterBlocking: (Participant) -> Model,
    UnspawnCharacter: (Participant) -> (),

    _selfDefenseList: {SelfDefenseEntry},
    AddSelfDefenseEntry: (Participant, params: SelfDefenseParams) -> (),
    HasSelfDefenseAgainstParticipant: (Participant, against: Participant) -> boolean,

    _killList: {Participant},
    _addToKillList: (Participant) -> (),
    GetKillList: (Participant) -> {Participant},

    _scores: Nillable<ScoreTable>,
    GetScores: (Participant) -> ScoreTable,
    AddScore: (Participant, reason: string, amount: number) -> (),

    _credits: number,
    AddCredits: (Participant, amount: number) -> (),
    SetCredits: (Participant, amount: number) -> (),
    GetCredits: (Participant) -> number,

    _equipmentPurchases: Nillable<EquipmentPurchases>,
    GetEquipmentPurchases: (Participant) -> EquipmentPurchases,
    AddEquipmentPurchase: (Participant, item: Item) -> (),

    _items: {[string]: Item?},
    AddItem: (Participant, item: Item) -> (),
    RemoveItem: (Participant, item: Item) -> (),
    GetItems: (Participant) -> {Item},

    _status: ParticipantStatus,
    _setStatus: (Participant, status: ParticipantStatus) -> (),
    GetStatus: (Participant) -> ParticipantStatus,

    IsAlive: (Participant) -> boolean,
    TryTakeDamage: (Participant, params: DamageParams) -> (),
    GetHealth: (Participant) -> number,
    SetHealth: (Participant, health: number) -> (),
}

export type RoundEvent = {
    Timestamp: number,
    Data: RoundEventData,
}

export type RoundEventData = DeathEventData | CorpseSearchedEventData | StartRoundEventData | EndRoundEventData

export type DeathEventData = {
    Kind: "DeathRoundEvent",

    Corpse: CorpseView,
}

export type CorpseSearchedEventData = {
    Kind: "CorpseSearchedRoundEvent",
    
    SearchedBy: ParticipantView,
    Corpse: CorpseView,
}

export type StartRoundEventData = {
    Kind: "StartRoundEvent",
}

export type EndRoundEventData = {
    Kind: "EndRoundEvent",
    VictoryText: string,
}

export type Round = {
    Gamemode: Gamemode,

    _participants: {[string]: Participant?},
    GetParticipant: (Round, name: string) -> Participant?,
    GetParticipants: (Round) -> {Participant},
    AddPlayer: (Round, player: Player) -> Participant,
    RemoveParticipant: (Round, participant: Participant) -> (),

    _eventLog: {RoundEvent},
    AddEvent: (Round, data: RoundEventData) -> (),
    GetEventLog: (Round) -> {RoundEvent},

    _roundPhase: RoundPhase,
    GetRoundPhase: (Round) -> RoundPhase,
    SetRoundPhase: (Round, phase: RoundPhase, duration: number) -> (),

    _lastAdvanceCallback: RoundAdvanceCallback?,
    _activeAdvanceThread: thread?,
    SetAdvanceTime: (Round, finishTime: number, callback: "preserve" | RoundAdvanceCallback) -> (),

    _isPaused: boolean,
    PauseRound: (Round, paused: boolean) -> (),
    GetIsRoundPaused: (Round) -> boolean,

    StartRound: (Round) -> (),
    EndRound: (Round, victor: Victor) -> (),

    GetRoleFromRoleName: (Round, name: string) -> Role,
    GetParticipantsWithRole: (Round, role: Role) -> {Participant},

    GetFormattedRoleName: (role: Role) -> string,

    IsRoleAlliedWithRole: (role1: Role, role2: Role) -> boolean,
}

return nil