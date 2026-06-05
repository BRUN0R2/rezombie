// ReZombie public game variables API.

#if defined _rezombie_api_gamevars_included
	#endinput
#endif

#define _rezombie_api_gamevars_included

#include <rezombie_const>
#include <rezombie/core/RoundState>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiGameVars
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiGameVars
	#endif
#else
	#pragma library ApiGameVars
#endif

/**
 * Gets a game runtime property.
 *
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid property
 */
native any:get_game_var(const var[], any:...);
