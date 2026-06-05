#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const WEAPON_HANDLE_OFFSET = 7000;

enum _:WeaponData
{
	WeaponHandle[RZ_MAX_HANDLE_LENGTH],
	Model:WeaponViewModel,
	Model:WeaponPlayerModel,
	Model:WeaponWorldModel
};

new Array:Weapons;
new Trie:WeaponsByHandle;

public plugin_natives()
{
	register_library("ApiWeapons");

	Weapons = ArrayCreate(WeaponData);
	WeaponsByHandle = TrieCreate();

	register_native("create_weapon", "NativeCreateWeapon");
	register_native("FindWeapon", "NativeFindWeapon");
	register_native("get_weapon_var", "NativeGetWeaponVar");
	register_native("set_weapon_var", "NativeSetWeaponVar");
}

public plugin_precache()
{
	register_plugin("API: Weapons", "0.1.0", "BRUN0");
}

public plugin_end()
{
	if (WeaponsByHandle != Invalid_Trie)
		TrieDestroy(WeaponsByHandle);

	if (Weapons != Invalid_Array)
	{
		ArrayDestroy(Weapons);
		Weapons = Invalid_Array;
	}
}

public Weapon:NativeCreateWeapon(plugin, params)
{
	enum
	{
		CreateWeaponParamHandle = 1
	};

	if (params < CreateWeaponParamHandle)
		return Weapon:ReportNativeError("create_weapon requires handle.");

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(CreateWeaponParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Weapon:ReportNativeError("Weapon handle cannot be empty.");

	if (FindWeaponByHandle(handle) != Invalid_Weapon)
		return Weapon:ReportNativeError("Weapon '%s' is already registered.", handle);

	new data[WeaponData];
	copy(data[WeaponHandle], charsmax(data[WeaponHandle]), handle);
	data[WeaponViewModel] = Invalid_Model;
	data[WeaponPlayerModel] = Invalid_Model;
	data[WeaponWorldModel] = Invalid_Model;

	new index = ArraySize(Weapons);
	if (!TrieSetCell(WeaponsByHandle, handle, index, false))
		return Weapon:ReportNativeError("Weapon '%s' handle index was not registered.", handle);

	ArrayPushArray(Weapons, data);

	return MakeWeaponHandle(index);
}

public Weapon:NativeFindWeapon(plugin, params)
{
	enum
	{
		FindWeaponParamHandle = 1
	};

	if (params < FindWeaponParamHandle)
		return Invalid_Weapon;

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(FindWeaponParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Invalid_Weapon;

	return FindWeaponByHandle(handle);
}

public any:NativeGetWeaponVar(plugin, params)
{
	enum
	{
		GetWeaponVarParamWeapon = 1,
		GetWeaponVarParamKey,
		GetWeaponVarParamOutput,
		GetWeaponVarParamOutputLength
	};

	if (params < GetWeaponVarParamKey)
		return ReportNativeError("get_weapon_var requires weapon and property name.");

	new Weapon:weapon = Weapon:get_param(GetWeaponVarParamWeapon);
	new index = GetWeaponIndex(weapon);

	if (!IsValidWeaponIndex(index))
		return ReportNativeError("Invalid weapon handle %d.", _:weapon);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetWeaponVarParamKey, key, charsmax(key));

	new data[WeaponData];
	ArrayGetArray(Weapons, index, data);

	if (equal(key, "handle"))
	{
		if (params < GetWeaponVarParamOutputLength)
			return ReportNativeError("get_weapon_var 'handle' requires output buffer and length.");

		set_string(
			GetWeaponVarParamOutput,
			data[WeaponHandle],
			get_param_byref(GetWeaponVarParamOutputLength)
		);
		return true;
	}

	if (equal(key, "view_model"))
		return data[WeaponViewModel];

	if (equal(key, "player_model"))
		return data[WeaponPlayerModel];

	if (equal(key, "world_model"))
		return data[WeaponWorldModel];

	return ReportNativeError("Invalid weapon property '%s'.", key);
}

public bool:NativeSetWeaponVar(plugin, params)
{
	enum
	{
		SetWeaponVarParamWeapon = 1,
		SetWeaponVarParamKey,
		SetWeaponVarParamValue
	};

	if (params < SetWeaponVarParamValue)
		return bool:ReportNativeError("set_weapon_var requires weapon, property name and value.");

	new Weapon:weapon = Weapon:get_param(SetWeaponVarParamWeapon);
	new index = GetWeaponIndex(weapon);

	if (!IsValidWeaponIndex(index))
		return bool:ReportNativeError("Invalid weapon handle %d.", _:weapon);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetWeaponVarParamKey, key, charsmax(key));

	new data[WeaponData];
	ArrayGetArray(Weapons, index, data);

	if (equal(key, "view_model"))
	{
		new Model:model = Model:get_param_byref(SetWeaponVarParamValue);

		if (!IsRegisteredModel(model))
			return bool:ReportNativeError("Invalid weapon view_model handle %d.", _:model);

		data[WeaponViewModel] = model;
		ArraySetArray(Weapons, index, data);
		return true;
	}

	if (equal(key, "player_model"))
	{
		new Model:model = Model:get_param_byref(SetWeaponVarParamValue);

		if (!IsRegisteredModel(model))
			return bool:ReportNativeError("Invalid weapon player_model handle %d.", _:model);

		data[WeaponPlayerModel] = model;
		ArraySetArray(Weapons, index, data);
		return true;
	}

	if (equal(key, "world_model"))
	{
		new Model:model = Model:get_param_byref(SetWeaponVarParamValue);

		if (!IsRegisteredModel(model))
			return bool:ReportNativeError("Invalid weapon world_model handle %d.", _:model);

		data[WeaponWorldModel] = model;
		ArraySetArray(Weapons, index, data);
		return true;
	}

	if (equal(key, "handle"))
		return bool:ReportNativeError("Weapon property '%s' is readonly.", key);

	return bool:ReportNativeError("Invalid weapon property '%s'.", key);
}

stock Weapon:FindWeaponByHandle(const handle[])
{
	new index;
	if (TrieGetCell(WeaponsByHandle, handle, index))
		return MakeWeaponHandle(index);

	return Invalid_Weapon;
}

stock Weapon:MakeWeaponHandle(index)
{
	return Weapon:(WEAPON_HANDLE_OFFSET + index + 1);
}

stock GetWeaponIndex(Weapon:weapon)
{
	return _:weapon - WEAPON_HANDLE_OFFSET - 1;
}

stock bool:IsValidWeaponIndex(index)
{
	return 0 <= index < ArraySize(Weapons);
}

stock bool:IsRegisteredModel(Model:model)
{
	if (model == Invalid_Model)
		return false;

	new path[RZ_MAX_RESOURCE_PATH_LENGTH];
	return bool:get_model_var(model, "path", path, charsmax(path));
}
