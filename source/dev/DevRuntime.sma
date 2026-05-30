#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const DEV_MAX_BOTS_PER_COMMAND = 16;
const DEV_NO_ATTACKER = 0;
const Float:DEV_IMMEDIATE_RESTART_DELAY = 0.0;
const DEV_ROUND_FLOW_DEFAULT_PLAYERS = 1;
const Float:DEV_ROUND_FLOW_CHECK_INTERVAL = 0.25;
const Float:DEV_ROUND_FLOW_WAIT_TIMEOUT = 20.0;
const Float:DEV_ROUND_FLOW_RESTART_WAIT = 1.0;
const Float:DEV_ROUND_FLOW_RESTART_DELAY = 1.0;
const DEV_MAX_PLAYER_WEAPONS = 32;
const DEV_MIN_JOIN_TEAM_SLOT = 1;
const DEV_MAX_JOIN_TEAM_SLOT = 6;
const DEV_JOIN_TEAM_SLOT_TEXT_LENGTH = 4;
const Float:DEV_MIN_SPAWN_DISTANCE = 96.0;

new const DEV_PREFIX[] = "[ReZombie Dev]";
new const DEV_DEFAULT_HUMAN_CLASS[] = "human";
new const DEV_DEFAULT_ZOMBIE_CLASS[] = "zombie";
new const DEV_DEFAULT_ROUND_FLOW_SUBCLASS[] = "fleshpound";
new const DEV_DEFAULT_MELEE_WEAPON[] = "weapon_knife";

enum DevRoundFlowState
{
	DevRoundFlowIdle = 0,
	DevRoundFlowWaitingPlayers,
	DevRoundFlowValidatingBaseline,
	DevRoundFlowValidatingRestart
};

new DevRoundFlowState:RoundFlowState = DevRoundFlowIdle;
new Subclass:RoundFlowSubclass = Invalid_Subclass;
new RoundFlowVictim;
new RoundFlowRequiredPlayers;
new bool:RoundFlowBotsRequested;
new Float:RoundFlowNextCheckAt;
new Float:RoundFlowTimeoutAt;
new RoundFlowSubclassHandle[RZ_MAX_HANDLE_LENGTH];
new RoundFlowZombieModelPath[RZ_MAX_RESOURCE_PATH_LENGTH];
new bool:BlockNextChangeClassPre;
new bool:BlockNextInfectPlayerPre;

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
	register_srvcmd("rz_dev_join_team", "CommandJoinTeam");
	register_srvcmd("rz_dev_restart_round", "CommandRestartRound");
	register_srvcmd("rz_dev_validate_spawn_spacing", "CommandValidateSpawnSpacing");
	register_srvcmd("rz_dev_validate_round_flow", "CommandValidateRoundFlow");
	register_srvcmd("rz_dev_validate_forward_returns", "CommandValidateForwardReturns");
	register_srvcmd("rz_dev_validate_round_state", "CommandValidateRoundState");
	register_forward(FM_StartFrame, "OnDevServerFrame");
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

public CommandJoinTeam()
{
	enum
	{
		JoinTeamArgPlayer = 1,
		JoinTeamArgSlot
	};

	if (!RequireArgumentCount(JoinTeamArgSlot + 1, "Usage: rz_dev_join_team <id> <slot>"))
		return;

	new id = read_argv_int(JoinTeamArgPlayer);
	if (!RequireConnectedPlayer(id))
		return;

	new slot = read_argv_int(JoinTeamArgSlot);
	if (slot < DEV_MIN_JOIN_TEAM_SLOT || slot > DEV_MAX_JOIN_TEAM_SLOT)
	{
		DevError("Join team slot must be between %d and %d.", DEV_MIN_JOIN_TEAM_SLOT, DEV_MAX_JOIN_TEAM_SLOT);
		return;
	}

	new slotText[DEV_JOIN_TEAM_SLOT_TEXT_LENGTH];
	num_to_str(slot, slotText, charsmax(slotText));

	engclient_cmd(id, "jointeam", slotText);
	server_exec();

	DevInfo("Player %d attempted jointeam slot %d.", id, slot);
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

public CommandValidateSpawnSpacing()
{
	new alivePlayers;

	for (new first = 1; first <= MaxClients; first++)
	{
		if (!IsAlivePlayablePlayer(first))
			continue;

		alivePlayers++;

		for (new second = first + 1; second <= MaxClients; second++)
		{
			if (!IsAlivePlayablePlayer(second))
				continue;

			if (ArePlayersTooClose(first, second))
			{
				DevError("Players %d and %d are too close after spawn.", first, second);
				return;
			}
		}
	}

	DevInfo("Spawn spacing validation passed for %d alive playable player(s).", alivePlayers);
}

public CommandValidateRoundFlow()
{
	enum
	{
		ValidateRoundFlowArgSubclass = 1,
		ValidateRoundFlowArgRequiredPlayers
	};

	if (RoundFlowState != DevRoundFlowIdle)
	{
		DevError("Round flow validation is already running.");
		return;
	}

	new subclassHandle[RZ_MAX_HANDLE_LENGTH];
	if (read_argc() > ValidateRoundFlowArgSubclass)
		read_argv(ValidateRoundFlowArgSubclass, subclassHandle, charsmax(subclassHandle));
	else
		copy(subclassHandle, charsmax(subclassHandle), DEV_DEFAULT_ROUND_FLOW_SUBCLASS);

	new Subclass:subclass = FindRequiredSubclass(subclassHandle);
	if (subclass == Invalid_Subclass)
		return;

	new requiredPlayers = DEV_ROUND_FLOW_DEFAULT_PLAYERS;
	if (read_argc() > ValidateRoundFlowArgRequiredPlayers)
		requiredPlayers = read_argv_int(ValidateRoundFlowArgRequiredPlayers);

	if (requiredPlayers <= 0 || requiredPlayers > DEV_MAX_BOTS_PER_COMMAND)
	{
		DevError("Round flow required players must be between 1 and %d.", DEV_MAX_BOTS_PER_COMMAND);
		return;
	}

	if (!PrepareRoundFlowModelPath(subclass))
		return;

	RoundFlowState = DevRoundFlowWaitingPlayers;
	RoundFlowSubclass = subclass;
	RoundFlowVictim = 0;
	RoundFlowRequiredPlayers = requiredPlayers;
	RoundFlowBotsRequested = false;
	copy(RoundFlowSubclassHandle, charsmax(RoundFlowSubclassHandle), subclassHandle);

	new Float:now = get_gametime();
	RoundFlowNextCheckAt = now;
	RoundFlowTimeoutAt = now + DEV_ROUND_FLOW_WAIT_TIMEOUT;

	DevInfo("Round flow validation started with subclass '%s' and %d required player(s).", subclassHandle, requiredPlayers);
}

public CommandValidateForwardReturns()
{
	enum
	{
		ValidateForwardReturnsArgPlayer = 1,
		ValidateForwardReturnsArgSubclass
	};

	new id;
	if (read_argc() > ValidateForwardReturnsArgPlayer)
	{
		id = read_argv_int(ValidateForwardReturnsArgPlayer);
	}
	else
	{
		id = FindFirstAlivePlayablePlayer();
		if (!id)
		{
			DevError("No alive playable player found for forward return validation.");
			return;
		}
	}

	if (!RequireAlivePlayer(id))
		return;

	new subclassHandle[RZ_MAX_HANDLE_LENGTH];
	if (read_argc() > ValidateForwardReturnsArgSubclass)
		read_argv(ValidateForwardReturnsArgSubclass, subclassHandle, charsmax(subclassHandle));
	else
		copy(subclassHandle, charsmax(subclassHandle), DEV_DEFAULT_ROUND_FLOW_SUBCLASS);

	new Class:class = FindRequiredClass(DEV_DEFAULT_ZOMBIE_CLASS);
	if (class == Invalid_Class)
		return;

	new Subclass:subclass = FindRequiredSubclass(subclassHandle);
	if (subclass == Invalid_Subclass)
		return;

	new Class:initialClass = get_player_class(id);
	new Subclass:initialSubclass = get_player_subclass(id);
	new bool:initialZombie = IsZombie(id);

	BlockNextChangeClassPre = true;
	new bool:blockedChangeClass = !change_player_class(id, class, subclass);
	BlockNextChangeClassPre = false;

	if (!blockedChangeClass)
	{
		DevError("@change_class_pre did not block change_player_class.");
		return;
	}

	if (!ValidateUnchangedPlayerState(id, initialClass, initialSubclass, initialZombie, "change_class_pre"))
		return;

	BlockNextInfectPlayerPre = true;
	new bool:blockedInfectPlayer = !infect_player(id, DEV_NO_ATTACKER, subclass);
	BlockNextInfectPlayerPre = false;

	if (!blockedInfectPlayer)
	{
		DevError("@infect_player_pre did not block infect_player.");
		return;
	}

	if (!ValidateUnchangedPlayerState(id, initialClass, initialSubclass, initialZombie, "infect_player_pre"))
		return;

	DevInfo("Forward return validation passed for player %d.", id);
}

public CommandValidateRoundState()
{
	if (!ValidateRoundState())
		return;

	DevInfo("Round state validation passed.");
}

RzReturn:@change_class_pre(id, Class:class, Subclass:subclass)
{
	#pragma unused id
	#pragma unused class
	#pragma unused subclass

	if (!BlockNextChangeClassPre)
		return RZ_CONTINUE;

	BlockNextChangeClassPre = false;
	return RZ_SUPERCEDE;
}

RzReturn:@infect_player_pre(id, attacker, Subclass:subclass)
{
	#pragma unused id
	#pragma unused attacker
	#pragma unused subclass

	if (!BlockNextInfectPlayerPre)
		return RZ_CONTINUE;

	BlockNextInfectPlayerPre = false;
	return RZ_SUPERCEDE;
}

public OnDevServerFrame()
{
	if (RoundFlowState == DevRoundFlowIdle)
		return FMRES_IGNORED;

	new Float:now = get_gametime();
	if (now < RoundFlowNextCheckAt)
		return FMRES_IGNORED;

	RoundFlowNextCheckAt = now + DEV_ROUND_FLOW_CHECK_INTERVAL;
	UpdateRoundFlow(now);

	return FMRES_IGNORED;
}

stock UpdateRoundFlow(Float:now)
{
	switch (RoundFlowState)
	{
		case DevRoundFlowWaitingPlayers:
			UpdateRoundFlowWaitingPlayers(now);
		case DevRoundFlowValidatingBaseline:
			UpdateRoundFlowBaseline(now);
		case DevRoundFlowValidatingRestart:
			UpdateRoundFlowRestart(now);
	}
}

stock UpdateRoundFlowWaitingPlayers(Float:now)
{
	new alivePlayers = CountAlivePlayablePlayers();
	if (alivePlayers >= RoundFlowRequiredPlayers)
	{
		rg_restart_round();

		RoundFlowState = DevRoundFlowValidatingBaseline;
		RoundFlowNextCheckAt = now + DEV_ROUND_FLOW_RESTART_WAIT;
		RoundFlowTimeoutAt = now + DEV_ROUND_FLOW_WAIT_TIMEOUT;

		DevInfo("Round flow baseline restart requested.");
		return;
	}

	if (!RoundFlowBotsRequested)
	{
		RequestMissingBots(RoundFlowRequiredPlayers - alivePlayers);
		RoundFlowBotsRequested = true;
	}

	if (now >= RoundFlowTimeoutAt)
		FailRoundFlow("Timed out waiting for %d alive playable players.", RoundFlowRequiredPlayers);
}

stock UpdateRoundFlowBaseline(Float:now)
{
	if (CountAlivePlayablePlayers() < RoundFlowRequiredPlayers)
	{
		if (now >= RoundFlowTimeoutAt)
			FailRoundFlow("Timed out waiting for alive players after baseline restart.");

		return;
	}

	if (!ValidateAliveHumans("baseline"))
	{
		StopRoundFlow();
		return;
	}

	new id = FindFirstAlivePlayablePlayer();
	if (!id)
	{
		FailRoundFlow("Could not find an alive playable player for infection.");
		return;
	}

	if (!infect_player(id, DEV_NO_ATTACKER, RoundFlowSubclass))
	{
		FailRoundFlow("Could not infect player %d with subclass '%s'.", id, RoundFlowSubclassHandle);
		return;
	}

	RoundFlowVictim = id;

	if (!ValidateRoundFlowZombie(id))
	{
		StopRoundFlow();
		return;
	}

	if (!rg_round_end(DEV_ROUND_FLOW_RESTART_DELAY, WINSTATUS_DRAW, ROUND_GAME_RESTART, "Dev Round Flow"))
	{
		FailRoundFlow("Could not schedule round restart after infection.");
		return;
	}

	RoundFlowState = DevRoundFlowValidatingRestart;
	RoundFlowNextCheckAt = now + DEV_ROUND_FLOW_RESTART_DELAY + DEV_ROUND_FLOW_RESTART_WAIT;
	RoundFlowTimeoutAt = now + DEV_ROUND_FLOW_RESTART_DELAY + DEV_ROUND_FLOW_WAIT_TIMEOUT;

	DevInfo("Round flow infected player %d and scheduled restart.", id);
}

stock UpdateRoundFlowRestart(Float:now)
{
	if (CountAlivePlayablePlayers() < RoundFlowRequiredPlayers)
	{
		if (now >= RoundFlowTimeoutAt)
			FailRoundFlow("Timed out waiting for alive players after restart.");

		return;
	}

	if (!RequireConnectedPlayer(RoundFlowVictim))
	{
		StopRoundFlow();
		return;
	}

	if (!ValidateRoundFlowHuman(RoundFlowVictim, "restart victim"))
	{
		StopRoundFlow();
		return;
	}

	if (!ValidateAliveHumans("restart"))
	{
		StopRoundFlow();
		return;
	}

	DevInfo("Round flow validation passed.");
	StopRoundFlow();
}

stock bool:ValidatePlayer(id)
{
	new Class:class = get_player_class(id);
	if (class == Invalid_Class)
		return DevError("Player %d has no class.", id);

	new Subclass:subclass = get_player_subclass(id);

	if (Class:get_player_var(id, "class") != class)
		return DevError("Player %d get_player_var class mismatch.", id);

	if (Subclass:get_player_var(id, "subclass") != subclass)
		return DevError("Player %d get_player_var subclass mismatch.", id);

	if (bool:get_player_var(id, "zombie") != IsZombie(id))
		return DevError("Player %d get_player_var zombie mismatch.", id);

	if (!ValidatePlayerTeam(id))
		return false;

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

	if (is_user_alive(id) && !ValidatePlayerDefaultItems(id))
		return false;

	return true;
}

stock bool:ValidatePlayerTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);

	if (IsZombie(id))
	{
		if (team != TEAM_TERRORIST)
			return DevError("Player %d is zombie outside Terrorist team.", id);

		return true;
	}

	if (team != TEAM_CT)
		return DevError("Player %d is human outside CT team.", id);

	return true;
}

stock bool:ValidateRoundState()
{
	new RoundState:roundState = get_round_var("state");
	if (!IsValidRoundState(roundState))
		return DevError("Round state native returned invalid state %d.", _:roundState);

	new Mode:mode = get_round_var("mode");
	new Float:timeLeft = get_round_var("time_left");

	if (timeLeft < 0.0)
		return DevError("Round state native returned negative time_left %.2f.", timeLeft);

	switch (roundState)
	{
		case RoundStatePreparing, RoundStatePlaying:
		{
			if (mode == Invalid_Mode)
				return DevError("Round state native returned invalid mode while active.");
		}
	}

	return true;
}

stock bool:IsValidRoundState(RoundState:roundState)
{
	switch (roundState)
	{
		case RoundStateFreezing, RoundStateWaiting, RoundStatePreparing, RoundStatePlaying, RoundStateEnding:
			return true;
	}

	return false;
}

stock bool:ValidatePlayerDefaultItems(id)
{
	if (!rg_has_item_by_name(id, DEV_DEFAULT_MELEE_WEAPON))
		return DevError("Player %d does not have default melee weapon.", id);

	if (!IsZombie(id))
		return true;

	new weapons[DEV_MAX_PLAYER_WEAPONS];
	new weaponsCount;
	get_user_weapons(id, weapons, weaponsCount);

	for (new index = 0; index < weaponsCount; index++)
	{
		if (weapons[index] != CSW_KNIFE)
			return DevError("Zombie player %d kept non-melee weapon id %d.", id, weapons[index]);
	}

	return true;
}

stock bool:ValidateUnchangedPlayerState(id, Class:initialClass, Subclass:initialSubclass, bool:initialZombie, const stage[])
{
	if (get_player_class(id) != initialClass)
		return DevError("Forward return %s changed player %d class.", stage, id);

	if (get_player_subclass(id) != initialSubclass)
		return DevError("Forward return %s changed player %d subclass.", stage, id);

	if (IsZombie(id) != initialZombie)
		return DevError("Forward return %s changed player %d zombie state.", stage, id);

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
	new TeamName:team = get_member(id, m_iTeam);

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

	DevInfo("Player %d '%s': alive=%d team=%d zombie=%d class=%s subclass=%s model=%s entity_model=%s health=%d speed=%d gravity=%.2f.",
		id,
		name,
		is_user_alive(id),
		_:team,
		IsZombie(id),
		classHandle,
		subclassHandle,
		modelHandle,
		entityModel,
		health,
		speed,
		gravity);
}

stock bool:PrepareRoundFlowModelPath(Subclass:subclass)
{
	new Class:class = Class:get_subclass_var(subclass, "class");
	if (class == Invalid_Class)
		return DevError("Round flow subclass has no parent class.");

	new Model:model = GetRuntimeModel(class, subclass);
	if (model == Invalid_Model)
		return DevError("Round flow subclass has no runtime model.");

	if (!get_model_var(model, "path", RoundFlowZombieModelPath, charsmax(RoundFlowZombieModelPath)))
		return DevError("Round flow subclass model has no path.");

	return true;
}

stock RequestMissingBots(missingPlayers)
{
	if (missingPlayers <= 0)
		return;

	if (missingPlayers > DEV_MAX_BOTS_PER_COMMAND)
		missingPlayers = DEV_MAX_BOTS_PER_COMMAND;

	for (new index = 0; index < missingPlayers; index++)
		server_cmd("sypb_add");

	server_exec();
	DevInfo("Round flow requested %d missing bot(s).", missingPlayers);
}

stock bool:ValidateAliveHumans(const stage[])
{
	new alivePlayers;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id) || !IsPlayerOnPlayableGameTeam(id))
			continue;

		alivePlayers++;

		if (!ValidateRoundFlowHuman(id, stage))
			return false;
	}

	if (alivePlayers < RoundFlowRequiredPlayers)
		return DevError("Round flow %s expected at least %d alive playable players.", stage, RoundFlowRequiredPlayers);

	return true;
}

stock bool:ValidateRoundFlowHuman(id, const stage[])
{
	new Class:class = FindRequiredClass(DEV_DEFAULT_HUMAN_CLASS);
	if (class == Invalid_Class)
		return false;

	if (!is_user_alive(id))
		return DevError("Round flow %s expected player %d alive.", stage, id);

	if (!IsHuman(id))
		return DevError("Round flow %s expected player %d human.", stage, id);

	if (get_member(id, m_iTeam) != TEAM_CT)
		return DevError("Round flow %s expected human player %d on CT team.", stage, id);

	if (get_player_class(id) != class)
		return DevError("Round flow %s expected player %d class human.", stage, id);

	if (get_player_subclass(id) != Invalid_Subclass)
		return DevError("Round flow %s expected player %d without subclass.", stage, id);

	if (!ValidatePlayer(id))
		return false;

	new entityModel[RZ_MAX_RESOURCE_PATH_LENGTH];
	get_entvar(id, var_model, entityModel, charsmax(entityModel));

	if (equal(entityModel, RoundFlowZombieModelPath))
		return DevError("Round flow %s player %d kept zombie model '%s'.", stage, id, entityModel);

	return true;
}

stock bool:ValidateRoundFlowZombie(id)
{
	new Class:class = FindRequiredClass(DEV_DEFAULT_ZOMBIE_CLASS);
	if (class == Invalid_Class)
		return false;

	if (!is_user_alive(id))
		return DevError("Round flow expected infected player %d alive.", id);

	if (!IsZombie(id))
		return DevError("Round flow expected infected player %d zombie.", id);

	if (get_member(id, m_iTeam) != TEAM_TERRORIST)
		return DevError("Round flow expected infected player %d on Terrorist team.", id);

	if (get_player_class(id) != class)
		return DevError("Round flow expected infected player %d class zombie.", id);

	if (get_player_subclass(id) != RoundFlowSubclass)
		return DevError("Round flow expected infected player %d subclass '%s'.", id, RoundFlowSubclassHandle);

	if (!ValidatePlayer(id))
		return false;

	new entityModel[RZ_MAX_RESOURCE_PATH_LENGTH];
	get_entvar(id, var_model, entityModel, charsmax(entityModel));

	if (!equal(entityModel, RoundFlowZombieModelPath))
		return DevError("Round flow expected infected player %d model '%s', got '%s'.", id, RoundFlowZombieModelPath, entityModel);

	return true;
}

stock CountAlivePlayablePlayers()
{
	new count;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id) && is_user_alive(id) && IsPlayerOnPlayableGameTeam(id))
			count++;
	}

	return count;
}

stock FindFirstAlivePlayablePlayer()
{
	for (new id = 1; id <= MaxClients; id++)
	{
		if (IsAlivePlayablePlayer(id))
			return id;
	}

	return 0;
}

stock bool:IsAlivePlayablePlayer(id)
{
	return is_user_connected(id) && is_user_alive(id) && IsPlayerOnPlayableGameTeam(id);
}

stock bool:ArePlayersTooClose(first, second)
{
	new Float:firstOrigin[3];
	new Float:secondOrigin[3];

	get_entvar(first, var_origin, firstOrigin);
	get_entvar(second, var_origin, secondOrigin);

	return GetOriginDistanceSquared(firstOrigin, secondOrigin) < (DEV_MIN_SPAWN_DISTANCE * DEV_MIN_SPAWN_DISTANCE);
}

stock Float:GetOriginDistanceSquared(Float:firstOrigin[3], Float:secondOrigin[3])
{
	new Float:deltaX = firstOrigin[0] - secondOrigin[0];
	new Float:deltaY = firstOrigin[1] - secondOrigin[1];
	new Float:deltaZ = firstOrigin[2] - secondOrigin[2];

	return (deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ);
}

stock bool:IsPlayerOnPlayableGameTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);

	return team == TEAM_TERRORIST || team == TEAM_CT;
}

stock StopRoundFlow()
{
	RoundFlowState = DevRoundFlowIdle;
	RoundFlowSubclass = Invalid_Subclass;
	RoundFlowVictim = 0;
	RoundFlowRequiredPlayers = 0;
	RoundFlowBotsRequested = false;
	RoundFlowNextCheckAt = 0.0;
	RoundFlowTimeoutAt = 0.0;
	RoundFlowSubclassHandle[0] = EOS;
	RoundFlowZombieModelPath[0] = EOS;
	BlockNextChangeClassPre = false;
	BlockNextInfectPlayerPre = false;
}

stock FailRoundFlow(const message[], any:...)
{
	new formatted[512];
	vformat(formatted, charsmax(formatted), message, 2);

	DevError("%s", formatted);
	StopRoundFlow();
}

#include <rezombie/dev/DevRuntimeSupport>
