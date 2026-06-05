// ReZombie subclasses API.

#if defined _rezombie_api_subclasses_included
	#endinput
#endif

#define _rezombie_api_subclasses_included

#include <rezombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiSubclasses
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiSubclasses
	#endif
#else
	#pragma library ApiSubclasses
#endif

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
