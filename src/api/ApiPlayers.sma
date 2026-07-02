#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <rezombie_version>
#include <rezombie_const>
#include <rezombie/api/Classes>
#include <rezombie/api/Subclasses>
#include <rezombie/api/Props>
#include <rezombie/api/Models>
#include <rezombie/api/Weapons>
#include <rezombie/api/GameVars>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

new const PLAYER_DEFAULT_HUMAN_CLASS[] = "human";
new const PLAYER_DEFAULT_ZOMBIE_CLASS[] = "zombie";
new const PLAYER_KNIFE_ITEM[] = "weapon_knife";
new const PLAYER_HUMAN_PISTOL_ITEM[] = "weapon_usp";

new const PLAYER_PROP_HEALTH[] = "health";
new const PLAYER_PROP_ARMOR[] = "armor";
new const PLAYER_PROP_SPEED[] = "speed";
new const PLAYER_PROP_GRAVITY[] = "gravity";
new const PLAYER_MODEL_PATH[] = "path";
new const PLAYER_WEAPON_VIEW_MODEL[] = "view_model";
new const PLAYER_WEAPON_PLAYER_MODEL[] = "player_model";
new const PLAYER_WEAPON_WORLD_MODEL[] = "world_model";

const WeaponIdType:PLAYER_HUMAN_PISTOL_ID = WEAPON_USP;
const PLAYER_HUMAN_PISTOL_CLIP = 12;
const PLAYER_HUMAN_PISTOL_AMMO = 24;
const PLAYER_FORWARD_INVALID = -1;

enum _:PlayerStateData
{
	bool:PlayerStateZombie,
	Class:PlayerStateClass,
	Subclass:PlayerStateSubclass,
	Class:PlayerStateSelectedHumanClass,
	Class:PlayerStateSelectedZombieClass,
	Weapon:PlayerStateMelee
};

enum _:PlayerClassPlanData
{
	Class:PlayerPlanClass,
	Subclass:PlayerPlanSubclass,
	Team:PlayerPlanTeam,
	TeamName:PlayerPlanGameTeam,
	bool:PlayerPlanZombie,
	bool:PlayerPlanApplyRuntime,
	PlayerPlanHealth,
	PlayerPlanArmor,
	PlayerPlanSpeed,
	Float:PlayerPlanGravity,
	Model:PlayerPlanModel,
	PlayerPlanModelName[RZ_MAX_HANDLE_LENGTH],
	PlayerPlanModelBody,
	PlayerPlanModelSkin,
	Weapon:PlayerPlanMelee,
	PlayerPlanKnifeViewModel[RZ_MAX_RESOURCE_PATH_LENGTH],
	PlayerPlanKnifePlayerModel[RZ_MAX_RESOURCE_PATH_LENGTH]
};

enum _:PlayerForwardData
{
	PlayerForwardChangeClassPre,
	PlayerForwardChangeClassPost,
	PlayerForwardInfectPlayerPre,
	PlayerForwardInfectPlayerPost,
	PlayerForwardCount
};

enum _:PlayerHookData
{
	PlayerHookGiveDefaultItems,
	PlayerHookSpawn,
	PlayerHookKnifeDeploy,
	PlayerHookCount
};

enum _:KnifeDeployArg
{
	KnifeDeployArgEntity = 1,
	KnifeDeployArgViewModel,
	KnifeDeployArgWeaponModel
};

new PlayerState[MAX_PLAYERS + 1][PlayerStateData];
new PlayerForwards[PlayerForwardCount];
new HookChain:PlayerHooks[PlayerHookCount];

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
	register_plugin("API: Players", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	CreatePlayerForwards();
	CreatePlayerHooks();
}

public plugin_end()
{
	DestroyPlayerHooks();
	DestroyPlayerForwards();
}

public client_putinserver(id)
{
	ResetPlayerState(id);
}

public client_disconnected(id)
{
	ResetPlayerState(id);
}

public OnGiveDefaultItemsPre(id)
{
	#pragma unused id

	return HC_SUPERCEDE;
}

public OnPlayerSpawnPost(id)
{
	if (!IsAliveGamePlayer(id))
		return;

	ApplyPlayerSpawnClass(id);
}

public OnKnifeDeployPre(entity, viewModel[], weaponModel[], anim, animExt[], skipLocal)
{
	#pragma unused viewModel
	#pragma unused weaponModel
	#pragma unused anim
	#pragma unused animExt
	#pragma unused skipLocal

	if (is_nullent(entity))
		return HC_CONTINUE;

	if (WeaponIdType:get_member(entity, m_iId) != WEAPON_KNIFE)
		return HC_CONTINUE;

	new id = get_member(entity, m_pPlayer);
	if (!IsAliveConnectedPlayer(id))
		return HC_CONTINUE;

	ApplyKnifeDeployModels(id);
	return HC_CONTINUE;
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
	if (!RequireConnectedPlayer(id, "get_player_class"))
		return Invalid_Class;

	return PlayerState[id][PlayerStateClass];
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
	if (!RequireConnectedPlayer(id, "get_player_subclass"))
		return Invalid_Subclass;

	return PlayerState[id][PlayerStateSubclass];
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
	if (!RequireConnectedPlayer(id, "get_player_var"))
		return null;

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetPlayerVarParamKey, key, charsmax(key));

	if (equal(key, "zombie"))
		return PlayerState[id][PlayerStateZombie];

	if (equal(key, "class"))
		return PlayerState[id][PlayerStateClass];

	if (equal(key, "subclass"))
		return PlayerState[id][PlayerStateSubclass];

	if (equal(key, "selected_human_class"))
		return PlayerState[id][PlayerStateSelectedHumanClass];

	if (equal(key, "selected_zombie_class"))
		return PlayerState[id][PlayerStateSelectedZombieClass];

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
	if (!RequireConnectedPlayer(id, "set_player_var"))
		return false;

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetPlayerVarParamKey, key, charsmax(key));

	if (equal(key, "class"))
	{
		new Class:class = Class:get_param_byref(SetPlayerVarParamValue);
		return bool:(ChangePlayerClass(id, class) == RZ_CONTINUE);
	}

	if (equal(key, "subclass"))
	{
		new Subclass:subclass = Subclass:get_param_byref(SetPlayerVarParamValue);

		if (subclass == Invalid_Subclass)
			return ClearPlayerSubclass(id);

		new Class:class = Class:get_subclass_var(subclass, "class");
		return bool:(ChangePlayerClass(id, class, 0, subclass) == RZ_CONTINUE);
	}

	if (equal(key, "selected_class"))
	{
		new Class:class = Class:get_param_byref(SetPlayerVarParamValue);
		return SetPlayerSelectedClass(id, class);
	}

	return bool:ReportNativeError("Invalid or readonly player property '%s'.", key);
}

public RzReturn:NativeChangePlayerClass(plugin, params)
{
	enum
	{
		ChangePlayerClassParamPlayer = 1,
		ChangePlayerClassParamClass,
		ChangePlayerClassParamAttacker,
		ChangePlayerClassParamSubclass,
		ChangePlayerClassParamApplyRuntime
	};

	if (params < ChangePlayerClassParamClass)
	{
		ReportNativeError("change_player_class requires player and class.");
		return RZ_SUPERCEDE;
	}

	new id = get_param(ChangePlayerClassParamPlayer);
	if (!RequireConnectedPlayer(id, "change_player_class"))
		return RZ_SUPERCEDE;

	new attacker = 0;
	if (params >= ChangePlayerClassParamAttacker)
	{
		attacker = get_param(ChangePlayerClassParamAttacker);
		if (attacker && !RequireConnectedPlayer(attacker, "change_player_class"))
			return RZ_SUPERCEDE;
	}

	new Class:class = Class:get_param(ChangePlayerClassParamClass);
	new Subclass:subclass = Invalid_Subclass;
	new bool:applyRuntime = true;

	if (params >= ChangePlayerClassParamSubclass)
		subclass = Subclass:get_param(ChangePlayerClassParamSubclass);

	if (params >= ChangePlayerClassParamApplyRuntime)
		applyRuntime = bool:get_param(ChangePlayerClassParamApplyRuntime);

	return ChangePlayerClass(id, class, attacker, subclass, applyRuntime);
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
	if (!RequireConnectedPlayer(id, "infect_player"))
		return false;

	new attacker = 0;
	if (params >= InfectPlayerParamAttacker)
	{
		attacker = get_param(InfectPlayerParamAttacker);
		if (attacker && !RequireConnectedPlayer(attacker, "infect_player"))
			return false;
	}

	new Subclass:subclass = Invalid_Subclass;
	if (params >= InfectPlayerParamSubclass)
		subclass = Subclass:get_param(InfectPlayerParamSubclass);

	return InfectPlayer(id, attacker, subclass);
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
	if (!RequireConnectedPlayer(id, "IsZombie"))
		return false;

	return PlayerState[id][PlayerStateZombie];
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
	if (!RequireConnectedPlayer(id, "IsHuman"))
		return false;

	return IsPlayerHuman(id);
}

stock RzReturn:ChangePlayerClass(
	id,
	Class:class,
	attacker = 0,
	Subclass:subclass = Invalid_Subclass,
	bool:applyRuntime = true
)
{
	new Team:team;
	if (!ResolveClassTeam(class, team))
		return RZ_SUPERCEDE;

	if (subclass != Invalid_Subclass && !IsSubclassForClass(subclass, class))
		return RZ_SUPERCEDE;

	new RzReturn:forwardResult = ExecuteChangeClassPre(id, class, attacker);
	if (forwardResult > RZ_CONTINUE)
		return forwardResult;

	new plan[PlayerClassPlanData];
	if (!BuildClassPlan(id, class, subclass, team, bool:(applyRuntime && is_user_alive(id)), plan))
		return RZ_SUPERCEDE;

	if (!ApplyClassPlan(id, plan))
		return RZ_SUPERCEDE;

	ExecuteChangeClassPost(id, class, attacker);
	return RZ_CONTINUE;
}

stock bool:InfectPlayer(id, attacker, Subclass:subclass)
{
	if (!ExecuteInfectPlayerPre(id, attacker, subclass))
		return false;

	new Class:zombieClass = FindClass(PLAYER_DEFAULT_ZOMBIE_CLASS);
	if (zombieClass == Invalid_Class)
		return bool:ReportNativeError("Required class '%s' was not registered.", PLAYER_DEFAULT_ZOMBIE_CLASS);

	if (ChangePlayerClass(id, zombieClass, attacker, subclass) > RZ_CONTINUE)
		return false;

	ExecuteInfectPlayerPost(id, attacker, subclass);
	return true;
}

stock bool:BuildClassPlan(
	id,
	Class:class,
	Subclass:subclass,
	Team:team,
	bool:applyRuntime,
	plan[PlayerClassPlanData]
)
{
	#pragma unused id

	plan[PlayerPlanClass] = class;
	plan[PlayerPlanSubclass] = subclass;
	plan[PlayerPlanTeam] = team;
	plan[PlayerPlanGameTeam] = GetGameTeam(team);
	plan[PlayerPlanZombie] = bool:(team == TEAM_ZOMBIE);
	plan[PlayerPlanApplyRuntime] = applyRuntime;
	plan[PlayerPlanModel] = ResolveClassModel(class, subclass);
	plan[PlayerPlanMelee] = ResolveClassMelee(class, subclass);
	plan[PlayerPlanModelName][0] = EOS;
	plan[PlayerPlanKnifeViewModel][0] = EOS;
	plan[PlayerPlanKnifePlayerModel][0] = EOS;

	if (!applyRuntime)
		return true;

	plan[PlayerPlanHealth] = ResolveClassProp(class, subclass, PLAYER_PROP_HEALTH);
	plan[PlayerPlanArmor] = ResolveClassProp(class, subclass, PLAYER_PROP_ARMOR);
	plan[PlayerPlanSpeed] = ResolveClassProp(class, subclass, PLAYER_PROP_SPEED);
	plan[PlayerPlanGravity] = Float:ResolveClassProp(class, subclass, PLAYER_PROP_GRAVITY);

	if (plan[PlayerPlanHealth] <= 0
		|| plan[PlayerPlanArmor] < 0
		|| plan[PlayerPlanSpeed] <= 0
		|| plan[PlayerPlanGravity] <= 0.0)
	{
		return bool:ReportNativeError("Invalid runtime props for class %d.", _:class);
	}

	if (!PrepareModelPlan(team, plan))
		return false;

	return PrepareMeleePlan(plan);
}

stock bool:ApplyClassPlan(id, plan[PlayerClassPlanData])
{
	PlayerState[id][PlayerStateClass] = plan[PlayerPlanClass];
	PlayerState[id][PlayerStateSubclass] = plan[PlayerPlanSubclass];
	PlayerState[id][PlayerStateZombie] = plan[PlayerPlanZombie];
	PlayerState[id][PlayerStateMelee] = plan[PlayerPlanMelee];

	if (TeamName:get_member(id, m_iTeam) != plan[PlayerPlanGameTeam])
		rg_set_user_team(id, plan[PlayerPlanGameTeam], MODEL_AUTO, true, false);

	if (!plan[PlayerPlanApplyRuntime])
		return true;

	ApplyPlayerProps(id, plan);
	ApplyPlayerModel(id, plan);
	return GivePlayerDefaultItems(id, plan);
}

stock ApplyPlayerSpawnClass(id)
{
	new Team:team = Team:get_game_var("respawn_team");
	if (!IsPlayerClassTeam(team))
		set_fail_state("ApiPlayers received invalid respawn team %d.", _:team);

	new Class:class = ResolveSpawnClass(id, team);
	if (ChangePlayerClass(id, class, id) > RZ_CONTINUE)
		set_fail_state("ApiPlayers could not apply spawn class %d to player %d.", _:class, id);
}

stock Class:ResolveSpawnClass(id, Team:team)
{
	new Class:defaultClass = Class:get_game_var("default_class");

	if (bool:get_game_var("override_default_class"))
		return ResolveDefaultClass(defaultClass, team);

	new Class:selectedClass = GetSelectedClass(id, team);
	if (selectedClass != Invalid_Class)
		return selectedClass;

	return ResolveDefaultClass(defaultClass, team);
}

stock Class:ResolveDefaultClass(Class:defaultClass, Team:team)
{
	if (defaultClass != Invalid_Class && Team:get_class_var(defaultClass, "team") == team)
		return defaultClass;

	switch (team)
	{
		case TEAM_HUMAN: return RequireClass(PLAYER_DEFAULT_HUMAN_CLASS);
		case TEAM_ZOMBIE: return RequireClass(PLAYER_DEFAULT_ZOMBIE_CLASS);
	}

	set_fail_state("ApiPlayers could not resolve default class for team %d.", _:team);
	return Invalid_Class;
}

stock bool:SetPlayerSelectedClass(id, Class:class)
{
	new Team:team;
	if (!ResolveClassTeam(class, team))
		return false;

	switch (team)
	{
		case TEAM_HUMAN:
		{
			PlayerState[id][PlayerStateSelectedHumanClass] = class;
			return true;
		}
		case TEAM_ZOMBIE:
		{
			PlayerState[id][PlayerStateSelectedZombieClass] = class;
			return true;
		}
	}

	return bool:ReportNativeError("Invalid selected class team %d.", _:team);
}

stock bool:ClearPlayerSubclass(id)
{
	new Class:class = PlayerState[id][PlayerStateClass];

	if (class == Invalid_Class)
		return bool:ReportNativeError("Player %d has no class.", id);

	return bool:(ChangePlayerClass(id, class) == RZ_CONTINUE);
}

stock bool:ResolveClassTeam(Class:class, &Team:team)
{
	if (class == Invalid_Class)
		return bool:ReportNativeError("Invalid class handle %d.", _:class);

	team = Team:get_class_var(class, "team");
	if (!IsPlayerClassTeam(team))
		return bool:ReportNativeError("Invalid class team %d for class %d.", _:team, _:class);

	return true;
}

stock bool:IsSubclassForClass(Subclass:subclass, Class:class)
{
	new Class:parentClass = Class:get_subclass_var(subclass, "class");
	if (parentClass == class)
		return true;

	return bool:ReportNativeError(
		"Subclass %d does not belong to class %d.",
		_:subclass,
		_:class
	);
}

stock ResolveClassProp(Class:class, Subclass:subclass, const prop[])
{
	new Props:props = Props:get_class_var(class, "props");

	if (subclass != Invalid_Subclass)
	{
		new Props:subclassProps = Props:get_subclass_var(subclass, "props");
		if (has_props_var(subclassProps, prop))
			props = subclassProps;
	}

	return get_props_var(props, prop);
}

stock Model:ResolveClassModel(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
	{
		new Model:model = Model:get_subclass_var(subclass, "model");
		if (model != Invalid_Model)
			return model;
	}

	new ModelsPack:models = ModelsPack:get_class_var(class, "models");
	return models_pack_get_random_model(models);
}

stock Weapon:ResolveClassMelee(Class:class, Subclass:subclass)
{
	new Weapon:melee = Weapon:get_class_var(class, "melee");

	if (subclass == Invalid_Subclass)
		return melee;

	new Weapon:subclassMelee = Weapon:get_subclass_var(subclass, "melee");
	if (HasWeaponModel(subclassMelee))
		return subclassMelee;

	return melee;
}

stock bool:PrepareModelPlan(Team:team, plan[PlayerClassPlanData])
{
	new Model:model = plan[PlayerPlanModel];
	if (model == Invalid_Model)
	{
		if (team == TEAM_HUMAN)
			return true;

		return bool:ReportNativeError("Zombie class %d has no runtime model.", _:plan[PlayerPlanClass]);
	}

	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	if (!get_model_var(model, PLAYER_MODEL_PATH, path, charsmax(path)))
		return bool:ReportNativeError("Invalid player model %d.", _:model);

	if (!GetModelNameFromPath(path, plan[PlayerPlanModelName], charsmax(plan[PlayerPlanModelName])))
		return bool:ReportNativeError("Invalid player model path '%s'.", path);

	plan[PlayerPlanModelBody] = get_model_var(model, "body");
	plan[PlayerPlanModelSkin] = get_model_var(model, "skin");
	return true;
}

stock bool:PrepareMeleePlan(plan[PlayerClassPlanData])
{
	new Weapon:melee = plan[PlayerPlanMelee];
	if (melee == Invalid_Weapon)
		return true;

	new Model:viewModel = Model:get_weapon_var(melee, PLAYER_WEAPON_VIEW_MODEL);
	if (viewModel != Invalid_Model
		&& !ReadModelPath(
			viewModel,
			PLAYER_WEAPON_VIEW_MODEL,
			plan[PlayerPlanKnifeViewModel],
			charsmax(plan[PlayerPlanKnifeViewModel])))
	{
		return false;
	}

	new Model:playerModel = Model:get_weapon_var(melee, PLAYER_WEAPON_PLAYER_MODEL);
	if (playerModel != Invalid_Model
		&& !ReadModelPath(
			playerModel,
			PLAYER_WEAPON_PLAYER_MODEL,
			plan[PlayerPlanKnifePlayerModel],
			charsmax(plan[PlayerPlanKnifePlayerModel])))
	{
		return false;
	}

	return true;
}

stock bool:ReadModelPath(Model:model, const label[], output[], length)
{
	if (get_model_var(model, PLAYER_MODEL_PATH, output, length))
		return true;

	return bool:ReportNativeError("Invalid %s model %d.", label, _:model);
}

stock bool:HasWeaponModel(Weapon:weapon)
{
	if (weapon == Invalid_Weapon)
		return false;

	return Model:get_weapon_var(weapon, PLAYER_WEAPON_VIEW_MODEL) != Invalid_Model
		|| Model:get_weapon_var(weapon, PLAYER_WEAPON_PLAYER_MODEL) != Invalid_Model
		|| Model:get_weapon_var(weapon, PLAYER_WEAPON_WORLD_MODEL) != Invalid_Model;
}

stock ApplyPlayerProps(id, plan[PlayerClassPlanData])
{
	set_entvar(id, var_health, float(plan[PlayerPlanHealth]));
	set_entvar(id, var_armorvalue, float(plan[PlayerPlanArmor]));
	set_entvar(id, var_maxspeed, float(plan[PlayerPlanSpeed]));
	set_entvar(id, var_gravity, plan[PlayerPlanGravity]);
}

stock ApplyPlayerModel(id, plan[PlayerClassPlanData])
{
	if (plan[PlayerPlanModel] == Invalid_Model)
	{
		rg_reset_user_model(id, true);
		return;
	}

	rg_set_user_model(id, plan[PlayerPlanModelName], true);
	set_entvar(id, var_body, plan[PlayerPlanModelBody]);
	set_entvar(id, var_skin, plan[PlayerPlanModelSkin]);
}

stock bool:GivePlayerDefaultItems(id, plan[PlayerClassPlanData])
{
	if (!rg_remove_all_items(id))
		return bool:ReportNativeError("Could not clear player %d inventory.", id);

	if (!GivePlayerItem(id, PLAYER_KNIFE_ITEM))
		return false;

	if (plan[PlayerPlanTeam] == TEAM_HUMAN)
		return GiveHumanPistol(id);

	ApplyActiveKnifeModels(id, plan[PlayerPlanKnifeViewModel], plan[PlayerPlanKnifePlayerModel]);
	return true;
}

stock bool:GiveHumanPistol(id)
{
	if (!GivePlayerItem(id, PLAYER_HUMAN_PISTOL_ITEM))
		return false;

	rg_set_user_ammo(id, PLAYER_HUMAN_PISTOL_ID, PLAYER_HUMAN_PISTOL_CLIP);
	rg_set_user_bpammo(id, PLAYER_HUMAN_PISTOL_ID, PLAYER_HUMAN_PISTOL_AMMO);
	return true;
}

stock bool:GivePlayerItem(id, const item[])
{
	if (rg_give_item(id, item, GT_REPLACE) != NULLENT)
		return true;

	return bool:ReportNativeError("Could not give item '%s' to player %d.", item, id);
}

stock ApplyKnifeDeployModels(id)
{
	new Weapon:melee = PlayerState[id][PlayerStateMelee];
	if (melee == Invalid_Weapon)
		return;

	new viewModel[RZ_MAX_RESOURCE_PATH_LENGTH];
	GetWeaponModelPath(melee, PLAYER_WEAPON_VIEW_MODEL, viewModel, charsmax(viewModel));

	new playerModel[RZ_MAX_RESOURCE_PATH_LENGTH];
	GetWeaponModelPath(melee, PLAYER_WEAPON_PLAYER_MODEL, playerModel, charsmax(playerModel));

	if (!IsNullString(viewModel))
		SetHookChainArg(KnifeDeployArgViewModel, ATYPE_STRING, viewModel);

	SetHookChainArg(KnifeDeployArgWeaponModel, ATYPE_STRING, playerModel);
}

stock ApplyActiveKnifeModels(id, const viewModel[], const playerModel[])
{
	if (!IsNullString(viewModel))
		set_entvar(id, var_viewmodel, viewModel);

	set_entvar(id, var_weaponmodel, playerModel);
}

stock bool:GetWeaponModelPath(Weapon:weapon, const key[], output[], length)
{
	output[0] = EOS;

	new Model:model = Model:get_weapon_var(weapon, key);
	if (model == Invalid_Model)
		return false;

	return bool:get_model_var(model, PLAYER_MODEL_PATH, output, length);
}

stock bool:IsPlayerHuman(id)
{
	if (PlayerState[id][PlayerStateClass] == Invalid_Class || PlayerState[id][PlayerStateZombie])
		return false;

	return Team:get_class_var(PlayerState[id][PlayerStateClass], "team") == TEAM_HUMAN;
}

stock Class:GetSelectedClass(id, Team:team)
{
	switch (team)
	{
		case TEAM_HUMAN: return PlayerState[id][PlayerStateSelectedHumanClass];
		case TEAM_ZOMBIE: return PlayerState[id][PlayerStateSelectedZombieClass];
	}

	return Invalid_Class;
}

stock TeamName:GetGameTeam(Team:team)
{
	switch (team)
	{
		case TEAM_HUMAN: return TEAM_CT;
		case TEAM_ZOMBIE: return TEAM_TERRORIST;
	}

	return TEAM_UNASSIGNED;
}

stock bool:IsPlayerClassTeam(Team:team)
{
	return team == TEAM_HUMAN || team == TEAM_ZOMBIE;
}

stock bool:IsAliveGamePlayer(id)
{
	if (!IsAliveConnectedPlayer(id))
		return false;

	new TeamName:team = get_member(id, m_iTeam);
	return team == TEAM_TERRORIST || team == TEAM_CT;
}

stock bool:IsAliveConnectedPlayer(id)
{
	return id >= 1 && id <= MaxClients && is_user_connected(id) && is_user_alive(id);
}

stock bool:RequireConnectedPlayer(id, const nativeName[])
{
	if (id < 1 || id > MaxClients)
	{
		ReportNativeError("%s received invalid player index %d.", nativeName, id);
		return false;
	}

	if (!is_user_connected(id))
	{
		ReportNativeError("%s received disconnected player %d.", nativeName, id);
		return false;
	}

	return true;
}

stock ResetPlayerState(id)
{
	PlayerState[id][PlayerStateZombie] = false;
	PlayerState[id][PlayerStateClass] = Invalid_Class;
	PlayerState[id][PlayerStateSubclass] = Invalid_Subclass;
	PlayerState[id][PlayerStateSelectedHumanClass] = Invalid_Class;
	PlayerState[id][PlayerStateSelectedZombieClass] = Invalid_Class;
	PlayerState[id][PlayerStateMelee] = Invalid_Weapon;
}

stock CreatePlayerForwards()
{
	for (new index = 0; index < sizeof PlayerForwards; index++)
		PlayerForwards[index] = PLAYER_FORWARD_INVALID;

	PlayerForwards[PlayerForwardChangeClassPre] = CreateRequiredPlayerForward("@change_class_pre", ET_CONTINUE);
	PlayerForwards[PlayerForwardChangeClassPost] = CreateRequiredPlayerForward("@change_class_post", ET_IGNORE);
	PlayerForwards[PlayerForwardInfectPlayerPre] = CreateRequiredPlayerForward("@infect_player_pre", ET_CONTINUE);
	PlayerForwards[PlayerForwardInfectPlayerPost] = CreateRequiredPlayerForward("@infect_player_post", ET_IGNORE);
}

stock CreateRequiredPlayerForward(const forwardName[], executionType)
{
	new forwardId = CreateMultiForward(forwardName, executionType, FP_CELL, FP_CELL, FP_CELL);
	if (forwardId == PLAYER_FORWARD_INVALID)
		set_fail_state("ApiPlayers could not create forward '%s'.", forwardName);

	return forwardId;
}

stock DestroyPlayerForwards()
{
	for (new index = 0; index < sizeof PlayerForwards; index++)
	{
		if (PlayerForwards[index] == PLAYER_FORWARD_INVALID)
			continue;

		DestroyForward(PlayerForwards[index]);
		PlayerForwards[index] = PLAYER_FORWARD_INVALID;
	}
}

stock RzReturn:ExecuteChangeClassPre(id, Class:class, attacker)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardChangeClassPre], forwardResult, id, class, attacker))
	{
		ReportNativeError("Could not execute @change_class_pre.");
		return RZ_SUPERCEDE;
	}

	return RzReturn:forwardResult;
}

stock ExecuteChangeClassPost(id, Class:class, attacker)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardChangeClassPost], forwardResult, id, class, attacker))
		ReportNativeError("Could not execute @change_class_post.");
}

stock bool:ExecuteInfectPlayerPre(id, attacker, Subclass:subclass)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardInfectPlayerPre], forwardResult, id, attacker, subclass))
		return bool:ReportNativeError("Could not execute @infect_player_pre.");

	return RzReturn:forwardResult < RZ_SUPERCEDE;
}

stock ExecuteInfectPlayerPost(id, attacker, Subclass:subclass)
{
	new forwardResult;
	if (!ExecuteForward(PlayerForwards[PlayerForwardInfectPlayerPost], forwardResult, id, attacker, subclass))
		ReportNativeError("Could not execute @infect_player_post.");
}

stock CreatePlayerHooks()
{
	for (new index = 0; index < sizeof PlayerHooks; index++)
		PlayerHooks[index] = INVALID_HOOKCHAIN;

	PlayerHooks[PlayerHookGiveDefaultItems] = RegisterRequiredPlayerHook(
		.functionId = RG_CBasePlayer_GiveDefaultItems,
		.callback = "OnGiveDefaultItemsPre",
		.post = false
	);

	PlayerHooks[PlayerHookSpawn] = RegisterRequiredPlayerHook(
		.functionId = RG_CBasePlayer_Spawn,
		.callback = "OnPlayerSpawnPost",
		.post = true
	);

	PlayerHooks[PlayerHookKnifeDeploy] = RegisterRequiredPlayerHook(
		.functionId = RG_CBasePlayerWeapon_DefaultDeploy,
		.callback = "OnKnifeDeployPre",
		.post = false
	);
}

stock HookChain:RegisterRequiredPlayerHook(ReAPIFunc:functionId, const callback[], bool:post)
{
	new HookChain:hook = RegisterHookChain(
		.function_id = functionId,
		.callback = callback,
		.post = post
	);

	if (hook == INVALID_HOOKCHAIN)
		set_fail_state("ApiPlayers could not register ReAPI hook '%s'.", callback);

	return hook;
}

stock DestroyPlayerHooks()
{
	for (new index = 0; index < sizeof PlayerHooks; index++)
	{
		if (PlayerHooks[index] == INVALID_HOOKCHAIN)
			continue;

		DisableHookChain(PlayerHooks[index]);
		PlayerHooks[index] = INVALID_HOOKCHAIN;
	}
}
