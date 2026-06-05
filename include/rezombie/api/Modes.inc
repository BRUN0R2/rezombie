// ReZombie modes API.

#if defined _rezombie_api_modes_included
	#endinput
#endif

#define _rezombie_api_modes_included

#include <rezombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiModes
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiModes
	#endif
#else
	#pragma library ApiModes
#endif

/**
 * Creates a game mode.
 *
 * @param handle         Unique mode handle
 * @param launchForward  Function called when the mode starts, must return non-zero on success
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
 * Gets the registered mode count.
 *
 * @return               Registered mode count
 */
native get_modes_count();

/**
 * Gets a registered mode by index.
 *
 * @param index          Mode index
 *
 * @return               Mode handle
 * @error                Fails on invalid index
 */
native Mode:get_mode(index);

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
