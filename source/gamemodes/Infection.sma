#include <amxmodx>
#include <reapi>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const INFECTION_MIN_PLAYERS = 2;
const INFECTION_COUNTDOWN_SECONDS = 10;

const Float:INFECTION_START_CHECK_INTERVAL = 5.0;
const Float:INFECTION_WIN_CHECK_INTERVAL = 1.0;
const Float:INFECTION_ROUND_END_DELAY = 2.0;

enum InfectionRoundState
{
	InfectionRoundWaiting = 0,
	InfectionRoundCountdown,
	InfectionRoundRunning,
	InfectionRoundEnded
};

new InfectionRoundState:RoundState = InfectionRoundWaiting;
new Class:HumanClass = Invalid_Class;
new Class:ZombieClass = Invalid_Class;
new LastCountdownSecond;
new Float:NextStartCheckAt;
new Float:CountdownEndsAt;
new Float:NextWinCheckAt;

public plugin_precache()
{
	register_plugin("Mode: Infection", "0.1.0", "BRUN0");
}

public plugin_init()
{
	HumanClass = RequireClass("human");
	ZombieClass = RequireClass("zombie");

	RegisterHookChain(RG_CSGameRules_OnRoundFreezeEnd, "OnRoundFreezeEndPost", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilledPost", true);
	RegisterHookChain(RG_RoundEnd, "OnRoundEndPost", true);
}

public client_putinserver(id)
{
	#pragma unused id

	if (RoundState == InfectionRoundWaiting)
		ScheduleRoundStartCheck(get_gametime());
}

public client_disconnected(id)
{
	#pragma unused id

	if (RoundState == InfectionRoundRunning)
		CheckWinConditions();
}

public OnRoundFreezeEndPost()
{
	PrepareInfectionRound();
}

public OnPlayerKilledPost(id, attacker, gib)
{
	#pragma unused id
	#pragma unused attacker
	#pragma unused gib

	if (RoundState == InfectionRoundRunning)
		CheckWinConditions();
}

public OnRoundEndPost(WinStatus:status, ScenarioEventEndRound:event, Float:delay)
{
	#pragma unused status
	#pragma unused event
	#pragma unused delay

	ClearRoundTimers();
	RoundState = InfectionRoundEnded;
}

public server_frame()
{
	new Float:time = get_gametime();

	switch (RoundState)
	{
		case InfectionRoundWaiting:
			FrameCheckRoundStart(time);
		case InfectionRoundCountdown:
			FrameRunInfectionCountdown(time);
		case InfectionRoundRunning:
			FrameCheckWinConditions(time);
	}
}

stock FrameCheckRoundStart(Float:time)
{
	if (NextStartCheckAt <= 0.0 || time < NextStartCheckAt)
		return;

	if (!HasEnoughAlivePlayers())
	{
		ScheduleRoundStartCheck(time);
		return;
	}

	StartInfectionCountdown(time);
}

stock FrameRunInfectionCountdown(Float:time)
{
	if (!HasEnoughAlivePlayers())
	{
		AbortInfectionCountdown(time);
		return;
	}

	if (time >= CountdownEndsAt)
	{
		StartInfectionRound(time);
		return;
	}

	new remaining = floatround(CountdownEndsAt - time, floatround_ceil);
	if (remaining != LastCountdownSecond)
	{
		LastCountdownSecond = remaining;
		client_print(0, print_center, "Infection starts in %d", remaining);
	}
}

stock FrameCheckWinConditions(Float:time)
{
	if (NextWinCheckAt <= 0.0 || time < NextWinCheckAt)
		return;

	NextWinCheckAt = time + INFECTION_WIN_CHECK_INTERVAL;
	CheckWinConditions();
}

public CheckWinConditions()
{
	if (RoundState != InfectionRoundRunning)
		return;

	new alivePlayers[MAX_PLAYERS];
	new aliveNum;
	get_players(alivePlayers, aliveNum, "a");

	if (aliveNum < 1)
	{
		EndInfectionRound(WINSTATUS_DRAW, ROUND_END_DRAW);
		return;
	}

	new humans;
	new zombies;

	for (new index = 0; index < aliveNum; index++)
	{
		new player = alivePlayers[index];

		if (IsZombie(player))
			zombies++;
		else if (IsHuman(player))
			humans++;
	}

	if (zombies < 1)
	{
		EndInfectionRound(WINSTATUS_CTS, ROUND_CTS_WIN);
		return;
	}

	if (humans < 1)
	{
		EndInfectionRound(WINSTATUS_TERRORISTS, ROUND_TERRORISTS_WIN);
		return;
	}
}

stock PrepareInfectionRound()
{
	ClearRoundTimers();
	RoundState = InfectionRoundWaiting;

	if (!HasEnoughAlivePlayers())
	{
		client_print(0, print_center, "Waiting for players");
		ScheduleRoundStartCheck(get_gametime());
		return;
	}

	StartInfectionCountdown(get_gametime());
}

stock StartInfectionCountdown(Float:time)
{
	ClearRoundTimers();
	RoundState = InfectionRoundCountdown;
	CountdownEndsAt = time + float(INFECTION_COUNTDOWN_SECONDS);
	LastCountdownSecond = -1;
	FrameRunInfectionCountdown(time);
}

stock AbortInfectionCountdown(Float:time)
{
	ClearRoundTimers();
	RoundState = InfectionRoundWaiting;
	client_print(0, print_center, "Waiting for players");
	ScheduleRoundStartCheck(time);
}

stock StartInfectionRound(Float:time)
{
	ClearRoundTimers();
	RoundState = InfectionRoundRunning;

	AssignAliveHumans();
	InfectFirstZombie();

	NextWinCheckAt = time + INFECTION_WIN_CHECK_INTERVAL;
	CheckWinConditions();
}

stock AssignAliveHumans()
{
	new alivePlayers[MAX_PLAYERS];
	new aliveNum;
	get_players(alivePlayers, aliveNum, "a");

	for (new index = 0; index < aliveNum; index++)
	{
		new player = alivePlayers[index];

		if (!change_player_class(player, HumanClass))
			set_fail_state("Failed to assign human class.");
	}
}

stock InfectFirstZombie()
{
	if (ZombieClass == Invalid_Class)
		set_fail_state("Required zombie class is invalid.");

	new alivePlayers[MAX_PLAYERS];
	new aliveNum;
	get_players(alivePlayers, aliveNum, "a");

	if (aliveNum < INFECTION_MIN_PLAYERS)
		set_fail_state("Cannot choose first zombie without enough alive players.");

	new target = alivePlayers[random(aliveNum)];

	if (!infect_player(target))
		set_fail_state("Failed to infect the first zombie.");

	new name[MAX_NAME_LENGTH];
	get_user_name(target, name, charsmax(name));
	client_print(0, print_center, "%s is the first zombie", name);
}

stock EndInfectionRound(WinStatus:status, ScenarioEventEndRound:event)
{
	ClearRoundTimers();
	RoundState = InfectionRoundEnded;
	rg_round_end(INFECTION_ROUND_END_DELAY, status, event, .trigger = true);
}

stock bool:HasEnoughAlivePlayers()
{
	new alivePlayers[MAX_PLAYERS];
	new aliveNum;
	get_players(alivePlayers, aliveNum, "a");

	return aliveNum >= INFECTION_MIN_PLAYERS;
}

stock ScheduleRoundStartCheck(Float:time)
{
	NextStartCheckAt = time + INFECTION_START_CHECK_INTERVAL;
}

stock ClearRoundTimers()
{
	NextStartCheckAt = 0.0;
	CountdownEndsAt = 0.0;
	NextWinCheckAt = 0.0;
	LastCountdownSecond = -1;
}
