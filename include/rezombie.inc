// ReZombie public API aggregate include.

#if defined _rezombie_included
	#endinput
#endif

#define _rezombie_included

#include <amxmodx>
#include <rezombie_const>
#include <rezombie_stock>
#include <rezombie/core/RoundState>

#include <rezombie/api/Props>
#include <rezombie/api/Models>
#include <rezombie/api/Weapons>
#include <rezombie/api/Classes>
#include <rezombie/api/Subclasses>
#include <rezombie/api/Modes>
#include <rezombie/api/GameVars>
#include <rezombie/api/Players>

/**
 * Called when the round enters prepare state.
 *
 * @param mode      Selected mode handle
 * @param duration  Prepare duration in seconds
 */
forward @round_prepare(Mode:mode, Float:duration);

/**
 * Called when the round starts playing.
 *
 * @param mode      Current mode handle
 * @param duration  Round duration in seconds
 */
forward @round_start(Mode:mode, Float:duration);

/**
 * Called when ReZombie ends the current round.
 *
 * @param event     Round end event
 */
forward @round_end(EndRoundEvent:event);

/**
 * Called when the visible round timer changes.
 *
 * @param timer     Visible timer in seconds
 */
forward @round_timer(timer);

/**
 * Called when the game state changes.
 *
 * @param oldState  Previous game state
 * @param newState  New game state
 */
forward @game_state_changed(GameState:oldState, GameState:newState);

/**
 * Called when the round state changes.
 *
 * @param oldState  Previous round state
 * @param newState  New round state
 */
forward @round_state_changed(RoundState:oldState, RoundState:newState);
