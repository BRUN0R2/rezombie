// ReZombie weapons API.

#if defined _rezombie_api_weapons_included
	#endinput
#endif

#define _rezombie_api_weapons_included

#include <rezombie_const>
#include <rezombie/api/Models>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiWeapons
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiWeapons
	#endif
#else
	#pragma library ApiWeapons
#endif

/**
 * Creates a weapon object.
 *
 * @param handle    Unique weapon handle
 *
 * @return          Weapon handle
 * @error           Fails on empty or duplicate handle
 */
native Weapon:create_weapon(const handle[]);

/**
 * Finds a weapon by handle.
 *
 * @param handle    Weapon handle
 *
 * @return          Weapon handle, or null when not found
 */
native Weapon:FindWeapon(const handle[]);

/**
 * Requires a weapon by handle.
 *
 * @param handle    Weapon handle
 *
 * @return          Weapon handle
 * @error           Fails when the weapon is not registered
 */
stock Weapon:RequireWeapon(const handle[])
{
	new Weapon:weapon = FindWeapon(handle);

	if (weapon == Invalid_Weapon)
	{
		set_fail_state("Required weapon '%s' was not registered.", handle);
	}

	return weapon;
}

/**
 * Gets a weapon property.
 *
 * @param weapon    Weapon handle
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid weapon or property
 */
native any:get_weapon_var(Weapon:weapon, const var[], any:...);

/**
 * Sets a weapon property.
 *
 * Writable properties: "view_model", "player_model", "world_model".
 * Readonly properties: "handle".
 *
 * @param weapon    Weapon handle
 * @param var       Property name
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid weapon, readonly property or invalid value
 */
native bool:set_weapon_var(Weapon:weapon, const var[], any:...);
