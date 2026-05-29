#include <amxmodx>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const INFECTION_NO_TARGET = 0;
const INFECTION_NO_ATTACKER = 0;
const INFECTION_MIN_PLAYERS = 2;
const Float:INFECTION_ROUND_TIME = 180.0;

new Mode:InfectionMode = Invalid_Mode;
new Class:ZombieClass = Invalid_Class;
new Subclass:ZombieSubclass = Invalid_Subclass;

public plugin_precache()
{
	register_plugin("Mode: Infection", "0.1.0", "BRUN0");

	ZombieClass = RequireClass("zombie");
	ZombieSubclass = RequireSubclass("zombie_swarm");

	InfectionMode = create_mode("infection", "@LaunchInfection");
	set_mode_var(InfectionMode, "name", "Infection");
	set_mode_var(InfectionMode, "notice_message", "Infection");
	set_mode_var(InfectionMode, "min_players", INFECTION_MIN_PLAYERS);
	set_mode_var(InfectionMode, "round_time", INFECTION_ROUND_TIME);
}

@LaunchInfection(Mode:mode, target)
{
	if (mode != InfectionMode)
		return false;

	if (ZombieClass == Invalid_Class)
		return false;

	if (ZombieSubclass == Invalid_Subclass)
		return false;

	new player = SelectFirstZombie(target);
	if (player == INFECTION_NO_TARGET)
		return false;

	return infect_player(player, INFECTION_NO_ATTACKER, ZombieSubclass);
}

stock SelectFirstZombie(target)
{
	if (IsEligibleFirstZombie(target))
		return target;

	new players[MAX_PLAYERS];
	new playersCount;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (!IsEligibleFirstZombie(id))
			continue;

		players[playersCount] = id;
		playersCount++;
	}

	if (!playersCount)
		return INFECTION_NO_TARGET;

	return players[random(playersCount)];
}

stock bool:IsEligibleFirstZombie(id)
{
	return is_user_connected(id) && is_user_alive(id) && IsHuman(id);
}
