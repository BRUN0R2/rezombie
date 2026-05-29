#if defined _rezombie_const_included
	#endinput
#endif

#define _rezombie_const_included

new const any:null = 0;
#pragma unused null

const RZ_MAX_HANDLE_LENGTH = 32;
const RZ_MAX_NAME_LENGTH = 64;
const RZ_MAX_RESOURCE_PATH_LENGTH = 128;

const Class:Invalid_Class = Class:0;
const Subclass:Invalid_Subclass = Subclass:0;
const Props:Invalid_Props = Props:0;
const Mode:Invalid_Mode = Mode:0;
const Model:Invalid_Model = Model:0;

enum Team
{
	TEAM_NONE = 0,
	TEAM_HUMAN,
	TEAM_ZOMBIE
}

#define IsAlive(%1) (1 <= %1 <= MaxClients && is_user_alive(%1) && is_user_connected(%1))
#define IsInvalidArray(%0) (%0 == Invalid_Array || !ArraySize(%0))
#define IsNullString(%0) bool:(%0[0] == EOS)
