#include <amxmodx>
#include <reapi>
#include <fakemeta>
#include <rezombie_version>
#include <rezombie_const>
#include <rezombie/api/Classes>
#include <rezombie/api/Modes>
#include <rezombie/api/Players>
#include <rezombie/core/GameVars>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

const GAME_RULES_FORWARD_INVALID = -1;

const Float:GAME_RULES_WARMUP_SECONDS = 40.0;
const Float:GAME_RULES_PREPARE_SECONDS = 20.0;
const Float:GAME_RULES_WARMUP_RESTART_SECONDS = 3.0;
const Float:GAME_RULES_RESTART_SECONDS = 5.0;

new const GAME_RULES_DEFAULT_HUMAN_CLASS[] = "human";
new const GAME_RULES_DEFAULT_ZOMBIE_CLASS[] = "zombie";

enum _:GameRulesRuntimeData
{
	GameState:GameRulesGameState,
	RoundState:GameRulesRoundState,
	Mode:GameRulesMode,
	Float:GameRulesStateEndsAt,
	GameRulesTimer,
	EndRoundEvent:GameRulesTerminateEvent,
	GameRulesHumanWins,
	GameRulesZombieWins
};

enum _:GameRulesForwardData
{
	GameRulesForwardRoundPrepare,
	GameRulesForwardRoundStart,
	GameRulesForwardRoundEnd,
	GameRulesForwardRoundTimer,
	GameRulesForwardGameStateChanged,
	GameRulesForwardRoundStateChanged,
	GameRulesForwardCount
};

enum _:GameRulesHookData
{
	GameRulesHookRestartRound,
	GameRulesHookCheckWinConditions,
	GameRulesHookCount
};

new GameRulesRuntime[GameRulesRuntimeData];
new GameRulesForwards[GameRulesForwardCount];
new HookChain:GameRulesHooks[GameRulesHookCount];
new bool:GameRulesLaunchingMode;

public plugin_init()
{
	register_plugin("Core: Game Rules", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	CreateGameRulesForwards();
	CreateGameRulesHooks();

	register_forward(FM_StartFrame, "OnServerFrame");
}

public plugin_cfg()
{
	ResetGameRulesRuntime();
	RefreshRoundFlow();
}

public plugin_end()
{
	for (new index = 0; index < sizeof GameRulesHooks; index++)
	{
		if (GameRulesHooks[index] == INVALID_HOOKCHAIN)
			continue;

		DisableHookChain(GameRulesHooks[index]);
		GameRulesHooks[index] = INVALID_HOOKCHAIN;
	}

	for (new index = 0; index < sizeof GameRulesForwards; index++)
	{
		if (GameRulesForwards[index] == GAME_RULES_FORWARD_INVALID)
			continue;

		DestroyForward(GameRulesForwards[index]);
		GameRulesForwards[index] = GAME_RULES_FORWARD_INVALID;
	}
}

public OnGameDllRestartRoundPre()
{
	RefreshRoundFlow();
	return HC_CONTINUE;
}

public OnGameDllCheckWinConditionsPre()
{
	EvaluateRoundWinConditions(get_gametime());
	return HC_SUPERCEDE;
}

public OnServerFrame()
{
	new Float:now = get_gametime();

	switch (GameRulesRuntime[GameRulesRoundState])
	{
		case RoundStateNone:
		{
			UpdateWaitingRoundFlow(now);
		}
		case RoundStatePrepare:
		{
			UpdateRoundTimer(now);

			if (now >= GameRulesRuntime[GameRulesStateEndsAt])
				BeginRoundPlaying(now);
		}
		case RoundStatePlaying:
		{
			UpdateRoundTimer(now);
			EvaluateRoundWinConditions(now);
		}
		case RoundStateTerminate:
		{
			UpdateRoundTimer(now);

			if (now >= GameRulesRuntime[GameRulesStateEndsAt])
				CompleteTerminatedRound(now);
		}
	}

	return FMRES_IGNORED;
}

stock ResetGameRulesRuntime()
{
	GameRulesRuntime[GameRulesGameState] = GameStateWarmup;
	GameRulesRuntime[GameRulesRoundState] = RoundStateNone;
	GameRulesRuntime[GameRulesMode] = Invalid_Mode;
	GameRulesRuntime[GameRulesStateEndsAt] = 0.0;
	GameRulesRuntime[GameRulesTimer] = 0;
	GameRulesRuntime[GameRulesTerminateEvent] = EndRoundEventNone;
	GameRulesRuntime[GameRulesHumanWins] = 0;
	GameRulesRuntime[GameRulesZombieWins] = 0;
	GameRulesLaunchingMode = false;

	PublishGameVars();
}

stock RefreshRoundFlow()
{
	new Float:now = get_gametime();

	if (GameRulesRuntime[GameRulesGameState] == GameStateWarmup)
	{
		BeginWarmup(now);
		return;
	}

	if (!HasEnoughRoundParticipants())
	{
		EnterWaitingState();
		return;
	}

	BeginRoundPrepare(now);
}

stock EnterWaitingState()
{
	new GameState:oldGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:oldRoundState = GameRulesRuntime[GameRulesRoundState];
	new oldTimer = GameRulesRuntime[GameRulesTimer];
	new bool:changed = false;

	changed = SetGameState(GameStateNeedPlayers) || changed;
	changed = SetRoundState(RoundStateNone) || changed;
	changed = SetRoundMode(Invalid_Mode) || changed;
	changed = SetRoundTimer(0) || changed;

	GameRulesRuntime[GameRulesStateEndsAt] = 0.0;

	if (changed)
		CommitGameRulesSnapshot(oldGameState, oldRoundState, oldTimer);
}

stock UpdateWaitingRoundFlow(Float:now)
{
	switch (GameRulesRuntime[GameRulesGameState])
	{
		case GameStatePlaying:
		{
			if (HasEnoughRoundParticipants())
				BeginRoundPrepare(now);
			else
				EnterWaitingState();
		}
		case GameStateWarmup:
		{
			if (GameRulesRuntime[GameRulesStateEndsAt] <= 0.0)
				BeginWarmup(now);

			UpdateRoundTimer(now);

			if (now < GameRulesRuntime[GameRulesStateEndsAt])
				return;

			EndRound(EndRoundEventWarmupEnd, now);
		}
		default:
		{
			if (HasEnoughRoundParticipants())
				BeginRoundPrepare(now);
			else
				EnterWaitingState();
		}
	}
}

stock BeginWarmup(Float:now)
{
	new GameState:oldGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:oldRoundState = GameRulesRuntime[GameRulesRoundState];
	new oldTimer = GameRulesRuntime[GameRulesTimer];

	SetGameState(GameStateWarmup);
	SetRoundState(RoundStateNone);
	SetRoundMode(Invalid_Mode);
	GameRulesRuntime[GameRulesTerminateEvent] = EndRoundEventNone;
	SetStateWindow(now, GAME_RULES_WARMUP_SECONDS);
	CommitGameRulesSnapshot(oldGameState, oldRoundState, oldTimer);
}

stock BeginRoundPrepare(Float:now)
{
	new Mode:mode = SelectRoundMode();
	if (mode == Invalid_Mode)
	{
		EnterWaitingState();
		return;
	}

	new GameState:oldGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:oldRoundState = GameRulesRuntime[GameRulesRoundState];
	new oldTimer = GameRulesRuntime[GameRulesTimer];

	SetGameState(GameStatePlaying);
	SetRoundState(RoundStatePrepare);
	SetRoundMode(mode);
	GameRulesRuntime[GameRulesTerminateEvent] = EndRoundEventNone;
	SetStateWindow(now, GAME_RULES_PREPARE_SECONDS);
	CommitGameRulesSnapshot(oldGameState, oldRoundState, oldTimer);

	ExecuteRoundPrepare(mode, GAME_RULES_PREPARE_SECONDS);
}

stock BeginRoundPlaying(Float:now)
{
	new Mode:mode = GameRulesRuntime[GameRulesMode];
	new Float:duration = GetModeRoundTime(mode);
	new GameState:oldGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:oldRoundState = GameRulesRuntime[GameRulesRoundState];
	new oldTimer = GameRulesRuntime[GameRulesTimer];

	GameRulesLaunchingMode = true;
	SetRoundState(RoundStatePlaying);
	GameRulesRuntime[GameRulesTerminateEvent] = EndRoundEventNone;
	SetStateWindow(now, duration);
	CommitGameRulesSnapshot(oldGameState, oldRoundState, oldTimer);

	new bool:launched = launch_mode(mode, RZ_MODE_NO_TARGET);
	GameRulesLaunchingMode = false;

	if (!launched)
		set_fail_state("GameRules could not launch selected mode %d.", _:mode);

	ExecuteRoundStart(mode, duration);
	EvaluateRoundWinConditions(now);
}

stock EndRound(EndRoundEvent:event, Float:now)
{
	if (GameRulesRuntime[GameRulesRoundState] == RoundStateTerminate)
		return;

	new GameState:oldGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:oldRoundState = GameRulesRuntime[GameRulesRoundState];
	new oldTimer = GameRulesRuntime[GameRulesTimer];

	switch (event)
	{
		case EndRoundEventHumansWin:
			GameRulesRuntime[GameRulesHumanWins]++;
		case EndRoundEventZombiesWin:
			GameRulesRuntime[GameRulesZombieWins]++;
	}

	SetRoundState(RoundStateTerminate);
	GameRulesRuntime[GameRulesTerminateEvent] = event;
	SetStateWindow(now, GetEndRoundDelay(event));
	CommitGameRulesSnapshot(oldGameState, oldRoundState, oldTimer);

	ExecuteRoundEnd(event);
}

stock Float:GetEndRoundDelay(EndRoundEvent:event)
{
	if (event == EndRoundEventWarmupEnd)
		return GAME_RULES_WARMUP_RESTART_SECONDS;

	return GAME_RULES_RESTART_SECONDS;
}

stock CompleteTerminatedRound(Float:now)
{
	if (GameRulesRuntime[GameRulesTerminateEvent] == EndRoundEventWarmupEnd)
		CompleteWarmupTermination(now);

	rg_restart_round();
}

stock CompleteWarmupTermination(Float:now)
{
	new GameState:oldGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:oldRoundState = GameRulesRuntime[GameRulesRoundState];
	new oldTimer = GameRulesRuntime[GameRulesTimer];
	new bool:changed = false;

	if (HasEnoughRoundParticipants())
		changed = SetGameState(GameStatePlaying) || changed;
	else
		changed = SetGameState(GameStateNeedPlayers) || changed;

	changed = SetRoundState(RoundStateNone) || changed;
	changed = SetRoundMode(Invalid_Mode) || changed;
	changed = SetRoundTimer(0) || changed;

	GameRulesRuntime[GameRulesTerminateEvent] = EndRoundEventNone;
	GameRulesRuntime[GameRulesStateEndsAt] = now;

	if (changed)
		CommitGameRulesSnapshot(oldGameState, oldRoundState, oldTimer);
}

stock bool:EvaluateRoundWinConditions(Float:now)
{
	if (!CanEvaluateRoundWinConditions())
		return false;

	new humans = CountAliveTeamPlayers(TEAM_HUMAN);
	new zombies = CountAliveTeamPlayers(TEAM_ZOMBIE);

	if (humans <= 0 && zombies <= 0)
	{
		EndRound(EndRoundEventEndDraw, now);
		return true;
	}

	if (humans <= 0)
	{
		EndRound(EndRoundEventZombiesWin, now);
		return true;
	}

	if (zombies <= 0)
	{
		EndRound(EndRoundEventHumansWin, now);
		return true;
	}

	if (now >= GameRulesRuntime[GameRulesStateEndsAt])
	{
		EndRound(EndRoundEventHumansWin, now);
		return true;
	}

	return false;
}

stock bool:CanEvaluateRoundWinConditions()
{
	return !GameRulesLaunchingMode
		&& GameRulesRuntime[GameRulesGameState] == GameStatePlaying
		&& GameRulesRuntime[GameRulesRoundState] == RoundStatePlaying;
}

stock Mode:SelectRoundMode()
{
	new modesCount = get_modes_count();
	if (modesCount <= 0)
		set_fail_state("GameRules could not select a mode because no mode is registered.");

	new players = CountRoundParticipants();

	for (new index = 0; index < modesCount; index++)
	{
		new Mode:mode = get_mode(index);

		if (players >= GetModeMinPlayers(mode))
			return mode;
	}

	return Invalid_Mode;
}

stock GetModeMinPlayers(Mode:mode)
{
	if (mode == Invalid_Mode)
		set_fail_state("GameRules received invalid mode for min_players.");

	new minPlayers = get_mode_var(mode, "min_players");
	if (minPlayers <= 0)
		set_fail_state("GameRules received invalid min_players %d for mode %d.", minPlayers, _:mode);

	return minPlayers;
}

stock Float:GetModeRoundTime(Mode:mode)
{
	if (mode == Invalid_Mode)
		set_fail_state("GameRules received invalid mode for round time.");

	new Float:roundTime = get_mode_var(mode, "round_time");
	if (roundTime <= 0.0)
		set_fail_state("GameRules received invalid round_time %.2f for mode %d.", roundTime, _:mode);

	return roundTime;
}

stock RespawnType:GetModeRespawnType(Mode:mode)
{
	if (mode == Invalid_Mode)
		set_fail_state("GameRules received invalid mode for respawn policy.");

	return RespawnType:get_mode_var(mode, "respawn");
}

stock Class:GetModeDefaultClass(Mode:mode)
{
	if (mode == Invalid_Mode)
		set_fail_state("GameRules received invalid mode for default class.");

	return Class:get_mode_var(mode, "default_class");
}

stock bool:GetModeOverrideDefaultClass(Mode:mode)
{
	if (mode == Invalid_Mode)
		set_fail_state("GameRules received invalid mode for default class override.");

	return bool:get_mode_var(mode, "override_default_class");
}

stock Team:GetClassTeam(Class:class)
{
	if (class == Invalid_Class)
		set_fail_state("GameRules received invalid class for team resolution.");

	return Team:get_class_var(class, "team");
}

stock SetStateWindow(Float:now, Float:duration)
{
	if (duration <= 0.0)
		set_fail_state("GameRules received invalid duration %.2f.", duration);

	GameRulesRuntime[GameRulesStateEndsAt] = now + duration;
	SetRoundTimer(floatround(duration, floatround_ceil));
}

stock UpdateRoundTimer(Float:now)
{
	new timer = GetRemainingSeconds(now);
	if (timer == GameRulesRuntime[GameRulesTimer])
		return;

	new GameState:oldGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:oldRoundState = GameRulesRuntime[GameRulesRoundState];
	new oldTimer = GameRulesRuntime[GameRulesTimer];

	SetRoundTimer(timer);
	CommitGameRulesSnapshot(oldGameState, oldRoundState, oldTimer);
}

stock GetRemainingSeconds(Float:now)
{
	new Float:remaining = GameRulesRuntime[GameRulesStateEndsAt] - now;
	if (remaining <= 0.0)
		return 0;

	return floatround(remaining, floatround_ceil);
}

stock bool:SetGameState(GameState:gameState)
{
	if (GameRulesRuntime[GameRulesGameState] == gameState)
		return false;

	GameRulesRuntime[GameRulesGameState] = gameState;

	return true;
}

stock bool:SetRoundState(RoundState:roundState)
{
	if (GameRulesRuntime[GameRulesRoundState] == roundState)
		return false;

	GameRulesRuntime[GameRulesRoundState] = roundState;

	return true;
}

stock bool:SetRoundMode(Mode:mode)
{
	if (GameRulesRuntime[GameRulesMode] == mode)
		return false;

	GameRulesRuntime[GameRulesMode] = mode;
	return true;
}

stock bool:SetRoundTimer(timer)
{
	if (timer < 0)
		set_fail_state("GameRules received negative timer %d.", timer);

	if (GameRulesRuntime[GameRulesTimer] == timer)
		return false;

	GameRulesRuntime[GameRulesTimer] = timer;
	return true;
}

stock CommitGameRulesSnapshot(GameState:oldGameState, RoundState:oldRoundState, oldTimer)
{
	PublishGameVars();

	new GameState:newGameState = GameRulesRuntime[GameRulesGameState];
	new RoundState:newRoundState = GameRulesRuntime[GameRulesRoundState];
	new newTimer = GameRulesRuntime[GameRulesTimer];

	if (oldGameState != newGameState)
		ExecuteGameStateChanged(oldGameState, newGameState);

	if (oldRoundState != newRoundState)
		ExecuteRoundStateChanged(oldRoundState, newRoundState);

	if (oldTimer != newTimer)
		ExecuteRoundTimer(newTimer);
}

stock PublishGameVars()
{
	new Team:respawnTeam = GetRespawnTeam();
	new Class:defaultClass = GetDefaultClass(respawnTeam);
	new bool:overrideDefaultClass = IsDefaultClassOverridden();

	if (!sync_game_vars(
		GameRulesRuntime[GameRulesGameState],
		GameRulesRuntime[GameRulesRoundState],
		GameRulesRuntime[GameRulesMode],
		float(GameRulesRuntime[GameRulesTimer]),
		GameRulesRuntime[GameRulesHumanWins],
		GameRulesRuntime[GameRulesZombieWins],
		respawnTeam,
		defaultClass,
		overrideDefaultClass
	))
	{
		set_fail_state("GameRules could not publish game vars.");
	}
}

stock Team:GetRespawnTeam()
{
	if (GameRulesRuntime[GameRulesGameState] != GameStatePlaying)
		return TEAM_HUMAN;

	if (GameRulesRuntime[GameRulesRoundState] != RoundStatePlaying)
		return TEAM_HUMAN;

	new Mode:mode = GameRulesRuntime[GameRulesMode];
	if (mode == Invalid_Mode)
		set_fail_state("GameRules could not resolve respawn team without an active mode.");

	new RespawnType:respawn = GetModeRespawnType(mode);

	switch (respawn)
	{
		case Respawn_ToZombiesTeam: return TEAM_ZOMBIE;
		case Respawn_Balance: return GetBalancedRespawnTeam();
		case Respawn_Off, Respawn_ToHumansTeam: return TEAM_HUMAN;
	}

	set_fail_state("GameRules received invalid respawn policy %d.", _:respawn);
	return TEAM_NONE;
}

stock Class:GetDefaultClass(Team:respawnTeam)
{
	if (IsDefaultClassOverridden())
	{
		new Mode:mode = GameRulesRuntime[GameRulesMode];
		new Class:defaultClass = GetModeDefaultClass(mode);

		if (defaultClass == Invalid_Class)
			set_fail_state("GameRules active mode has override_default_class without default_class.");

		if (GetClassTeam(defaultClass) != respawnTeam)
			set_fail_state("GameRules mode default_class %d does not match respawn team %d.", _:defaultClass, _:respawnTeam);

		return defaultClass;
	}

	return GetFallbackDefaultClass(respawnTeam);
}

stock bool:IsDefaultClassOverridden()
{
	if (GameRulesRuntime[GameRulesGameState] != GameStatePlaying)
		return false;

	if (GameRulesRuntime[GameRulesRoundState] != RoundStatePlaying)
		return false;

	new Mode:mode = GameRulesRuntime[GameRulesMode];
	if (mode == Invalid_Mode)
		return false;

	return GetModeOverrideDefaultClass(mode);
}

stock Class:GetFallbackDefaultClass(Team:team)
{
	switch (team)
	{
		case TEAM_HUMAN: return RequireClass(GAME_RULES_DEFAULT_HUMAN_CLASS);
		case TEAM_ZOMBIE: return RequireClass(GAME_RULES_DEFAULT_ZOMBIE_CLASS);
	}

	set_fail_state("GameRules could not resolve fallback class for team %d.", _:team);
	return Invalid_Class;
}

stock Team:GetBalancedRespawnTeam()
{
	if (CountAliveTeamPlayers(TEAM_HUMAN) >= CountAliveTeamPlayers(TEAM_ZOMBIE))
		return TEAM_ZOMBIE;

	return TEAM_HUMAN;
}

stock bool:HasEnoughRoundParticipants()
{
	return SelectRoundMode() != Invalid_Mode;
}

stock CountRoundParticipants()
{
	new count;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id) && !is_user_hltv(id))
			count++;
	}

	return count;
}

stock CountAliveTeamPlayers(Team:team)
{
	new count;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (!is_user_connected(id) || !is_user_alive(id))
			continue;

		if (!IsPlayerOnPlayableTeam(id))
			continue;

		if (team == TEAM_HUMAN && IsHuman(id))
			count++;
		else if (team == TEAM_ZOMBIE && IsZombie(id))
			count++;
	}

	return count;
}

stock bool:IsPlayerOnPlayableTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);

	return team == TEAM_TERRORIST || team == TEAM_CT;
}

stock CreateGameRulesHooks()
{
	ResetGameRulesHooks();

	GameRulesHooks[GameRulesHookRestartRound] = RegisterRequiredGameRulesHook(
		.functionId = RG_CSGameRules_RestartRound,
		.callback = "OnGameDllRestartRoundPre",
		.post = false
	);

	GameRulesHooks[GameRulesHookCheckWinConditions] = RegisterRequiredGameRulesHook(
		.functionId = RG_CSGameRules_CheckWinConditions,
		.callback = "OnGameDllCheckWinConditionsPre",
		.post = false
	);
}

stock ResetGameRulesHooks()
{
	for (new index = 0; index < sizeof GameRulesHooks; index++)
		GameRulesHooks[index] = INVALID_HOOKCHAIN;
}

stock HookChain:RegisterRequiredGameRulesHook(ReAPIFunc:functionId, const callback[], bool:post)
{
	new HookChain:hookChain = RegisterHookChain(
		.function_id = functionId,
		.callback = callback,
		.post = post
	);
	if (hookChain == INVALID_HOOKCHAIN)
		set_fail_state("GameRules could not register ReAPI hook '%s'.", callback);

	return hookChain;
}

stock CreateGameRulesForwards()
{
	for (new index = 0; index < sizeof GameRulesForwards; index++)
		GameRulesForwards[index] = GAME_RULES_FORWARD_INVALID;

	GameRulesForwards[GameRulesForwardRoundPrepare] = CreateMultiForward("@round_prepare", ET_IGNORE, FP_CELL, FP_FLOAT);
	GameRulesForwards[GameRulesForwardRoundStart] = CreateMultiForward("@round_start", ET_IGNORE, FP_CELL, FP_FLOAT);
	GameRulesForwards[GameRulesForwardRoundEnd] = CreateMultiForward("@round_end", ET_IGNORE, FP_CELL);
	GameRulesForwards[GameRulesForwardRoundTimer] = CreateMultiForward("@round_timer", ET_IGNORE, FP_CELL);
	GameRulesForwards[GameRulesForwardGameStateChanged] = CreateMultiForward("@game_state_changed", ET_IGNORE, FP_CELL, FP_CELL);
	GameRulesForwards[GameRulesForwardRoundStateChanged] = CreateMultiForward("@round_state_changed", ET_IGNORE, FP_CELL, FP_CELL);

	RequireGameRulesForward(GameRulesForwards[GameRulesForwardRoundPrepare], "@round_prepare");
	RequireGameRulesForward(GameRulesForwards[GameRulesForwardRoundStart], "@round_start");
	RequireGameRulesForward(GameRulesForwards[GameRulesForwardRoundEnd], "@round_end");
	RequireGameRulesForward(GameRulesForwards[GameRulesForwardRoundTimer], "@round_timer");
	RequireGameRulesForward(GameRulesForwards[GameRulesForwardGameStateChanged], "@game_state_changed");
	RequireGameRulesForward(GameRulesForwards[GameRulesForwardRoundStateChanged], "@round_state_changed");
}

stock RequireGameRulesForward(forwardId, const forwardName[])
{
	if (forwardId == GAME_RULES_FORWARD_INVALID)
		set_fail_state("GameRules could not create forward '%s'.", forwardName);
}

stock ExecuteRoundPrepare(Mode:mode, Float:duration)
{
	new forwardResult;
	if (!ExecuteForward(GameRulesForwards[GameRulesForwardRoundPrepare], forwardResult, mode, duration))
		set_fail_state("GameRules could not execute @round_prepare.");
}

stock ExecuteRoundStart(Mode:mode, Float:duration)
{
	new forwardResult;
	if (!ExecuteForward(GameRulesForwards[GameRulesForwardRoundStart], forwardResult, mode, duration))
		set_fail_state("GameRules could not execute @round_start.");
}

stock ExecuteRoundEnd(EndRoundEvent:event)
{
	new forwardResult;
	if (!ExecuteForward(GameRulesForwards[GameRulesForwardRoundEnd], forwardResult, event))
		set_fail_state("GameRules could not execute @round_end.");
}

stock ExecuteRoundTimer(timer)
{
	new forwardResult;
	if (!ExecuteForward(GameRulesForwards[GameRulesForwardRoundTimer], forwardResult, timer))
		set_fail_state("GameRules could not execute @round_timer.");
}

stock ExecuteGameStateChanged(GameState:oldState, GameState:newState)
{
	new forwardResult;
	if (!ExecuteForward(GameRulesForwards[GameRulesForwardGameStateChanged], forwardResult, oldState, newState))
		set_fail_state("GameRules could not execute @game_state_changed.");
}

stock ExecuteRoundStateChanged(RoundState:oldState, RoundState:newState)
{
	new forwardResult;
	if (!ExecuteForward(GameRulesForwards[GameRulesForwardRoundStateChanged], forwardResult, oldState, newState))
		set_fail_state("GameRules could not execute @round_state_changed.");
}
