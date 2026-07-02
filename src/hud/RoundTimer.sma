#include <amxmodx>
#include <hlsdk_const>
#include <rezombie_version>
#include <rezombie_const>
#include <rezombie/core/RoundState>
#include <rezombie/api/GameVars>
#include <rezombie/api/Modes>

#pragma semicolon 1
#pragma compress 1

const ROUND_TIMER_MESSAGE_ARG_TIME = 1;
const HIDE_WEAPON_MESSAGE_ARG_FLAGS = 1;

new PlayerBaseHideFlags[MAX_PLAYERS + 1];
new RoundTimeMessageId;
new HideWeaponMessageId;
new bool:RoundTimerStarted;

public plugin_init()
{
	register_plugin("HUD: Round Timer", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	RoundTimeMessageId = get_user_msgid("RoundTime");
	HideWeaponMessageId = get_user_msgid("HideWeapon");

	if (!RoundTimeMessageId)
		set_fail_state("RoundTimer could not find RoundTime user message.");

	if (!HideWeaponMessageId)
		set_fail_state("RoundTimer could not find HideWeapon user message.");

	register_message(RoundTimeMessageId, "OnRoundTime");
	register_message(HideWeaponMessageId, "OnHideWeapon");
}

public plugin_cfg()
{
	RoundTimerStarted = IsPlayingRoundPublished();
	SyncRoundTimerHudToAll();
}

public client_putinserver(id)
{
	PlayerBaseHideFlags[id] = 0;
	SyncRoundTimerHud(id);
}

public client_disconnected(id)
{
	PlayerBaseHideFlags[id] = 0;
}

public OnRoundTime(messageId, messageDestination, id)
{
	#pragma unused messageId
	#pragma unused messageDestination
	#pragma unused id

	if (!ShouldShowRoundTimer())
		return PLUGIN_HANDLED;

	set_msg_arg_int(ROUND_TIMER_MESSAGE_ARG_TIME, ARG_SHORT, GetPublishedRoundTimer());
	return PLUGIN_CONTINUE;
}

public OnHideWeapon(messageId, messageDestination, id)
{
	#pragma unused messageId
	#pragma unused messageDestination

	if (!IsValidClientIndex(id))
		return PLUGIN_CONTINUE;

	new flags = get_msg_arg_int(HIDE_WEAPON_MESSAGE_ARG_FLAGS);
	PlayerBaseHideFlags[id] = flags & ~HIDEHUD_TIMER;

	set_msg_arg_int(HIDE_WEAPON_MESSAGE_ARG_FLAGS, ARG_BYTE, GetManagedHideFlags(id));
	return PLUGIN_CONTINUE;
}

public @game_state_changed(GameState:oldState, GameState:newState)
{
	#pragma unused oldState

	if (newState == GameStatePlaying)
		return;

	RoundTimerStarted = false;
	SyncRoundTimerHudToAll();
}

public @round_prepare(Mode:mode, Float:duration)
{
	#pragma unused mode
	#pragma unused duration

	RoundTimerStarted = false;
	SyncRoundTimerHudToAll();
}

public @round_start(Mode:mode, Float:duration)
{
	#pragma unused mode
	#pragma unused duration

	RoundTimerStarted = true;
	SyncRoundTimerHudToAll();
}

public @round_timer(timer)
{
	#pragma unused timer

	if (ShouldShowRoundTimer())
		SendRoundTimeToAll();
}

public @round_end(EndRoundEvent:event)
{
	#pragma unused event

	RoundTimerStarted = false;
	SyncRoundTimerHudToAll();
}

public @round_state_changed(RoundState:oldState, RoundState:newState)
{
	#pragma unused oldState

	if (newState == RoundStatePlaying)
		return;

	RoundTimerStarted = false;
	SyncRoundTimerHudToAll();
}

stock bool:ShouldShowRoundTimer()
{
	return RoundTimerStarted && IsPlayingRoundPublished();
}

stock bool:IsPlayingRoundPublished()
{
	return GameState:get_game_var("game_state") == GameStatePlaying
		&& RoundState:get_game_var("round_state") == RoundStatePlaying
		&& Mode:get_game_var("mode") != Invalid_Mode;
}

stock GetPublishedRoundTimer()
{
	new timer = floatround(Float:get_game_var("timer"), floatround_ceil);
	return timer > 0 ? timer : 0;
}

stock SyncRoundTimerHudToAll()
{
	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id))
			SyncRoundTimerHud(id);
	}
}

stock SyncRoundTimerHud(id)
{
	if (!IsValidConnectedClient(id))
		return;

	if (ShouldShowRoundTimer())
		SendRoundTime(id, GetPublishedRoundTimer());

	SendHideWeapon(id, GetManagedHideFlags(id));
}

stock SendRoundTimeToAll()
{
	new timer = GetPublishedRoundTimer();

	for (new id = 1; id <= MaxClients; id++)
	{
		if (is_user_connected(id))
			SendRoundTime(id, timer);
	}
}

stock SendRoundTime(id, timer)
{
	message_begin(MSG_ONE_UNRELIABLE, RoundTimeMessageId, _, id);
	write_short(timer);
	message_end();
}

stock SendHideWeapon(id, flags)
{
	message_begin(MSG_ONE_UNRELIABLE, HideWeaponMessageId, _, id);
	write_byte(flags);
	message_end();
}

stock GetManagedHideFlags(id)
{
	new flags = PlayerBaseHideFlags[id] & ~HIDEHUD_TIMER;

	if (!ShouldShowRoundTimer())
		flags |= HIDEHUD_TIMER;

	return flags;
}

stock bool:IsValidConnectedClient(id)
{
	return IsValidClientIndex(id) && is_user_connected(id);
}

stock bool:IsValidClientIndex(id)
{
	return id >= 1 && id <= MaxClients;
}
