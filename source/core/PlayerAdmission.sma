#include <amxmodx>
#include <fakemeta>
#include <reapi>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const PLAYER_ADMISSION_HOOK_FALSE = 0;
const PLAYER_ADMISSION_NO_ENTITY = 0;
const PLAYER_ADMISSION_NO_OBSERVER_TARGET = 0;
const PLAYER_ADMISSION_MAX_PLAYERS = 32;
const PLAYER_ADMISSION_PLAYERS_PER_PUMP = 4;
const Float:PLAYER_ADMISSION_PUMP_INTERVAL = 0.10;
const Float:PLAYER_ADMISSION_NO_INTRO_CAMERA_TIME = 0.0;

const TeamName:PLAYER_ADMISSION_DEFAULT_TEAM = TEAM_CT;

enum AdmissionState
{
	AdmissionStateNone = 0,
	AdmissionStateWaitingEntity,
	AdmissionStateAssigningTeam,
	AdmissionStateCompletingJoin,
	AdmissionStateWaitingRespawn,
	AdmissionStateActive,
	AdmissionStateCount
};

new AdmissionState:PlayerAdmissionStates[PLAYER_ADMISSION_MAX_PLAYERS + 1];
new AdmissionPumpCursor = 1;
new Float:NextAdmissionPumpAt;

public plugin_precache()
{
	register_plugin("Core: Player Admission", "0.1.0", "BRUN0");
}

public plugin_init()
{
	register_clcmd("chooseteam", "CommandBlockDefaultJoinFlow");
	register_clcmd("jointeam", "CommandBlockDefaultJoinFlow");
	register_clcmd("joinclass", "CommandBlockDefaultJoinFlow");

	RegisterHookChain(RG_HandleMenu_ChooseTeam, "OnChooseTeamPre", false);
	RegisterHookChain(RG_HandleMenu_ChooseAppearance, "OnChooseAppearancePre", false);
	RegisterHookChain(RG_ShowVGUIMenu, "OnShowVguiMenuPre", false);
	RegisterHookChain(RG_ShowMenu, "OnShowMenuPre", false);
	RegisterHookChain(RG_CBasePlayer_JoiningThink, "OnPlayerJoiningThinkPre", false);
	register_forward(FM_StartFrame, "OnServerFrame");
}

public plugin_cfg()
{
	AdmissionPumpCursor = 1;
	NextAdmissionPumpAt = 0.0;
	QueueConnectedPlayers();
}

public client_putinserver(id)
{
	QueuePlayerAdmission(id);
}

public client_disconnected(id)
{
	ClearPlayerAdmission(id);
}

public CommandBlockDefaultJoinFlow(id)
{
	QueuePlayerAdmission(id);
	ProcessPlayerAdmission(id);
	return PLUGIN_HANDLED;
}

public OnChooseTeamPre(id, MenuChooseTeam:slot)
{
	#pragma unused slot

	if (!IsConnectedPlayer(id))
		return HC_CONTINUE;

	QueuePlayerAdmission(id);
	ProcessPlayerAdmission(id);
	SetHookChainReturn(ATYPE_INTEGER, PLAYER_ADMISSION_HOOK_FALSE);
	return HC_SUPERCEDE;
}

public OnChooseAppearancePre(id, slot)
{
	#pragma unused slot

	if (!IsConnectedPlayer(id))
		return HC_CONTINUE;

	QueuePlayerAdmission(id);
	ProcessPlayerAdmission(id);
	return HC_SUPERCEDE;
}

public OnShowVguiMenuPre(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	#pragma unused bitsSlots
	#pragma unused oldMenu

	if (!IsConnectedPlayer(id))
		return HC_CONTINUE;

	if (!IsDefaultTeamMenu(menuType))
		return HC_CONTINUE;

	QueuePlayerAdmission(id);
	ProcessPlayerAdmission(id);
	return HC_SUPERCEDE;
}

public OnShowMenuPre(id, bitsSlots, displayTime, needMore, menuText[])
{
	#pragma unused bitsSlots, displayTime, needMore, menuText

	if (!IsConnectedPlayer(id))
		return HC_CONTINUE;

	if (!IsPlayerEntityReady(id))
	{
		QueuePlayerAdmission(id);
		return HC_CONTINUE;
	}

	if (!IsDefaultTeamMenuState(get_member(id, m_iMenu)))
		return HC_CONTINUE;

	QueuePlayerAdmission(id);
	ProcessPlayerAdmission(id);
	return HC_SUPERCEDE;
}

public OnPlayerJoiningThinkPre(id)
{
	if (!IsConnectedPlayer(id))
		return HC_CONTINUE;

	QueuePlayerAdmission(id);
	ProcessPlayerAdmission(id);
	return HC_SUPERCEDE;
}

public OnServerFrame()
{
	new Float:now = get_gametime();
	if (now < NextAdmissionPumpAt)
		return FMRES_IGNORED;

	NextAdmissionPumpAt = now + PLAYER_ADMISSION_PUMP_INTERVAL;
	QueueConnectedPlayers();
	RunAdmissionPump();

	return FMRES_IGNORED;
}

stock QueueConnectedPlayers()
{
	for (new id = 1; id <= MaxClients; id++)
	{
		if (!IsConnectedPlayer(id))
			continue;

		if (PlayerAdmissionStates[id] == AdmissionStateNone)
			QueuePlayerAdmission(id);
	}
}

stock QueuePlayerAdmission(id)
{
	if (!IsConnectedPlayer(id))
		return;

	switch (PlayerAdmissionStates[id])
	{
		case AdmissionStateNone, AdmissionStateActive:
			PlayerAdmissionStates[id] = AdmissionStateWaitingEntity;
	}
}

stock ClearPlayerAdmission(id)
{
	if (!IsPlayerIndex(id))
		return;

	PlayerAdmissionStates[id] = AdmissionStateNone;
}

stock RunAdmissionPump()
{
	new processedPlayers;

	for (new scannedPlayers = 0; scannedPlayers < PLAYER_ADMISSION_MAX_PLAYERS && processedPlayers < PLAYER_ADMISSION_PLAYERS_PER_PUMP; scannedPlayers++)
	{
		new id = AdmissionPumpCursor;
		AdvanceAdmissionPumpCursor();

		if (!IsPlayerIndex(id))
			continue;

		if (!IsConnectedPlayer(id))
		{
			ClearPlayerAdmission(id);
			continue;
		}

		if (ShouldRespawnActivePlayer(id))
			PlayerAdmissionStates[id] = AdmissionStateWaitingRespawn;

		if (PlayerAdmissionStates[id] == AdmissionStateNone)
			continue;

		ProcessPlayerAdmission(id);
		processedPlayers++;
	}
}

stock AdvanceAdmissionPumpCursor()
{
	AdmissionPumpCursor++;

	if (AdmissionPumpCursor > PLAYER_ADMISSION_MAX_PLAYERS)
		AdmissionPumpCursor = 1;
}

stock bool:ProcessPlayerAdmission(id)
{
	if (!IsConnectedPlayer(id))
	{
		ClearPlayerAdmission(id);
		return false;
	}

	if (!IsPlayerEntityReady(id))
	{
		PlayerAdmissionStates[id] = AdmissionStateWaitingEntity;
		return false;
	}

	for (new step = 0; step < _:AdmissionStateCount; step++)
	{
		switch (PlayerAdmissionStates[id])
		{
			case AdmissionStateNone:
			{
				return true;
			}
			case AdmissionStateWaitingEntity:
			{
				PlayerAdmissionStates[id] = AdmissionStateAssigningTeam;
			}
			case AdmissionStateAssigningTeam:
			{
				if (!EnsureAdmissionTeam(id))
					return false;

				PlayerAdmissionStates[id] = AdmissionStateCompletingJoin;
			}
			case AdmissionStateCompletingJoin:
			{
				CompletePlayerAdmission(id);
				PlayerAdmissionStates[id] = ShouldRespawnOnAdmission(id) ? AdmissionStateWaitingRespawn : AdmissionStateActive;
			}
			case AdmissionStateWaitingRespawn:
			{
				if (!ApplyAdmissionRespawn(id))
					return false;

				PlayerAdmissionStates[id] = AdmissionStateActive;
				return true;
			}
			case AdmissionStateActive:
			{
				return true;
			}
		}
	}

	return PlayerAdmissionStates[id] == AdmissionStateActive;
}

stock bool:EnsureAdmissionTeam(id)
{
	new TeamName:team = TeamName:get_member(id, m_iTeam);
	if (IsPlayableGameTeam(team))
	{
		if (IsAcceptingHumans() && team != PLAYER_ADMISSION_DEFAULT_TEAM)
			return AssignDefaultTeam(id);

		return true;
	}

	return AssignDefaultTeam(id);
}

stock bool:AssignDefaultTeam(id)
{
	rg_set_user_team(id, PLAYER_ADMISSION_DEFAULT_TEAM, MODEL_AUTO, true, false);

	if (!IsConnectedPlayer(id))
	{
		ClearPlayerAdmission(id);
		return false;
	}

	if (!IsPlayerEntityReady(id))
	{
		PlayerAdmissionStates[id] = AdmissionStateWaitingEntity;
		return false;
	}

	if (TeamName:get_member(id, m_iTeam) != PLAYER_ADMISSION_DEFAULT_TEAM)
		set_fail_state("PlayerAdmission could not admit player %d to the default team.", id);

	return true;
}

stock CompletePlayerAdmission(id)
{
	CompletePlayerJoinState(id);

	if (ShouldResetPlayerJoinCamera(id))
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
	set_member(id, m_pIntroCamera, PLAYER_ADMISSION_NO_ENTITY);
	set_member(id, m_fIntroCamTime, PLAYER_ADMISSION_NO_INTRO_CAMERA_TIME);
	set_entvar(id, var_iuser1, OBS_NONE);
	set_entvar(id, var_iuser2, PLAYER_ADMISSION_NO_OBSERVER_TARGET);
	set_entvar(id, var_iuser3, PLAYER_ADMISSION_NO_OBSERVER_TARGET);
	engset_view(id, id);
}

stock bool:ApplyAdmissionRespawn(id)
{
	if (!IsConnectedPlayer(id))
	{
		ClearPlayerAdmission(id);
		return false;
	}

	if (!CanRespawnOnAdmission() || is_user_alive(id))
		return true;

	rg_round_respawn(id);

	if (!IsConnectedPlayer(id))
	{
		ClearPlayerAdmission(id);
		return false;
	}

	if (!IsPlayerEntityReady(id))
	{
		PlayerAdmissionStates[id] = AdmissionStateWaitingEntity;
		return false;
	}

	CompletePlayerAdmission(id);
	return true;
}

stock bool:ShouldResetPlayerJoinCamera(id)
{
	return !is_user_bot(id) && !is_user_hltv(id);
}

stock bool:ShouldRespawnOnAdmission(id)
{
	return CanRespawnOnAdmission() && !is_user_alive(id);
}

stock bool:ShouldRespawnActivePlayer(id)
{
	return PlayerAdmissionStates[id] == AdmissionStateActive
		&& IsPlayerEntityReady(id)
		&& ShouldRespawnOnAdmission(id);
}

stock bool:CanRespawnOnAdmission()
{
	return IsAcceptingHumans();
}

stock bool:IsAcceptingHumans()
{
	new GameState:gameState = get_game_var("game_state");
	if (gameState != GameStatePlaying)
		return true;

	new RoundState:roundState = get_game_var("round_state");
	return roundState == RoundStateNone || roundState == RoundStatePrepare;
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

stock bool:IsPlayableGameTeam(TeamName:team)
{
	return team == TEAM_TERRORIST || team == TEAM_CT;
}

stock bool:IsPlayerIndex(id)
{
	return 1 <= id <= PLAYER_ADMISSION_MAX_PLAYERS;
}

stock bool:IsConnectedPlayer(id)
{
	return IsPlayerIndex(id) && is_user_connected(id);
}

stock bool:IsPlayerEntityReady(id)
{
	return IsConnectedPlayer(id) && is_entity(id);
}
