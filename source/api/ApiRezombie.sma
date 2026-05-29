#include <amxmodx>
#include <reapi>
#include <rezombie>

#pragma semicolon 1
#pragma compress 1

#include <rezombie/api/ClassApi>
#include <rezombie/api/ModeApi>
#include <rezombie/api/PlayerApi>

public plugin_natives()
{
	register_library("rezombie");

	InitializeClassApi();
	InitializeModeApi();

	RegisterClassNatives();
	RegisterModeNatives();
	RegisterPlayerNatives();
}

public plugin_precache()
{
	register_plugin("ReZombie API", "0.1.0", "BRUN0");
}

public plugin_init()
{
	RegisterPlayerHooks();
}

public plugin_end()
{
	DestroyModeApi();
	DestroyClassApi();
}
