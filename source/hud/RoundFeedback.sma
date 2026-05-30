#include <amxmodx>
#include <fakemeta>
#include <rezombie>
#include <rezombie/core/RoundState>

#pragma semicolon 1
#pragma compress 1

const ROUND_FEEDBACK_HUD_RED = 0;
const ROUND_FEEDBACK_HUD_GREEN = 180;
const ROUND_FEEDBACK_HUD_BLUE = 80;
const ROUND_FEEDBACK_HUD_CHANNEL = 3;
const ROUND_FEEDBACK_MIN_COUNTDOWN_SECONDS = 1;
const Float:ROUND_FEEDBACK_HUD_X = -1.0;
const Float:ROUND_FEEDBACK_HUD_Y = 0.22;
const Float:ROUND_FEEDBACK_HOLD_TIME = 1.1;
const Float:ROUND_FEEDBACK_FADE_IN = 0.0;
const Float:ROUND_FEEDBACK_FADE_OUT = 0.1;
const Float:ROUND_FEEDBACK_NEXT_COUNTDOWN_DELAY = 1.0;

enum FeedbackCountdown
{
	FeedbackCountdownNone = 0,
	FeedbackCountdownWarmup,
	FeedbackCountdownPrepare
};

new FeedbackCountdown:ActiveCountdown;
new Float:CountdownEndsAt;
new Float:NextCountdownAt;
new LastCountdownSeconds;

public plugin_precache()
{
	register_plugin("HUD: Round Feedback", "0.1.0", "BRUN0");
}

public plugin_init()
{
	register_forward(FM_StartFrame, "OnServerFrame");
}

public OnServerFrame()
{
	RefreshCountdownFromGameVars();

	if (ActiveCountdown == FeedbackCountdownNone)
		return FMRES_IGNORED;

	new Float:now = get_gametime();
	if (now < NextCountdownAt)
		return FMRES_IGNORED;

	ShowActiveCountdown(now);

	return FMRES_IGNORED;
}

public @game_state_changed(GameState:oldState, GameState:newState)
{
	if (newState == GameStateWarmup)
	{
		StartCountdown(FeedbackCountdownWarmup, 0.0);
		return;
	}

	if (oldState == GameStateWarmup && ActiveCountdown == FeedbackCountdownWarmup)
		StopCountdown();
}

public @round_prepare(Mode:mode, Float:duration)
{
	StartCountdown(FeedbackCountdownPrepare, get_gametime() + duration);

	new modeName[RZ_MAX_NAME_LENGTH];
	GetModeDisplayName(mode, modeName, charsmax(modeName));

	ShowHudMessage("%s starts soon", modeName);
}

public @round_start(Mode:mode, Float:duration)
{
	#pragma unused duration

	StopCountdown();

	new modeName[RZ_MAX_NAME_LENGTH];
	GetModeDisplayName(mode, modeName, charsmax(modeName));

	ShowHudMessage("%s started", modeName);
}

public @round_end(EndRoundEvent:event)
{
	StopCountdown();

	new message[RZ_MAX_NAME_LENGTH];
	GetRoundEndMessage(event, message, charsmax(message));

	ShowHudMessage("%s", message);
}

public @infect_player_post(id, attacker, Subclass:subclass)
{
	#pragma unused subclass

	new victimName[MAX_NAME_LENGTH];
	get_user_name(id, victimName, charsmax(victimName));

	if (attacker && is_user_connected(attacker))
	{
		new attackerName[MAX_NAME_LENGTH];
		get_user_name(attacker, attackerName, charsmax(attackerName));

		client_print(0, print_chat, "[ReZombie] %s infected %s.", attackerName, victimName);
		return;
	}

	client_print(0, print_chat, "[ReZombie] %s became the first zombie.", victimName);
}

stock RefreshCountdownFromGameVars()
{
	new GameState:gameState = get_game_var("game_state");
	new RoundState:roundState = get_game_var("round_state");

	if (gameState == GameStateWarmup && roundState == RoundStateNone)
	{
		if (ActiveCountdown != FeedbackCountdownWarmup)
			StartCountdown(FeedbackCountdownWarmup, 0.0);

		return;
	}

	if (ActiveCountdown == FeedbackCountdownWarmup)
		StopCountdown();
}

stock StartCountdown(FeedbackCountdown:countdown, Float:endsAt)
{
	ActiveCountdown = countdown;
	CountdownEndsAt = endsAt;
	NextCountdownAt = 0.0;
	LastCountdownSeconds = 0;
}

stock StopCountdown()
{
	ActiveCountdown = FeedbackCountdownNone;
	CountdownEndsAt = 0.0;
	NextCountdownAt = 0.0;
	LastCountdownSeconds = 0;
}

stock ShowActiveCountdown(Float:now)
{
	new seconds = GetActiveCountdownSeconds(now);
	if (seconds < ROUND_FEEDBACK_MIN_COUNTDOWN_SECONDS)
	{
		StopCountdown();
		return;
	}

	if (seconds == LastCountdownSeconds)
	{
		NextCountdownAt = now + ROUND_FEEDBACK_NEXT_COUNTDOWN_DELAY;
		return;
	}

	LastCountdownSeconds = seconds;
	NextCountdownAt = now + ROUND_FEEDBACK_NEXT_COUNTDOWN_DELAY;

	switch (ActiveCountdown)
	{
		case FeedbackCountdownWarmup:
			ShowHudMessage("Warmup ends in %d", seconds);
		case FeedbackCountdownPrepare:
			ShowHudMessage("Infection starts in %d", seconds);
	}
}

stock GetActiveCountdownSeconds(Float:now)
{
	switch (ActiveCountdown)
	{
		case FeedbackCountdownWarmup:
		{
			new Float:timer = get_game_var("timer");
			return floatround(timer, floatround_ceil);
		}
		case FeedbackCountdownPrepare:
		{
			return floatround(CountdownEndsAt - now, floatround_ceil);
		}
	}

	return 0;
}

stock GetModeDisplayName(Mode:mode, output[], length)
{
	if (!get_mode_var(mode, "notice_message", output, length))
		set_fail_state("RoundFeedback could not read mode notice_message.");

	if (!IsNullString(output))
		return;

	if (!get_mode_var(mode, "name", output, length))
		set_fail_state("RoundFeedback could not read mode name.");
}

stock GetRoundEndMessage(EndRoundEvent:event, output[], length)
{
	switch (event)
	{
		case EndRoundEventHumansWin:
		{
			copy(output, length, "Humans win");
		}
		case EndRoundEventZombiesWin:
		{
			copy(output, length, "Zombies win");
		}
		case EndRoundEventEndDraw:
		{
			copy(output, length, "Round draw");
		}
		default:
		{
			copy(output, length, "Round ended");
		}
	}
}

stock ShowHudMessage(const message[], any:...)
{
	new formatted[192];
	vformat(formatted, charsmax(formatted), message, 2);

	set_hudmessage(
		ROUND_FEEDBACK_HUD_RED,
		ROUND_FEEDBACK_HUD_GREEN,
		ROUND_FEEDBACK_HUD_BLUE,
		ROUND_FEEDBACK_HUD_X,
		ROUND_FEEDBACK_HUD_Y,
		0,
		0.0,
		ROUND_FEEDBACK_HOLD_TIME,
		ROUND_FEEDBACK_FADE_IN,
		ROUND_FEEDBACK_FADE_OUT,
		ROUND_FEEDBACK_HUD_CHANNEL
	);

	show_hudmessage(0, "%s", formatted);
}
