#include <amxmodx>
#include <rezombie>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

const MODEL_HANDLE_OFFSET = 5000;

enum _:ModelData
{
	ModelHandle[RZ_MAX_HANDLE_LENGTH],
	ModelName[RZ_MAX_HANDLE_LENGTH],
	ModelPath[RZ_MAX_RESOURCE_PATH_LENGTH],
	ModelPrecacheIndex
};

new Array:Models;
new Trie:ModelsByHandle;

public plugin_natives()
{
	register_library("rezombie");

	Models = ArrayCreate(ModelData);
	ModelsByHandle = TrieCreate();

	register_native("create_model", "NativeCreateModel");
	register_native("FindModel", "NativeFindModel");
	register_native("get_model_var", "NativeGetModelVar");
}

public plugin_precache()
{
	register_plugin("API: Models", "0.1.0", "BRUN0");
}

public plugin_end()
{
	if (ModelsByHandle != Invalid_Trie)
		TrieDestroy(ModelsByHandle);

	if (Models != Invalid_Array)
	{
		ArrayDestroy(Models);
		Models = Invalid_Array;
	}
}

public Model:NativeCreateModel(plugin, params)
{
	enum
	{
		CreateModelParamHandle = 1
	};

	if (params < CreateModelParamHandle)
		return Model:ReportNativeError("create_model requires model handle.");

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(CreateModelParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Model:ReportNativeError("Model handle cannot be empty.");

	if (FindModelByHandle(handle) != Invalid_Model)
		return Model:ReportNativeError("Model '%s' is already registered.", handle);

	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	GetPlayerModelPath(handle, path, charsmax(path));

	if (!file_exists(path))
		return Model:ReportNativeError("Model '%s' file was not found: %s.", handle, path);

	new precacheIndex = precache_model(path);
	if (precacheIndex <= 0)
		return Model:ReportNativeError("Model '%s' could not be precached.", handle);

	PrecacheTextureModel(handle);

	new data[ModelData];
	copy(data[ModelHandle], charsmax(data[ModelHandle]), handle);
	copy(data[ModelName], charsmax(data[ModelName]), handle);
	copy(data[ModelPath], charsmax(data[ModelPath]), path);
	data[ModelPrecacheIndex] = precacheIndex;

	new index = ArraySize(Models);
	if (!TrieSetCell(ModelsByHandle, handle, index, false))
		return Model:ReportNativeError("Model '%s' handle index was not registered.", handle);

	ArrayPushArray(Models, data);

	return MakeModelHandle(index);
}

public Model:NativeFindModel(plugin, params)
{
	enum
	{
		FindModelParamHandle = 1
	};

	if (params < FindModelParamHandle)
		return Invalid_Model;

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(FindModelParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Invalid_Model;

	return FindModelByHandle(handle);
}

public any:NativeGetModelVar(plugin, params)
{
	enum
	{
		GetModelVarParamModel = 1,
		GetModelVarParamKey,
		GetModelVarParamOutput,
		GetModelVarParamOutputLength
	};

	if (params < GetModelVarParamKey)
		return ReportNativeError("get_model_var requires model and property name.");

	new Model:model = Model:get_param(GetModelVarParamModel);
	new index = GetModelIndex(model);

	if (!IsValidModelIndex(index))
		return ReportNativeError("Invalid model handle %d.", _:model);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetModelVarParamKey, key, charsmax(key));

	new data[ModelData];
	ArrayGetArray(Models, index, data);

	if (equal(key, "handle"))
	{
		if (params < GetModelVarParamOutputLength)
			return ReportNativeError("get_model_var 'handle' requires output buffer and length.");

		set_string(GetModelVarParamOutput, data[ModelHandle], get_param_byref(GetModelVarParamOutputLength));
		return true;
	}

	if (equal(key, "name"))
	{
		if (params < GetModelVarParamOutputLength)
			return ReportNativeError("get_model_var 'name' requires output buffer and length.");

		set_string(GetModelVarParamOutput, data[ModelName], get_param_byref(GetModelVarParamOutputLength));
		return true;
	}

	if (equal(key, "path"))
	{
		if (params < GetModelVarParamOutputLength)
			return ReportNativeError("get_model_var 'path' requires output buffer and length.");

		set_string(GetModelVarParamOutput, data[ModelPath], get_param_byref(GetModelVarParamOutputLength));
		return true;
	}

	if (equal(key, "precache_index"))
		return data[ModelPrecacheIndex];

	return ReportNativeError("Invalid model property '%s'.", key);
}

stock GetPlayerModelPath(const handle[], path[], length)
{
	formatex(path, length, "models/player/%s/%s.mdl", handle, handle);
}

stock PrecacheTextureModel(const handle[])
{
	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	formatex(path, charsmax(path), "models/player/%s/%sT.mdl", handle, handle);

	if (file_exists(path))
		precache_model(path);
}

stock Model:FindModelByHandle(const handle[])
{
	new index;
	if (TrieGetCell(ModelsByHandle, handle, index))
		return MakeModelHandle(index);

	return Invalid_Model;
}

stock Model:MakeModelHandle(index)
{
	return Model:(MODEL_HANDLE_OFFSET + index + 1);
}

stock GetModelIndex(Model:model)
{
	return _:model - MODEL_HANDLE_OFFSET - 1;
}

stock bool:IsValidModelIndex(index)
{
	return 0 <= index < ArraySize(Models);
}
