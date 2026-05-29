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
 * Finds a player subclass by handle.
 *
 * @param handle    Subclass handle
 *
 * @return          Subclass handle, or null when not found
 */
native Subclass:FindSubclass(const handle[]);

/**
 * Requires a player subclass by handle.
 *
 * @param handle    Subclass handle
 *
 * @return          Subclass handle
 * @error           Fails when the subclass is not registered
 */
stock Subclass:RequireSubclass(const handle[])
{
	new Subclass:subclass = FindSubclass(handle);

	if (subclass == Invalid_Subclass)
	{
		set_fail_state("Required subclass '%s' was not registered.", handle);
	}

	return subclass;
}

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
 * Creates a props object.
 *
 * @param handle    Unique props handle
 *
 * @return          Props handle
 * @error           Fails on empty or duplicate handle
 */
native Props:create_props(const handle[]);

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
 * Mode natives.
 */

/**
 * Creates a game mode.
 *
 * @param handle         Unique mode handle
 * @param launchForward  Function called when the mode starts
 *
 * @return               Mode handle
 * @error                Fails on empty handle, duplicate mode or missing forward
 */
native Mode:create_mode(const handle[], const launchForward[]);

/**
 * Finds a game mode by handle.
 *
 * @param handle         Mode handle
 *
 * @return               Mode handle, or null when not found
 */
native Mode:FindMode(const handle[]);

/**
 * Requires a game mode by handle.
 *
 * @param handle         Mode handle
 *
 * @return               Mode handle
 * @error                Fails when the mode is not registered
 */
stock Mode:RequireMode(const handle[])
{
	new Mode:mode = FindMode(handle);

	if (mode == Invalid_Mode)
	{
		set_fail_state("Required mode '%s' was not registered.", handle);
	}

	return mode;
}

/**
 * Gets a mode property.
 *
 * @param mode           Mode handle
 * @param var            Property name
 *
 * @return               Property value
 * @error                Fails on invalid mode or property
 */
native any:get_mode_var(Mode:mode, const var[], any:...);

/**
 * Sets a mode property.
 *
 * @param mode           Mode handle
 * @param var            Property name
 *
 * @return               true on success, false otherwise
 * @error                Fails on invalid mode, property or value
 */
native bool:set_mode_var(Mode:mode, const var[], any:...);

/**
 * Launches a game mode.
 *
 * @param mode           Mode handle
 * @param target         Optional target player
 *
 * @return               true on success, false otherwise
 * @error                Fails on invalid mode or failed launch forward
 */
native bool:launch_mode(Mode:mode, target = 0);

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
