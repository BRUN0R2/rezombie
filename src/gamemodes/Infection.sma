#include <rezombie_main>
#include <reapi>

#pragma semicolon 1
#pragma compress 1

new Mode:infectionMode = Invalid_Mode;
new Class:zombieClass = Invalid_Class;
new HookChain:InfectionTakeDamageHook = INVALID_HOOKCHAIN;

public plugin_precache()
{
	register_plugin("Mode: Infection", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	zombieClass = RequireClass("zombie");

	new Mode:mode = infectionMode = create_mode("infection", "@LaunchInfection");
	set_mode_var(mode, "name", "Infection");
	set_mode_var(mode, "notice_message", "Infection");
	set_mode_var(mode, "min_players", 2);
	set_mode_var(mode, "round_time", 360.0);
	set_mode_var(mode, "respawn", Respawn_ToZombiesTeam);
	set_mode_var(mode, "default_class", zombieClass);
	set_mode_var(mode, "override_default_class", true);
}

public plugin_init()
{
	InfectionTakeDamageHook = RegisterHookChain(
		.function_id = RG_CBasePlayer_TakeDamage,
		.callback = "OnPlayerTakeDamagePre",
		.post = false
	);

	if (InfectionTakeDamageHook == INVALID_HOOKCHAIN)
		set_fail_state("Infection could not register player damage hook.");
}

public plugin_end()
{
	if (InfectionTakeDamageHook != INVALID_HOOKCHAIN)
	{
		DisableHookChain(InfectionTakeDamageHook);
		InfectionTakeDamageHook = INVALID_HOOKCHAIN;
	}
}

@LaunchInfection(target)
{
	new players[MAX_PLAYERS];
	new playersCount;
	CollectAliveHumans(players, playersCount);

	if (target != RZ_MODE_NO_TARGET && !IsAliveHuman(target))
	{
		log_amx("Infection launch target %d must be an alive human.", target);
		return false;
	}

	new zombiesCount = GetInitialZombieCount(playersCount);
	if (zombiesCount <= 0)
		return false;

	for (new zombieIndex = 0; zombieIndex < zombiesCount; zombieIndex++)
	{
		new preferred = zombieIndex == 0 ? target : RZ_MODE_NO_TARGET;
		new player = PickPlayer(players, playersCount, preferred);
		if (!player)
			return false;

		if (change_player_class(player, zombieClass) > RZ_CONTINUE)
			return false;
	}

	return bool:zombiesCount;
}

stock GetInitialZombieCount(playersCount)
{
	new zombiesCount = 1;
	if (playersCount > 30)
		zombiesCount = 4;
	else if (playersCount > 20)
		zombiesCount = 3;
	else if (playersCount > 10)
		zombiesCount = 2;

	return min(zombiesCount, playersCount);
}

public OnPlayerTakeDamagePre(victim, inflictor, attacker, Float:damage, damageType)
{
	if (!IsAliveHuman(victim) || !IsAliveZombie(attacker)) {
		return HC_CONTINUE;
	}

	if (Mode:get_game_var("mode") != infectionMode) {
		return HC_CONTINUE;
	}

	if (Class:get_player_var(attacker, "class") != zombieClass) {
		return HC_CONTINUE;
	}

	/*new Weapon:weapon = get_entvar(inflictor, var_impulse);
	if (!is_weapon(weapon)) {
		return HC_CONTINUE;
	}

	if (get_weapon_var(weapon, "type") != weapon_type_melee) {
		return HC_CONTINUE;
	}*/

	// Temporary fix.
	if (get_user_weapon(attacker) != CSW_KNIFE) {
		return HC_CONTINUE;
	}

	if (AbsorbInfectionDamageWithArmor(victim, damage))
		return HC_CONTINUE;

	if (!infect_player(victim, attacker))
		return HC_CONTINUE;

	SetHookChainArg(4, ATYPE_FLOAT, 0.0);
	return HC_CONTINUE;
}

stock bool:AbsorbInfectionDamageWithArmor(victim, Float:damage)
{
	new Float:armor = get_entvar(
		victim,
		var_armorvalue
	);

	if (armor <= 0.0)
		return false;

	armor = floatmax(armor - damage, 0.0);
	set_entvar(victim, var_armorvalue, armor);
	SetHookChainArg(4, ATYPE_FLOAT, 0.0);

	return armor > 0.0;
}
