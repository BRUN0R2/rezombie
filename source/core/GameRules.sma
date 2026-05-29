#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezombie>
#include <rezombie_stock>
#include <rezombie/core/RoundState>

#pragma semicolon 1
#pragma compress 1

const GAME_RULES_FORWARD_INVALID = -1;
const GAME_RULES_MIN_ALIVE_PLAYERS = 2;
const GAME_RULES_PREPARE_SECONDS = 10;
const GAME_RULES_FREEZE_SECONDS = 0;
const GAME_RULES_LIMIT_TEAMS = 0;
const GAME_RULES_AUTO_TEAM_BALANCE = 0;
const GAME_RULES_HOOK_FALSE = 0;
const TeamName:GAME_RULES_DEFAULT_JOIN_TEAM = TEAM_CT;
const Float:GAME_RULES_WAIT_CHECK_INTERVAL = 1.0;
const Float:GAME_RULES_WIN_CHECK_INTERVAL = 1.0;
const Float:GAME_RULES_ROUND_END_DELAY = 5.0;

new const GAME_RULES_DEFAULT_HUMAN_CLASS[] = "human";
new const GAME_RULES_ROUND_VAR_STATE[] = "state";
new const GAME_RULES_ROUND_VAR_MODE[] = "mode";
new const GAME_RULES_ROUND_VAR_TIME_LEFT[] = "time_left";

new RoundState:CurrentRoundState = RoundStateFreezing;
new Mode:CurrentMode = Invalid_Mode;
new Float:NextWaitCheckAt;
new Float:PrepareEndsAt;
new Float:RoundEndsAt;
new Float:NextWinCheckAt;
new bool:MissingModesReported;
new bool:GameRulesEndingRound;
new RoundPrepareForward = GAME_RULES_FORWARD_INVALID;
new RoundStartForward = GAME_RULES_FORWARD_INVALID;
new RoundEndForward = GAME_RULES_FORWARD_INVALID;

public plugin_precache()
{
	register_plugin("Core: Game Rules", "0.1.0", "BRUN0");
}

public plugin_init()
{
	CreateRoundForwards();
	register_clcmd("chooseteam", "CommandBlockDefaultTeamMenu");
	register_clcmd("jointeam", "CommandBlockDefaultTeamMenu");
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "OnChooseTeamPre", false);
	RegisterHookChain(RG_HandleMenu_ChooseAppearance, "OnChooseAppearancePre", false);
	RegisterHookChain(RG_ShowVGUIMenu, "OnShowVguiMenuPre", false);
	RegisterHookChain(RG_ShowMenu, "OnShowMenuPre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPre", false);
	RegisterHookChain(RG_CSGameRules_FPlayerCanRespawn, "OnPlayerCanRespawnPre", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPre", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPost", true);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundFreezeEndPost", true);
	RegisterHookChain(RG_RoundEnd, "OnRoundEndPre", false);
	RegisterHookChain(RG_RoundEnd, "OnRoundEndPost", true);
	register_forward(FM_StartFrame, "OnServerFrame");
}

public plugin_cfg()
{
	EnforceGameRuleCvars();
	SyncRoundVars(0.0);
}

public CommandBlockDefaultTeamMenu(id)
{
	if (is_user_connected(id))
		AdmitPlayerToDefaultTeam(id);

	return PLUGIN_HANDLED;
}

public plugin_end()
{
	DestroyRoundForwards();
}

public OnRestartRoundPre()
{
	EnforceGameRuleCvars();
	EnterFreezingRound();
	ResetPlayablePlayersToHumans();
}

public OnRestartRoundPost()
{
	if (get_cvar_float("mp_freezetime") <= 0.0)
		ResetRoundState(get_gametime());
}

public OnRoundFreezeEndPost()
{
	if (CurrentRoundState != RoundStateFreezing)
		return;

	ResetRoundState(get_gametime());
}

public OnRoundEndPost(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	#pragma unused status
	#pragma unused event
	#pragma unused delay

	if (!GameRulesEndingRound)
		return;

	CurrentRoundState = RoundStateEnding;
	CurrentMode = Invalid_Mode;
	SyncRoundVars(0.0);
}

public OnRoundEndPre(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	#pragma unused status
	#pragma unused event
	#pragma unused delay

	if (GameRulesEndingRound)
		return HC_CONTINUE;

	switch (CurrentRoundState)
	{
		case RoundStateWaiting, RoundStatePreparing, RoundStatePlaying:
		{
			SetHookChainReturn(ATYPE_BOOL, false);
			return HC_SUPERCEDE;
		}
	}

	return HC_CONTINUE;
}

public OnChooseTeamPre(id, MenuChooseTeam:slot)
{
	if (!is_user_connected(id))
		return HC_CONTINUE;

	#pragma unused slot

	AdmitPlayerToDefaultTeam(id);
	SetHookChainReturn(ATYPE_INTEGER, GAME_RULES_HOOK_FALSE);
	return HC_SUPERCEDE;
}

public OnChooseAppearancePre(id, slot)
{
	#pragma unused slot

	if (!is_user_connected(id))
		return HC_CONTINUE;

	AdmitPlayerToDefaultTeam(id);
	return HC_SUPERCEDE;
}

public OnShowVguiMenuPre(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	#pragma unused bitsSlots
	#pragma unused oldMenu

	if (!is_user_connected(id))
		return HC_CONTINUE;

	if (IsDefaultTeamMenu(menuType))
	{
		AdmitPlayerToDefaultTeam(id);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public OnShowMenuPre(id, bitsSlots, displayTime, needMore, menuText[])
{
	#pragma unused bitsSlots
	#pragma unused displayTime
	#pragma unused needMore
	#pragma unused menuText

	if (!is_user_connected(id))
		return HC_CONTINUE;

	if (IsDefaultTeamMenuState(get_member(id, m_iMenu)))
	{
		AdmitPlayerToDefaultTeam(id);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public OnPlayerSpawnPre(id)
{
	if (!is_user_connected(id))
		return HC_CONTINUE;

	if (IsRoundBlockingAdmission() && !is_user_alive(id))
		return HC_SUPERCEDE;

	if (IsRoundAcceptingHumans() && IsPlayerOnPlayableGameTeam(id) && get_member(id, m_iTeam) != TEAM_CT)
		ForceSpawnedPlayerToHumanTeam(id);

	return HC_CONTINUE;
}

public OnPlayerCanRespawnPre(id)
{
	if (!is_user_connected(id))
		return HC_CONTINUE;

	if (CurrentRoundState == RoundStatePlaying || CurrentRoundState == RoundStateEnding)
	{
		SetHookChainReturn(ATYPE_INTEGER, GAME_RULES_HOOK_FALSE);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
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

public OnServerFrame()
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

	return FMRES_IGNORED;
}

stock ResetRoundState(Float:now)
{
	CurrentRoundState = RoundStateWaiting;
	CurrentMode = Invalid_Mode;
	PrepareEndsAt = 0.0;
	RoundEndsAt = 0.0;
	NextWinCheckAt = 0.0;
	ScheduleWaitCheck(now);
	SyncRoundVars(0.0);
}

stock EnterFreezingRound()
{
	CurrentRoundState = RoundStateFreezing;
	CurrentMode = Invalid_Mode;
	PrepareEndsAt = 0.0;
	RoundEndsAt = 0.0;
	NextWinCheckAt = 0.0;
	NextWaitCheckAt = 0.0;
	SyncRoundVars(0.0);
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
	SyncRoundVars(float(GAME_RULES_PREPARE_SECONDS));

	ExecuteRoundPrepareForward(mode, float(GAME_RULES_PREPARE_SECONDS));
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
	SyncRoundVars(roundTime);

	ExecuteRoundStartForward(CurrentMode, roundTime);
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
	CurrentMode = Invalid_Mode;
	SyncRoundVars(0.0);
	GameRulesEndingRound = true;
	ExecuteRoundEndForward(reason);

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

	GameRulesEndingRound = false;
}

stock CreateRoundForwards()
{
	RoundPrepareForward = CreateMultiForward("@round_prepare", ET_IGNORE, FP_CELL, FP_FLOAT);
	RoundStartForward = CreateMultiForward("@round_start", ET_IGNORE, FP_CELL, FP_FLOAT);
	RoundEndForward = CreateMultiForward("@round_end", ET_IGNORE, FP_CELL);
}

stock DestroyRoundForwards()
{
	DestroyRoundForward(RoundPrepareForward);
	DestroyRoundForward(RoundStartForward);
	DestroyRoundForward(RoundEndForward);
}

stock DestroyRoundForward(&forwardId)
{
	if (forwardId == GAME_RULES_FORWARD_INVALID)
		return;

	DestroyForward(forwardId);
	forwardId = GAME_RULES_FORWARD_INVALID;
}

stock ExecuteRoundPrepareForward(Mode:mode, Float:prepareTime)
{
	new result;
	if (!ExecuteForward(RoundPrepareForward, result, mode, prepareTime))
		set_fail_state("GameRules could not execute @round_prepare.");
}

stock ExecuteRoundStartForward(Mode:mode, Float:roundTime)
{
	new result;
	if (!ExecuteForward(RoundStartForward, result, mode, roundTime))
		set_fail_state("GameRules could not execute @round_start.");
}

stock ExecuteRoundEndForward(RoundEndReason:reason)
{
	new result;
	if (!ExecuteForward(RoundEndForward, result, reason))
		set_fail_state("GameRules could not execute @round_end.");
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

stock EnforceGameRuleCvars()
{
	set_cvar_num("mp_freezetime", GAME_RULES_FREEZE_SECONDS);
	set_cvar_num("mp_limitteams", GAME_RULES_LIMIT_TEAMS);
	set_cvar_num("mp_autoteambalance", GAME_RULES_AUTO_TEAM_BALANCE);
}

stock ResetPlayablePlayersToHumans()
{
	new Class:class = RequireClass(GAME_RULES_DEFAULT_HUMAN_CLASS);

	for (new id = 1; id <= MaxClients; id++)
	{
		if (!is_user_connected(id) || !IsPlayerOnPlayableGameTeam(id))
			continue;

		ResetPlayerToHuman(id, class);
	}
}

stock ResetPlayerToHuman(id, Class:class)
{
	if (IsHuman(id) && get_player_class(id) == class && get_player_subclass(id) == Invalid_Subclass && get_member(id, m_iTeam) == TEAM_CT)
		return;

	if (!change_player_class(id, class, Invalid_Subclass, false))
		set_fail_state("GameRules could not reset player %d to human.", id);
}

stock bool:IsRoundAcceptingHumans()
{
	switch (CurrentRoundState)
	{
		case RoundStateFreezing, RoundStateWaiting, RoundStatePreparing:
			return true;
	}

	return false;
}

stock bool:IsRoundBlockingAdmission()
{
	switch (CurrentRoundState)
	{
		case RoundStatePlaying, RoundStateEnding:
			return true;
	}

	return false;
}

stock bool:IsDefaultTeamMenu(VGUIMenu:menuType)
{
	switch (menuType)
	{
		case VGUI_Menu_Team, VGUI_Menu_Class_T, VGUI_Menu_Class_CT:
			return true;
	}

	return false;
}

stock bool:IsDefaultTeamMenuState(menu)
{
	switch (menu)
	{
		case Menu_ChooseTeam, Menu_IGChooseTeam, Menu_ChooseAppearance:
			return true;
	}

	return false;
}

stock AdmitPlayerToDefaultTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);
	if (team != TEAM_TERRORIST && team != TEAM_CT)
	{
		rg_set_user_team(id, GAME_RULES_DEFAULT_JOIN_TEAM, MODEL_AUTO, true, false);

		if (get_member(id, m_iTeam) != GAME_RULES_DEFAULT_JOIN_TEAM)
			set_fail_state("GameRules could not admit player %d to the default team.", id);
	}

	CompletePlayerAdmission(id);

	if (IsRoundAcceptingHumans() && !is_user_alive(id))
	{
		rg_round_respawn(id);
		CompletePlayerAdmission(id);
	}
}

stock CompletePlayerAdmission(id)
{
	set_member(id, m_iJoiningState, JOINED);
	set_member(id, m_iMenu, Menu_OFF);
	set_member(id, m_bJustConnected, false);
}

stock ForceSpawnedPlayerToHumanTeam(id)
{
	rg_set_user_team(id, TEAM_CT, MODEL_AUTO, true, false);

	if (get_member(id, m_iTeam) != TEAM_CT)
		set_fail_state("GameRules could not force player %d to CT.", id);
}

stock bool:IsPlayerOnPlayableGameTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);

	return team == TEAM_TERRORIST || team == TEAM_CT;
}

stock ReportMissingModes()
{
	if (MissingModesReported)
		return;

	MissingModesReported = true;
	log_amx("GameRules is waiting for at least one registered mode.");
}

stock SyncRoundVars(Float:timeLeft)
{
	if (!set_round_var(GAME_RULES_ROUND_VAR_STATE, CurrentRoundState))
		set_fail_state("GameRules could not sync round state.");

	if (!set_round_var(GAME_RULES_ROUND_VAR_MODE, CurrentMode))
		set_fail_state("GameRules could not sync round mode.");

	if (!set_round_var(GAME_RULES_ROUND_VAR_TIME_LEFT, timeLeft))
		set_fail_state("GameRules could not sync round time_left.");
}
