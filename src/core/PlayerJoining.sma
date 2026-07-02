#include <amxmodx>
#include <reapi>
#include <rezombie_version>
#include <rezombie_const>

#pragma semicolon 1
#pragma compress 1

const PLAYER_JOINING_HOOK_FALSE = 0;
const TeamName:PLAYER_JOINING_DEFAULT_TEAM = TEAM_CT;

enum _:PlayerJoiningHookData
{
	PlayerJoiningHookChooseTeam,
	PlayerJoiningHookChooseAppearance,
	PlayerJoiningHookShowVguiMenu,
	PlayerJoiningHookShowMenu,
	PlayerJoiningHookJoiningThink,
	PlayerJoiningHookCount
};

new HookChain:PlayerJoiningHooks[PlayerJoiningHookCount];

public plugin_init()
{
	register_plugin("Core: Player Joining", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	register_clcmd("chooseteam", "CommandJoinTeam");
	register_clcmd("jointeam", "CommandJoinTeam");
	register_clcmd("joinclass", "CommandJoinTeam");

	CreatePlayerJoiningHooks();
}

public plugin_end()
{
	for (new index = 0; index < sizeof PlayerJoiningHooks; index++)
	{
		if (PlayerJoiningHooks[index] == INVALID_HOOKCHAIN)
			continue;

		DisableHookChain(PlayerJoiningHooks[index]);
		PlayerJoiningHooks[index] = INVALID_HOOKCHAIN;
	}
}

stock CreatePlayerJoiningHooks()
{
	for (new index = 0; index < sizeof PlayerJoiningHooks; index++)
		PlayerJoiningHooks[index] = INVALID_HOOKCHAIN;

	PlayerJoiningHooks[PlayerJoiningHookChooseTeam] = RegisterRequiredPlayerJoiningHook(
		.functionId = RG_HandleMenu_ChooseTeam,
		.callback = "OnChooseTeamPre",
		.post = false
	);

	PlayerJoiningHooks[PlayerJoiningHookChooseAppearance] = RegisterRequiredPlayerJoiningHook(
		.functionId = RG_HandleMenu_ChooseAppearance,
		.callback = "OnChooseAppearancePre",
		.post = false
	);

	PlayerJoiningHooks[PlayerJoiningHookShowVguiMenu] = RegisterRequiredPlayerJoiningHook(
		.functionId = RG_ShowVGUIMenu,
		.callback = "OnShowVguiMenuPre",
		.post = false
	);

	PlayerJoiningHooks[PlayerJoiningHookShowMenu] = RegisterRequiredPlayerJoiningHook(
		.functionId = RG_ShowMenu,
		.callback = "OnShowMenuPre",
		.post = false
	);

	PlayerJoiningHooks[PlayerJoiningHookJoiningThink] = RegisterRequiredPlayerJoiningHook(
		.functionId = RG_CBasePlayer_JoiningThink,
		.callback = "OnPlayerJoiningThinkPost",
		.post = true
	);
}

stock HookChain:RegisterRequiredPlayerJoiningHook(ReAPIFunc:functionId, const callback[], bool:post)
{
	new HookChain:hookChain = RegisterHookChain(
		.function_id = functionId,
		.callback = callback,
		.post = post
	);
	if (hookChain == INVALID_HOOKCHAIN)
		set_fail_state("PlayerJoining could not register ReAPI hook '%s'.", callback);

	return hookChain;
}

public CommandJoinTeam(id)
{
	JoinPlayer(id);
	return PLUGIN_HANDLED;
}

public OnChooseTeamPre(id, MenuChooseTeam:slot)
{
	#pragma unused slot

	if (!IsConnected(id))
		return HC_CONTINUE;

	JoinPlayer(id);
	SetHookChainReturn(ATYPE_INTEGER, PLAYER_JOINING_HOOK_FALSE);
	return HC_SUPERCEDE;
}

public OnChooseAppearancePre(id, slot)
{
	#pragma unused slot

	if (!IsConnected(id))
		return HC_CONTINUE;

	JoinPlayer(id);
	return HC_SUPERCEDE;
}

public OnShowVguiMenuPre(id, VGUIMenu:menuType, bitsSlots, oldMenu[])
{
	#pragma unused bitsSlots
	#pragma unused oldMenu

	if (!IsConnected(id))
		return HC_CONTINUE;

	if (!IsDefaultJoiningVguiMenu(menuType))
		return HC_CONTINUE;

	JoinPlayer(id);
	return HC_SUPERCEDE;
}

public OnShowMenuPre(id, bitsSlots, displayTime, needMore, menuText[])
{
	#pragma unused bitsSlots, displayTime, needMore, menuText

	if (!IsConnected(id))
		return HC_CONTINUE;

	if (!IsDefaultJoiningMenu(get_member(id, m_iMenu)))
		return HC_CONTINUE;

	JoinPlayer(id);
	return HC_SUPERCEDE;
}

public OnPlayerJoiningThinkPost(id)
{
	if (IsConnected(id))
		JoinPlayer(id);

	return HC_CONTINUE;
}

stock bool:JoinPlayer(id)
{
	if (!CanStartPlayerJoining(id))
		return false;

	MarkPlayerPickingTeam(id);

	return PlayerJoined(id);
}

stock bool:PlayerJoined(id)
{
	if (!rg_join_team(id, PLAYER_JOINING_DEFAULT_TEAM))
		return false;

	return true;
}

stock bool:IsPlayerJoined(id)
{
	new JoinState:joiningState = JoinState:get_member(id, m_iJoiningState);

	return joiningState == JOINED || joiningState == GETINTOGAME;
}

stock bool:CanStartPlayerJoining(id)
{
	if (is_nullent(id) || !IsConnected(id))
		return false;

	if (IsPlayerJoined(id))
		return false;

	if (IsPlayerChoosingAppearance(id))
		return false;

	return IsPlayerWaitingForTeamPick(id);
}

stock bool:IsPlayerWaitingForTeamPick(id)
{
	new JoinState:joiningState = JoinState:get_member(id, m_iJoiningState);
	return joiningState == SHOWTEAMSELECT || joiningState == PICKINGTEAM;
}

stock bool:IsPlayerChoosingAppearance(id)
{
	return get_member(id, m_iMenu) == Menu_ChooseAppearance;
}

stock MarkPlayerPickingTeam(id)
{
	if (JoinState:get_member(id, m_iJoiningState) == SHOWTEAMSELECT)
		set_member(id, m_iJoiningState, PICKINGTEAM);
}

stock bool:IsDefaultJoiningVguiMenu(VGUIMenu:menuType)
{
	switch (menuType)
	{
		case VGUI_Menu_Team, VGUI_Menu_Class_T, VGUI_Menu_Class_CT:
			return true;
	}

	return false;
}

stock bool:IsDefaultJoiningMenu(menu)
{
	switch (menu)
	{
		case Menu_ChooseTeam, Menu_IGChooseTeam, Menu_ChooseAppearance:
			return true;
	}

	return false;
}
