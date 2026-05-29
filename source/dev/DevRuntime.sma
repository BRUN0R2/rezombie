#include <amxmodx>
#include <reapi>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const DEV_MAX_BOTS_PER_COMMAND = 16;
const DEV_NO_ATTACKER = 0;
const Float:DEV_IMMEDIATE_RESTART_DELAY = 0.0;

new const DEV_PREFIX[] = "[ReZombie Dev]";

public plugin_precache()
{
	register_plugin("Dev: Runtime", "0.1.0", "BRUN0");
}

public plugin_init()
{
	register_srvcmd("rz_dev_add_bots", "CommandAddBots");
	register_srvcmd("rz_dev_respawn_player", "CommandRespawnPlayer");
	register_srvcmd("rz_dev_infect_player", "CommandInfectPlayer");
	register_srvcmd("rz_dev_change_class", "CommandChangeClass");
	register_srvcmd("rz_dev_validate_player", "CommandValidatePlayer");
	register_srvcmd("rz_dev_dump_player", "CommandDumpPlayer");
	register_srvcmd("rz_dev_restart_round", "CommandRestartRound");
}

public CommandAddBots()
{
	enum
	{
		AddBotsArgCount = 1
	};

	if (!RequireArgumentCount(AddBotsArgCount + 1, "Usage: rz_dev_add_bots <count>"))
		return;

	new count = read_argv_int(AddBotsArgCount);
	if (count <= 0 || count > DEV_MAX_BOTS_PER_COMMAND)
	{
		DevError("Bot count must be between 1 and %d.", DEV_MAX_BOTS_PER_COMMAND);
		return;
	}

	for (new index = 0; index < count; index++)
		server_cmd("sypb_add");

	server_exec();
	DevInfo("Requested %d SyPB bot(s).", count);
}

public CommandRespawnPlayer()
{
	enum
	{
		RespawnPlayerArgPlayer = 1
	};

	if (!RequireArgumentCount(RespawnPlayerArgPlayer + 1, "Usage: rz_dev_respawn_player <id>"))
		return;

	new id = read_argv_int(RespawnPlayerArgPlayer);
	if (!RequireConnectedPlayer(id))
		return;

	rg_round_respawn(id);
	DevInfo("Respawn requested for player %d.", id);
}

public CommandInfectPlayer()
{
	enum
	{
		InfectPlayerArgPlayer = 1,
		InfectPlayerArgSubclass
	};

	if (!RequireArgumentCount(InfectPlayerArgSubclass + 1, "Usage: rz_dev_infect_player <id> <subclass>"))
		return;

	new id = read_argv_int(InfectPlayerArgPlayer);
	if (!RequireAlivePlayer(id))
		return;

	new subclassHandle[RZ_MAX_HANDLE_LENGTH];
	read_argv(InfectPlayerArgSubclass, subclassHandle, charsmax(subclassHandle));

	new Subclass:subclass = FindRequiredSubclass(subclassHandle);
	if (subclass == Invalid_Subclass)
		return;

	if (!infect_player(id, DEV_NO_ATTACKER, subclass))
	{
		DevError("Failed to infect player %d with subclass '%s'.", id, subclassHandle);
		return;
	}

	DevInfo("Player %d infected with subclass '%s'.", id, subclassHandle);
	DumpPlayer(id);
}

public CommandChangeClass()
{
	enum
	{
		ChangeClassArgPlayer = 1,
		ChangeClassArgClass,
		ChangeClassArgSubclass
	};

	if (!RequireArgumentCount(ChangeClassArgClass + 1, "Usage: rz_dev_change_class <id> <class> [subclass]"))
		return;

	new id = read_argv_int(ChangeClassArgPlayer);
	if (!RequireAlivePlayer(id))
		return;

	new classHandle[RZ_MAX_HANDLE_LENGTH];
	read_argv(ChangeClassArgClass, classHandle, charsmax(classHandle));

	new Class:class = FindRequiredClass(classHandle);
	if (class == Invalid_Class)
		return;

	new Subclass:subclass = Invalid_Subclass;
	new subclassHandle[RZ_MAX_HANDLE_LENGTH];

	if (read_argc() > ChangeClassArgSubclass)
	{
		read_argv(ChangeClassArgSubclass, subclassHandle, charsmax(subclassHandle));
		subclass = FindRequiredSubclass(subclassHandle);

		if (subclass == Invalid_Subclass)
			return;
	}

	if (!change_player_class(id, class, subclass))
	{
		DevError("Failed to change player %d to class '%s'.", id, classHandle);
		return;
	}

	if (subclass == Invalid_Subclass)
		DevInfo("Player %d changed to class '%s'.", id, classHandle);
	else
		DevInfo("Player %d changed to class '%s' subclass '%s'.", id, classHandle, subclassHandle);

	DumpPlayer(id);
}

public CommandValidatePlayer()
{
	enum
	{
		ValidatePlayerArgPlayer = 1
	};

	if (!RequireArgumentCount(ValidatePlayerArgPlayer + 1, "Usage: rz_dev_validate_player <id>"))
		return;

	new id = read_argv_int(ValidatePlayerArgPlayer);
	if (!RequireConnectedPlayer(id))
		return;

	if (!ValidatePlayer(id))
		return;

	DevInfo("Player %d validation passed.", id);
}

public CommandDumpPlayer()
{
	enum
	{
		DumpPlayerArgPlayer = 1
	};

	if (!RequireArgumentCount(DumpPlayerArgPlayer + 1, "Usage: rz_dev_dump_player <id>"))
		return;

	new id = read_argv_int(DumpPlayerArgPlayer);
	if (!RequireConnectedPlayer(id))
		return;

	DumpPlayer(id);
}

public CommandRestartRound()
{
	enum
	{
		RestartRoundArgDelay = 1
	};

	new Float:delay = DEV_IMMEDIATE_RESTART_DELAY;

	if (read_argc() > RestartRoundArgDelay)
		delay = read_argv_float(RestartRoundArgDelay);

	if (delay < 0.0)
	{
		DevError("Round restart delay cannot be negative.");
		return;
	}

	if (delay == DEV_IMMEDIATE_RESTART_DELAY)
	{
		rg_restart_round();
		DevInfo("Round restarted immediately.");
		return;
	}

	if (!rg_round_end(delay, WINSTATUS_DRAW, ROUND_GAME_RESTART, "Round Restart"))
	{
		DevError("Failed to schedule round restart with %.2f second delay.", delay);
		return;
	}

	DevInfo("Round restart scheduled with %.2f second delay.", delay);
}

stock bool:ValidatePlayer(id)
{
	new Class:class = get_player_class(id);
	if (class == Invalid_Class)
		return DevError("Player %d has no class.", id);

	new Subclass:subclass = get_player_subclass(id);

	if (subclass != Invalid_Subclass)
	{
		new Class:parentClass = Class:get_subclass_var(subclass, "class");
		if (parentClass != class)
			return DevError("Player %d subclass parent does not match player class.", id);
	}

	new Props:props = GetRuntimeProps(class, subclass);
	if (props == Invalid_Props)
		return DevError("Player %d has invalid runtime props.", id);

	new health = get_props_var(props, "health");
	new speed = get_props_var(props, "speed");
	new Float:gravity = get_props_var(props, "gravity");

	if (health <= 0 || speed <= 0 || gravity <= 0.0)
		return DevError("Player %d has invalid props health=%d speed=%d gravity=%.2f.", id, health, speed, gravity);

	if (IsZombie(id) && GetRuntimeModel(class, subclass) == Invalid_Model)
		return DevError("Player %d is zombie without runtime model.", id);

	return true;
}

stock DumpPlayer(id)
{
	new name[MAX_NAME_LENGTH];
	get_user_name(id, name, charsmax(name));

	new Class:class = get_player_class(id);
	new Subclass:subclass = get_player_subclass(id);
	new Props:props = GetRuntimeProps(class, subclass);
	new Model:model = GetRuntimeModel(class, subclass);

	new classHandle[RZ_MAX_HANDLE_LENGTH];
	GetClassHandle(class, classHandle, charsmax(classHandle));

	new subclassHandle[RZ_MAX_HANDLE_LENGTH];
	GetSubclassHandle(subclass, subclassHandle, charsmax(subclassHandle));

	new modelHandle[RZ_MAX_HANDLE_LENGTH];
	GetModelHandle(model, modelHandle, charsmax(modelHandle));

	new entityModel[RZ_MAX_RESOURCE_PATH_LENGTH];
	if (is_user_alive(id))
		get_entvar(id, var_model, entityModel, charsmax(entityModel));
	else
		copy(entityModel, charsmax(entityModel), "not_alive");

	new health;
	new speed;
	new Float:gravity;

	if (props != Invalid_Props)
	{
		health = get_props_var(props, "health");
		speed = get_props_var(props, "speed");
		gravity = get_props_var(props, "gravity");
	}

	DevInfo("Player %d '%s': alive=%d zombie=%d class=%s subclass=%s model=%s entity_model=%s health=%d speed=%d gravity=%.2f.",
		id,
		name,
		is_user_alive(id),
		IsZombie(id),
		classHandle,
		subclassHandle,
		modelHandle,
		entityModel,
		health,
		speed,
		gravity);
}

stock Props:GetRuntimeProps(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
		return Props:get_subclass_var(subclass, "props");

	if (class != Invalid_Class)
		return Props:get_class_var(class, "props");

	return Invalid_Props;
}

stock Model:GetRuntimeModel(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
	{
		new Model:model = Model:get_subclass_var(subclass, "model");

		if (model != Invalid_Model)
			return model;
	}

	if (class != Invalid_Class)
		return Model:get_class_var(class, "model");

	return Invalid_Model;
}

stock Class:FindRequiredClass(const handle[])
{
	if (!handle[0])
	{
		DevError("Class handle cannot be empty.");
		return Invalid_Class;
	}

	new Class:class = FindClass(handle);
	if (class == Invalid_Class)
	{
		DevError("Class '%s' was not found.", handle);
		return Invalid_Class;
	}

	return class;
}

stock Subclass:FindRequiredSubclass(const handle[])
{
	if (!handle[0])
	{
		DevError("Subclass handle cannot be empty.");
		return Invalid_Subclass;
	}

	new Subclass:subclass = FindSubclass(handle);
	if (subclass == Invalid_Subclass)
	{
		DevError("Subclass '%s' was not found.", handle);
		return Invalid_Subclass;
	}

	return subclass;
}

stock bool:RequireArgumentCount(requiredCount, const usage[])
{
	if (read_argc() >= requiredCount)
		return true;

	return DevError("%s.", usage);
}

stock bool:RequireConnectedPlayer(id)
{
	if (!IsPlayerIndex(id))
		return DevError("Invalid player index %d.", id);

	if (!is_user_connected(id))
		return DevError("Player %d is not connected.", id);

	return true;
}

stock bool:RequireAlivePlayer(id)
{
	if (!RequireConnectedPlayer(id))
		return false;

	if (!is_user_alive(id))
		return DevError("Player %d is not alive. Use rz_dev_respawn_player first.", id);

	return true;
}

stock GetClassHandle(Class:class, handle[], length)
{
	if (class == Invalid_Class)
	{
		copy(handle, length, "none");
		return;
	}

	get_class_var(class, "handle", handle, length);
}

stock GetSubclassHandle(Subclass:subclass, handle[], length)
{
	if (subclass == Invalid_Subclass)
	{
		copy(handle, length, "none");
		return;
	}

	get_subclass_var(subclass, "handle", handle, length);
}

stock GetModelHandle(Model:model, handle[], length)
{
	if (model == Invalid_Model)
	{
		copy(handle, length, "none");
		return;
	}

	get_model_var(model, "handle", handle, length);
}

stock bool:IsPlayerIndex(id)
{
	return 1 <= id <= MaxClients;
}

stock DevInfo(const message[], any:...)
{
	new formatted[512];
	vformat(formatted, charsmax(formatted), message, 2);

	server_print("%s %s", DEV_PREFIX, formatted);
	log_amx("%s", formatted);
}

stock bool:DevError(const message[], any:...)
{
	new formatted[512];
	vformat(formatted, charsmax(formatted), message, 2);

	server_print("%s ERROR: %s", DEV_PREFIX, formatted);
	log_amx("ERROR: %s", formatted);

	return false;
}
