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

stock bool:HasModelExtension(const path[])
{
	new length = strlen(path);
	if (length <= 4)
		return false;

	return bool:(path[length - 4] == '.'
		&& (path[length - 3] == 'm' || path[length - 3] == 'M')
		&& (path[length - 2] == 'd' || path[length - 2] == 'D')
		&& (path[length - 1] == 'l' || path[length - 1] == 'L'));
}

stock bool:GetModelNameFromPath(const path[], name[], length)
{
	new start;
	for (new index = 0; path[index] != EOS; index++)
	{
		if (path[index] == '/' || path[index] == 92)
			start = index + 1;
	}

	copy(name, length, path[start]);

	new nameLength = strlen(name);
	if (nameLength <= 4 || !HasModelExtension(name))
		return false;

	name[nameLength - 4] = EOS;
	return !IsNullString(name);
}

stock bool:GetTextureModelPath(const modelPath[], texturePath[], length)
{
	if (!HasModelExtension(modelPath))
		return false;

	copy(texturePath, length, modelPath);

	new pathLength = strlen(texturePath);
	texturePath[pathLength - 4] = EOS;
	add(texturePath, length, "T.mdl");
	return true;
}
