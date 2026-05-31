#include <amxmodx>
#include <reapi>

#pragma semicolon 1
#pragma compress 1

const MAP_OBJECTIVES_SCAN_GUARD = 2048;

enum _:MapObjectivesHookData
{
	MapObjectivesHookGetEntityInit,
	MapObjectivesHookCheckMapConditions,
	MapObjectivesHookCleanUpMap,
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
	"func_buyzone"
};

new HookChain:MapObjectivesHooks[MapObjectivesHookCount];

public plugin_precache()
{
	register_plugin("Core: Map Objectives", "0.1.0", "BRUN0");

	CreateMapObjectivesHooks();
}

public plugin_cfg()
{
	DisableDefaultMapRules();
	RemoveMapObjectives();
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

public OnCleanUpMapPost()
{
	DisableDefaultMapRules();
	RemoveMapObjectives();
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
		RH_GetEntityInit,
		"OnGetEntityInitPre",
		false
	);

	MapObjectivesHooks[MapObjectivesHookCheckMapConditions] = RegisterRequiredMapObjectivesHook(
		RG_CSGameRules_CheckMapConditions,
		"OnCheckMapConditionsPre",
		false
	);

	MapObjectivesHooks[MapObjectivesHookCleanUpMap] = RegisterRequiredMapObjectivesHook(
		RG_CSGameRules_CleanUpMap,
		"OnCleanUpMapPost",
		true
	);

	MapObjectivesHooks[MapObjectivesHookGiveC4] = RegisterRequiredMapObjectivesHook(
		RG_CSGameRules_GiveC4,
		"OnGiveC4Pre",
		false
	);
}

stock HookChain:RegisterRequiredMapObjectivesHook(ReAPIFunc:functionId, const callback[], bool:post)
{
	new HookChain:hook = RegisterHookChain(functionId, callback, post);
	if (hook == INVALID_HOOKCHAIN)
		set_fail_state("MapObjectives could not register ReAPI hook '%s'.", callback);

	return hook;
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

stock RemoveMapObjectives()
{
	for (new index = 0; index < sizeof MapObjectiveClasses; index++)
		RemoveMapObjectivesByClass(MapObjectiveClasses[index]);
}

stock RemoveMapObjectivesByClass(const classname[])
{
	new entity = NULLENT;
	new scannedEntities;

	while ((entity = rg_find_ent_by_class(entity, classname)) > 0)
	{
		scannedEntities++;
		if (scannedEntities > MAP_OBJECTIVES_SCAN_GUARD)
			set_fail_state("MapObjectives scan exceeded guard for class '%s'.", classname);

		if (!is_entity(entity))
			set_fail_state("MapObjectives received invalid entity %d for class '%s'.", entity, classname);

		rg_remove_entity(entity);
	}
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
