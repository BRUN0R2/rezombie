// ReZombie models API.

#if defined _rezombie_api_models_included
	#endinput
#endif

#define _rezombie_api_models_included

#include <rezombie_const>

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib ApiModels
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib ApiModels
	#endif
#else
	#pragma library ApiModels
#endif

/**
 * Creates and precaches a model.
 *
 * @param path      Model file path
 * @param body      Default model body
 * @param skin      Default model skin
 * @param handle    Optional model handle for named lookup
 *
 * @return          Model handle
 * @error           Fails on empty path, duplicate non-empty handle or missing model file
 */
native Model:create_model(const path[], body = 0, skin = 0, const handle[] = "");

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
 * Sets a model property.
 *
 * Writable properties: "body", "skin".
 * Readonly properties: "handle", "path", "precache_id".
 *
 * @param model     Model handle
 * @param var       Property name
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid model, readonly property or invalid property
 */
native bool:set_model_var(Model:model, const var[], any:...);

/**
 * Creates a models pack.
 *
 * Classes create their own models pack automatically. Use this only when a
 * separate pack is needed.
 *
 * @param handle    Optional models pack handle for named lookup
 *
 * @return          Models pack handle
 * @error           Fails on duplicate non-empty handle
 */
native ModelsPack:create_models_pack(const handle[] = "");

/**
 * Adds a model to a models pack.
 *
 * @param models    Models pack handle
 * @param model     Model handle
 *
 * @return          true on success, false otherwise
 * @error           Fails on invalid models pack or model
 */
native bool:models_pack_add_model(ModelsPack:models, Model:model);

/**
 * Gets a random model from a models pack.
 *
 * @param models    Models pack handle
 *
 * @return          Model handle, or null when the pack is empty
 * @error           Fails on invalid models pack
 */
native Model:models_pack_get_random_model(ModelsPack:models);
