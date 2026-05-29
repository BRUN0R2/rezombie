#include <amxmodx>
#include <reapi>
#include <rezombie>
#include <rezombie_stock>
#include <rezombie/core/PlayerState>

#pragma semicolon 1
#pragma compress 1

const PLAYER_FORWARD_INVALID = -1;

new const DEFAULT_HUMAN_CLASS[] = "human";
new const DEFAULT_ZOMBIE_CLASS[] = "zombie";

new ChangeClassPreForward = PLAYER_FORWARD_INVALID;
new ChangeClassPostForward = PLAYER_FORWARD_INVALID;
new InfectPlayerPreForward = PLAYER_FORWARD_INVALID;
new InfectPlayerPostForward = PLAYER_FORWARD_INVALID;

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
	CreatePlayerForwards();
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPost", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilledPost", true);
}

public plugin_end()
{
	DestroyPlayerForwards();
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
	if (class == Invalid_Class)
	{
		ApplyDefaultHumanClass(id);
		return;
	}

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
		InfectPlayerParamAttacker,
		InfectPlayerParamSubclass
	};

	if (params < InfectPlayerParamPlayer)
		return bool:ReportNativeError("infect_player requires player index.");

	new id = get_param(InfectPlayerParamPlayer);
	if (!IsValidConnectedPlayer(id, "infect_player"))
		return false;

	new attacker = 0;
	if (params >= InfectPlayerParamAttacker)
	{
		attacker = get_param(InfectPlayerParamAttacker);
		if (attacker && !IsValidConnectedPlayer(attacker, "infect_player"))
			return false;
	}

	new Class:class = FindClass(DEFAULT_ZOMBIE_CLASS);
	if (class == Invalid_Class)
		return bool:ReportNativeError("Required class 'zombie' was not registered.");

	new Subclass:subclass = Invalid_Subclass;
	if (params >= InfectPlayerParamSubclass)
		subclass = Subclass:get_param(InfectPlayerParamSubclass);

	if (!ExecuteInfectPlayerPreForward(id, attacker, subclass))
		return false;

	if (!ChangePlayerClass(id, class, subclass))
		return false;

	ExecuteInfectPlayerPostForward(id, attacker, subclass);
	return true;
}

stock ApplyDefaultHumanClass(id)
{
	new Class:class = FindClass(DEFAULT_HUMAN_CLASS);
	if (class == Invalid_Class)
		set_fail_state("Required class 'human' was not registered.");

	if (!ChangePlayerClass(id, class, Invalid_Subclass))
		set_fail_state("ApiPlayers could not apply default human class to player %d.", id);
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

	if (!ExecuteChangeClassPreForward(id, class, subclass))
		return false;

	SetPlayerClass(id, class);
	SetPlayerSubclass(id, subclass);
	SetPlayerZombie(id, bool:(team == TEAM_ZOMBIE));

	ApplyPlayerTeam(id, team);

	if (IsPlayerAlive(id))
		ApplyPlayerClassProps(id, class, subclass);

	ExecuteChangeClassPostForward(id, class, subclass);
	return true;
}

stock CreatePlayerForwards()
{
	ChangeClassPreForward = CreateMultiForward("@change_class_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	ChangeClassPostForward = CreateMultiForward("@change_class_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	InfectPlayerPreForward = CreateMultiForward("@infect_player_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	InfectPlayerPostForward = CreateMultiForward("@infect_player_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

stock DestroyPlayerForwards()
{
	DestroyPlayerForward(ChangeClassPreForward);
	DestroyPlayerForward(ChangeClassPostForward);
	DestroyPlayerForward(InfectPlayerPreForward);
	DestroyPlayerForward(InfectPlayerPostForward);
}

stock DestroyPlayerForward(&forwardId)
{
	if (forwardId == PLAYER_FORWARD_INVALID)
		return;

	DestroyForward(forwardId);
	forwardId = PLAYER_FORWARD_INVALID;
}

stock bool:ExecuteChangeClassPreForward(id, Class:class, Subclass:subclass)
{
	new result;
	if (!ExecuteForward(ChangeClassPreForward, result, id, class, subclass))
		return bool:ReportNativeError("Could not execute @change_class_pre.");

	return result < PLUGIN_HANDLED;
}

stock ExecuteChangeClassPostForward(id, Class:class, Subclass:subclass)
{
	new result;
	if (!ExecuteForward(ChangeClassPostForward, result, id, class, subclass))
		ReportNativeError("Could not execute @change_class_post.");
}

stock bool:ExecuteInfectPlayerPreForward(id, attacker, Subclass:subclass)
{
	new result;
	if (!ExecuteForward(InfectPlayerPreForward, result, id, attacker, subclass))
		return bool:ReportNativeError("Could not execute @infect_player_pre.");

	return result < PLUGIN_HANDLED;
}

stock ExecuteInfectPlayerPostForward(id, attacker, Subclass:subclass)
{
	new result;
	if (!ExecuteForward(InfectPlayerPostForward, result, id, attacker, subclass))
		ReportNativeError("Could not execute @infect_player_post.");
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

	ApplyPlayerModel(id, class, subclass);
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

stock ApplyPlayerModel(id, Class:class, Subclass:subclass)
{
	new Model:model = GetClassRuntimeModel(class, subclass);

	if (model == Invalid_Model)
	{
		if (GetClassTeamValue(class) == TEAM_HUMAN)
		{
			rg_reset_user_model(id, true);
			return;
		}

		ReportNativeError("Missing runtime model for player %d, class %d, subclass %d.", id, _:class, _:subclass);
		return;
	}

	new name[RZ_MAX_HANDLE_LENGTH];
	if (!get_model_var(model, "name", name, charsmax(name)))
	{
		ReportNativeError("Invalid runtime model for player %d.", id);
		return;
	}

	rg_set_user_model(id, name, true);
}

stock Model:GetClassRuntimeModel(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
	{
		new Model:model = Model:get_subclass_var(subclass, "model");

		if (model != Invalid_Model)
			return model;
	}

	return Model:get_class_var(class, "model");
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
