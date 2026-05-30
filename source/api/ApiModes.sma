#include <amxmodx>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

const MODE_HANDLE_OFFSET = 4000;
const MODE_FORWARD_INVALID = -1;
const MODE_DEFAULT_MIN_PLAYERS = 2;
const Float:MODE_DEFAULT_ROUND_TIME = 180.0;

enum _:ModeData
{
	ModeHandle[RZ_MAX_HANDLE_LENGTH],
	ModeName[RZ_MAX_NAME_LENGTH],
	ModeNoticeMessage[RZ_MAX_NAME_LENGTH],
	ModeLaunchForwardName[RZ_MAX_HANDLE_LENGTH],
	ModeLaunchForward,
	ModeMinPlayers,
	Float:ModeRoundTime,
	RespawnType:ModeRespawn
};

new Array:Modes;
new Trie:ModesByHandle;

public plugin_natives()
{
	register_library("rezombie");

	Modes = ArrayCreate(ModeData);
	ModesByHandle = TrieCreate();

	register_native("create_mode", "NativeCreateMode");
	register_native("FindMode", "NativeFindMode");
	register_native("get_modes_count", "NativeGetModesCount");
	register_native("get_mode", "NativeGetMode");
	register_native("get_mode_var", "NativeGetModeVar");
	register_native("set_mode_var", "NativeSetModeVar");
	register_native("launch_mode", "NativeLaunchMode");
}

public plugin_precache()
{
	register_plugin("API: Modes", "0.1.0", "BRUN0");
}

public plugin_end()
{
	if (Modes != Invalid_Array)
	{
		new data[ModeData];
		for (new index = 0; index < ArraySize(Modes); index++)
		{
			ArrayGetArray(Modes, index, data);

			if (data[ModeLaunchForward] != MODE_FORWARD_INVALID)
				DestroyForward(data[ModeLaunchForward]);
		}

		ArrayDestroy(Modes);
		Modes = Invalid_Array;
	}

	if (ModesByHandle != Invalid_Trie)
		TrieDestroy(ModesByHandle);
}

public Mode:NativeCreateMode(plugin, params)
{
	enum
	{
		CreateModeParamHandle = 1,
		CreateModeParamLaunchForward
	};

	if (params < CreateModeParamLaunchForward)
		return Mode:ReportNativeError("create_mode requires handle and launch forward.");

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(CreateModeParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Mode:ReportNativeError("Mode handle cannot be empty.");

	if (FindModeByHandle(handle) != Invalid_Mode)
		return Mode:ReportNativeError("Mode '%s' is already registered.", handle);

	new launchForward[RZ_MAX_HANDLE_LENGTH];
	get_string(CreateModeParamLaunchForward, launchForward, charsmax(launchForward));

	if (IsNullString(launchForward))
		return Mode:ReportNativeError("Mode '%s' launch forward cannot be empty.", handle);

	new launchForwardId = CreateOneForward(plugin, launchForward, FP_CELL, FP_CELL);
	if (launchForwardId == MODE_FORWARD_INVALID)
		return Mode:ReportNativeError("Mode '%s' launch forward '%s' was not found.", handle, launchForward);

	new data[ModeData];
	copy(data[ModeHandle], charsmax(data[ModeHandle]), handle);
	copy(data[ModeName], charsmax(data[ModeName]), handle);
	data[ModeNoticeMessage][0] = EOS;
	copy(data[ModeLaunchForwardName], charsmax(data[ModeLaunchForwardName]), launchForward);
	data[ModeLaunchForward] = launchForwardId;
	data[ModeMinPlayers] = MODE_DEFAULT_MIN_PLAYERS;
	data[ModeRoundTime] = MODE_DEFAULT_ROUND_TIME;
	data[ModeRespawn] = Respawn_Off;

	new index = ArraySize(Modes);
	if (!TrieSetCell(ModesByHandle, handle, index, false))
	{
		DestroyForward(launchForwardId);
		return Mode:ReportNativeError("Mode '%s' handle index was not registered.", handle);
	}

	ArrayPushArray(Modes, data);

	return MakeModeHandle(index);
}

public Mode:NativeFindMode(plugin, params)
{
	enum
	{
		FindModeParamHandle = 1
	};

	if (params < FindModeParamHandle)
		return Invalid_Mode;

	new handle[RZ_MAX_HANDLE_LENGTH];
	get_string(FindModeParamHandle, handle, charsmax(handle));

	if (IsNullString(handle))
		return Invalid_Mode;

	return FindModeByHandle(handle);
}

public NativeGetModesCount(plugin, params)
{
	#pragma unused plugin
	#pragma unused params

	return ArraySize(Modes);
}

public Mode:NativeGetMode(plugin, params)
{
	enum
	{
		GetModeParamIndex = 1
	};

	if (params < GetModeParamIndex)
		return Mode:ReportNativeError("get_mode requires index.");

	new index = get_param(GetModeParamIndex);

	if (!IsValidModeIndex(index))
		return Mode:ReportNativeError("Invalid mode index %d.", index);

	return MakeModeHandle(index);
}

public any:NativeGetModeVar(plugin, params)
{
	enum
	{
		GetModeVarParamMode = 1,
		GetModeVarParamKey,
		GetModeVarParamOutput,
		GetModeVarParamOutputLength
	};

	if (params < GetModeVarParamKey)
		return ReportNativeError("get_mode_var requires mode and property name.");

	new Mode:mode = Mode:get_param(GetModeVarParamMode);
	new index = GetModeIndex(mode);

	if (!IsValidModeIndex(index))
		return ReportNativeError("Invalid mode handle %d.", _:mode);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetModeVarParamKey, key, charsmax(key));

	new data[ModeData];
	ArrayGetArray(Modes, index, data);

	if (equal(key, "handle"))
	{
		if (params < GetModeVarParamOutputLength)
			return ReportNativeError("get_mode_var 'handle' requires output buffer and length.");

		set_string(GetModeVarParamOutput, data[ModeHandle], get_param_byref(GetModeVarParamOutputLength));
		return true;
	}

	if (equal(key, "name"))
	{
		if (params < GetModeVarParamOutputLength)
			return ReportNativeError("get_mode_var 'name' requires output buffer and length.");

		set_string(GetModeVarParamOutput, data[ModeName], get_param_byref(GetModeVarParamOutputLength));
		return true;
	}

	if (equal(key, "notice_message"))
	{
		if (params < GetModeVarParamOutputLength)
			return ReportNativeError("get_mode_var 'notice_message' requires output buffer and length.");

		set_string(GetModeVarParamOutput, data[ModeNoticeMessage], get_param_byref(GetModeVarParamOutputLength));
		return true;
	}

	if (equal(key, "launch_forward"))
	{
		if (params < GetModeVarParamOutputLength)
			return ReportNativeError("get_mode_var 'launch_forward' requires output buffer and length.");

		set_string(GetModeVarParamOutput, data[ModeLaunchForwardName], get_param_byref(GetModeVarParamOutputLength));
		return true;
	}

	if (equal(key, "min_players"))
		return data[ModeMinPlayers];

	if (equal(key, "round_time"))
		return data[ModeRoundTime];

	if (equal(key, "respawn"))
		return data[ModeRespawn];

	return ReportNativeError("Invalid mode property '%s'.", key);
}

public bool:NativeSetModeVar(plugin, params)
{
	enum
	{
		SetModeVarParamMode = 1,
		SetModeVarParamKey,
		SetModeVarParamValue
	};

	if (params < SetModeVarParamValue)
		return bool:ReportNativeError("set_mode_var requires mode, property name and value.");

	new Mode:mode = Mode:get_param(SetModeVarParamMode);
	new index = GetModeIndex(mode);

	if (!IsValidModeIndex(index))
		return bool:ReportNativeError("Invalid mode handle %d.", _:mode);

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetModeVarParamKey, key, charsmax(key));

	new data[ModeData];
	ArrayGetArray(Modes, index, data);

	if (equal(key, "name"))
	{
		get_string(SetModeVarParamValue, data[ModeName], charsmax(data[ModeName]));
		ArraySetArray(Modes, index, data);
		return true;
	}

	if (equal(key, "notice_message"))
	{
		get_string(SetModeVarParamValue, data[ModeNoticeMessage], charsmax(data[ModeNoticeMessage]));
		ArraySetArray(Modes, index, data);
		return true;
	}

	if (equal(key, "min_players"))
	{
		new minPlayers = get_param_byref(SetModeVarParamValue);
		if (minPlayers < 1)
			return bool:ReportNativeError("Mode min_players must be greater than zero.");

		data[ModeMinPlayers] = minPlayers;
		ArraySetArray(Modes, index, data);
		return true;
	}

	if (equal(key, "round_time"))
	{
		new Float:roundTime = get_float_byref(SetModeVarParamValue);
		if (roundTime <= 0.0)
			return bool:ReportNativeError("Mode round_time must be greater than zero.");

		data[ModeRoundTime] = roundTime;
		ArraySetArray(Modes, index, data);
		return true;
	}

	if (equal(key, "respawn"))
	{
		new RespawnType:respawn = RespawnType:get_param_byref(SetModeVarParamValue);
		if (!IsValidRespawnType(respawn))
			return bool:ReportNativeError("Invalid mode respawn policy %d.", _:respawn);

		data[ModeRespawn] = respawn;
		ArraySetArray(Modes, index, data);
		return true;
	}

	return bool:ReportNativeError("Invalid or readonly mode property '%s'.", key);
}

public bool:NativeLaunchMode(plugin, params)
{
	enum
	{
		LaunchModeParamMode = 1,
		LaunchModeParamTarget
	};

	if (params < LaunchModeParamMode)
		return bool:ReportNativeError("launch_mode requires mode.");

	new Mode:mode = Mode:get_param(LaunchModeParamMode);
	new target = 0;

	if (params >= LaunchModeParamTarget)
		target = get_param(LaunchModeParamTarget);

	return LaunchMode(mode, target);
}

stock bool:LaunchMode(Mode:mode, target)
{
	new index = GetModeIndex(mode);
	if (!IsValidModeIndex(index))
		return bool:ReportNativeError("Invalid mode handle %d.", _:mode);

	new data[ModeData];
	ArrayGetArray(Modes, index, data);

	new result;
	if (!ExecuteForward(data[ModeLaunchForward], result, mode, target))
		return bool:ReportNativeError("Mode '%s' launch forward could not be executed.", data[ModeHandle]);

	return bool:result;
}

stock Mode:FindModeByHandle(const handle[])
{
	new index;
	if (TrieGetCell(ModesByHandle, handle, index))
		return MakeModeHandle(index);

	return Invalid_Mode;
}

stock Mode:MakeModeHandle(index)
{
	return Mode:(MODE_HANDLE_OFFSET + index + 1);
}

stock GetModeIndex(Mode:mode)
{
	return _:mode - MODE_HANDLE_OFFSET - 1;
}

stock bool:IsValidModeHandle(Mode:mode)
{
	return IsValidModeIndex(GetModeIndex(mode));
}

stock bool:IsValidModeIndex(index)
{
	return 0 <= index < ArraySize(Modes);
}

stock bool:IsValidRespawnType(RespawnType:respawn)
{
	switch (respawn)
	{
		case Respawn_Off, Respawn_ToHumansTeam, Respawn_ToZombiesTeam, Respawn_Balance:
			return true;
	}

	return false;
}
