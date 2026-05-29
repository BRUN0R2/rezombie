// ReZombie public API.

#if defined _rezombie_included
	#endinput
#endif

#define _rezombie_included

#if AMXX_VERSION_NUM >= 175
	#pragma reqlib rezombie
	#if !defined AMXMODX_NOAUTOLOAD
		#pragma loadlib rezombie
	#endif
#else
	#pragma library rezombie
#endif

// ReZombie API functions.
native bool:IsZombie(id);
native bool:IsHuman(id);