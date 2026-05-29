#if defined _rezombie_stock_included
	#endinput
#endif

#define _rezombie_stock_included

#include <amxmodx>
#include <rezombie_const>

stock bool:IsPlayerIndex(id)
{
	return 1 <= id <= MaxClients;
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
