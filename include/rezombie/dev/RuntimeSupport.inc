#if defined _RuntimeSupport_included
	#endinput
#endif

#define _RuntimeSupport_included

stock Props:GetRuntimeProps(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
		return Props:get_subclass_var(subclass, "props");

	if (class != Invalid_Class)
		return Props:get_class_var(class, "props");

	return Invalid_Props;
}

stock Model:GetRuntimeModel(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
	{
		new Model:model = Model:get_subclass_var(subclass, "model");

		if (model != Invalid_Model)
			return model;
	}

	if (class != Invalid_Class)
	{
		new ModelsPack:models = ModelsPack:get_class_var(class, "models");

		if (models != Invalid_ModelsPack)
			return models_pack_get_random_model(models);
	}

	return Invalid_Model;
}

stock Class:FindRequiredClass(const handle[])
{
	if (!handle[0])
	{
		DevError("Class handle cannot be empty.");
		return Invalid_Class;
	}

	new Class:class = FindClass(handle);
	if (class == Invalid_Class)
	{
		DevError("Class '%s' was not found.", handle);
		return Invalid_Class;
	}

	return class;
}

stock Subclass:FindRequiredSubclass(const handle[])
{
	if (!handle[0])
	{
		DevError("Subclass handle cannot be empty.");
		return Invalid_Subclass;
	}

	new Subclass:subclass = FindSubclass(handle);
	if (subclass == Invalid_Subclass)
	{
		DevError("Subclass '%s' was not found.", handle);
		return Invalid_Subclass;
	}

	return subclass;
}

stock bool:RequireArgumentCount(requiredCount, const usage[])
{
	if (read_argc() >= requiredCount)
		return true;

	return DevError("%s.", usage);
}

stock bool:RequireConnectedPlayer(id)
{
	if (!IsPlayerIndex(id))
		return DevError("Invalid player index %d.", id);

	if (!is_user_connected(id))
		return DevError("Player %d is not connected.", id);

	return true;
}

stock bool:RequireAlivePlayer(id)
{
	if (!RequireConnectedPlayer(id))
		return false;

	if (!is_user_alive(id))
		return DevError("Player %d is not alive. Use rz_dev_respawn_player first.", id);

	return true;
}

stock GetClassHandle(Class:class, handle[], length)
{
	if (class == Invalid_Class)
	{
		copy(handle, length, "none");
		return;
	}

	get_class_var(class, "handle", handle, length);
}

stock GetSubclassHandle(Subclass:subclass, handle[], length)
{
	if (subclass == Invalid_Subclass)
	{
		copy(handle, length, "none");
		return;
	}

	get_subclass_var(subclass, "handle", handle, length);
}

stock GetModelHandle(Model:model, handle[], length)
{
	if (model == Invalid_Model)
	{
		copy(handle, length, "none");
		return;
	}

	get_model_var(model, "handle", handle, length);
}

stock DevInfo(const message[], any:...)
{
	new formatted[512];
	vformat(formatted, charsmax(formatted), message, 2);

	server_print("%s %s", DEV_PREFIX, formatted);
	log_amx("%s", formatted);
}

stock bool:DevError(const message[], any:...)
{
	new formatted[512];
	vformat(formatted, charsmax(formatted), message, 2);

	server_print("%s ERROR: %s", DEV_PREFIX, formatted);
	log_amx("ERROR: %s", formatted);

	return false;
}
