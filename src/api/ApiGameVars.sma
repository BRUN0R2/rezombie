#include <amxmodx>
#include <rezombie_version>
#include <rezombie_const>
#include <rezombie_stock>
#include <rezombie/core/RoundState>
#include <rezombie/api/Classes>
#include <rezombie/api/Modes>

#pragma semicolon 1
#pragma compress 1

new const GAME_VARS_WRITER_PLUGIN[] = "GameRules.amxx";

enum _:GameVarsRuntimeData
{
	GameState:GameVarsGameState,
	RoundState:GameVarsRoundState,
	Mode:GameVarsMode,
	Float:GameVarsTimer,
	GameVarsHumanWins,
	GameVarsZombieWins,
	Team:GameVarsRespawnTeam,
	Class:GameVarsDefaultClass,
	bool:GameVarsOverrideDefaultClass
};

new GameVarsRuntime[GameVarsRuntimeData];

public plugin_natives()
{
	register_library("ApiGameVars");

	register_native("get_game_var", "NativeGetGameVar");
	register_native("sync_game_vars", "NativeSyncGameVars");
}

public plugin_precache()
{
	register_plugin("API: Game Vars", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	ResetGameVarsRuntime();
}

public any:NativeGetGameVar(plugin, params)
{
	enum
	{
		GetGameVarParamKey = 1,
		GetGameVarParamValue
	};

	#pragma unused plugin

	if (params < GetGameVarParamKey)
		return ReportNativeError("get_game_var requires property name.");

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetGameVarParamKey, key, charsmax(key));

	if (equal(key, "game_state"))
		return GameVarsRuntime[GameVarsGameState];

	if (equal(key, "round_state"))
		return GameVarsRuntime[GameVarsRoundState];

	if (equal(key, "mode"))
		return GameVarsRuntime[GameVarsMode];

	if (equal(key, "timer"))
		return GameVarsRuntime[GameVarsTimer];

	if (equal(key, "human_wins"))
		return GameVarsRuntime[GameVarsHumanWins];

	if (equal(key, "zombie_wins"))
		return GameVarsRuntime[GameVarsZombieWins];

	if (equal(key, "team_wins"))
	{
		if (params < GetGameVarParamValue)
			return ReportNativeError("get_game_var 'team_wins' requires team.");

		new Team:team = Team:get_param(GetGameVarParamValue);

		return GetTeamWins(team);
	}

	if (equal(key, "respawn_team"))
		return GameVarsRuntime[GameVarsRespawnTeam];

	if (equal(key, "default_class"))
		return GameVarsRuntime[GameVarsDefaultClass];

	if (equal(key, "override_default_class"))
		return GameVarsRuntime[GameVarsOverrideDefaultClass];

	return ReportNativeError("Invalid game property '%s'.", key);
}

public bool:NativeSyncGameVars(plugin, params)
{
	enum
	{
		SyncGameVarsParamGameState = 1,
		SyncGameVarsParamRoundState,
		SyncGameVarsParamMode,
		SyncGameVarsParamTimer,
		SyncGameVarsParamHumanWins,
		SyncGameVarsParamZombieWins,
		SyncGameVarsParamRespawnTeam,
		SyncGameVarsParamDefaultClass,
		SyncGameVarsParamOverrideDefaultClass
	};

	if (!IsGameRulesCaller(plugin))
		return bool:ReportNativeError("sync_game_vars can only be called by GameRules.");

	if (params < SyncGameVarsParamOverrideDefaultClass)
		return bool:ReportNativeError("sync_game_vars requires a complete snapshot.");

	new GameState:gameState = GameState:get_param(SyncGameVarsParamGameState);
	new RoundState:roundState = RoundState:get_param(SyncGameVarsParamRoundState);
	new Mode:mode = Mode:get_param(SyncGameVarsParamMode);
	new Float:timer = get_param_f(SyncGameVarsParamTimer);
	new humanWins = get_param(SyncGameVarsParamHumanWins);
	new zombieWins = get_param(SyncGameVarsParamZombieWins);
	new Team:respawnTeam = Team:get_param(SyncGameVarsParamRespawnTeam);
	new Class:defaultClass = Class:get_param(SyncGameVarsParamDefaultClass);
	new bool:overrideDefaultClass = bool:get_param(SyncGameVarsParamOverrideDefaultClass);

	if (!IsValidGameState(gameState))
		return bool:ReportNativeError("Invalid game state %d.", _:gameState);

	if (!IsValidRoundState(roundState))
		return bool:ReportNativeError("Invalid round state %d.", _:roundState);

	if (timer < 0.0)
		return bool:ReportNativeError("Game timer cannot be negative.");

	if (humanWins < 0 || zombieWins < 0)
		return bool:ReportNativeError("Team wins cannot be negative.");

	if (IsActiveRoundState(roundState) && !IsRegisteredMode(mode))
		return bool:ReportNativeError("Active round snapshot requires a registered mode.");

	if (!IsPlayableRespawnTeam(respawnTeam))
		return bool:ReportNativeError("Invalid respawn team %d.", _:respawnTeam);

	if (!IsRegisteredClass(defaultClass))
		return bool:ReportNativeError("Invalid default class %d.", _:defaultClass);

	if (GetClassTeam(defaultClass) != respawnTeam)
		return bool:ReportNativeError("Default class %d does not match respawn team %d.", _:defaultClass, _:respawnTeam);

	GameVarsRuntime[GameVarsGameState] = gameState;
	GameVarsRuntime[GameVarsRoundState] = roundState;
	GameVarsRuntime[GameVarsMode] = mode;
	GameVarsRuntime[GameVarsTimer] = timer;
	GameVarsRuntime[GameVarsHumanWins] = humanWins;
	GameVarsRuntime[GameVarsZombieWins] = zombieWins;
	GameVarsRuntime[GameVarsRespawnTeam] = respawnTeam;
	GameVarsRuntime[GameVarsDefaultClass] = defaultClass;
	GameVarsRuntime[GameVarsOverrideDefaultClass] = overrideDefaultClass;

	return true;
}

stock ResetGameVarsRuntime()
{
	GameVarsRuntime[GameVarsGameState] = GameStateWarmup;
	GameVarsRuntime[GameVarsRoundState] = RoundStateNone;
	GameVarsRuntime[GameVarsMode] = Invalid_Mode;
	GameVarsRuntime[GameVarsTimer] = 0.0;
	GameVarsRuntime[GameVarsHumanWins] = 0;
	GameVarsRuntime[GameVarsZombieWins] = 0;
	GameVarsRuntime[GameVarsRespawnTeam] = TEAM_HUMAN;
	GameVarsRuntime[GameVarsDefaultClass] = Invalid_Class;
	GameVarsRuntime[GameVarsOverrideDefaultClass] = false;
}

stock GetTeamWins(Team:team)
{
	switch (team)
	{
		case TEAM_HUMAN:
			return GameVarsRuntime[GameVarsHumanWins];
		case TEAM_ZOMBIE:
			return GameVarsRuntime[GameVarsZombieWins];
	}

	return ReportNativeError("Invalid team_wins team %d.", _:team);
}

stock bool:IsGameRulesCaller(plugin)
{
	new filename[64];
	get_plugin(plugin, filename, charsmax(filename));

	new basename[64];
	GetPluginBasename(filename, basename, charsmax(basename));

	return bool:equal(basename, GAME_VARS_WRITER_PLUGIN);
}

stock GetPluginBasename(const filename[], basename[], length)
{
	new start;
	for (new index = 0; filename[index] != EOS; index++)
	{
		if (filename[index] == '/' || filename[index] == 92)
			start = index + 1;
	}

	copy(basename, length, filename[start]);
}

stock bool:IsValidGameState(GameState:gameState)
{
	switch (gameState)
	{
		case GameStateWarmup, GameStateNeedPlayers, GameStatePlaying, GameStateOver:
			return true;
	}

	return false;
}

stock bool:IsValidRoundState(RoundState:roundState)
{
	switch (roundState)
	{
		case RoundStateNone, RoundStatePrepare, RoundStatePlaying, RoundStateTerminate:
			return true;
	}

	return false;
}

stock bool:IsActiveRoundState(RoundState:roundState)
{
	return roundState == RoundStatePrepare || roundState == RoundStatePlaying;
}

stock bool:IsPlayableRespawnTeam(Team:team)
{
	return team == TEAM_HUMAN || team == TEAM_ZOMBIE;
}

stock bool:IsRegisteredMode(Mode:mode)
{
	if (mode == Invalid_Mode)
		return false;

	new handle[RZ_MAX_HANDLE_LENGTH];

	return bool:get_mode_var(mode, "handle", handle, charsmax(handle));
}

stock bool:IsRegisteredClass(Class:class)
{
	if (class == Invalid_Class)
		return false;

	new Team:team = GetClassTeam(class);
	return team == TEAM_HUMAN || team == TEAM_ZOMBIE;
}

stock Team:GetClassTeam(Class:class)
{
	return Team:get_class_var(class, "team");
}
