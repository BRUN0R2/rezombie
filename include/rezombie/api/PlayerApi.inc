#if defined _PlayerApi_included
	#endinput
#endif

#define _PlayerApi_included

#include <amxmodx>
#include <reapi>
#include <rezombie>
#include <rezombie_stock>
#include <rezombie/core/PlayerState>

stock RegisterPlayerNatives()
{
	register_native("get_player_class", "NativeGetPlayerClass");
	register_native("get_player_subclass", "NativeGetPlayerSubclass");
	register_native("change_player_class", "NativeChangePlayerClass");

	register_native("infect_player", "NativeInfectPlayer");
	register_native("IsZombie", "NativeIsZombie");
	register_native("IsHuman", "NativeIsHuman");
}

stock RegisterPlayerHooks()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPost", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilledPost", true);
}

public client_putinserver(id)
{
	ConnectPlayerState(id);
}

public client_disconnected(id)
{
	DisconnectPlayerState(id);
}

public OnPlayerSpawnPost(id)
{
	SpawnPlayerState(id);

	new Class:class = GetPlayerClass(id);
	if (class != Invalid_Class)
		ApplyPlayerClassProps(id, class, GetPlayerSubclass(id));
}

public OnPlayerKilledPost(id, attacker, gib)
{
	#pragma unused attacker
	#pragma unused gib

	KillPlayerState(id);
}

public bool:NativeIsZombie(plugin, params)
{
	enum
	{
		IsZombieParamPlayer = 1
	};

	if (params < IsZombieParamPlayer)
		return bool:ReportNativeError("IsZombie requires player index.");

	new id = get_param(IsZombieParamPlayer);

	if (!IsValidConnectedPlayer(id, "IsZombie"))
		return false;

	return IsPlayerZombie(id);
}

public bool:NativeIsHuman(plugin, params)
{
	enum
	{
		IsHumanParamPlayer = 1
	};

	if (params < IsHumanParamPlayer)
		return bool:ReportNativeError("IsHuman requires player index.");

	new id = get_param(IsHumanParamPlayer);

	if (!IsValidConnectedPlayer(id, "IsHuman"))
		return false;

	return IsPlayerHuman(id);
}

public Class:NativeGetPlayerClass(plugin, params)
{
	enum
	{
		GetPlayerClassParamPlayer = 1
	};

	if (params < GetPlayerClassParamPlayer)
		return Class:ReportNativeError("get_player_class requires player index.");

	new id = get_param(GetPlayerClassParamPlayer);

	if (!IsValidConnectedPlayer(id, "get_player_class"))
		return Invalid_Class;

	return GetPlayerClass(id);
}

public Subclass:NativeGetPlayerSubclass(plugin, params)
{
	enum
	{
		GetPlayerSubclassParamPlayer = 1
	};

	if (params < GetPlayerSubclassParamPlayer)
		return Subclass:ReportNativeError("get_player_subclass requires player index.");

	new id = get_param(GetPlayerSubclassParamPlayer);

	if (!IsValidConnectedPlayer(id, "get_player_subclass"))
		return Invalid_Subclass;

	return GetPlayerSubclass(id);
}

public bool:NativeChangePlayerClass(plugin, params)
{
	enum
	{
		ChangePlayerClassParamPlayer = 1,
		ChangePlayerClassParamClass,
		ChangePlayerClassParamSubclass
	};

	if (params < ChangePlayerClassParamClass)
		return bool:ReportNativeError("change_player_class requires player and class.");

	new id = get_param(ChangePlayerClassParamPlayer);
	if (!IsValidConnectedPlayer(id, "change_player_class"))
		return false;

	new Class:class = Class:get_param(ChangePlayerClassParamClass);
	new Subclass:subclass = Invalid_Subclass;

	if (params >= ChangePlayerClassParamSubclass)
		subclass = Subclass:get_param(ChangePlayerClassParamSubclass);

	return ChangePlayerClass(id, class, subclass);
}

public bool:NativeInfectPlayer(plugin, params)
{
	enum
	{
		InfectPlayerParamPlayer = 1,
		InfectPlayerParamAttacker
	};

	if (params < InfectPlayerParamPlayer)
		return bool:ReportNativeError("infect_player requires player index.");

	new id = get_param(InfectPlayerParamPlayer);
	if (!IsValidConnectedPlayer(id, "infect_player"))
		return false;

	if (params >= InfectPlayerParamAttacker)
	{
		new attacker = get_param(InfectPlayerParamAttacker);
		if (attacker && !IsValidConnectedPlayer(attacker, "infect_player"))
			return false;
	}

	new Class:class = FindClassByHandle("zombie");
	if (class == Invalid_Class)
		return bool:ReportNativeError("Required class 'zombie' was not registered.");

	return ChangePlayerClass(id, class, Invalid_Subclass);
}

stock bool:ChangePlayerClass(id, Class:class, Subclass:subclass)
{
	if (!IsValidClassHandle(class))
		return bool:ReportNativeError("Invalid class handle %d.", _:class);

	if (subclass != Invalid_Subclass && !IsValidSubclassForClass(subclass, class))
		return bool:ReportNativeError("Invalid subclass handle %d for class %d.", _:subclass, _:class);

	new Team:team = GetClassTeam(class);
	if (!IsPlayableClassTeam(team))
		return bool:ReportNativeError("Invalid class team %d.", _:team);

	SetPlayerClass(id, class);
	SetPlayerSubclass(id, subclass);
	SetPlayerZombie(id, bool:(team == TEAM_ZOMBIE));

	ApplyPlayerTeam(id, team);

	if (IsPlayerAlive(id))
		ApplyPlayerClassProps(id, class, subclass);

	return true;
}

stock ApplyPlayerClassProps(id, Class:class, Subclass:subclass)
{
	new Props:props = GetClassRuntimeProps(class, subclass);
	if (!IsValidPropsHandle(props))
	{
		ReportNativeError("Invalid runtime props for player %d.", id);
		return;
	}

	new data[PropsData];
	ArrayGetArray(PropsList, GetPropsIndex(props), data);

	set_entvar(id, var_health, float(data[PropsHealth]));
	set_entvar(id, var_maxspeed, float(data[PropsSpeed]));
	set_entvar(id, var_gravity, data[PropsGravity]);
}

stock ApplyPlayerTeam(id, Team:team)
{
	rg_set_user_team(id, GetGameTeam(team), MODEL_AUTO, true, false);
}

stock Props:GetClassRuntimeProps(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
		return GetSubclassProps(subclass);

	return GetClassProps(class);
}

stock TeamName:GetGameTeam(Team:team)
{
	switch (team)
	{
		case TEAM_HUMAN:
			return TEAM_CT;
		case TEAM_ZOMBIE:
			return TEAM_TERRORIST;
	}

	return TEAM_UNASSIGNED;
}

stock bool:IsValidConnectedPlayer(id, const nativeName[])
{
	if (!IsPlayerIndex(id))
	{
		ReportNativeError("%s received invalid player index %d.", nativeName, id);
		return false;
	}

	if (!IsPlayerConnected(id))
	{
		ReportNativeError("%s received disconnected player %d.", nativeName, id);
		return false;
	}

	return true;
}
