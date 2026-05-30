#if defined _RoundRuntime_included
	#endinput
#endif

#define _RoundRuntime_included

#include <rezombie_const>
#include <rezombie/core/RoundState>

/**
 * Publishes the internal round runtime snapshot.
 *
 * @param roundState  Current round state
 * @param mode        Current round mode
 * @param timeLeft    Current round time left in seconds
 *
 * @return            true on success, false otherwise
 * @error             Fails on invalid caller or invalid snapshot data
 *
 * @note              Owned by GameRules only.
 */
native bool:sync_round_runtime(RoundState:roundState, Mode:mode, Float:timeLeft);
