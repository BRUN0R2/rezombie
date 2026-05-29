// ReZombie public API.

#if defined _rezombie_included
	#endinput
#endif

#define _rezombie_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib rezombie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib rezombie
	#endif
#else
	#pragma library rezombie
#endif

/**
 * Zombie natives.
 */

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
