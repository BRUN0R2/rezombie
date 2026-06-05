// ReZombie players API.

#if defined _rezombie_api_players_included
	#endinput
#endif

#define _rezombie_api_players_included

#include <rezombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiPlayers
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiPlayers
	#endif
#else
	#pragma library ApiPlayers
#endif

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
 * Gets a player property.
 *
 * @param id        Player index
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid player or property
 */
native any:get_player_var(id, const var[], any:...);

/**
 * Sets a safe player property through the official runtime flow.
 *
 * @param id        Player index
 * @param var       Property name
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid player, readonly property or value
 */
native bool:set_player_var(id, const var[], any:...);

/**
 * Changes the player class and applies its runtime state.
 *
 * @param id            Player index
 * @param class         Class handle
 * @param subclass      Optional subclass handle
 * @param applyRuntime  Apply props, model and default items immediately when alive
 *
 * @return              true on success, false otherwise
 * @error               Fails on invalid player, class or subclass
 */
native bool:change_player_class(id, Class:class, Subclass:subclass = Invalid_Subclass, bool:applyRuntime = true);

/**
 * Infects a player using the registered zombie class.
 *
 * @param id        Player index
 * @param attacker  Optional attacker index
 * @param subclass  Optional zombie subclass handle
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid player, attacker, subclass or missing zombie class
 */
native bool:infect_player(id, attacker = 0, Subclass:subclass = Invalid_Subclass);

/**
 * Checks whether a player is currently a zombie.
 *
 * @param id        Player index
 *
 * @return          true if the player is a zombie, false otherwise
 */
native bool:IsZombie(id);

/**
 * Checks whether a player is currently a human.
 *
 * @param id        Player index
 *
 * @return          true if the player is a human, false otherwise
 */
native bool:IsHuman(id);

/**
 * Called before a player class is changed.
 *
 * @param id        Player index
 * @param class     New class handle
 * @param subclass  New subclass handle, or null
 *
 * @return          RZ_CONTINUE to allow, RZ_SUPERCEDE to block
 */
forward RzReturn:@change_class_pre(id, Class:class, Subclass:subclass);

/**
 * Called after a player class is changed.
 *
 * @param id        Player index
 * @param class     Applied class handle
 * @param subclass  Applied subclass handle, or null
 */
forward @change_class_post(id, Class:class, Subclass:subclass);

/**
 * Called before a player is infected.
 *
 * @param id        Player index
 * @param attacker  Attacker index, or 0
 * @param subclass  Zombie subclass handle, or null
 *
 * @return          RZ_CONTINUE to allow, RZ_SUPERCEDE to block
 */
forward RzReturn:@infect_player_pre(id, attacker, Subclass:subclass);

/**
 * Called after a player is infected.
 *
 * @param id        Player index
 * @param attacker  Attacker index, or 0
 * @param subclass  Applied zombie subclass handle, or null
 */
forward @infect_player_post(id, attacker, Subclass:subclass);
