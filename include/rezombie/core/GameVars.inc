#if defined _GameVars_included
	#endinput
#endif

#define _GameVars_included

#include <rezombie_const>
#include <rezombie/api/GameVars>
#include <rezombie/core/RoundState>

/**
 * Publishes the internal game runtime snapshot.
 *
 * @param gameState   Current game state
 * @param roundState  Current round state
 * @param mode        Current round mode
 * @param timer       Current visible timer in seconds
 * @param humanWins   Human team win count
 * @param zombieWins  Zombie team win count
 * @param admissionRespawn  Whether admitted players may respawn now
 * @param respawnTeam       Team assigned on player respawn
 *
 * @return            true on success, false otherwise
 * @error             Fails on invalid caller or invalid snapshot data
 *
 * @note              Owned by GameRules only.
 */
native bool:sync_game_vars(
	GameState:gameState,
	RoundState:roundState,
	Mode:mode,
	Float:timer,
	humanWins,
	zombieWins,
	bool:admissionRespawn,
	Team:respawnTeam
);
