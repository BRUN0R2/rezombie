#include <amxmodx>
#include <rezombie>
#include <rezombie/core/RoundRuntime>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

new const ROUND_API_VAR_STATE[] = "state";
new const ROUND_API_VAR_MODE[] = "mode";
new const ROUND_API_VAR_TIME_LEFT[] = "time_left";
new const ROUND_API_RUNTIME_WRITER_FILENAME[] = "GameRules.amxx";
new const ROUND_API_RUNTIME_WRITER_PATH[] = "rezombie/core/GameRules.amxx";
new const ROUND_API_RUNTIME_WRITER_WINDOWS_PATH[] = "rezombie\\core\\GameRules.amxx";

enum _:RoundApiRuntime
{
	RoundState:RoundApiRuntimeState,
	Mode:RoundApiRuntimeMode,
	Float:RoundApiRuntimeDeadlineAt
};

new RoundApiRuntimeData[RoundApiRuntime];

public plugin_natives()
{
	InitializeRoundApiRuntime();

	register_library("rezombie");

	register_native("get_round_var", "NativeGetRoundVar");
	register_native("sync_round_runtime", "NativeSyncRoundRuntime");
}

public plugin_precache()
{
	register_plugin("API: Rounds", "0.1.0", "BRUN0");
}

public any:NativeGetRoundVar(plugin, params)
{
	enum
	{
		GetRoundVarParamKey = 1
	};

	if (params < GetRoundVarParamKey)
		return ReportNativeError("get_round_var requires property name.");

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(GetRoundVarParamKey, key, charsmax(key));

	if (equal(key, ROUND_API_VAR_STATE))
		return RoundApiRuntimeData[RoundApiRuntimeState];

	if (equal(key, ROUND_API_VAR_MODE))
		return RoundApiRuntimeData[RoundApiRuntimeMode];

	if (equal(key, ROUND_API_VAR_TIME_LEFT))
		return GetRoundTimeLeft();

	return ReportNativeError("Invalid round property '%s'.", key);
}

public bool:NativeSyncRoundRuntime(plugin, params)
{
	enum
	{
		SyncRoundRuntimeParamState = 1,
		SyncRoundRuntimeParamMode,
		SyncRoundRuntimeParamTimeLeft
	};

	if (!IsRoundRuntimeWriter(plugin))
		return bool:ReportNativeError("sync_round_runtime can only be called by GameRules.");

	if (params < SyncRoundRuntimeParamTimeLeft)
		return bool:ReportNativeError("sync_round_runtime requires state, mode and time_left.");

	new RoundState:roundState = RoundState:get_param(SyncRoundRuntimeParamState);
	if (!IsValidRoundState(roundState))
		return bool:ReportNativeError("Invalid round state %d.", _:roundState);

	new Mode:mode = Mode:get_param(SyncRoundRuntimeParamMode);
	if (!IsValidRoundMode(mode))
		return bool:ReportNativeError("Invalid round mode %d.", _:mode);

	new Float:timeLeft = get_param_f(SyncRoundRuntimeParamTimeLeft);
	if (timeLeft < 0.0)
		return bool:ReportNativeError("Round time_left cannot be negative.");

	RoundApiRuntimeData[RoundApiRuntimeState] = roundState;
	RoundApiRuntimeData[RoundApiRuntimeMode] = mode;
	SyncRoundRuntimeDeadline(timeLeft);

	return true;
}

stock InitializeRoundApiRuntime()
{
	RoundApiRuntimeData[RoundApiRuntimeState] = RoundStateFreezing;
	RoundApiRuntimeData[RoundApiRuntimeMode] = Invalid_Mode;
	RoundApiRuntimeData[RoundApiRuntimeDeadlineAt] = 0.0;
}

stock bool:IsValidRoundState(RoundState:roundState)
{
	return RoundStateFreezing <= roundState <= RoundStateEnding;
}

stock bool:IsValidRoundMode(Mode:mode)
{
	if (mode == Invalid_Mode)
		return true;

	new handle[RZ_MAX_HANDLE_LENGTH];
	return bool:get_mode_var(mode, "handle", handle, charsmax(handle));
}

stock bool:IsRoundRuntimeWriter(plugin)
{
	new filename[RZ_MAX_RESOURCE_PATH_LENGTH];
	get_plugin(plugin, filename, charsmax(filename));

	return equal(filename, ROUND_API_RUNTIME_WRITER_FILENAME)
		|| containi(filename, ROUND_API_RUNTIME_WRITER_PATH) != -1
		|| containi(filename, ROUND_API_RUNTIME_WRITER_WINDOWS_PATH) != -1;
}

stock SyncRoundRuntimeDeadline(Float:timeLeft)
{
	if (timeLeft > 0.0)
	{
		RoundApiRuntimeData[RoundApiRuntimeDeadlineAt] = get_gametime() + timeLeft;
		return;
	}

	RoundApiRuntimeData[RoundApiRuntimeDeadlineAt] = 0.0;
}

stock Float:GetRoundTimeLeft()
{
	if (RoundApiRuntimeData[RoundApiRuntimeDeadlineAt] <= 0.0)
		return 0.0;

	new Float:timeLeft = RoundApiRuntimeData[RoundApiRuntimeDeadlineAt] - get_gametime();
	if (timeLeft < 0.0)
		return 0.0;

	return timeLeft;
}
