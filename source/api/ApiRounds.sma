#include <amxmodx>
#include <rezombie>
#include <rezombie_stock>

#pragma semicolon 1
#pragma compress 1

new RoundState:CurrentRoundState = RoundStateFreezing;
new Mode:CurrentRoundMode = Invalid_Mode;
new Float:CurrentRoundDeadlineAt;

public plugin_natives()
{
	register_library("rezombie");

	register_native("get_round_var", "NativeGetRoundVar");
	register_native("set_round_var", "NativeSetRoundVar");
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

	if (equal(key, "state"))
		return CurrentRoundState;

	if (equal(key, "mode"))
		return CurrentRoundMode;

	if (equal(key, "time_left"))
		return GetRoundTimeLeft();

	return ReportNativeError("Invalid round property '%s'.", key);
}

public bool:NativeSetRoundVar(plugin, params)
{
	enum
	{
		SetRoundVarParamKey = 1,
		SetRoundVarParamValue
	};

	if (params < SetRoundVarParamValue)
		return bool:ReportNativeError("set_round_var requires property name and value.");

	new key[RZ_MAX_HANDLE_LENGTH];
	get_string(SetRoundVarParamKey, key, charsmax(key));

	if (equal(key, "state"))
	{
		new RoundState:roundState = RoundState:get_param_byref(SetRoundVarParamValue);
		if (!IsValidRoundState(roundState))
			return bool:ReportNativeError("Invalid round state %d.", _:roundState);

		CurrentRoundState = roundState;
		return true;
	}

	if (equal(key, "mode"))
	{
		new Mode:mode = Mode:get_param_byref(SetRoundVarParamValue);
		if (_:mode < _:Invalid_Mode)
			return bool:ReportNativeError("Invalid round mode %d.", _:mode);

		CurrentRoundMode = mode;
		return true;
	}

	if (equal(key, "time_left"))
	{
		new Float:timeLeft = get_float_byref(SetRoundVarParamValue);
		if (timeLeft < 0.0)
			return bool:ReportNativeError("Round time_left cannot be negative.");

		if (timeLeft > 0.0)
			CurrentRoundDeadlineAt = get_gametime() + timeLeft;
		else
			CurrentRoundDeadlineAt = 0.0;

		return true;
	}

	return bool:ReportNativeError("Invalid round property '%s'.", key);
}

stock bool:IsValidRoundState(RoundState:roundState)
{
	return RoundStateFreezing <= roundState <= RoundStateEnding;
}

stock Float:GetRoundTimeLeft()
{
	if (CurrentRoundDeadlineAt <= 0.0)
		return 0.0;

	new Float:timeLeft = CurrentRoundDeadlineAt - get_gametime();
	if (timeLeft < 0.0)
		return 0.0;

	return timeLeft;
}
