#include <amxmodx>
#include <reapi>
#include <rezombie_version>

#pragma semicolon 1
#pragma compress 1

enum _:MapObjectivesHookData
{
	MapObjectivesHookGetEntityInit,
	MapObjectivesHookCheckMapConditions,
	MapObjectivesHookGiveC4,
	MapObjectivesHookCount
};

new const MapObjectiveClasses[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"hostage_entity",
	"armoury_entity",
	"player_weaponstrip",
	"game_player_equip",
	"env_fog",
	"env_rain",
	"env_snow",
	"monster_scientist",
	"item_longjump",
	"game_text",
	"func_buyzone"
};

new HookChain:MapObjectivesHooks[MapObjectivesHookCount];

public plugin_precache()
{
	register_plugin("Core: Map Objectives", REZOMBIE_VERSION, REZOMBIE_AUTHOR);

	CreateMapObjectivesHooks();
}

public plugin_cfg()
{
	DisableDefaultMapRules();
}

public plugin_end()
{
	for (new index = 0; index < sizeof MapObjectivesHooks; index++)
	{
		if (MapObjectivesHooks[index] == INVALID_HOOKCHAIN)
			continue;

		DisableHookChain(MapObjectivesHooks[index]);
		MapObjectivesHooks[index] = INVALID_HOOKCHAIN;
	}
}

public OnGetEntityInitPre(const classname[])
{
	if (!IsMapObjectiveClass(classname))
		return HC_CONTINUE;

	SetHookChainReturn(ATYPE_INTEGER, 0);
	return HC_SUPERCEDE;
}

public OnCheckMapConditionsPre()
{
	DisableDefaultMapRules();
	return HC_SUPERCEDE;
}

public OnGiveC4Pre()
{
	return HC_SUPERCEDE;
}

stock CreateMapObjectivesHooks()
{
	for (new index = 0; index < sizeof MapObjectivesHooks; index++)
		MapObjectivesHooks[index] = INVALID_HOOKCHAIN;

	MapObjectivesHooks[MapObjectivesHookGetEntityInit] = RegisterRequiredMapObjectivesHook(
		.functionId = RH_GetEntityInit,
		.callback = "OnGetEntityInitPre",
		.post = false
	);

	MapObjectivesHooks[MapObjectivesHookCheckMapConditions] = RegisterRequiredMapObjectivesHook(
		.functionId = RG_CSGameRules_CheckMapConditions,
		.callback = "OnCheckMapConditionsPre",
		.post = false
	);

	MapObjectivesHooks[MapObjectivesHookGiveC4] = RegisterRequiredMapObjectivesHook(
		.functionId = RG_CSGameRules_GiveC4,
		.callback = "OnGiveC4Pre",
		.post = false
	);
}

stock HookChain:RegisterRequiredMapObjectivesHook(ReAPIFunc:functionId, const callback[], bool:post)
{
	new HookChain:hookChain = RegisterHookChain(
		.function_id = functionId,
		.callback = callback,
		.post = post
	);
	if (hookChain == INVALID_HOOKCHAIN)
		set_fail_state("MapObjectives could not register ReAPI hook '%s'.", callback);

	return hookChain;
}

stock DisableDefaultMapRules()
{
	set_member_game(m_bMapHasBombTarget, false);
	set_member_game(m_bMapHasBombZone, false);
	set_member_game(m_bMapHasBuyZone, false);
	set_member_game(m_bMapHasRescueZone, false);
	set_member_game(m_bMapHasEscapeZone, false);
	set_member_game(m_bMapHasVIPSafetyZone, false);
	set_member_game(m_bCTCantBuy, true);
	set_member_game(m_bTCantBuy, true);
}

stock bool:IsMapObjectiveClass(const classname[])
{
	for (new index = 0; index < sizeof MapObjectiveClasses; index++)
	{
		if (equal(classname, MapObjectiveClasses[index]))
			return true;
	}

	return false;
}
