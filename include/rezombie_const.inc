#if defined _rezombie_const_included
	#endinput
#endif

#define _rezombie_const_included

#define IsAlive(%1) (1 <= %1 <= MaxClients && is_user_alive(%1) && is_user_connected(%1))
#define IsPlayerConnected(%1) (1 <= %1 <= MaxClients && is_user_connected(%1))
#define IsInvalidArray(%0) (%0 == Invalid_Array || !ArraySize(%0))
#define IsNullString(%0) bool:(%0[0] == EOS)


stock precache_player_model(const modelname[])
{
	static longname[128], index;
	formatex(longname, charsmax(longname), "models/player/%s/%s.mdl", modelname, modelname);
	index = precache_model(longname);

	copy(longname[strlen(longname)-4], charsmax(longname) - (strlen(longname)-4), "T.mdl");

	if (file_exists(longname))
		precache_model(longname);

	return index;
}