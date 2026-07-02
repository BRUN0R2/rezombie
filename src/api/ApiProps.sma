#include <amxmodx>
#include <rezombie_version>
#include <rezombie_const>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

const PROPS_HANDLE_OFFSET = 3000;
const PROPS_DEFAULT_HEALTH = 100;
const PROPS_DEFAULT_ARMOR = 0;
const PROPS_DEFAULT_SPEED = 250;
const Float:PROPS_DEFAULT_GRAVITY = 1.0;

enum _:PropsData
{
	PropsHandle[RZ_MAX_HANDLE_LENGTH],
	PropsHealth,
	PropsArmor,
	PropsSpeed,
	Float:PropsGravity,
	bool:PropsHealthConfigured,
	bool:PropsArmorConfigured,
	bool:PropsSpeedConfigured,
	bool:PropsGravityConfigured
};

new Array:PropsList;
new Trie:PropsByHandle;

public plugin_natives()
{
	register_library("ApiProps");

	PropsList = ArrayCreate(PropsData);
	PropsByHandle = TrieCreate();

	if (PropsList == Invalid_Array)
		set_fail_state("ApiProps props storage could not be initialized.");

	if (PropsByHandle == Invalid_Trie)
		set_fail_state("ApiProps handle index could not be initialized.");

	register_native("create_props", "NativeCreateProps");
	register_native("has_props_var", "NativeHasPropsVar");
	register_native("get_props_var", "NativeGetPropsVar");
	register_native("set_props_var", "NativeSetPropsVar");
}

public plugin_precache()
{
	register_plugin("API: Props", REZOMBIE_VERSION, REZOMBIE_AUTHOR);
}

public plugin_end()
{
	if (PropsByHandle != Invalid_Trie)
		TrieDestroy(PropsByHandle);

	if (PropsList != Invalid_Array)
	{
		ArrayDestroy(PropsList);
		PropsList = Invalid_Array;
	}
}

public Props:NativeCreateProps(plugin, params)
{
	enum
	{
		CreatePropsParamHandle = 1
	};

	if (params < CreatePropsParamHandle)
		return Props:ReportNativeError("create_props requires handle.");

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(CreatePropsParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Props:ReportNativeError("Props handle cannot be empty.");

	if (FindPropsByHandle(handle) != Invalid_Props)
		return Props:ReportNativeError("Props '%s' is already registered.", handle);

	new data[PropsData];
	copy(data[PropsHandle], charsmax(data[PropsHandle]), handle);
	data[PropsHealth] = PROPS_DEFAULT_HEALTH;
	data[PropsArmor] = PROPS_DEFAULT_ARMOR;
	data[PropsSpeed] = PROPS_DEFAULT_SPEED;
	data[PropsGravity] = PROPS_DEFAULT_GRAVITY;
	data[PropsHealthConfigured] = false;
	data[PropsArmorConfigured] = false;
	data[PropsSpeedConfigured] = false;
	data[PropsGravityConfigured] = false;

	new index = ArraySize(PropsList);
	if (!TrieSetCell(PropsByHandle, handle, index, false))
		return Props:ReportNativeError("Props '%s' handle index was not registered.", handle);

	ArrayPushArray(PropsList, data);

	return MakePropsHandle(index);
}

public bool:NativeHasPropsVar(plugin, params)
{
	enum
	{
		HasPropsVarParamProps = 1,
		HasPropsVarParamKey
	};

	if (params < HasPropsVarParamKey)
		return bool:ReportNativeError("has_props_var requires props and property name.");

	new Props:props = Props:get_param(HasPropsVarParamProps);
	new index = GetPropsIndex(props);

	if (!IsValidPropsIndex(index))
		return bool:ReportNativeError("Invalid props handle %d.", _:props);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(HasPropsVarParamKey, key, charsmax(key));

	new data[PropsData];
	ArrayGetArray(PropsList, index, data);

	if (equal(key, "health"))
		return data[PropsHealthConfigured];

	if (equal(key, "armor"))
		return data[PropsArmorConfigured];

	if (equal(key, "speed"))
		return data[PropsSpeedConfigured];

	if (equal(key, "gravity"))
		return data[PropsGravityConfigured];

	return bool:ReportNativeError("Invalid props property '%s'.", key);
}

public any:NativeGetPropsVar(plugin, params)
{
	enum
	{
		GetPropsVarParamProps = 1,
		GetPropsVarParamKey,
		GetPropsVarParamOutput,
		GetPropsVarParamOutputLength
	};

	if (params < GetPropsVarParamKey)
		return ReportNativeError("get_props_var requires props and property name.");

	new Props:props = Props:get_param(GetPropsVarParamProps);
	new index = GetPropsIndex(props);

	if (!IsValidPropsIndex(index))
		return ReportNativeError("Invalid props handle %d.", _:props);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetPropsVarParamKey, key, charsmax(key));

	new data[PropsData];
	ArrayGetArray(PropsList, index, data);

	if (equal(key, "handle"))
	{
		if (params < GetPropsVarParamOutputLength)
			return ReportNativeError("get_props_var 'handle' requires output buffer and length.");

		set_string(
			GetPropsVarParamOutput,
			data[PropsHandle],
			get_param_byref(GetPropsVarParamOutputLength)
		);

		return true;
	}

	if (equal(key, "health"))
		return data[PropsHealth];

	if (equal(key, "armor"))
		return data[PropsArmor];

	if (equal(key, "speed"))
		return data[PropsSpeed];

	if (equal(key, "gravity"))
		return data[PropsGravity];

	return ReportNativeError("Invalid props property '%s'.", key);
}

public bool:NativeSetPropsVar(plugin, params)
{
	enum
	{
		SetPropsVarParamProps = 1,
		SetPropsVarParamKey,
		SetPropsVarParamValue
	};

	if (params < SetPropsVarParamValue)
		return bool:ReportNativeError("set_props_var requires props, property name and value.");

	new Props:props = Props:get_param(SetPropsVarParamProps);
	new index = GetPropsIndex(props);

	if (!IsValidPropsIndex(index))
		return bool:ReportNativeError("Invalid props handle %d.", _:props);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetPropsVarParamKey, key, charsmax(key));

	new data[PropsData];
	ArrayGetArray(PropsList, index, data);

	if (equal(key, "health"))
	{
		new health = get_param_byref(SetPropsVarParamValue);
		if (health <= 0)
			return bool:ReportNativeError("Props health must be greater than zero.");

		data[PropsHealth] = health;
		data[PropsHealthConfigured] = true;
		ArraySetArray(PropsList, index, data);
		return true;
	}

	if (equal(key, "armor"))
	{
		new armor = get_param_byref(SetPropsVarParamValue);
		if (armor < 0)
			return bool:ReportNativeError("Props armor cannot be negative.");

		data[PropsArmor] = armor;
		data[PropsArmorConfigured] = true;
		ArraySetArray(PropsList, index, data);
		return true;
	}

	if (equal(key, "speed"))
	{
		new speed = get_param_byref(SetPropsVarParamValue);
		if (speed <= 0)
			return bool:ReportNativeError("Props speed must be greater than zero.");

		data[PropsSpeed] = speed;
		data[PropsSpeedConfigured] = true;
		ArraySetArray(PropsList, index, data);
		return true;
	}

	if (equal(key, "gravity"))
	{
		new Float:gravity = get_float_byref(SetPropsVarParamValue);
		if (gravity <= 0.0)
			return bool:ReportNativeError("Props gravity must be greater than zero.");

		data[PropsGravity] = gravity;
		data[PropsGravityConfigured] = true;
		ArraySetArray(PropsList, index, data);
		return true;
	}

	return bool:ReportNativeError("Invalid or readonly props property '%s'.", key);
}

stock Props:FindPropsByHandle(const handle[])
{
	new index;
	if (TrieGetCell(PropsByHandle, handle, index))
		return MakePropsHandle(index);

	return Invalid_Props;
}

stock Props:MakePropsHandle(index)
{
	return Props:(PROPS_HANDLE_OFFSET + index + 1);
}

stock GetPropsIndex(Props:props)
{
	return _:props - PROPS_HANDLE_OFFSET - 1;
}

stock bool:IsValidPropsIndex(index)
{
	return 0 <= index < ArraySize(PropsList);
}
