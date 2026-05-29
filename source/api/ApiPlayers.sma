#include <amxmodx>
#include <reapi>
#include <rezombie>
#include <rezombie_stock>
#include <rezombie/core/PlayerState>

#pragma semicolon 1
#pragma compress 1

public plugin_natives()
{
	register_library("rezombie");

	register_native("get_player_class", "NativeGetPlayerClass");
	register_native("get_player_subclass", "NativeGetPlayerSubclass");
	register_native("change_player_class", "NativeChangePlayerClass");

	register_native("infect_player", "NativeInfectPlayer");
	register_native("IsZombie", "NativeIsZombie");
	register_native("IsHuman", "NativeIsHuman");
}

public plugin_precache()
{
	register_plugin("API: Players", "0.1.0", "BRUN0");
}

public plugin_init()
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

	new Class:class = FindClass("zombie");
	if (class == Invalid_Class)
		return bool:ReportNativeError("Required class 'zombie' was not registered.");

	return ChangePlayerClass(id, class, Invalid_Subclass);
}

stock bool:ChangePlayerClass(id, Class:class, Subclass:subclass)
{
	if (!IsRegisteredClass(class))
		return bool:ReportNativeError("Invalid class handle %d.", _:class);

	if (subclass != Invalid_Subclass && !IsRegisteredSubclassForClass(subclass, class))
		return bool:ReportNativeError("Invalid subclass handle %d for class %d.", _:subclass, _:class);

	new Team:team = GetClassTeamValue(class);
	if (!IsPlayablePlayerTeam(team))
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
	if (props == Invalid_Props)
	{
		ReportNativeError("Invalid runtime props for player %d.", id);
		return;
	}

	new health = get_props_var(props, "health");
	new speed = get_props_var(props, "speed");
	new Float:gravity = get_props_var(props, "gravity");

	if (health <= 0 || speed <= 0 || gravity <= 0.0)
	{
		ReportNativeError("Invalid runtime props values for player %d.", id);
		return;
	}

	set_entvar(id, var_health, float(health));
	set_entvar(id, var_maxspeed, float(speed));
	set_entvar(id, var_gravity, gravity);
}

stock ApplyPlayerTeam(id, Team:team)
{
	rg_set_user_team(id, GetGameTeam(team), MODEL_AUTO, true, false);
}

stock Props:GetClassRuntimeProps(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
		return Props:get_subclass_var(subclass, "props");

	return Props:get_class_var(class, "props");
}

stock Team:GetClassTeamValue(Class:class)
{
	return Team:get_class_var(class, "team");
}

stock bool:IsRegisteredClass(Class:class)
{
	if (class == Invalid_Class)
		return false;

	return IsPlayablePlayerTeam(GetClassTeamValue(class));
}

stock bool:IsRegisteredSubclassForClass(Subclass:subclass, Class:class)
{
	new Class:parentClass = Class:get_subclass_var(subclass, "class");

	return parentClass == class;
}

stock bool:IsPlayablePlayerTeam(Team:team)
{
	return team == TEAM_HUMAN || team == TEAM_ZOMBIE;
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
