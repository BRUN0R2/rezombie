// ReZombie public API.

#if defined _rezombie_included
	#endinput
#endif

#define _rezombie_included

#include <rezombie_const>
#include <rezombie/core/RoundState>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib rezombie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib rezombie
	#endif
#else
	#pragma library rezombie
#endif

/**
 * Model natives.
 */

/**
 * Creates and precaches a player model.
 *
 * @param handle    Internal player model name
 *
 * @return          Model handle
 * @error           Fails on empty handle, duplicate model or missing model file
 */
native Model:create_model(const handle[]);

/**
 * Finds a model by handle.
 *
 * @param handle    Model handle
 *
 * @return          Model handle, or null when not found
 */
native Model:FindModel(const handle[]);

/**
 * Requires a model by handle.
 *
 * @param handle    Model handle
 *
 * @return          Model handle
 * @error           Fails when the model is not registered
 */
stock Model:RequireModel(const handle[])
{
	new Model:model = FindModel(handle);

	if (model == Invalid_Model)
	{
		set_fail_state("Required model '%s' was not registered.", handle);
	}

	return model;
}

/**
 * Gets a model property.
 *
 * @param model     Model handle
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid model or property
 */
native any:get_model_var(Model:model, const var[], any:...);

/**
 * Class natives.
 */

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

/**
 * Subclass natives.
 */

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

/**
 * Props natives.
 */

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

/**
 * Mode natives.
 */

/**
 * Creates a game mode.
 *
 * @param handle         Unique mode handle
 * @param launchForward  Function called when the mode starts, must return non-zero on success
 *
 * @return               Mode handle
 * @error                Fails on empty handle, duplicate mode or missing forward
 */
native Mode:create_mode(const handle[], const launchForward[]);

/**
 * Finds a game mode by handle.
 *
 * @param handle         Mode handle
 *
 * @return               Mode handle, or null when not found
 */
native Mode:FindMode(const handle[]);

/**
 * Gets the registered mode count.
 *
 * @return               Registered mode count
 */
native get_modes_count();

/**
 * Gets a registered mode by index.
 *
 * @param index          Mode index
 *
 * @return               Mode handle
 * @error                Fails on invalid index
 */
native Mode:get_mode(index);

/**
 * Requires a game mode by handle.
 *
 * @param handle         Mode handle
 *
 * @return               Mode handle
 * @error                Fails when the mode is not registered
 */
stock Mode:RequireMode(const handle[])
{
	new Mode:mode = FindMode(handle);

	if (mode == Invalid_Mode)
	{
		set_fail_state("Required mode '%s' was not registered.", handle);
	}

	return mode;
}

/**
 * Gets a mode property.
 *
 * @param mode           Mode handle
 * @param var            Property name
 *
 * @return               Property value
 * @error                Fails on invalid mode or property
 */
native any:get_mode_var(Mode:mode, const var[], any:...);

/**
 * Sets a mode property.
 *
 * @param mode           Mode handle
 * @param var            Property name
 *
 * @return               true on success, false otherwise
 * @error                Fails on invalid mode, property or value
 */
native bool:set_mode_var(Mode:mode, const var[], any:...);

/**
 * Launches a game mode.
 *
 * @param mode           Mode handle
 * @param target         Optional target player
 *
 * @return               true on success, false otherwise
 * @error                Fails on invalid mode or failed launch forward
 */
native bool:launch_mode(Mode:mode, target = 0);

/**
 * Game variable natives.
 */

/**
 * Gets a game runtime property.
 *
 * @param var       Property name
 *
 * @return          Property value
 * @error           Fails on invalid property
 */
native any:get_game_var(const var[], any:...);

/**
 * Player natives.
 */

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
 * Zombie natives.
 */

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

/**
 * Forward callbacks.
 */

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
