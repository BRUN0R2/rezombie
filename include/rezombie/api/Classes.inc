// ReZombie classes API.

#if defined _rezombie_api_classes_included
	#endinput
#endif

#define _rezombie_api_classes_included

#include <rezombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiClasses
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiClasses
	#endif
#else
	#pragma library ApiClasses
#endif

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
