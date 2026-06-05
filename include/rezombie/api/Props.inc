// ReZombie props API.

#if defined _rezombie_api_props_included
	#endinput
#endif

#define _rezombie_api_props_included

#include <rezombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiProps
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiProps
	#endif
#else
	#pragma library ApiProps
#endif

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
