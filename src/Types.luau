export type ParticipantStatus = "Alive" | "Missing" | "Dead" | "Spectating"
export type DamageSource = Item | "Fall" | "Drown" | "Explode" | "Burn" | "Stab" | "Shot" | "Bludgeon" | "Crush" | "Magic" | "Other"

export type ScoreTable = {[string]: number}
export type EquipmentPurchases = {[string]: number}

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
    
    Roles: {Role},
}

export type Item = {
    Name: string,
    Description: string?,

    CreditCost: number?,

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

export type Corpse = {
    Model: Model?,

    _searchedBy: {Participant},
    GetSearchedBy: {Participant},
    AddSearchedBy: (Participant) -> (),

    WasFreeKill: boolean,
    WasHeadshot: boolean,
    WasSelfDefense: boolean,

    DeathTime: number,
    DNAExpiry: number?,

    Killer: Participant?,
    DamageSource: DamageSource,
}

export type Participant = {
    Player: Player,
    Role: Role?,

    Corpse: Corpse?,
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
    SetCredits: (Participant, amount: number) -> (),
    GetCredits: (Participant) -> number,

    _equipmentPurchases: Nillable<EquipmentPurchases>,
    GetEquipmentPurchases: (Participant) -> EquipmentPurchases,
    AddEquipmentPurchase: (Participant, item: Item) -> (),

    _items: {Item},
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
}

export type Round = {
    RoundNumber: number,

    Gamemode: Gamemode,

    Participants: {Participant},

    FinishTime: number,
    IsPaused: boolean,
}