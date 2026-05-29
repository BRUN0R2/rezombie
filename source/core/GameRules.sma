#include <amxmodx>
#include <reapi>
#include <rezombie>
#include <rezombie/core/RoundState>

#pragma semicolon 1
#pragma compress 1

const GAME_RULES_MIN_ALIVE_PLAYERS = 2;
const GAME_RULES_PREPARE_SECONDS = 10;
const Float:GAME_RULES_WAIT_CHECK_INTERVAL = 1.0;
const Float:GAME_RULES_WIN_CHECK_INTERVAL = 1.0;
const Float:GAME_RULES_ROUND_END_DELAY = 5.0;

new RoundState:CurrentRoundState = RoundStateWaiting;
new Mode:CurrentMode = Invalid_Mode;
new Float:NextWaitCheckAt;
new Float:PrepareEndsAt;
new Float:RoundEndsAt;
new Float:NextWinCheckAt;
new bool:MissingModesReported;

public plugin_precache()
{
	register_plugin("Core: Game Rules", "0.1.0", "BRUN0");
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPost", true);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundFreezeEndPost", true);
	RegisterHookChain(RG_RoundEnd, "OnRoundEndPost", true);
}

public OnRestartRoundPost()
{
	ResetRoundState(get_gametime());
}

public OnRoundFreezeEndPost()
{
	ResetRoundState(get_gametime());
}

public OnRoundEndPost(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	#pragma unused status
	#pragma unused event
	#pragma unused delay

	CurrentRoundState = RoundStateEnding;
	CurrentMode = Invalid_Mode;
}

public client_putinserver(id)
{
	#pragma unused id

	if (CurrentRoundState == RoundStateWaiting)
		ScheduleWaitCheck(get_gametime());
}

public client_disconnected(id)
{
	#pragma unused id

	if (CurrentRoundState == RoundStatePlaying)
		NextWinCheckAt = get_gametime();
}

public server_frame()
{
	new Float:now = get_gametime();

	switch (CurrentRoundState)
	{
		case RoundStateWaiting:
			UpdateWaitingRound(now);
		case RoundStatePreparing:
			UpdatePreparingRound(now);
		case RoundStatePlaying:
			UpdatePlayingRound(now);
	}
}

stock ResetRoundState(Float:now)
{
	CurrentRoundState = RoundStateWaiting;
	CurrentMode = Invalid_Mode;
	PrepareEndsAt = 0.0;
	RoundEndsAt = 0.0;
	NextWinCheckAt = 0.0;
	ScheduleWaitCheck(now);
}

stock UpdateWaitingRound(Float:now)
{
	if (now < NextWaitCheckAt)
		return;

	new alivePlayers = CountAlivePlayers();
	if (alivePlayers < GAME_RULES_MIN_ALIVE_PLAYERS)
	{
		ScheduleWaitCheck(now);
		return;
	}

	new Mode:mode = SelectMode(alivePlayers);
	if (mode == Invalid_Mode)
	{
		ScheduleWaitCheck(now);
		return;
	}

	StartPrepareRound(mode, now);
}

stock UpdatePreparingRound(Float:now)
{
	if (!HasEnoughPlayersForMode(CurrentMode))
	{
		ResetRoundState(now);
		return;
	}

	if (now < PrepareEndsAt)
		return;

	StartPlayingRound(now);
}

stock UpdatePlayingRound(Float:now)
{
	if (now >= RoundEndsAt)
	{
		EndRound(RoundEndReasonHumans);
		return;
	}

	if (now < NextWinCheckAt)
		return;

	NextWinCheckAt = now + GAME_RULES_WIN_CHECK_INTERVAL;
	CheckWinConditions();
}

stock StartPrepareRound(Mode:mode, Float:now)
{
	CurrentRoundState = RoundStatePreparing;
	CurrentMode = mode;
	PrepareEndsAt = now + float(GAME_RULES_PREPARE_SECONDS);
	NextWinCheckAt = 0.0;
}

stock StartPlayingRound(Float:now)
{
	if (!launch_mode(CurrentMode))
		set_fail_state("GameRules could not launch the selected mode.");

	new Float:roundTime = get_mode_var(CurrentMode, "round_time");
	if (roundTime <= 0.0)
		set_fail_state("Selected mode has invalid round_time.");

	CurrentRoundState = RoundStatePlaying;
	RoundEndsAt = now + roundTime;
	NextWinCheckAt = now + GAME_RULES_WIN_CHECK_INTERVAL;
}

stock CheckWinConditions()
{
	new aliveHumans = CountAliveHumans();
	new aliveZombies = CountAliveZombies();

	if (aliveHumans <= 0 && aliveZombies <= 0)
	{
		EndRound(RoundEndReasonDraw);
		return;
	}

	if (aliveHumans <= 0)
	{
		EndRound(RoundEndReasonZombies);
		return;
	}

	if (aliveZombies <= 0)
		EndRound(RoundEndReasonHumans);
}

stock EndRound(RoundEndReason:reason)
{
	if (CurrentRoundState == RoundStateEnding)
		return;

	CurrentRoundState = RoundStateEnding;

	switch (reason)
	{
		case RoundEndReasonHumans:
			rg_round_end(GAME_RULES_ROUND_END_DELAY, WINSTATUS_CTS, ROUND_CTS_WIN);
		case RoundEndReasonZombies:
			rg_round_end(GAME_RULES_ROUND_END_DELAY, WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN);
		case RoundEndReasonDraw:
			rg_round_end(GAME_RULES_ROUND_END_DELAY, WINSTATUS_DRAW, ROUND_END_DRAW);
		default:
			rg_round_end(GAME_RULES_ROUND_END_DELAY, WINSTATUS_NONE, ROUND_NONE);
	}
}

stock Mode:SelectMode(alivePlayers)
{
	new modesCount = get_modes_count();
	if (modesCount <= 0)
	{
		ReportMissingModes();
		return Invalid_Mode;
	}

	for (new index = 0; index < modesCount; index++)
	{
		new Mode:mode = get_mode(index);
		new minPlayers = get_mode_var(mode, "min_players");

		if (alivePlayers >= minPlayers)
			return mode;
	}

	return Invalid_Mode;
}

stock bool:HasEnoughPlayersForMode(Mode:mode)
{
	if (mode == Invalid_Mode)
		return false;

	new alivePlayers = CountAlivePlayers();
	new minPlayers = get_mode_var(mode, "min_players");

	return alivePlayers >= minPlayers;
}

stock CountAlivePlayers()
{
	new count;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id) && is_user_alive(id))
			count++;
	}

	return count;
}

stock CountAliveHumans()
{
	new count;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id) && is_user_alive(id) && IsHuman(id))
			count++;
	}

	return count;
}

stock CountAliveZombies()
{
	new count;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id) && is_user_alive(id) && IsZombie(id))
			count++;
	}

	return count;
}

stock ScheduleWaitCheck(Float:now)
{
	NextWaitCheckAt = now + GAME_RULES_WAIT_CHECK_INTERVAL;
}

stock ReportMissingModes()
{
	if (MissingModesReported)
		return;

	MissingModesReported = true;
	log_amx("GameRules is waiting for at least one registered mode.");
}
