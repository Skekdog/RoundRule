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

export type Participant = {
    
}

export type Round = {
    RoundNumber: number,

    Gamemode: Gamemode,

    Participants: {Participant},

    FinishTime: number,
    IsPaused: boolean,
}