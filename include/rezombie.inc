// ReZombie public API.

#if defined _rezombie_included
	#endinput
#endif

#define _rezombie_included

#include <rezombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib rezombie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib rezombie
	#endif
#else
	#pragma library rezombie
#endif

/**
 * Class natives.
 */

/**
 * Creates a player class.
 *
 * @param handle    Unique class handle
 * @param team      Class team
 *
 * @return          Class handle
 */
native Class:create_class(const handle[], Team:team);

/**
 * Finds a player class by handle.
 *
 * @param handle    Class handle
 *
 * @return          Class handle, or null when not found
 */
native Class:FindClass(const handle[]);

/**
 * Requires a player class by handle.
 *
 * @param handle    Class handle
 *
 * @return          Class handle
 * @error           Fails when the class is not registered
 */
stock Class:RequireClass(const handle[])
{
	new Class:class = FindClass(handle);

	if (class == Invalid_Class)
	{
		set_fail_state("Required class '%s' was not registered.", handle);
	}

	return class;
}

/**
 * Gets a class property.
 *
 * @param class     Class handle
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid class or property
 */
native any:get_class_var(Class:class, const var[], any:...);

/**
 * Sets a class property.
 *
 * @param class     Class handle
 * @param var       Property name
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid class, property or value
 */
native bool:set_class_var(Class:class, const var[], any:...);

/**
 * Subclass natives.
 */

/**
 * Creates a player subclass.
 *
 * @param handle    Unique subclass handle
 * @param class     Parent class handle
 *
 * @return          Subclass handle
 * @error           Fails on invalid parent class
 */
native Subclass:create_subclass(const handle[], Class:class);

/**
 * Gets a subclass property.
 *
 * @param subclass  Subclass handle
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid subclass or property
 */
native any:get_subclass_var(Subclass:subclass, const var[], any:...);

/**
 * Sets a subclass property.
 *
 * @param subclass  Subclass handle
 * @param var       Property name
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid subclass, property or value
 */
native bool:set_subclass_var(Subclass:subclass, const var[], any:...);

/**
 * Props natives.
 */

/**
 * Gets a props property.
 *
 * @param props     Props handle
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid props or property
 */
native any:get_props_var(Props:props, const var[], any:...);

/**
 * Sets a props property.
 *
 * @param props     Props handle
 * @param var       Property name
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid props, property or value
 */
native bool:set_props_var(Props:props, const var[], any:...);

/**
 * Player natives.
 */

/**
 * Gets the current player class.
 *
 * @param id        Player index
 *
 * @return          Player class handle
 * @error           Fails on invalid or disconnected player
 */
native Class:get_player_class(id);

/**
 * Gets the current player subclass.
 *
 * @param id        Player index
 *
 * @return          Player subclass handle, or null when not set
 * @error           Fails on invalid or disconnected player
 */
native Subclass:get_player_subclass(id);

/**
 * Changes the player class and applies its runtime state.
 *
 * @param id        Player index
 * @param class     Class handle
 * @param subclass  Optional subclass handle
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid player, class or subclass
 */
native bool:change_player_class(id, Class:class, Subclass:subclass = Invalid_Subclass);

/**
 * Zombie natives.
 */

/**
 * Infects a player using the registered zombie class.
 *
 * @param id        Player index
 * @param attacker  Optional attacker index
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid player, attacker or missing zombie class
 */
native bool:infect_player(id, attacker = 0);

/**
 * Checks whether a player is currently a zombie.
 *
 * @param id        Player index
 *
 * @return          true if the player is a zombie, false otherwise
 */
native bool:IsZombie(id);

/**
 * Human natives.
 */

/**
 * Checks whether a player is currently a human.
 *
 * @param id        Player index
 *
 * @return          true if the player is a human, false otherwise
 */
native bool:IsHuman(id);
