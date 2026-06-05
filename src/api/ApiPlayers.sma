#include <rezombie>
#include <reapi>

#pragma semicolon 1
#pragma compress 1

const PLAYER_FORWARD_INVALID = -1;

new const DEFAULT_HUMAN_CLASS[] = "human";
new const DEFAULT_ZOMBIE_CLASS[] = "zombie";
new const DEFAULT_MELEE_WEAPON[] = "weapon_knife";
new const DEFAULT_HUMAN_SECONDARY_WEAPON[] = "weapon_usp";

const WeaponIdType:DEFAULT_HUMAN_SECONDARY_WEAPON_ID = WEAPON_USP;
const DEFAULT_HUMAN_SECONDARY_CLIP_AMMO = 12;
const DEFAULT_HUMAN_SECONDARY_BACKPACK_AMMO = 24;

enum _:PlayerRuntimeData
{
	bool:PlayerRuntimeConnected,
	bool:PlayerRuntimeAlive,
	bool:PlayerRuntimeZombie,
	Class:PlayerRuntimeClass,
	Subclass:PlayerRuntimeSubclass,
	Weapon:PlayerRuntimeMelee
};

enum _:PlayerForwardData
{
	PlayerForwardChangeClassPre,
	PlayerForwardChangeClassPost,
	PlayerForwardInfectPlayerPre,
	PlayerForwardInfectPlayerPost,
	PlayerForwardCount
};

new PlayerRuntime[MAX_PLAYERS + 1][PlayerRuntimeData];
new PlayerForwards[PlayerForwardCount];

public plugin_natives()
{
	register_library("ApiPlayers");

	register_native("get_player_class", "NativeGetPlayerClass");
	register_native("get_player_subclass", "NativeGetPlayerSubclass");
	register_native("get_player_var", "NativeGetPlayerVar");
	register_native("set_player_var", "NativeSetPlayerVar");
	register_native("change_player_class", "NativeChangePlayerClass");

	register_native("infect_player", "NativeInfectPlayer");
	register_native("IsZombie", "NativeIsZombie");
	register_native("IsHuman", "NativeIsHuman");
}

public plugin_init()
{
	register_plugin("API: Players", "0.1.0", "BRUN0");

	for (new index = 0; index < sizeof PlayerForwards; index++)
		PlayerForwards[index] = PLAYER_FORWARD_INVALID;

	PlayerForwards[PlayerForwardChangeClassPre] = CreateMultiForward("@change_class_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	PlayerForwards[PlayerForwardChangeClassPost] = CreateMultiForward("@change_class_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	PlayerForwards[PlayerForwardInfectPlayerPre] = CreateMultiForward("@infect_player_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	PlayerForwards[PlayerForwardInfectPlayerPost] = CreateMultiForward("@infect_player_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);

	RegisterHookChain(RG_CBasePlayer_GiveDefaultItems, "OnGiveDefaultItemsPre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPost", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilledPost", true);
	RegisterHookChain(RG_CBasePlayerWeapon_DefaultDeploy, "OnWeaponDefaultDeployPre", false);
}

public plugin_end()
{
	for (new index = 0; index < sizeof PlayerForwards; index++)
	{
		if (PlayerForwards[index] == PLAYER_FORWARD_INVALID)
			continue;

		DestroyForward(PlayerForwards[index]);
		PlayerForwards[index] = PLAYER_FORWARD_INVALID;
	}
}

stock ResetPlayerRuntime(id)
{
	PlayerRuntime[id][PlayerRuntimeConnected] = false;
	PlayerRuntime[id][PlayerRuntimeAlive] = false;
	PlayerRuntime[id][PlayerRuntimeZombie] = false;
	PlayerRuntime[id][PlayerRuntimeClass] = Invalid_Class;
	PlayerRuntime[id][PlayerRuntimeSubclass] = Invalid_Subclass;
	PlayerRuntime[id][PlayerRuntimeMelee] = Invalid_Weapon;
}

public client_putinserver(id)
{
	ResetPlayerRuntime(id);
	PlayerRuntime[id][PlayerRuntimeConnected] = true;
}

public client_disconnected(id)
{
	ResetPlayerRuntime(id);
}

public OnPlayerSpawnPost(id)
{
	if (!is_user_alive(id))
	{
		PlayerRuntime[id][PlayerRuntimeAlive] = false;
		return;
	}

	if (!IsPlayerOnGameTeam(id))
	{
		PlayerRuntime[id][PlayerRuntimeAlive] = false;
		return;
	}

	PlayerRuntime[id][PlayerRuntimeConnected] = true;
	PlayerRuntime[id][PlayerRuntimeAlive] = true;

	ApplySpawnClass(id);
}

public OnGiveDefaultItemsPre(id)
{
	#pragma unused id

	return HC_SUPERCEDE;
}

public OnPlayerKilledPost(id, attacker, gib)
{
	#pragma unused attacker
	#pragma unused gib

	PlayerRuntime[id][PlayerRuntimeAlive] = false;
}

public OnWeaponDefaultDeployPre(const entity, viewModel[], weaponModel[], anim, animExt[], skiplocal)
{
	if (is_nullent(entity))
		return HC_CONTINUE;

	if (WeaponIdType:get_member(entity, m_iId) != WEAPON_KNIFE)
		return HC_CONTINUE;

	new id = get_member(entity, m_pPlayer);
	if (!IsValidAlivePlayer(id))
		return HC_CONTINUE;

	ApplyPlayerMeleeDeployModels(id);
	return HC_CONTINUE;
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

	return PlayerRuntime[id][PlayerRuntimeZombie];
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

	return !PlayerRuntime[id][PlayerRuntimeZombie];
}

public any:NativeGetPlayerVar(plugin, params)
{
	enum
	{
		GetPlayerVarParamPlayer = 1,
		GetPlayerVarParamKey
	};

	if (params < GetPlayerVarParamKey)
		return ReportNativeError("get_player_var requires player and property name.");

	new id = get_param(GetPlayerVarParamPlayer);
	if (!IsValidConnectedPlayer(id, "get_player_var"))
		return null;

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetPlayerVarParamKey, key, charsmax(key));

	if (equal(key, "connected"))
		return PlayerRuntime[id][PlayerRuntimeConnected];

	if (equal(key, "alive"))
		return PlayerRuntime[id][PlayerRuntimeAlive];

	if (equal(key, "zombie"))
		return PlayerRuntime[id][PlayerRuntimeZombie];

	if (equal(key, "class"))
		return PlayerRuntime[id][PlayerRuntimeClass];

	if (equal(key, "subclass"))
		return PlayerRuntime[id][PlayerRuntimeSubclass];

	return ReportNativeError("Invalid player property '%s'.", key);
}

public bool:NativeSetPlayerVar(plugin, params)
{
	enum
	{
		SetPlayerVarParamPlayer = 1,
		SetPlayerVarParamKey,
		SetPlayerVarParamValue
	};

	if (params < SetPlayerVarParamValue)
		return bool:ReportNativeError("set_player_var requires player, property name and value.");

	new id = get_param(SetPlayerVarParamPlayer);
	if (!IsValidConnectedPlayer(id, "set_player_var"))
		return false;

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetPlayerVarParamKey, key, charsmax(key));

	if (equal(key, "class"))
	{
		new Class:class = Class:get_param_byref(SetPlayerVarParamValue);

		return ChangePlayerClass(id, class, Invalid_Subclass);
	}

	if (equal(key, "subclass"))
	{
		new Subclass:subclass = Subclass:get_param_byref(SetPlayerVarParamValue);

		if (subclass == Invalid_Subclass)
			return ClearPlayerSubclass(id);

		new Class:class = Class:get_subclass_var(subclass, "class");

		return ChangePlayerClass(id, class, subclass);
	}

	if (equal(key, "connected") || equal(key, "alive") || equal(key, "zombie"))
		return bool:ReportNativeError("Player property '%s' is readonly.", key);

	return bool:ReportNativeError("Invalid player property '%s'.", key);
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

	return PlayerRuntime[id][PlayerRuntimeClass];
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

	return PlayerRuntime[id][PlayerRuntimeSubclass];
}

public bool:NativeChangePlayerClass(plugin, params)
{
	enum
	{
		ChangePlayerClassParamPlayer = 1,
		ChangePlayerClassParamClass,
		ChangePlayerClassParamSubclass,
		ChangePlayerClassParamApplyRuntime
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

	new bool:applyRuntime = true;
	if (params >= ChangePlayerClassParamApplyRuntime)
		applyRuntime = bool:get_param(ChangePlayerClassParamApplyRuntime);

	return ChangePlayerClass(id, class, subclass, applyRuntime);
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

stock ApplySpawnClass(id)
{
	new Team:team = GetRespawnTeam();
	new Class:class = GetDefaultClassForTeam(team);

	if (!ChangePlayerClass(id, class, Invalid_Subclass))
		set_fail_state("ApiPlayers could not apply spawn class %d to player %d.", _:class, id);
}

stock Team:GetRespawnTeam()
{
	new Team:team = get_game_var("respawn_team");
	if (!IsPlayablePlayerTeam(team))
		set_fail_state("ApiPlayers received invalid respawn team %d.", _:team);

	return team;
}

stock Class:GetDefaultClassForTeam(Team:team)
{
	switch (team)
	{
		case TEAM_HUMAN:
			return RequireDefaultClass(DEFAULT_HUMAN_CLASS);
		case TEAM_ZOMBIE:
			return RequireDefaultClass(DEFAULT_ZOMBIE_CLASS);
	}

	set_fail_state("ApiPlayers received invalid default class team %d.", _:team);
	return Invalid_Class;
}

stock Class:RequireDefaultClass(const handle[])
{
	new Class:class = FindClass(handle);
	if (class == Invalid_Class)
		set_fail_state("Required class '%s' was not registered.", handle);

	return class;
}

stock bool:ChangePlayerClass(id, Class:class, Subclass:subclass, bool:applyRuntime = true)
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

	PlayerRuntime[id][PlayerRuntimeClass] = class;
	PlayerRuntime[id][PlayerRuntimeSubclass] = subclass;
	PlayerRuntime[id][PlayerRuntimeZombie] = bool:(team == TEAM_ZOMBIE);
	SetPlayerRuntimeMelee(id, class, subclass);

	ApplyPlayerTeam(id, team);

	if (applyRuntime && is_user_alive(id) && !ApplyPlayerClassRuntime(id, class, subclass))
		return false;

	ExecuteChangeClassPostForward(id, class, subclass);
	return true;
}

stock bool:ClearPlayerSubclass(id)
{
	new Class:class = PlayerRuntime[id][PlayerRuntimeClass];

	if (class == Invalid_Class)
		return bool:ReportNativeError("Player %d has no class to clear subclass.", id);

	return ChangePlayerClass(id, class, Invalid_Subclass);
}

stock bool:ExecuteChangeClassPreForward(id, Class:class, Subclass:subclass)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardChangeClassPre], forwardResult, id, class, subclass))
		return bool:ReportNativeError("Could not execute @change_class_pre.");

	return RzReturn:forwardResult < RZ_SUPERCEDE;
}

stock ExecuteChangeClassPostForward(id, Class:class, Subclass:subclass)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardChangeClassPost], forwardResult, id, class, subclass))
		ReportNativeError("Could not execute @change_class_post.");
}

stock bool:ExecuteInfectPlayerPreForward(id, attacker, Subclass:subclass)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardInfectPlayerPre], forwardResult, id, attacker, subclass))
		return bool:ReportNativeError("Could not execute @infect_player_pre.");

	return RzReturn:forwardResult < RZ_SUPERCEDE;
}

stock ExecuteInfectPlayerPostForward(id, attacker, Subclass:subclass)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardInfectPlayerPost], forwardResult, id, attacker, subclass))
		ReportNativeError("Could not execute @infect_player_post.");
}

stock bool:ApplyPlayerClassRuntime(id, Class:class, Subclass:subclass)
{
	if (!ApplyPlayerProps(id, class, subclass))
		return false;

	if (!ApplyPlayerModel(id, class, subclass))
		return false;

	return ApplyPlayerDefaultItems(id, GetClassTeamValue(class));
}

stock bool:ApplyPlayerProps(id, Class:class, Subclass:subclass)
{
	new Props:props = GetClassRuntimeProps(class, subclass);
	if (props == Invalid_Props)
	{
		ReportNativeError("Invalid runtime props for player %d.", id);
		return false;
	}

	new health = get_props_var(props, "health");
	new speed = get_props_var(props, "speed");
	new Float:gravity = get_props_var(props, "gravity");

	if (health <= 0 || speed <= 0 || gravity <= 0.0)
	{
		ReportNativeError("Invalid runtime props values for player %d.", id);
		return false;
	}

	set_entvar(id, var_health, float(health));
	set_entvar(id, var_maxspeed, float(speed));
	set_entvar(id, var_gravity, gravity);

	return true;
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

stock bool:ApplyPlayerModel(id, Class:class, Subclass:subclass)
{
	new Model:model = GetClassRuntimeModel(class, subclass);

	if (model == Invalid_Model)
	{
		if (GetClassTeamValue(class) == TEAM_HUMAN)
		{
			rg_reset_user_model(id, true);
			return true;
		}

		ReportNativeError("Missing runtime model for player %d, class %d, subclass %d.", id, _:class, _:subclass);
		return false;
	}

	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	if (!get_model_var(model, "path", path, charsmax(path)))
	{
		ReportNativeError("Invalid runtime model for player %d.", id);
		return false;
	}

	new name[RZ_MAX_HANDLE_LENGTH];
	if (!GetModelNameFromPath(path, name, charsmax(name)))
	{
		ReportNativeError("Invalid runtime model path for player %d: %s.", id, path);
		return false;
	}

	rg_set_user_model(id, name, true);
	set_entvar(id, var_body, get_model_var(model, "body"));
	set_entvar(id, var_skin, get_model_var(model, "skin"));

	return true;
}

stock bool:ApplyPlayerDefaultItems(id, Team:team)
{
	if (!rg_remove_all_items(id))
	{
		ReportNativeError("Could not remove player %d items.", id);
		return false;
	}

	switch (team)
	{
		case TEAM_HUMAN:
		{
			return GiveDefaultHumanItems(id);
		}
		case TEAM_ZOMBIE:
		{
			return GiveDefaultZombieItems(id);
		}
		default:
		{
			ReportNativeError("Invalid default item team %d for player %d.", _:team, id);
			return false;
		}
	}

	return false;
}

stock bool:ApplyPlayerMeleeDeployModels(id)
{
	new Weapon:melee = PlayerRuntime[id][PlayerRuntimeMelee];
	if (melee == Invalid_Weapon)
		return true;

	new Model:viewModel = Model:get_weapon_var(melee, "view_model");
	new Model:playerModel = Model:get_weapon_var(melee, "player_model");

	if (viewModel == Invalid_Model && playerModel == Invalid_Model)
		return true;

	if (viewModel != Invalid_Model && !SetWeaponDeployModelArg(id, 2, viewModel, "view_model"))
		return false;

	if (playerModel != Invalid_Model)
	{
		if (!SetWeaponDeployModelArg(id, 3, playerModel, "player_model"))
			return false;
	}
	else
	{
		SetHookChainArg(3, ATYPE_STRING, "");
	}

	return true;
}

stock bool:ApplyPlayerActiveMeleeModels(id)
{
	new Weapon:melee = PlayerRuntime[id][PlayerRuntimeMelee];
	if (melee == Invalid_Weapon)
		return true;

	new Model:viewModel = Model:get_weapon_var(melee, "view_model");
	new Model:playerModel = Model:get_weapon_var(melee, "player_model");

	if (viewModel == Invalid_Model && playerModel == Invalid_Model)
		return true;

	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	if (viewModel != Invalid_Model)
	{
		if (!GetMeleeModelPath(id, viewModel, "view_model", path, charsmax(path)))
			return false;

		set_entvar(id, var_viewmodel, path);
	}

	if (playerModel != Invalid_Model)
	{
		if (!GetMeleeModelPath(id, playerModel, "player_model", path, charsmax(path)))
			return false;

		set_entvar(id, var_weaponmodel, path);
	}
	else
	{
		set_entvar(id, var_weaponmodel, "");
	}

	return true;
}

stock bool:SetWeaponDeployModelArg(id, arg, Model:model, const var[])
{
	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	if (!GetMeleeModelPath(id, model, var, path, charsmax(path)))
		return false;

	SetHookChainArg(arg, ATYPE_STRING, path);
	return true;
}

stock bool:GetMeleeModelPath(id, Model:model, const var[], path[], length)
{
	if (!get_model_var(model, "path", path, length))
	{
		ReportNativeError("Invalid melee %s for player %d.", var, id);
		return false;
	}

	return true;
}

stock SetPlayerRuntimeMelee(id, Class:class, Subclass:subclass)
{
	new Weapon:melee = Weapon:get_class_var(class, "melee");

	if (subclass != Invalid_Subclass)
		melee = Weapon:get_subclass_var(subclass, "melee");

	PlayerRuntime[id][PlayerRuntimeMelee] = melee;
}

stock bool:GiveDefaultHumanItems(id)
{
	if (!GivePlayerItem(id, DEFAULT_MELEE_WEAPON))
		return false;

	if (!GivePlayerItem(id, DEFAULT_HUMAN_SECONDARY_WEAPON))
		return false;

	rg_set_user_ammo(id, DEFAULT_HUMAN_SECONDARY_WEAPON_ID, DEFAULT_HUMAN_SECONDARY_CLIP_AMMO);
	rg_set_user_bpammo(id, DEFAULT_HUMAN_SECONDARY_WEAPON_ID, DEFAULT_HUMAN_SECONDARY_BACKPACK_AMMO);

	return true;
}

stock bool:GiveDefaultZombieItems(id)
{
	if (!GivePlayerItem(id, DEFAULT_MELEE_WEAPON))
		return false;

	if (!SwitchPlayerDefaultMeleeWeapon(id))
		return false;

	return ApplyPlayerActiveMeleeModels(id);
}

stock bool:SwitchPlayerDefaultMeleeWeapon(id)
{
	new weapon = get_member(id, m_rgpPlayerItems, KNIFE_SLOT);
	if (is_nullent(weapon))
	{
		ReportNativeError("Missing default melee item for player %d.", id);
		return false;
	}

	if (get_member(id, m_pActiveItem) == weapon)
		return true;

	if (!rg_switch_weapon(id, weapon))
	{
		ReportNativeError("Could not switch player %d to default melee.", id);
		return false;
	}

	return true;
}

stock bool:GivePlayerItem(id, const item[])
{
	if (rg_give_item(id, item, GT_REPLACE) == NULLENT)
	{
		ReportNativeError("Could not give item '%s' to player %d.", item, id);
		return false;
	}

	return true;
}

stock Model:GetClassRuntimeModel(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
	{
		new Model:model = Model:get_subclass_var(subclass, "model");

		if (model != Invalid_Model)
			return model;
	}

	new ModelsPack:models = ModelsPack:get_class_var(class, "models");
	if (models == Invalid_ModelsPack)
		return Invalid_Model;

	return models_pack_get_random_model(models);
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

stock bool:IsPlayerOnGameTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);

	return team == TEAM_TERRORIST || team == TEAM_CT;
}

stock bool:IsValidConnectedPlayer(id, const nativeName[])
{
	if (!IsPlayerIndex(id))
	{
		ReportNativeError("%s received invalid player index %d.", nativeName, id);
		return false;
	}

	if (!PlayerRuntime[id][PlayerRuntimeConnected])
	{
		ReportNativeError("%s received disconnected player %d.", nativeName, id);
		return false;
	}

	return true;
}

stock bool:IsValidAlivePlayer(id)
{
	if (!IsPlayerIndex(id))
		return false;

	if (!PlayerRuntime[id][PlayerRuntimeConnected])
		return false;

	return bool:is_user_alive(id);
}
