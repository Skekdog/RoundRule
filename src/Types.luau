export type ParticipantStatus = "Alive" | "Missing" | "Dead" | "Spectating"
export type DamageSource = Item | "Fall" | "Drown" | "Explode" | "Burn" | "Stab" | "Shot" | "Bludgeon" | "Crush" | "Magic" | "Other"

export type ScoreTable = {[string]: number}
export type EquipmentPurchases = {[string]: number}

export type Victor = Participant | Role

type Nillable<T> = {[keyof<T>]: index<T, "">?}

export type Role = {
    Name: string,
    Description: string,
    Color: Color3,
}

export type Gamemode = {
    Name: string,
    Description: string,

    Duration: (numParticipants: number) -> number,
    
    Roles: {[string]: Role},
}

export type Item = {
    Name: string,
    Description: string?,

    CreditCost: number?,
    MaxStock: number?,

    AllowFreeKill: boolean,
}

export type DamageParams = {
    Amount: number,
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

export type CorpseView = {
    WasFreeKill: boolean,
    WasHeadshot: boolean,
    WasSelfDefense: boolean,

    DeathTime: number,
    DNAExpiry: number?,

    DamageSource: DamageSource & string,
}

export type Corpse = CorpseView & {
    Model: Model?,

    _searchedBy: {Participant},
    GetSearchedBy: {Participant},
    AddSearchedBy: (Participant) -> (),

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
    Player: Player,
    Role: Role?,

    GetFormattedName: (Participant) -> string,

    Corpse: Corpse?,

    _humanoid: Humanoid?,
    Character: Model?,
    SpawnCharacter: () -> Model,
    UnspawnCharacter: () -> (),

    _selfDefenseList: {Participant},
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
    ClearItems: (Participant) -> (),
    GetItems: (Participant) -> {Item},

    _status: ParticipantStatus,
    _setStatus: (Participant, status: ParticipantStatus) -> (),
    GetStatus: (Participant) -> ParticipantStatus,

    IsAlive: (Participant) -> boolean,
    TakeDamage: (Participant, params: DamageParams) -> (),
    GetHealth: (Participant) -> number,
    SetHealth: (Participant, health: number) -> (),
}

export type Round = {
    RoundNumber: number,

    Gamemode: Gamemode,

    _participants: {[string]: Participant?},
    GetParticipant: (Round, name: string) -> Participant?,
    GetParticipants: (Round) -> {Participant},
    AddParticipant: (Round, participant: Participant) -> (),
    RemoveParticipant: (Round, participant: Participant) -> (),

    StartRound: (Round) -> (),
    PauseRound: (Round, paused: boolean) -> (),
    EndRound: (Round, victor: Victor) -> (),

    FinishTime: number,
    IsPaused: boolean,

    GetRoleFromRoleName: (Round, name: string) -> Role,
    GetParticipantsWithRole: (Round, role: Role) -> {Participant},
}