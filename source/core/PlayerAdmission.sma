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
const Float:PLAYER_ADMISSION_SCAN_INTERVAL = 0.25;
const Float:PLAYER_ADMISSION_NO_INTRO_CAMERA_TIME = 0.0;

const TeamName:PLAYER_ADMISSION_DEFAULT_TEAM = TEAM_CT;

new Float:NextAdmissionScanAt;

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
	NextAdmissionScanAt = 0.0;
	RunAdmissionScan();
}

public client_putinserver(id)
{
	if (is_user_connected(id))
		AdmitPlayer(id);
}

public CommandBlockDefaultJoinFlow(id)
{
	if (is_user_connected(id))
		AdmitPlayer(id);

	return PLUGIN_HANDLED;
}

public OnChooseTeamPre(id, MenuChooseTeam:slot)
{
	#pragma unused slot

	if (!is_user_connected(id))
		return HC_CONTINUE;

	AdmitPlayer(id);
	SetHookChainReturn(ATYPE_INTEGER, PLAYER_ADMISSION_HOOK_FALSE);
	return HC_SUPERCEDE;
}

public OnChooseAppearancePre(id, slot)
{
	#pragma unused slot

	if (!is_user_connected(id))
		return HC_CONTINUE;

	AdmitPlayer(id);
	return HC_SUPERCEDE;
}

public OnShowVguiMenuPre(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	#pragma unused bitsSlots
	#pragma unused oldMenu

	if (!is_user_connected(id))
		return HC_CONTINUE;

	if (!IsDefaultTeamMenu(menuType))
		return HC_CONTINUE;

	AdmitPlayer(id);
	return HC_SUPERCEDE;
}

public OnShowMenuPre(id, bitsSlots, displayTime, needMore, menuText[])
{
	#pragma unused bitsSlots
	#pragma unused displayTime
	#pragma unused needMore
	#pragma unused menuText

	if (!is_user_connected(id))
		return HC_CONTINUE;

	if (!IsDefaultTeamMenuState(get_member(id, m_iMenu)))
		return HC_CONTINUE;

	AdmitPlayer(id);
	return HC_SUPERCEDE;
}

public OnPlayerJoiningThinkPre(id)
{
	if (!is_user_connected(id))
		return HC_CONTINUE;

	AdmitPlayer(id);
	return HC_SUPERCEDE;
}

public OnServerFrame()
{
	new Float:now = get_gametime();
	if (now < NextAdmissionScanAt)
		return FMRES_IGNORED;

	NextAdmissionScanAt = now + PLAYER_ADMISSION_SCAN_INTERVAL;
	RunAdmissionScan();

	return FMRES_IGNORED;
}

stock RunAdmissionScan()
{
	for (new id = 1; id <= MaxClients; id++)
	{
		if (!NeedsAdmission(id))
			continue;

		AdmitPlayer(id);
	}
}

stock bool:NeedsAdmission(id)
{
	if (!IsPlayerIndex(id) || !is_user_connected(id))
		return false;

	if (!IsPlayerOnPlayableGameTeam(id))
		return true;

	if (bool:get_member(id, m_bJustConnected))
		return true;

	if (IsDefaultTeamMenuState(get_member(id, m_iMenu)))
		return true;

	return !is_user_alive(id) && CanRespawnOnAdmission();
}

stock AdmitPlayer(id)
{
	EnsureAdmissionTeam(id);
	CompletePlayerAdmission(id);

	if (CanRespawnOnAdmission() && !is_user_alive(id))
	{
		rg_round_respawn(id);
		CompletePlayerAdmission(id);
	}
}

stock EnsureAdmissionTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);
	if (IsPlayableGameTeam(team))
	{
		if (IsAcceptingHumans() && team != PLAYER_ADMISSION_DEFAULT_TEAM)
			AssignDefaultTeam(id);

		return;
	}

	AssignDefaultTeam(id);
}

stock AssignDefaultTeam(id)
{
	rg_set_user_team(id, PLAYER_ADMISSION_DEFAULT_TEAM, MODEL_AUTO, true, false);

	if (get_member(id, m_iTeam) != PLAYER_ADMISSION_DEFAULT_TEAM)
		set_fail_state("PlayerAdmission could not admit player %d to the default team.", id);
}

stock CompletePlayerAdmission(id)
{
	set_member(id, m_iJoiningState, JOINED);
	set_member(id, m_iMenu, Menu_OFF);
	set_member(id, m_bJustConnected, false);

	set_member(id, m_pIntroCamera, PLAYER_ADMISSION_NO_ENTITY);
	set_member(id, m_fIntroCamTime, PLAYER_ADMISSION_NO_INTRO_CAMERA_TIME);
	set_entvar(id, var_iuser1, OBS_NONE);
	set_entvar(id, var_iuser2, PLAYER_ADMISSION_NO_OBSERVER_TARGET);
	set_entvar(id, var_iuser3, PLAYER_ADMISSION_NO_OBSERVER_TARGET);
	engset_view(id, id);
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

stock bool:IsPlayerOnPlayableGameTeam(id)
{
	return IsPlayableGameTeam(TeamName:get_member(id, m_iTeam));
}

stock bool:IsPlayableGameTeam(TeamName:team)
{
	return team == TEAM_TERRORIST || team == TEAM_CT;
}

stock bool:IsPlayerIndex(id)
{
	return 1 <= id <= PLAYER_ADMISSION_MAX_PLAYERS;
}
