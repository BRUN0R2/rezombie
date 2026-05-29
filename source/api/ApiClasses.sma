#include <amxmodx>
#include <rezombie>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

const CLASS_HANDLE_OFFSET = 1000;

enum _:ClassData
{
	ClassHandle[RZ_MAX_HANDLE_LENGTH],
	ClassName[RZ_MAX_NAME_LENGTH],
	Team:ClassTeam,
	Props:ClassProps
};

new Array:Classes;
new Trie:ClassesByHandle;

public plugin_natives()
{
	register_library("rezombie");

	Classes = ArrayCreate(ClassData);
	ClassesByHandle = TrieCreate();

	register_native("create_class", "NativeCreateClass");
	register_native("FindClass", "NativeFindClass");
	register_native("get_class_var", "NativeGetClassVar");
	register_native("set_class_var", "NativeSetClassVar");
}

public plugin_precache()
{
	register_plugin("API: Classes", "0.1.0", "BRUN0");
}

public plugin_end()
{
	if (ClassesByHandle != Invalid_Trie)
		TrieDestroy(ClassesByHandle);

	if (Classes != Invalid_Array)
	{
		ArrayDestroy(Classes);
		Classes = Invalid_Array;
	}
}

public Class:NativeCreateClass(plugin, params)
{
	enum
	{
		CreateClassParamHandle = 1,
		CreateClassParamTeam
	};

	if (params < CreateClassParamTeam)
		return Class:ReportNativeError("create_class requires handle and team.");

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(CreateClassParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Class:ReportNativeError("Class handle cannot be empty.");

	if (FindClassByHandle(handle) != Invalid_Class)
		return Class:ReportNativeError("Class '%s' is already registered.", handle);

	new Team:team = Team:get_param(CreateClassParamTeam);
	if (!IsPlayableClassTeam(team))
		return Class:ReportNativeError("Invalid class team %d.", _:team);

	new Props:props = create_props(handle);
	if (props == Invalid_Props)
		return Class:ReportNativeError("Class '%s' props were not created.", handle);

	new data[ClassData];
	copy(data[ClassHandle], charsmax(data[ClassHandle]), handle);
	copy(data[ClassName], charsmax(data[ClassName]), handle);
	data[ClassTeam] = team;
	data[ClassProps] = props;

	new index = ArraySize(Classes);
	if (!TrieSetCell(ClassesByHandle, handle, index, false))
		return Class:ReportNativeError("Class '%s' handle index was not registered.", handle);

	ArrayPushArray(Classes, data);

	return MakeClassHandle(index);
}

public Class:NativeFindClass(plugin, params)
{
	enum
	{
		FindClassParamHandle = 1
	};

	if (params < FindClassParamHandle)
		return Invalid_Class;

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(FindClassParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Invalid_Class;

	return FindClassByHandle(handle);
}

public any:NativeGetClassVar(plugin, params)
{
	enum
	{
		GetClassVarParamClass = 1,
		GetClassVarParamKey,
		GetClassVarParamOutput,
		GetClassVarParamOutputLength
	};

	if (params < GetClassVarParamKey)
		return ReportNativeError("get_class_var requires class and property name.");

	new Class:class = Class:get_param(GetClassVarParamClass);
	new index = GetClassIndex(class);

	if (!IsValidClassIndex(index))
		return ReportNativeError("Invalid class handle %d.", _:class);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetClassVarParamKey, key, charsmax(key));

	new data[ClassData];
	ArrayGetArray(Classes, index, data);

	if (equal(key, "handle"))
	{
		if (params < GetClassVarParamOutputLength)
			return ReportNativeError("get_class_var 'handle' requires output buffer and length.");

		set_string(GetClassVarParamOutput, data[ClassHandle], get_param(GetClassVarParamOutputLength));
		return true;
	}

	if (equal(key, "name"))
	{
		if (params < GetClassVarParamOutputLength)
			return ReportNativeError("get_class_var 'name' requires output buffer and length.");

		set_string(GetClassVarParamOutput, data[ClassName], get_param(GetClassVarParamOutputLength));
		return true;
	}

	if (equal(key, "team"))
		return data[ClassTeam];

	if (equal(key, "props"))
		return data[ClassProps];

	return ReportNativeError("Invalid class property '%s'.", key);
}

public bool:NativeSetClassVar(plugin, params)
{
	enum
	{
		SetClassVarParamClass = 1,
		SetClassVarParamKey,
		SetClassVarParamValue
	};

	if (params < SetClassVarParamValue)
		return bool:ReportNativeError("set_class_var requires class, property name and value.");

	new Class:class = Class:get_param(SetClassVarParamClass);
	new index = GetClassIndex(class);

	if (!IsValidClassIndex(index))
		return bool:ReportNativeError("Invalid class handle %d.", _:class);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetClassVarParamKey, key, charsmax(key));

	new data[ClassData];
	ArrayGetArray(Classes, index, data);

	if (equal(key, "name"))
	{
		get_string(SetClassVarParamValue, data[ClassName], charsmax(data[ClassName]));
		ArraySetArray(Classes, index, data);
		return true;
	}

	if (equal(key, "props"))
	{
		new Props:props = Props:get_param(SetClassVarParamValue);

		if (!IsRegisteredProps(props))
			return bool:ReportNativeError("Invalid props handle %d.", _:props);

		data[ClassProps] = props;
		ArraySetArray(Classes, index, data);
		return true;
	}

	return bool:ReportNativeError("Invalid or readonly class property '%s'.", key);
}

stock Class:FindClassByHandle(const handle[])
{
	new index;
	if (TrieGetCell(ClassesByHandle, handle, index))
		return MakeClassHandle(index);

	return Invalid_Class;
}

stock Class:MakeClassHandle(index)
{
	return Class:(CLASS_HANDLE_OFFSET + index + 1);
}

stock GetClassIndex(Class:class)
{
	return _:class - CLASS_HANDLE_OFFSET - 1;
}

stock bool:IsValidClassIndex(index)
{
	return 0 <= index < ArraySize(Classes);
}

stock bool:IsRegisteredProps(Props:props)
{
	if (props == Invalid_Props)
		return false;

	new handle[RZ_MAX_HANDLE_LENGTH];
	return bool:get_props_var(props, "handle", handle, charsmax(handle));
}

stock bool:IsPlayableClassTeam(Team:team)
{
	return team == TEAM_HUMAN || team == TEAM_ZOMBIE;
}
