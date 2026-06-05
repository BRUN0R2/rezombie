#include <rezombie>

#pragma semicolon 1
#pragma compress 1

const GAME_CVARS_INVALID_INDEX = -1;
const GAME_CVARS_INVALID_POINTER = 0;

new const cvarhook:GAME_CVARS_INVALID_HOOK = cvarhook:0;

enum _:GameCvarDefinition
{
	GameCvarName[32],
	GameCvarValue[8]
};

new const GameCvarDefinitions[][GameCvarDefinition] =
{
	{ "mp_freezetime", "0" },
	{ "mp_limitteams", "0" },
	{ "mp_autoteambalance", "0" },
	{ "mp_autokick", "0" },
	{ "sv_filetransfercompression", "0" }
};

new GameCvarPointers[sizeof GameCvarDefinitions];
new cvarhook:GameCvarHooks[sizeof GameCvarDefinitions];

public plugin_precache()
{
	register_plugin("Core: Game Cvars", "0.1.0", "BRUN0");
}

public plugin_init()
{
	InitializeGameCvars();
}

public plugin_cfg()
{
	EnforceGameCvars();
}

public plugin_end()
{
	DisableGameCvarHooks();
}

public OnGameCvarChange(pcvar, const oldValue[], const newValue[])
{
	#pragma unused oldValue

	new index = FindGameCvarByPointer(pcvar);
	if (index == GAME_CVARS_INVALID_INDEX)
		set_fail_state("GameCvars received an unknown cvar change.");

	if (equal(newValue, GameCvarDefinitions[index][GameCvarValue]))
		return;

	RestoreGameCvar(index);
}

stock InitializeGameCvars()
{
	for (new index = 0; index < sizeof GameCvarDefinitions; index++)
	{
		GameCvarPointers[index] = RequireGameCvarPointer(index);
		set_pcvar_string(GameCvarPointers[index], GameCvarDefinitions[index][GameCvarValue]);
		GameCvarHooks[index] = hook_cvar_change(GameCvarPointers[index], "OnGameCvarChange");
	}
}

stock EnforceGameCvars()
{
	for (new index = 0; index < sizeof GameCvarDefinitions; index++)
		RestoreGameCvar(index);
}

stock RestoreGameCvar(index)
{
	if (GameCvarPointers[index] == GAME_CVARS_INVALID_POINTER)
		set_fail_state("GameCvars cvar '%s' was not initialized.", GameCvarDefinitions[index][GameCvarName]);

	if (GameCvarHooks[index] == GAME_CVARS_INVALID_HOOK)
	{
		set_pcvar_string(GameCvarPointers[index], GameCvarDefinitions[index][GameCvarValue]);
		return;
	}

	disable_cvar_hook(GameCvarHooks[index]);
	set_pcvar_string(GameCvarPointers[index], GameCvarDefinitions[index][GameCvarValue]);
	enable_cvar_hook(GameCvarHooks[index]);
}

stock DisableGameCvarHooks()
{
	for (new index = 0; index < sizeof GameCvarDefinitions; index++)
	{
		if (GameCvarHooks[index] == GAME_CVARS_INVALID_HOOK)
			continue;

		disable_cvar_hook(GameCvarHooks[index]);
		GameCvarHooks[index] = GAME_CVARS_INVALID_HOOK;
	}
}

stock RequireGameCvarPointer(index)
{
	new pcvar = get_cvar_pointer(GameCvarDefinitions[index][GameCvarName]);
	if (pcvar == GAME_CVARS_INVALID_POINTER)
		set_fail_state("Required game cvar '%s' was not found.", GameCvarDefinitions[index][GameCvarName]);

	return pcvar;
}

stock FindGameCvarByPointer(pcvar)
{
	for (new index = 0; index < sizeof GameCvarDefinitions; index++)
	{
		if (GameCvarPointers[index] == pcvar)
			return index;
	}

	return GAME_CVARS_INVALID_INDEX;
}
