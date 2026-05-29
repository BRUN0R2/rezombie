#include <amxmodx>
#include <reapi>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

#include <rezombie/core/PlayerState>

const CLASS_HANDLE_OFFSET = 1000;
const SUBCLASS_HANDLE_OFFSET = 2000;
const PROPS_HANDLE_OFFSET = 3000;

enum _:ClassData
{
	ClassHandle[RZ_MAX_HANDLE_LENGTH],
	ClassName[RZ_MAX_NAME_LENGTH],
	Team:ClassTeam,
	Props:ClassProps
};

enum _:SubclassData
{
	SubclassHandle[RZ_MAX_HANDLE_LENGTH],
	SubclassName[RZ_MAX_NAME_LENGTH],
	Class:SubclassClass,
	Props:SubclassProps
};

enum _:PropsData
{
	PropsHandle[RZ_MAX_HANDLE_LENGTH],
	PropsHealth,
	PropsSpeed,
	Float:PropsGravity
};

new Array:Classes;
new Array:Subclasses;
new Array:PropsList;

stock any:ReportNativeError(const message[], any:...);

public plugin_natives()
{
	register_library("rezombie");

	Classes = ArrayCreate(ClassData);
	Subclasses = ArrayCreate(SubclassData);
	PropsList = ArrayCreate(PropsData);

	register_native("create_class", "NativeCreateClass");
	register_native("FindClass", "NativeFindClass");
	register_native("get_class_var", "NativeGetClassVar");
	register_native("set_class_var", "NativeSetClassVar");

	register_native("create_subclass", "NativeCreateSubclass");
	register_native("get_subclass_var", "NativeGetSubclassVar");
	register_native("set_subclass_var", "NativeSetSubclassVar");

	register_native("get_props_var", "NativeGetPropsVar");
	register_native("set_props_var", "NativeSetPropsVar");

	register_native("get_player_class", "NativeGetPlayerClass");
	register_native("get_player_subclass", "NativeGetPlayerSubclass");
	register_native("change_player_class", "NativeChangePlayerClass");

	register_native("infect_player", "NativeInfectPlayer");
	register_native("IsZombie", "NativeIsZombie");
	register_native("IsHuman", "NativeIsHuman");
}

public plugin_precache()
{
	register_plugin("ReZombie API", "0.1.0", "BRUN0");
}

public plugin_init()
{
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPost", true);
	RegisterHookChain(RG_CBasePlayer_Killed, "OnPlayerKilledPost", true);
}

public plugin_end()
{
	if (Classes != Invalid_Array)
		ArrayDestroy(Classes);

	if (Subclasses != Invalid_Array)
		ArrayDestroy(Subclasses);

	if (PropsList != Invalid_Array)
		ArrayDestroy(PropsList);
}

public client_putinserver(id)
{
	ConnectPlayerState(id);
}

public client_disconnected(id)
{
	DisconnectPlayerState(id);
}

public OnPlayerSpawnPost(id)
{
	SpawnPlayerState(id);

	new Class:class = GetPlayerClass(id);
	if (class != Invalid_Class)
		ApplyPlayerClassProps(id, class, GetPlayerSubclass(id));
}

public OnPlayerKilledPost(id, attacker, gib)
{
	#pragma unused attacker
	#pragma unused gib

	KillPlayerState(id);
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

	new data[ClassData];
	copy(data[ClassHandle], charsmax(data[ClassHandle]), handle);
	copy(data[ClassName], charsmax(data[ClassName]), handle);
	new Team:team = Team:get_param(CreateClassParamTeam);
	if (!IsPlayableClassTeam(team))
		return Class:ReportNativeError("Invalid class team %d.", _:team);

	data[ClassTeam] = team;
	data[ClassProps] = CreateProps(handle);

	ArrayPushArray(Classes, data);

	return MakeClassHandle(ArraySize(Classes) - 1);
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

		if (!IsValidPropsHandle(props))
			return bool:ReportNativeError("Invalid props handle %d.", _:props);

		data[ClassProps] = props;
		ArraySetArray(Classes, index, data);
		return true;
	}

	return bool:ReportNativeError("Invalid or readonly class property '%s'.", key);
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

	if (!IsValidClassHandle(class))
		return Subclass:ReportNativeError("Invalid parent class handle %d.", _:class);

	new data[SubclassData];
	copy(data[SubclassHandle], charsmax(data[SubclassHandle]), handle);
	copy(data[SubclassName], charsmax(data[SubclassName]), handle);
	data[SubclassClass] = class;
	data[SubclassProps] = CreateProps(handle);

	ArrayPushArray(Subclasses, data);

	return MakeSubclassHandle(ArraySize(Subclasses) - 1);
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

		if (!IsValidPropsHandle(props))
			return bool:ReportNativeError("Invalid props handle %d.", _:props);

		data[SubclassProps] = props;
		ArraySetArray(Subclasses, index, data);
		return true;
	}

	return bool:ReportNativeError("Invalid or readonly subclass property '%s'.", key);
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

		set_string(GetPropsVarParamOutput, data[PropsHandle], get_param(GetPropsVarParamOutputLength));
		return true;
	}

	if (equal(key, "health"))
		return data[PropsHealth];

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
		data[PropsHealth] = get_param(SetPropsVarParamValue);
		ArraySetArray(PropsList, index, data);
		return true;
	}

	if (equal(key, "speed"))
	{
		data[PropsSpeed] = get_param(SetPropsVarParamValue);
		ArraySetArray(PropsList, index, data);
		return true;
	}

	if (equal(key, "gravity"))
	{
		data[PropsGravity] = get_param_f(SetPropsVarParamValue);
		ArraySetArray(PropsList, index, data);
		return true;
	}

	return bool:ReportNativeError("Invalid or readonly props property '%s'.", key);
}

public bool:NativeIsZombie(plugin, params)
{
	enum
	{
		IsZombieParamPlayer = 1
	};

	if (params < IsZombieParamPlayer)
		return bool:ReportNativeError("IsZombie requires player index.");

	new id = get_param(IsZombieParamPlayer);

	if (!IsValidConnectedPlayer(id, "IsZombie"))
		return false;

	return IsPlayerZombie(id);
}

public bool:NativeIsHuman(plugin, params)
{
	enum
	{
		IsHumanParamPlayer = 1
	};

	if (params < IsHumanParamPlayer)
		return bool:ReportNativeError("IsHuman requires player index.");

	new id = get_param(IsHumanParamPlayer);

	if (!IsValidConnectedPlayer(id, "IsHuman"))
		return false;

	return IsPlayerHuman(id);
}

public Class:NativeGetPlayerClass(plugin, params)
{
	enum
	{
		GetPlayerClassParamPlayer = 1
	};

	if (params < GetPlayerClassParamPlayer)
		return Class:ReportNativeError("get_player_class requires player index.");

	new id = get_param(GetPlayerClassParamPlayer);

	if (!IsValidConnectedPlayer(id, "get_player_class"))
		return Invalid_Class;

	return GetPlayerClass(id);
}

public Subclass:NativeGetPlayerSubclass(plugin, params)
{
	enum
	{
		GetPlayerSubclassParamPlayer = 1
	};

	if (params < GetPlayerSubclassParamPlayer)
		return Subclass:ReportNativeError("get_player_subclass requires player index.");

	new id = get_param(GetPlayerSubclassParamPlayer);

	if (!IsValidConnectedPlayer(id, "get_player_subclass"))
		return Invalid_Subclass;

	return GetPlayerSubclass(id);
}

public bool:NativeChangePlayerClass(plugin, params)
{
	enum
	{
		ChangePlayerClassParamPlayer = 1,
		ChangePlayerClassParamClass,
		ChangePlayerClassParamSubclass
	};

	if (params < ChangePlayerClassParamClass)
		return bool:ReportNativeError("change_player_class requires player and class.");

	new id = get_param(ChangePlayerClassParamPlayer);
	if (!IsValidConnectedPlayer(id, "change_player_class"))
		return false;

	new Class:class = Class:get_param(ChangePlayerClassParamClass);
	new Subclass:subclass = Invalid_Subclass;

	if (params >= ChangePlayerClassParamSubclass)
		subclass = Subclass:get_param(ChangePlayerClassParamSubclass);

	return ChangePlayerClass(id, class, subclass);
}

public bool:NativeInfectPlayer(plugin, params)
{
	enum
	{
		InfectPlayerParamPlayer = 1,
		InfectPlayerParamAttacker
	};

	if (params < InfectPlayerParamPlayer)
		return bool:ReportNativeError("infect_player requires player index.");

	new id = get_param(InfectPlayerParamPlayer);
	if (!IsValidConnectedPlayer(id, "infect_player"))
		return false;

	if (params >= InfectPlayerParamAttacker)
	{
		new attacker = get_param(InfectPlayerParamAttacker);
		if (attacker && !IsValidConnectedPlayer(attacker, "infect_player"))
			return false;
	}

	new Class:class = FindClassByHandle("zombie");
	if (class == Invalid_Class)
		return bool:ReportNativeError("Required class 'zombie' was not registered.");

	return ChangePlayerClass(id, class, Invalid_Subclass);
}

stock Props:CreateProps(const handle[])
{
	new data[PropsData];
	copy(data[PropsHandle], charsmax(data[PropsHandle]), handle);
	data[PropsHealth] = 100;
	data[PropsSpeed] = 250;
	data[PropsGravity] = 1.0;

	ArrayPushArray(PropsList, data);

	return MakePropsHandle(ArraySize(PropsList) - 1);
}

stock bool:ChangePlayerClass(id, Class:class, Subclass:subclass)
{
	if (!IsValidClassHandle(class))
		return bool:ReportNativeError("Invalid class handle %d.", _:class);

	if (subclass != Invalid_Subclass && !IsValidSubclassForClass(subclass, class))
		return bool:ReportNativeError("Invalid subclass handle %d for class %d.", _:subclass, _:class);

	new Team:team = GetClassTeam(class);
	if (!IsPlayableClassTeam(team))
		return bool:ReportNativeError("Invalid class team %d.", _:team);

	SetPlayerClass(id, class);
	SetPlayerSubclass(id, subclass);
	SetPlayerZombie(id, bool:(team == TEAM_ZOMBIE));

	ApplyPlayerTeam(id, team);

	if (IsPlayerAlive(id))
		ApplyPlayerClassProps(id, class, subclass);

	return true;
}

stock ApplyPlayerClassProps(id, Class:class, Subclass:subclass)
{
	new Props:props = GetClassRuntimeProps(class, subclass);
	if (!IsValidPropsHandle(props))
	{
		ReportNativeError("Invalid runtime props for player %d.", id);
		return;
	}

	new data[PropsData];
	ArrayGetArray(PropsList, GetPropsIndex(props), data);

	set_entvar(id, var_health, float(data[PropsHealth]));
	set_entvar(id, var_maxspeed, float(data[PropsSpeed]));
	set_entvar(id, var_gravity, data[PropsGravity]);
}

stock ApplyPlayerTeam(id, Team:team)
{
	rg_set_user_team(id, GetGameTeam(team), MODEL_AUTO, true, false);
}

stock Props:GetClassRuntimeProps(Class:class, Subclass:subclass)
{
	if (subclass != Invalid_Subclass)
		return GetSubclassProps(subclass);

	return GetClassProps(class);
}

stock TeamName:GetGameTeam(Team:team)
{
	switch (team)
	{
		case TEAM_HUMAN:
			return TEAM_CT;
		case TEAM_ZOMBIE:
			return TEAM_TERRORIST;
	}

	return TEAM_UNASSIGNED;
}

stock Team:GetClassTeam(Class:class)
{
	new data[ClassData];
	ArrayGetArray(Classes, GetClassIndex(class), data);

	return data[ClassTeam];
}

stock Props:GetClassProps(Class:class)
{
	new data[ClassData];
	ArrayGetArray(Classes, GetClassIndex(class), data);

	return data[ClassProps];
}

stock Class:GetSubclassClass(Subclass:subclass)
{
	new data[SubclassData];
	ArrayGetArray(Subclasses, GetSubclassIndex(subclass), data);

	return data[SubclassClass];
}

stock Props:GetSubclassProps(Subclass:subclass)
{
	new data[SubclassData];
	ArrayGetArray(Subclasses, GetSubclassIndex(subclass), data);

	return data[SubclassProps];
}

stock Class:FindClassByHandle(const handle[])
{
	new data[ClassData];

	for (new index = 0; index < ArraySize(Classes); index++)
	{
		ArrayGetArray(Classes, index, data);

		if (equal(data[ClassHandle], handle))
			return MakeClassHandle(index);
	}

	return Invalid_Class;
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

stock Class:MakeClassHandle(index)
{
	return Class:(CLASS_HANDLE_OFFSET + index + 1);
}

stock Subclass:MakeSubclassHandle(index)
{
	return Subclass:(SUBCLASS_HANDLE_OFFSET + index + 1);
}

stock Props:MakePropsHandle(index)
{
	return Props:(PROPS_HANDLE_OFFSET + index + 1);
}

stock GetClassIndex(Class:class)
{
	return _:class - CLASS_HANDLE_OFFSET - 1;
}

stock GetSubclassIndex(Subclass:subclass)
{
	return _:subclass - SUBCLASS_HANDLE_OFFSET - 1;
}

stock GetPropsIndex(Props:props)
{
	return _:props - PROPS_HANDLE_OFFSET - 1;
}

stock bool:IsValidClassHandle(Class:class)
{
	return IsValidClassIndex(GetClassIndex(class));
}

stock bool:IsValidSubclassHandle(Subclass:subclass)
{
	return IsValidSubclassIndex(GetSubclassIndex(subclass));
}

stock bool:IsValidSubclassForClass(Subclass:subclass, Class:class)
{
	if (!IsValidSubclassHandle(subclass))
		return false;

	return GetSubclassClass(subclass) == class;
}

stock bool:IsValidPropsHandle(Props:props)
{
	return IsValidPropsIndex(GetPropsIndex(props));
}

stock bool:IsValidClassIndex(index)
{
	return 0 <= index < ArraySize(Classes);
}

stock bool:IsValidSubclassIndex(index)
{
	return 0 <= index < ArraySize(Subclasses);
}

stock bool:IsValidPropsIndex(index)
{
	return 0 <= index < ArraySize(PropsList);
}

stock bool:IsPlayerIndex(id)
{
	return 1 <= id <= MaxClients;
}

stock bool:IsPlayableClassTeam(Team:team)
{
	return team == TEAM_HUMAN || team == TEAM_ZOMBIE;
}

stock bool:IsValidConnectedPlayer(id, const nativeName[])
{
	if (!IsPlayerIndex(id))
	{
		ReportNativeError("%s received invalid player index %d.", nativeName, id);
		return false;
	}

	if (!IsPlayerConnected(id))
	{
		ReportNativeError("%s received disconnected player %d.", nativeName, id);
		return false;
	}

	return true;
}

stock any:ReportNativeError(const message[], any:...)
{
	enum
	{
		NativeErrorFirstVarArg = 2
	};

	new text[192];
	vformat(text, charsmax(text), message, NativeErrorFirstVarArg);
	log_error(AMX_ERR_NATIVE, "%s", text);

	return null;
}
