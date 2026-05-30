#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezombie>
#include <rezombie_stock>
#include <rezombie/core/RoundState>

#pragma semicolon 1
#pragma compress 1

const GAME_RULES_FORWARD_INVALID = -1;
const GAME_RULES_HOOK_FALSE = 0;
const GAME_RULES_NO_ENTITY = 0;
const GAME_RULES_NO_OBSERVER_TARGET = 0;

new const GAME_RULES_DEFAULT_HUMAN_CLASS[] = "human";
new const GAME_RULES_ROUND_VAR_STATE[] = "state";
new const GAME_RULES_ROUND_VAR_MODE[] = "mode";
new const GAME_RULES_ROUND_VAR_TIME_LEFT[] = "time_left";

enum _:RoundConfig
{
	RoundConfigMinAlivePlayers,
	RoundConfigPrepareSeconds,
	TeamName:RoundConfigDefaultJoinTeam,
	Float:RoundConfigWaitCheckInterval,
	Float:RoundConfigWinCheckInterval,
	Float:RoundConfigEndDelay,
	Float:RoundConfigNoIntroCameraTime
};

enum _:RoundRuntime
{
	RoundState:RoundRuntimeState,
	Mode:RoundRuntimeMode,
	Float:RoundRuntimeNextWaitCheckAt,
	Float:RoundRuntimePrepareEndsAt,
	Float:RoundRuntimeRoundEndsAt,
	Float:RoundRuntimeNextWinCheckAt,
	bool:RoundRuntimeMissingModesReported,
	bool:RoundRuntimeEndingRound
};

enum _:RoundForwards
{
	RoundForwardPrepare,
	RoundForwardStart,
	RoundForwardEnd
};

new RoundConfigData[RoundConfig];
new RoundRuntimeData[RoundRuntime];
new RoundForwardData[RoundForwards] =
{
	GAME_RULES_FORWARD_INVALID,
	GAME_RULES_FORWARD_INVALID,
	GAME_RULES_FORWARD_INVALID
};

public plugin_precache()
{
	register_plugin("Core: Game Rules", "0.1.0", "BRUN0");
}

public plugin_init()
{
	InitializeRoundConfig();
	InitializeRoundRuntime();
	CreateRoundForwards();
	register_clcmd("chooseteam", "CommandBlockDefaultJoinFlow");
	register_clcmd("jointeam", "CommandBlockDefaultJoinFlow");
	register_clcmd("joinclass", "CommandBlockDefaultJoinFlow");
	RegisterHookChain(RG_HandleMenu_ChooseTeam, "OnChooseTeamPre", false);
	RegisterHookChain(RG_HandleMenu_ChooseAppearance, "OnChooseAppearancePre", false);
	RegisterHookChain(RG_ShowVGUIMenu, "OnShowVguiMenuPre", false);
	RegisterHookChain(RG_ShowMenu, "OnShowMenuPre", false);
	RegisterHookChain(RG_CBasePlayer_JoiningThink, "OnPlayerJoiningThinkPre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPre", false);
	RegisterHookChain(RG_CSGameRules_FPlayerCanRespawn, "OnPlayerCanRespawnPre", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPre", false);
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPost", true);
	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundFreezeEndPost", true);
	RegisterHookChain(RG_RoundEnd, "OnRoundEndPre", false);
	RegisterHookChain(RG_RoundEnd, "OnRoundEndPost", true);
	register_forward(FM_StartFrame, "OnServerFrame");
}

stock InitializeRoundConfig()
{
	RoundConfigData[RoundConfigMinAlivePlayers] = 2;
	RoundConfigData[RoundConfigPrepareSeconds] = 10;
	RoundConfigData[RoundConfigDefaultJoinTeam] = TEAM_CT;
	RoundConfigData[RoundConfigWaitCheckInterval] = 1.0;
	RoundConfigData[RoundConfigWinCheckInterval] = 1.0;
	RoundConfigData[RoundConfigEndDelay] = 5.0;
	RoundConfigData[RoundConfigNoIntroCameraTime] = 0.0;
}

stock InitializeRoundRuntime()
{
	RoundRuntimeData[RoundRuntimeState] = RoundStateFreezing;
	RoundRuntimeData[RoundRuntimeMode] = Invalid_Mode;
	RoundRuntimeData[RoundRuntimeNextWaitCheckAt] = 0.0;
	RoundRuntimeData[RoundRuntimePrepareEndsAt] = 0.0;
	RoundRuntimeData[RoundRuntimeRoundEndsAt] = 0.0;
	RoundRuntimeData[RoundRuntimeNextWinCheckAt] = 0.0;
	RoundRuntimeData[RoundRuntimeMissingModesReported] = false;
	RoundRuntimeData[RoundRuntimeEndingRound] = false;
}

public plugin_cfg()
{
	SyncRoundVars(0.0);
}

public CommandBlockDefaultJoinFlow(id)
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
	EnterFreezingRound();
	ResetPlayablePlayersToHumans();
}

public OnRestartRoundPost()
{
	ResetRoundState(get_gametime());
	RespawnNewRoundPlayers();
}

public OnRoundFreezeEndPost()
{
	if (RoundRuntimeData[RoundRuntimeState] != RoundStateFreezing)
		return;

	ResetRoundState(get_gametime());
}

public OnRoundEndPost(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	#pragma unused status
	#pragma unused event
	#pragma unused delay

	if (!RoundRuntimeData[RoundRuntimeEndingRound])
		return;

	RoundRuntimeData[RoundRuntimeState] = RoundStateEnding;
	RoundRuntimeData[RoundRuntimeMode] = Invalid_Mode;
	SyncRoundVars(0.0);
}

public OnRoundEndPre(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	#pragma unused status
	#pragma unused event
	#pragma unused delay

	if (RoundRuntimeData[RoundRuntimeEndingRound])
		return HC_CONTINUE;

	switch (RoundRuntimeData[RoundRuntimeState])
	{
		case RoundStateFreezing, RoundStateWaiting, RoundStatePreparing, RoundStatePlaying:
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

public OnPlayerJoiningThinkPre(id)
{
	if (!is_user_connected(id))
		return HC_CONTINUE;

	AdmitPlayerToDefaultTeam(id);
	return HC_SUPERCEDE;
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

	if (RoundRuntimeData[RoundRuntimeState] == RoundStatePlaying || RoundRuntimeData[RoundRuntimeState] == RoundStateEnding)
	{
		SetHookChainReturn(ATYPE_INTEGER, GAME_RULES_HOOK_FALSE);
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public client_putinserver(id)
{
	#pragma unused id

	if (RoundRuntimeData[RoundRuntimeState] == RoundStateWaiting)
		ScheduleWaitCheck(get_gametime());
}

public client_disconnected(id)
{
	#pragma unused id

	if (RoundRuntimeData[RoundRuntimeState] == RoundStatePlaying)
		RoundRuntimeData[RoundRuntimeNextWinCheckAt] = get_gametime();
}

public OnServerFrame()
{
	new Float:now = get_gametime();

	switch (RoundRuntimeData[RoundRuntimeState])
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
	RoundRuntimeData[RoundRuntimeState] = RoundStateWaiting;
	RoundRuntimeData[RoundRuntimeMode] = Invalid_Mode;
	RoundRuntimeData[RoundRuntimePrepareEndsAt] = 0.0;
	RoundRuntimeData[RoundRuntimeRoundEndsAt] = 0.0;
	RoundRuntimeData[RoundRuntimeNextWinCheckAt] = 0.0;
	ScheduleWaitCheck(now);
	SyncRoundVars(0.0);
}

stock EnterFreezingRound()
{
	RoundRuntimeData[RoundRuntimeState] = RoundStateFreezing;
	RoundRuntimeData[RoundRuntimeMode] = Invalid_Mode;
	RoundRuntimeData[RoundRuntimePrepareEndsAt] = 0.0;
	RoundRuntimeData[RoundRuntimeRoundEndsAt] = 0.0;
	RoundRuntimeData[RoundRuntimeNextWinCheckAt] = 0.0;
	RoundRuntimeData[RoundRuntimeNextWaitCheckAt] = 0.0;
	SyncRoundVars(0.0);
}

stock UpdateWaitingRound(Float:now)
{
	if (now < RoundRuntimeData[RoundRuntimeNextWaitCheckAt])
		return;

	new alivePlayers = CountAlivePlayers();
	if (alivePlayers < RoundConfigData[RoundConfigMinAlivePlayers])
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
	if (!HasEnoughPlayersForMode(RoundRuntimeData[RoundRuntimeMode]))
	{
		ResetRoundState(now);
		return;
	}

	if (now < RoundRuntimeData[RoundRuntimePrepareEndsAt])
		return;

	StartPlayingRound(now);
}

stock UpdatePlayingRound(Float:now)
{
	if (now >= RoundRuntimeData[RoundRuntimeRoundEndsAt])
	{
		EndRound(RoundEndReasonHumans);
		return;
	}

	if (now < RoundRuntimeData[RoundRuntimeNextWinCheckAt])
		return;

	RoundRuntimeData[RoundRuntimeNextWinCheckAt] = now + RoundConfigData[RoundConfigWinCheckInterval];
	CheckWinConditions();
}

stock StartPrepareRound(Mode:mode, Float:now)
{
	RoundRuntimeData[RoundRuntimeState] = RoundStatePreparing;
	RoundRuntimeData[RoundRuntimeMode] = mode;
	RoundRuntimeData[RoundRuntimePrepareEndsAt] = now + float(RoundConfigData[RoundConfigPrepareSeconds]);
	RoundRuntimeData[RoundRuntimeNextWinCheckAt] = 0.0;
	SyncRoundVars(float(RoundConfigData[RoundConfigPrepareSeconds]));

	ExecuteRoundPrepareForward(mode, float(RoundConfigData[RoundConfigPrepareSeconds]));
}

stock StartPlayingRound(Float:now)
{
	if (!launch_mode(RoundRuntimeData[RoundRuntimeMode]))
		set_fail_state("GameRules could not launch the selected mode.");

	new Float:roundTime = get_mode_var(RoundRuntimeData[RoundRuntimeMode], "round_time");
	if (roundTime <= 0.0)
		set_fail_state("Selected mode has invalid round_time.");

	RoundRuntimeData[RoundRuntimeState] = RoundStatePlaying;
	RoundRuntimeData[RoundRuntimeRoundEndsAt] = now + roundTime;
	RoundRuntimeData[RoundRuntimeNextWinCheckAt] = now + RoundConfigData[RoundConfigWinCheckInterval];
	SyncRoundVars(roundTime);

	ExecuteRoundStartForward(RoundRuntimeData[RoundRuntimeMode], roundTime);
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
	if (RoundRuntimeData[RoundRuntimeState] == RoundStateEnding)
		return;

	RoundRuntimeData[RoundRuntimeState] = RoundStateEnding;
	RoundRuntimeData[RoundRuntimeMode] = Invalid_Mode;
	SyncRoundVars(0.0);
	RoundRuntimeData[RoundRuntimeEndingRound] = true;
	ExecuteRoundEndForward(reason);

	switch (reason)
	{
		case RoundEndReasonHumans:
			rg_round_end(RoundConfigData[RoundConfigEndDelay], WINSTATUS_CTS, ROUND_CTS_WIN);
		case RoundEndReasonZombies:
			rg_round_end(RoundConfigData[RoundConfigEndDelay], WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN);
		case RoundEndReasonDraw:
			rg_round_end(RoundConfigData[RoundConfigEndDelay], WINSTATUS_DRAW, ROUND_END_DRAW);
		default:
			rg_round_end(RoundConfigData[RoundConfigEndDelay], WINSTATUS_NONE, ROUND_NONE);
	}

	RoundRuntimeData[RoundRuntimeEndingRound] = false;
}

stock CreateRoundForwards()
{
	RoundForwardData[RoundForwardPrepare] = CreateMultiForward("@round_prepare", ET_IGNORE, FP_CELL, FP_FLOAT);
	RoundForwardData[RoundForwardStart] = CreateMultiForward("@round_start", ET_IGNORE, FP_CELL, FP_FLOAT);
	RoundForwardData[RoundForwardEnd] = CreateMultiForward("@round_end", ET_IGNORE, FP_CELL);
}

stock DestroyRoundForwards()
{
	DestroyRoundForward(RoundForwardData[RoundForwardPrepare]);
	DestroyRoundForward(RoundForwardData[RoundForwardStart]);
	DestroyRoundForward(RoundForwardData[RoundForwardEnd]);
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
	if (!ExecuteForward(RoundForwardData[RoundForwardPrepare], result, mode, prepareTime))
		set_fail_state("GameRules could not execute @round_prepare.");
}

stock ExecuteRoundStartForward(Mode:mode, Float:roundTime)
{
	new result;
	if (!ExecuteForward(RoundForwardData[RoundForwardStart], result, mode, roundTime))
		set_fail_state("GameRules could not execute @round_start.");
}

stock ExecuteRoundEndForward(RoundEndReason:reason)
{
	new result;
	if (!ExecuteForward(RoundForwardData[RoundForwardEnd], result, reason))
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
	RoundRuntimeData[RoundRuntimeNextWaitCheckAt] = now + RoundConfigData[RoundConfigWaitCheckInterval];
}

stock RespawnNewRoundPlayers()
{
	for (new id = 1; id <= MaxClients; id++)
	{
		if (!is_user_connected(id))
			continue;

		AdmitPlayerToDefaultTeam(id);
	}
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
	switch (RoundRuntimeData[RoundRuntimeState])
	{
		case RoundStateFreezing, RoundStateWaiting, RoundStatePreparing:
			return true;
	}

	return false;
}

stock bool:IsRoundBlockingAdmission()
{
	switch (RoundRuntimeData[RoundRuntimeState])
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
		rg_set_user_team(id, RoundConfigData[RoundConfigDefaultJoinTeam], MODEL_AUTO, true, false);

		if (get_member(id, m_iTeam) != RoundConfigData[RoundConfigDefaultJoinTeam])
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
	CompletePlayerJoinState(id);
	ResetPlayerJoinCamera(id);
}

stock CompletePlayerJoinState(id)
{
	set_member(id, m_iJoiningState, JOINED);
	set_member(id, m_iMenu, Menu_OFF);
	set_member(id, m_bJustConnected, false);
}

stock ResetPlayerJoinCamera(id)
{
	set_member(id, m_pIntroCamera, GAME_RULES_NO_ENTITY);
	set_member(id, m_fIntroCamTime, RoundConfigData[RoundConfigNoIntroCameraTime]);
	set_entvar(id, var_iuser1, OBS_NONE);
	set_entvar(id, var_iuser2, GAME_RULES_NO_OBSERVER_TARGET);
	set_entvar(id, var_iuser3, GAME_RULES_NO_OBSERVER_TARGET);
	engset_view(id, id);
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
	if (RoundRuntimeData[RoundRuntimeMissingModesReported])
		return;

	RoundRuntimeData[RoundRuntimeMissingModesReported] = true;
	log_amx("GameRules is waiting for at least one registered mode.");
}

stock SyncRoundVars(Float:timeLeft)
{
	if (!set_round_var(GAME_RULES_ROUND_VAR_STATE, RoundRuntimeData[RoundRuntimeState]))
		set_fail_state("GameRules could not sync round state.");

	if (!set_round_var(GAME_RULES_ROUND_VAR_MODE, RoundRuntimeData[RoundRuntimeMode]))
		set_fail_state("GameRules could not sync round mode.");

	if (!set_round_var(GAME_RULES_ROUND_VAR_TIME_LEFT, timeLeft))
		set_fail_state("GameRules could not sync round time_left.");
}
