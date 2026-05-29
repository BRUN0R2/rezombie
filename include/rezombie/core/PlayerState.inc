#if defined _PlayerState_included
	#endinput
#endif

#define _PlayerState_included

enum _:PlayerStateData
{
	bool:PlayerStateConnected,
	bool:PlayerStateAlive,
	bool:PlayerStateZombie,
	Class:PlayerStateClass,
	Subclass:PlayerStateSubclass
};

new PlayerState[MAX_PLAYERS + 1][PlayerStateData];

stock ResetPlayerState(id)
{
	PlayerState[id][PlayerStateConnected] = false;
	PlayerState[id][PlayerStateAlive] = false;
	PlayerState[id][PlayerStateZombie] = false;
	PlayerState[id][PlayerStateClass] = Invalid_Class;
	PlayerState[id][PlayerStateSubclass] = Invalid_Subclass;
}

stock ConnectPlayerState(id)
{
	ResetPlayerState(id);
	PlayerState[id][PlayerStateConnected] = true;
}

stock DisconnectPlayerState(id)
{
	ResetPlayerState(id);
}

stock SpawnPlayerState(id)
{
	PlayerState[id][PlayerStateConnected] = true;
	PlayerState[id][PlayerStateAlive] = true;
}

stock KillPlayerState(id)
{
	PlayerState[id][PlayerStateAlive] = false;
}

stock bool:IsPlayerConnected(id)
{
	return PlayerState[id][PlayerStateConnected];
}

stock bool:IsPlayerAlive(id)
{
	return PlayerState[id][PlayerStateAlive];
}

stock bool:IsPlayerZombie(id)
{
	return PlayerState[id][PlayerStateZombie];
}

stock bool:IsPlayerHuman(id)
{
	return !PlayerState[id][PlayerStateZombie];
}

stock Class:GetPlayerClass(id)
{
	return PlayerState[id][PlayerStateClass];
}

stock Subclass:GetPlayerSubclass(id)
{
	return PlayerState[id][PlayerStateSubclass];
}

stock SetPlayerClass(id, Class:class)
{
	PlayerState[id][PlayerStateClass] = class;
}

stock SetPlayerSubclass(id, Subclass:subclass)
{
	PlayerState[id][PlayerStateSubclass] = subclass;
}

stock SetPlayerZombie(id, bool:zombie)
{
	PlayerState[id][PlayerStateZombie] = zombie;
}
