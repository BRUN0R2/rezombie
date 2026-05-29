#include <amxmodx>
#include <rezombie>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

const SUBCLASS_HANDLE_OFFSET = 2000;

enum _:SubclassData
{
	SubclassHandle[RZ_MAX_HANDLE_LENGTH],
	SubclassName[RZ_MAX_NAME_LENGTH],
	Class:SubclassClass,
	Props:SubclassProps
};

new Array:Subclasses;

public plugin_natives()
{
	register_library("rezombie");

	Subclasses = ArrayCreate(SubclassData);

	register_native("create_subclass", "NativeCreateSubclass");
	register_native("FindSubclass", "NativeFindSubclass");
	register_native("get_subclass_var", "NativeGetSubclassVar");
	register_native("set_subclass_var", "NativeSetSubclassVar");
}

public plugin_precache()
{
	register_plugin("API: Subclasses", "0.1.0", "BRUN0");
}

public plugin_end()
{
	if (Subclasses != Invalid_Array)
	{
		ArrayDestroy(Subclasses);
		Subclasses = Invalid_Array;
	}
}

public Subclass:NativeCreateSubclass(plugin, params)
{
	enum
	{
		CreateSubclassParamHandle = 1,
		CreateSubclassParamClass
	};

	if (params < CreateSubclassParamClass)
		return Subclass:ReportNativeError("create_subclass requires handle and parent class.");

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(CreateSubclassParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Subclass:ReportNativeError("Subclass handle cannot be empty.");

	if (FindSubclassByHandle(handle) != Invalid_Subclass)
		return Subclass:ReportNativeError("Subclass '%s' is already registered.", handle);

	new Class:class = Class:get_param(CreateSubclassParamClass);
	if (!IsRegisteredClass(class))
		return Subclass:ReportNativeError("Invalid parent class handle %d.", _:class);

	new Props:props = create_props(handle);
	if (props == Invalid_Props)
		return Subclass:ReportNativeError("Subclass '%s' props were not created.", handle);

	new data[SubclassData];
	copy(data[SubclassHandle], charsmax(data[SubclassHandle]), handle);
	copy(data[SubclassName], charsmax(data[SubclassName]), handle);
	data[SubclassClass] = class;
	data[SubclassProps] = props;

	ArrayPushArray(Subclasses, data);

	return MakeSubclassHandle(ArraySize(Subclasses) - 1);
}

public Subclass:NativeFindSubclass(plugin, params)
{
	enum
	{
		FindSubclassParamHandle = 1
	};

	if (params < FindSubclassParamHandle)
		return Invalid_Subclass;

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(FindSubclassParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Invalid_Subclass;

	return FindSubclassByHandle(handle);
}

public any:NativeGetSubclassVar(plugin, params)
{
	enum
	{
		GetSubclassVarParamSubclass = 1,
		GetSubclassVarParamKey,
		GetSubclassVarParamOutput,
		GetSubclassVarParamOutputLength
	};

	if (params < GetSubclassVarParamKey)
		return ReportNativeError("get_subclass_var requires subclass and property name.");

	new Subclass:subclass = Subclass:get_param(GetSubclassVarParamSubclass);
	new index = GetSubclassIndex(subclass);

	if (!IsValidSubclassIndex(index))
		return ReportNativeError("Invalid subclass handle %d.", _:subclass);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetSubclassVarParamKey, key, charsmax(key));

	new data[SubclassData];
	ArrayGetArray(Subclasses, index, data);

	if (equal(key, "handle"))
	{
		if (params < GetSubclassVarParamOutputLength)
			return ReportNativeError("get_subclass_var 'handle' requires output buffer and length.");

		set_string(GetSubclassVarParamOutput, data[SubclassHandle], get_param(GetSubclassVarParamOutputLength));
		return true;
	}

	if (equal(key, "name"))
	{
		if (params < GetSubclassVarParamOutputLength)
			return ReportNativeError("get_subclass_var 'name' requires output buffer and length.");

		set_string(GetSubclassVarParamOutput, data[SubclassName], get_param(GetSubclassVarParamOutputLength));
		return true;
	}

	if (equal(key, "class"))
		return data[SubclassClass];

	if (equal(key, "props"))
		return data[SubclassProps];

	return ReportNativeError("Invalid subclass property '%s'.", key);
}

public bool:NativeSetSubclassVar(plugin, params)
{
	enum
	{
		SetSubclassVarParamSubclass = 1,
		SetSubclassVarParamKey,
		SetSubclassVarParamValue
	};

	if (params < SetSubclassVarParamValue)
		return bool:ReportNativeError("set_subclass_var requires subclass, property name and value.");

	new Subclass:subclass = Subclass:get_param(SetSubclassVarParamSubclass);
	new index = GetSubclassIndex(subclass);

	if (!IsValidSubclassIndex(index))
		return bool:ReportNativeError("Invalid subclass handle %d.", _:subclass);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetSubclassVarParamKey, key, charsmax(key));

	new data[SubclassData];
	ArrayGetArray(Subclasses, index, data);

	if (equal(key, "name"))
	{
		get_string(SetSubclassVarParamValue, data[SubclassName], charsmax(data[SubclassName]));
		ArraySetArray(Subclasses, index, data);
		return true;
	}

	if (equal(key, "props"))
	{
		new Props:props = Props:get_param(SetSubclassVarParamValue);

		if (!IsRegisteredProps(props))
			return bool:ReportNativeError("Invalid props handle %d.", _:props);

		data[SubclassProps] = props;
		ArraySetArray(Subclasses, index, data);
		return true;
	}

	return bool:ReportNativeError("Invalid or readonly subclass property '%s'.", key);
}

stock Subclass:FindSubclassByHandle(const handle[])
{
	new data[SubclassData];

	for (new index = 0; index < ArraySize(Subclasses); index++)
	{
		ArrayGetArray(Subclasses, index, data);

		if (equal(data[SubclassHandle], handle))
			return MakeSubclassHandle(index);
	}

	return Invalid_Subclass;
}

stock Subclass:MakeSubclassHandle(index)
{
	return Subclass:(SUBCLASS_HANDLE_OFFSET + index + 1);
}

stock GetSubclassIndex(Subclass:subclass)
{
	return _:subclass - SUBCLASS_HANDLE_OFFSET - 1;
}

stock bool:IsValidSubclassIndex(index)
{
	return 0 <= index < ArraySize(Subclasses);
}

stock bool:IsRegisteredClass(Class:class)
{
	if (class == Invalid_Class)
		return false;

	new Team:team = Team:get_class_var(class, "team");
	return team == TEAM_HUMAN || team == TEAM_ZOMBIE;
}

stock bool:IsRegisteredProps(Props:props)
{
	if (props == Invalid_Props)
		return false;

	new handle[RZ_MAX_HANDLE_LENGTH];
	return bool:get_props_var(props, "handle", handle, charsmax(handle));
}
