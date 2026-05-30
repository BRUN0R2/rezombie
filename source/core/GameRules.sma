#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezombie>
#include <rezombie/core/GameVars>

#pragma semicolon 1
#pragma compress 1

const GAME_RULES_FORWARD_INVALID = -1;
const GAME_RULES_NO_TARGET = 0;
const GAME_RULES_MIN_PLAYERS = 2;

const Float:GAME_RULES_PREPARE_SECONDS = 10.0;
const Float:GAME_RULES_RESTART_SECONDS = 5.0;

enum _:GameRulesRuntimeData
{
	GameState:GameRulesGameState,
	RoundState:GameRulesRoundState,
	Mode:GameRulesMode,
	Float:GameRulesStateEndsAt,
	GameRulesTimer,
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

new GameRulesRuntime[GameRulesRuntimeData];
new GameRulesForwards[GameRulesForwardCount];

public plugin_precache()
{
	register_plugin("Core: Game Rules", "0.1.0", "BRUN0");
}

public plugin_init()
{
	CreateGameRulesForwards();

	register_forward(FM_StartFrame, "OnServerFrame");
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPre", false);
}

public plugin_cfg()
{
	ResetGameRulesRuntime();
	RefreshRoundFlow();
}

public plugin_end()
{
	DestroyGameRulesForwards();
}

public OnRestartRoundPre()
{
	RefreshRoundFlow();
}

public OnServerFrame()
{
	new Float:now = get_gametime();

	switch (GameRulesRuntime[GameRulesRoundState])
	{
		case RoundStateNone:
		{
			if (HasEnoughPlayers())
				BeginRoundPrepare(now);
			else
				EnterWaitingState();
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
			CheckRoundWinConditions(now);
		}
		case RoundStateTerminate:
		{
			UpdateRoundTimer(now);

			if (now >= GameRulesRuntime[GameRulesStateEndsAt])
				rg_restart_round();
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
	GameRulesRuntime[GameRulesHumanWins] = 0;
	GameRulesRuntime[GameRulesZombieWins] = 0;

	PublishGameVars();
}

stock RefreshRoundFlow()
{
	if (!HasEnoughPlayers())
	{
		EnterWaitingState();
		return;
	}

	BeginRoundPrepare(get_gametime());
}

stock EnterWaitingState()
{
	new bool:changed = false;

	changed = SetGameState(GameStateNeedPlayers) || changed;
	changed = SetRoundState(RoundStateNone) || changed;
	changed = SetRoundMode(Invalid_Mode) || changed;
	changed = SetRoundTimer(0) || changed;

	GameRulesRuntime[GameRulesStateEndsAt] = 0.0;

	if (changed)
		PublishGameVars();
}

stock BeginRoundPrepare(Float:now)
{
	new Mode:mode = SelectRoundMode();

	SetGameState(GameStatePlaying);
	SetRoundState(RoundStatePrepare);
	SetRoundMode(mode);
	SetRoundWindow(now, GAME_RULES_PREPARE_SECONDS);
	PublishGameVars();

	ExecuteRoundPrepare(mode, GAME_RULES_PREPARE_SECONDS);
}

stock BeginRoundPlaying(Float:now)
{
	new Mode:mode = GameRulesRuntime[GameRulesMode];
	new Float:duration = GetModeRoundTime(mode);

	if (!launch_mode(mode, GAME_RULES_NO_TARGET))
		set_fail_state("GameRules could not launch selected mode %d.", _:mode);

	SetRoundState(RoundStatePlaying);
	SetRoundWindow(now, duration);
	PublishGameVars();

	ExecuteRoundStart(mode, duration);
	CheckRoundWinConditions(now);
}

stock EndRound(RoundEndReason:reason, Float:now)
{
	if (GameRulesRuntime[GameRulesRoundState] == RoundStateTerminate)
		return;

	switch (reason)
	{
		case RoundEndReasonHumans:
			GameRulesRuntime[GameRulesHumanWins]++;
		case RoundEndReasonZombies:
			GameRulesRuntime[GameRulesZombieWins]++;
	}

	SetRoundState(RoundStateTerminate);
	SetRoundWindow(now, GAME_RULES_RESTART_SECONDS);
	PublishGameVars();

	ExecuteRoundEnd(reason);
}

stock CheckRoundWinConditions(Float:now)
{
	if (GameRulesRuntime[GameRulesRoundState] != RoundStatePlaying)
		return;

	new humans = CountAliveTeamPlayers(TEAM_HUMAN);
	new zombies = CountAliveTeamPlayers(TEAM_ZOMBIE);

	if (humans <= 0 && zombies <= 0)
	{
		EndRound(RoundEndReasonDraw, now);
		return;
	}

	if (humans <= 0)
	{
		EndRound(RoundEndReasonZombies, now);
		return;
	}

	if (zombies <= 0)
	{
		EndRound(RoundEndReasonHumans, now);
		return;
	}

	if (now >= GameRulesRuntime[GameRulesStateEndsAt])
		EndRound(RoundEndReasonHumans, now);
}

stock Mode:SelectRoundMode()
{
	new modesCount = get_modes_count();
	if (modesCount <= 0)
		set_fail_state("GameRules could not select a mode because no mode is registered.");

	new players = CountPlayablePlayers();
	new Mode:fallbackMode = Invalid_Mode;

	for (new index = 0; index < modesCount; index++)
	{
		new Mode:mode = get_mode(index);

		if (fallbackMode == Invalid_Mode)
			fallbackMode = mode;

		if (players >= get_mode_var(mode, "min_players"))
			return mode;
	}

	if (fallbackMode == Invalid_Mode)
		set_fail_state("GameRules could not select a fallback mode.");

	return fallbackMode;
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

stock SetRoundWindow(Float:now, Float:duration)
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

	SetRoundTimer(timer);
	PublishGameVars();
	ExecuteRoundTimer(timer);
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

	new GameState:oldState = GameRulesRuntime[GameRulesGameState];
	GameRulesRuntime[GameRulesGameState] = gameState;
	ExecuteGameStateChanged(oldState, gameState);

	return true;
}

stock bool:SetRoundState(RoundState:roundState)
{
	if (GameRulesRuntime[GameRulesRoundState] == roundState)
		return false;

	new RoundState:oldState = GameRulesRuntime[GameRulesRoundState];
	GameRulesRuntime[GameRulesRoundState] = roundState;
	ExecuteRoundStateChanged(oldState, roundState);

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

stock PublishGameVars()
{
	if (!sync_game_vars(
		GameRulesRuntime[GameRulesGameState],
		GameRulesRuntime[GameRulesRoundState],
		GameRulesRuntime[GameRulesMode],
		float(GameRulesRuntime[GameRulesTimer]),
		GameRulesRuntime[GameRulesHumanWins],
		GameRulesRuntime[GameRulesZombieWins]
	))
	{
		set_fail_state("GameRules could not publish game vars.");
	}
}

stock bool:HasEnoughPlayers()
{
	return CountPlayablePlayers() >= GAME_RULES_MIN_PLAYERS;
}

stock CountPlayablePlayers()
{
	new count;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id) && IsPlayerOnPlayableTeam(id))
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

stock CreateGameRulesForwards()
{
	ResetGameRulesForwards();

	GameRulesForwards[GameRulesForwardRoundPrepare] = CreateMultiForward("@round_prepare", ET_IGNORE, FP_CELL, FP_FLOAT);
	GameRulesForwards[GameRulesForwardRoundStart] = CreateMultiForward("@round_start", ET_IGNORE, FP_CELL, FP_FLOAT);
	GameRulesForwards[GameRulesForwardRoundEnd] = CreateMultiForward("@round_end", ET_IGNORE, FP_CELL);
	GameRulesForwards[GameRulesForwardRoundTimer] = CreateMultiForward("@round_timer", ET_IGNORE, FP_CELL);
	GameRulesForwards[GameRulesForwardGameStateChanged] = CreateMultiForward("@game_state_changed", ET_IGNORE, FP_CELL, FP_CELL);
	GameRulesForwards[GameRulesForwardRoundStateChanged] = CreateMultiForward("@round_state_changed", ET_IGNORE, FP_CELL, FP_CELL);
}

stock ResetGameRulesForwards()
{
	for (new index = 0; index < sizeof GameRulesForwards; index++)
		GameRulesForwards[index] = GAME_RULES_FORWARD_INVALID;
}

stock DestroyGameRulesForwards()
{
	for (new index = 0; index < sizeof GameRulesForwards; index++)
		DestroyGameRulesForward(GameRulesForwards[index]);
}

stock DestroyGameRulesForward(&forwardId)
{
	if (forwardId == GAME_RULES_FORWARD_INVALID)
		return;

	DestroyForward(forwardId);
	forwardId = GAME_RULES_FORWARD_INVALID;
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

stock ExecuteRoundEnd(RoundEndReason:reason)
{
	new forwardResult;
	if (!ExecuteForward(GameRulesForwards[GameRulesForwardRoundEnd], forwardResult, reason))
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
