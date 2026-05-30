#if defined _RoundRuntime_included
	#endinput
#endif

#define _RoundRuntime_included

#include <rezombie_const>
#include <rezombie/core/RoundState>

/**
 * Sets an internal round runtime property.
 *
 * @param var       Property name
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid caller, property or value
 *
 * @note            Owned by GameRules only.
 */
native bool:set_round_runtime_var(const var[], any:...);
