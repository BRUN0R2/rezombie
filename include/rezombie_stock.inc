#if defined _rezombie_stock_included
	#endinput
#endif

#define _rezombie_stock_included

#include <amxmodx>
#include <rezombie_const>

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

/*
 * ###########################################
 *		Players stocks helpers
 * ###########################################
 */

/**
 * Checks whether a value is a valid player index.
 *
 * @param id        Player index
 *
 * @return          true when the index is in the player range
 */
stock bool:IsPlayerIndex(id)
{
	return bool:(1 <= id <= MaxClients);
}

/**
 * Checks whether a player is connected and alive.
 *
 * @param id        Player index
 *
 * @return          true when the player is connected and alive
 */
stock bool:IsAlivePlayer(id)
{
	return IsPlayerIndex(id) && is_user_connected(id) && is_user_alive(id);
}

/**
 * Checks whether a player is connected, alive and human.
 *
 * @param id        Player index
 *
 * @return          true when the player is alive and human
 */
stock bool:IsAliveHuman(id)
{
	return IsAlivePlayer(id) && IsHuman(id);
}

/**
 * Checks whether a player is connected, alive and zombie.
 *
 * @param id        Player index
 *
 * @return          true when the player is alive and zombie
 */
stock bool:IsAliveZombie(id)
{
	return IsAlivePlayer(id) && IsZombie(id);
}

/**
 * Collects connected alive players.
 *
 * @param players       Output player index array, sized as MAX_PLAYERS
 * @param playersCount  Output player count
 *
 * @return              Number of collected players
 */
stock CollectAlivePlayers(players[MAX_PLAYERS], &playersCount)
{
	playersCount = 0;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (!IsAlivePlayer(id))
			continue;

		players[playersCount] = id;
		playersCount++;
	}

	return playersCount;
}

/**
 * Collects alive human players.
 *
 * @param players       Output player index array, sized as MAX_PLAYERS
 * @param playersCount  Output player count
 *
 * @return              Number of collected players
 */
stock CollectAliveHumans(players[MAX_PLAYERS], &playersCount)
{
	playersCount = 0;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (!IsAliveHuman(id))
			continue;

		players[playersCount] = id;
		playersCount++;
	}

	return playersCount;
}

/**
 * Collects alive zombie players.
 *
 * @param players       Output player index array, sized as MAX_PLAYERS
 * @param playersCount  Output player count
 *
 * @return              Number of collected players
 */
stock CollectAliveZombies(players[MAX_PLAYERS], &playersCount)
{
	playersCount = 0;

	for (new id = 1; id <= MaxClients; id++)
	{
		if (!IsAliveZombie(id))
			continue;

		players[playersCount] = id;
		playersCount++;
	}

	return playersCount;
}

/**
 * Picks a player from a collected player array and removes it from the list.
 *
 * @param players       Player index array
 * @param playersCount  Player count, decremented when a player is picked
 * @param preferred     Preferred player index, or 0 for random
 *
 * @return              Picked player index, or 0 when the array is empty
 */
stock PickPlayer(players[MAX_PLAYERS], &playersCount, preferred = 0)
{
	if (playersCount <= 0)
		return 0;

	new pickedIndex = random(playersCount);

	for (new index = 0; index < playersCount; index++)
	{
		if (players[index] == preferred)
		{
			pickedIndex = index;
			break;
		}
	}

	new player = players[pickedIndex];

	for (new index = pickedIndex; index < playersCount - 1; index++)
		players[index] = players[index + 1];

	playersCount--;
	return player;
}

/*
 * ###########################################
 *		Classes stocks helpers
 * ###########################################
 */

/**
 * Requires a player class by handle.
 *
 * @param handle    Class handle
 *
 * @return          Class handle
 * @error           Fails when the class is not registered
 */
stock Class:RequireClass(const handle[])
{
	new Class:class = FindClass(handle);

	if (class == Invalid_Class)
	{
		set_fail_state("Required class '%s' was not registered.", handle);
	}

	return class;
}
