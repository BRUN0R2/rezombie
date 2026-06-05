#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const MODEL_HANDLE_OFFSET = 5000;
const MODELS_PACK_HANDLE_OFFSET = 6000;

enum _:ModelData
{
	ModelHandle[RZ_MAX_RESOURCE_PATH_LENGTH],
	ModelPath[RZ_MAX_RESOURCE_PATH_LENGTH],
	ModelBody,
	ModelSkin,
	ModelPrecacheIndex
};

enum _:ModelsPackData
{
	ModelsPackHandle[RZ_MAX_HANDLE_LENGTH],
	Array:ModelsPackModels
};

new Array:Models;
new Trie:ModelsByHandle;
new Array:ModelsPacks;
new Trie:ModelsPacksByHandle;

public plugin_natives()
{
	register_library("ApiModels");

	Models = ArrayCreate(ModelData);
	ModelsByHandle = TrieCreate();
	ModelsPacks = ArrayCreate(ModelsPackData);
	ModelsPacksByHandle = TrieCreate();

	register_native("create_model", "NativeCreateModel");
	register_native("FindModel", "NativeFindModel");
	register_native("get_model_var", "NativeGetModelVar");
	register_native("set_model_var", "NativeSetModelVar");
	register_native("create_models_pack", "NativeCreateModelsPack");
	register_native("models_pack_add_model", "NativeModelsPackAddModel");
	register_native("models_pack_get_random_model", "NativeModelsPackGetRandomModel");
}

public plugin_precache()
{
	register_plugin("API: Models", "0.1.0", "BRUN0");
}

public plugin_end()
{
	DestroyModelsPacks();

	if (ModelsPacksByHandle != Invalid_Trie)
		TrieDestroy(ModelsPacksByHandle);

	if (ModelsByHandle != Invalid_Trie)
		TrieDestroy(ModelsByHandle);

	if (ModelsPacks != Invalid_Array)
	{
		ArrayDestroy(ModelsPacks);
		ModelsPacks = Invalid_Array;
	}

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
		CreateModelParamPath = 1,
		CreateModelParamBody,
		CreateModelParamSkin,
		CreateModelParamHandle
	};

	if (params < CreateModelParamPath)
		return Model:ReportNativeError("create_model requires model path.");

	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	get_string(CreateModelParamPath, path, charsmax(path));

	if (IsNullString(path))
		return Model:ReportNativeError("Model path cannot be empty.");

	if (!HasModelExtension(path))
		return Model:ReportNativeError("Model path must point to a .mdl file: %s.", path);

	new body;
	if (params >= CreateModelParamBody)
		body = get_param(CreateModelParamBody);

	new skin;
	if (params >= CreateModelParamSkin)
		skin = get_param(CreateModelParamSkin);

	new handle[RZ_MAX_RESOURCE_PATH_LENGTH];
	if (params >= CreateModelParamHandle)
		get_string(CreateModelParamHandle, handle, charsmax(handle));

	if (!IsNullString(handle) && FindModelByHandle(handle) != Invalid_Model)
		return Model:ReportNativeError("Model '%s' is already registered.", handle);

	if (!file_exists(path))
		return Model:ReportNativeError("Model file was not found: %s.", path);

	new precacheIndex = precache_model(path);
	if (precacheIndex <= 0)
		return Model:ReportNativeError("Model could not be precached: %s.", path);

	PrecacheTextureModel(path);

	new data[ModelData];
	copy(data[ModelHandle], charsmax(data[ModelHandle]), handle);
	copy(data[ModelPath], charsmax(data[ModelPath]), path);
	data[ModelBody] = body;
	data[ModelSkin] = skin;
	data[ModelPrecacheIndex] = precacheIndex;

	new index = ArraySize(Models);
	if (!IsNullString(handle) && !TrieSetCell(ModelsByHandle, handle, index, false))
		return Model:ReportNativeError("Model '%s' handle index was not registered.", handle);

	ArrayPushArray(Models, data);

	return MakeModelHandle(index);
}

public ModelsPack:NativeCreateModelsPack(plugin, params)
{
	enum
	{
		CreateModelsPackParamHandle = 1
	};

	new handle[RZ_MAX_HANDLE_LENGTH];
	if (params >= CreateModelsPackParamHandle)
		get_string(CreateModelsPackParamHandle, handle, charsmax(handle));

	if (!IsNullString(handle) && FindModelsPackByHandle(handle) != Invalid_ModelsPack)
		return ModelsPack:ReportNativeError("Models pack '%s' is already registered.", handle);

	new Array:models = ArrayCreate(1);
	if (models == Invalid_Array)
		return ModelsPack:ReportNativeError("Models pack '%s' models list was not created.", handle);

	new data[ModelsPackData];
	copy(data[ModelsPackHandle], charsmax(data[ModelsPackHandle]), handle);
	data[ModelsPackModels] = models;

	new index = ArraySize(ModelsPacks);
	if (!IsNullString(handle) && !TrieSetCell(ModelsPacksByHandle, handle, index, false))
	{
		ArrayDestroy(models);
		return ModelsPack:ReportNativeError("Models pack '%s' handle index was not registered.", handle);
	}

	ArrayPushArray(ModelsPacks, data);

	return MakeModelsPackHandle(index);
}

public bool:NativeModelsPackAddModel(plugin, params)
{
	enum
	{
		ModelsPackAddModelParamPack = 1,
		ModelsPackAddModelParamModel
	};

	if (params < ModelsPackAddModelParamModel)
		return bool:ReportNativeError("models_pack_add_model requires models pack and model.");

	new ModelsPack:modelsPack = ModelsPack:get_param(ModelsPackAddModelParamPack);
	new packIndex = GetModelsPackIndex(modelsPack);

	if (!IsValidModelsPackIndex(packIndex))
		return bool:ReportNativeError("Invalid models pack handle %d.", _:modelsPack);

	new Model:model = Model:get_param(ModelsPackAddModelParamModel);
	if (!IsValidModelIndex(GetModelIndex(model)))
		return bool:ReportNativeError("Invalid model handle %d.", _:model);

	new data[ModelsPackData];
	ArrayGetArray(ModelsPacks, packIndex, data);
	ArrayPushCell(data[ModelsPackModels], model);
	return true;
}

public Model:NativeModelsPackGetRandomModel(plugin, params)
{
	enum
	{
		ModelsPackGetRandomModelParamPack = 1
	};

	if (params < ModelsPackGetRandomModelParamPack)
		return Invalid_Model;

	new ModelsPack:modelsPack = ModelsPack:get_param(ModelsPackGetRandomModelParamPack);
	new packIndex = GetModelsPackIndex(modelsPack);

	if (!IsValidModelsPackIndex(packIndex))
		return Model:ReportNativeError("Invalid models pack handle %d.", _:modelsPack);

	new data[ModelsPackData];
	ArrayGetArray(ModelsPacks, packIndex, data);

	new count = ArraySize(data[ModelsPackModels]);
	if (count <= 0)
		return Invalid_Model;

	return Model:ArrayGetCell(data[ModelsPackModels], random_num(0, count - 1));
}

public Model:NativeFindModel(plugin, params)
{
	enum
	{
		FindModelParamHandle = 1
	};

	if (params < FindModelParamHandle)
		return Invalid_Model;

	new handle[RZ_MAX_RESOURCE_PATH_LENGTH];
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

	if (equal(key, "path"))
	{
		if (params < GetModelVarParamOutputLength)
			return ReportNativeError("get_model_var 'path' requires output buffer and length.");

		set_string(GetModelVarParamOutput, data[ModelPath], get_param_byref(GetModelVarParamOutputLength));
		return true;
	}

	if (equal(key, "body"))
		return data[ModelBody];

	if (equal(key, "skin"))
		return data[ModelSkin];

	if (equal(key, "precache_id"))
		return data[ModelPrecacheIndex];

	return ReportNativeError("Invalid model property '%s'.", key);
}

public bool:NativeSetModelVar(plugin, params)
{
	enum
	{
		SetModelVarParamModel = 1,
		SetModelVarParamKey,
		SetModelVarParamValue
	};

	if (params < SetModelVarParamValue)
		return bool:ReportNativeError("set_model_var requires model, property name and value.");

	new Model:model = Model:get_param(SetModelVarParamModel);
	new index = GetModelIndex(model);

	if (!IsValidModelIndex(index))
		return bool:ReportNativeError("Invalid model handle %d.", _:model);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetModelVarParamKey, key, charsmax(key));

	new data[ModelData];
	ArrayGetArray(Models, index, data);

	if (equal(key, "body"))
	{
		data[ModelBody] = get_param_byref(SetModelVarParamValue);
		ArraySetArray(Models, index, data);
		return true;
	}

	if (equal(key, "skin"))
	{
		data[ModelSkin] = get_param_byref(SetModelVarParamValue);
		ArraySetArray(Models, index, data);
		return true;
	}

	if (equal(key, "handle") || equal(key, "path") || equal(key, "precache_id"))
		return bool:ReportNativeError("Model property '%s' is readonly.", key);

	return bool:ReportNativeError("Invalid model property '%s'.", key);
}

stock PrecacheTextureModel(const modelPath[])
{
	new texturePath[RZ_MAX_RESOURCE_PATH_LENGTH];
	if (!GetTextureModelPath(modelPath, texturePath, charsmax(texturePath)))
		return;

	if (file_exists(texturePath))
		precache_model(texturePath);
}

stock DestroyModelsPacks()
{
	if (ModelsPacks == Invalid_Array)
		return;

	new data[ModelsPackData];
	for (new index = 0; index < ArraySize(ModelsPacks); index++)
	{
		ArrayGetArray(ModelsPacks, index, data);

		if (data[ModelsPackModels] != Invalid_Array)
			ArrayDestroy(data[ModelsPackModels]);
	}
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

stock ModelsPack:FindModelsPackByHandle(const handle[])
{
	new index;
	if (TrieGetCell(ModelsPacksByHandle, handle, index))
		return MakeModelsPackHandle(index);

	return Invalid_ModelsPack;
}

stock ModelsPack:MakeModelsPackHandle(index)
{
	return ModelsPack:(MODELS_PACK_HANDLE_OFFSET + index + 1);
}

stock GetModelsPackIndex(ModelsPack:modelsPack)
{
	return _:modelsPack - MODELS_PACK_HANDLE_OFFSET - 1;
}

stock bool:IsValidModelsPackIndex(index)
{
	return 0 <= index < ArraySize(ModelsPacks);
}
