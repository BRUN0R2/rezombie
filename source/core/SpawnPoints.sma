#include <amxmodx>
#include <fakemeta>
#include <reapi>

#pragma semicolon 1
#pragma compress 1

const SPAWN_POINTS_INVALID_INDEX = -1;
const SPAWN_POINTS_ANCHOR_RESERVED_COUNT = 64;
const SPAWN_POINTS_SLOT_RESERVED_COUNT = 256;
const SPAWN_POINTS_RESERVATION_RESERVED_COUNT = 32;
const SPAWN_POINTS_SCAN_GUARD = 2048;
const SPAWN_POINTS_TRACE_IGNORE_NONE = 0;
const SPAWN_POINTS_TRACE_RESULT = 0;
const SPAWN_POINTS_FIX_ANGLE = 1;
const SPAWN_POINTS_GRID_RADIUS = 2;
const Float:SPAWN_POINTS_GRID_STEP = 48.0;
const Float:SPAWN_POINTS_MIN_DISTANCE = 36.0;
const Float:SPAWN_POINTS_RESERVATION_SECONDS = 0.25;
const Float:SPAWN_POINTS_ORIGIN_OFFSET_Z = 1.0;

enum SpawnSource
{
	SpawnSourceCounterTerrorist,
	SpawnSourceTerrorist
};

enum _:SpawnPointClassDefinition
{
	SpawnPointClassName[32],
	SpawnSource:SpawnPointClassSource
};

enum _:SpawnAnchorData
{
	SpawnAnchorEntity,
	SpawnSource:SpawnAnchorSource,
	Float:SpawnAnchorOriginX,
	Float:SpawnAnchorOriginY,
	Float:SpawnAnchorOriginZ,
	Float:SpawnAnchorAnglesX,
	Float:SpawnAnchorAnglesY,
	Float:SpawnAnchorAnglesZ
};

enum _:SpawnSlotData
{
	SpawnSlotEntity,
	SpawnSource:SpawnSlotSource,
	Float:SpawnSlotOriginX,
	Float:SpawnSlotOriginY,
	Float:SpawnSlotOriginZ,
	Float:SpawnSlotAnglesX,
	Float:SpawnSlotAnglesY,
	Float:SpawnSlotAnglesZ
};

enum _:SpawnReservationData
{
	Float:SpawnReservationOriginX,
	Float:SpawnReservationOriginY,
	Float:SpawnReservationOriginZ
};

new const SpawnPointClassDefinitions[][SpawnPointClassDefinition] =
{
	{ "info_player_start", SpawnSourceCounterTerrorist },
	{ "info_player_deathmatch", SpawnSourceTerrorist }
};

new Array:SpawnAnchors = Invalid_Array;
new Array:SpawnSlots = Invalid_Array;
new Array:SpawnReservations = Invalid_Array;
new LastSpawnSlotIndex = SPAWN_POINTS_INVALID_INDEX;
new Float:LastSpawnReservationAt = 0.0;

public plugin_precache()
{
	register_plugin("Core: Spawn Points", "0.1.0", "BRUN0");

	InitializeSpawnStorage();
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPost", true);
	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "OnGetPlayerSpawnSpotPre", false);
	InitializeSpawnPoints();
}

public plugin_end()
{
	DestroySpawnStorage();
}

public OnRestartRoundPost()
{
	InitializeSpawnPoints();
}

public OnGetPlayerSpawnSpotPre(id)
{
	if (!is_user_connected(id))
		return HC_CONTINUE;

	if (!IsPlayableGameTeam(id))
		return HC_CONTINUE;

	new spawnSlot[SpawnSlotData];
	if (!SelectSpawnSlot(id, spawnSlot))
		set_fail_state("SpawnPoints could not find a free spawn slot for player %d.", id);

	ApplySpawnSlot(id, spawnSlot);
	SetHookChainReturn(ATYPE_INTEGER, spawnSlot[SpawnSlotEntity]);

	return HC_SUPERCEDE;
}

stock InitializeSpawnStorage()
{
	SpawnAnchors = ArrayCreate(SpawnAnchorData, SPAWN_POINTS_ANCHOR_RESERVED_COUNT);
	SpawnSlots = ArrayCreate(SpawnSlotData, SPAWN_POINTS_SLOT_RESERVED_COUNT);
	SpawnReservations = ArrayCreate(SpawnReservationData, SPAWN_POINTS_RESERVATION_RESERVED_COUNT);

	if (SpawnAnchors == Invalid_Array)
		set_fail_state("SpawnPoints anchor storage could not be initialized.");

	if (SpawnSlots == Invalid_Array)
		set_fail_state("SpawnPoints slot storage could not be initialized.");

	if (SpawnReservations == Invalid_Array)
		set_fail_state("SpawnPoints reservation storage could not be initialized.");
}

stock DestroySpawnStorage()
{
	if (SpawnReservations != Invalid_Array)
		ArrayDestroy(SpawnReservations);

	if (SpawnSlots != Invalid_Array)
		ArrayDestroy(SpawnSlots);

	if (SpawnAnchors != Invalid_Array)
		ArrayDestroy(SpawnAnchors);
}

stock InitializeSpawnPoints()
{
	RequireSpawnStorage();
	ResetSpawnState();
	CollectSpawnAnchors();
	BuildSpawnSlots();
	ValidateSpawnSlots();
	SyncGameSpawnCounts();
}

stock ResetSpawnState()
{
	ArrayClear(SpawnAnchors);
	ArrayClear(SpawnSlots);
	ArrayClear(SpawnReservations);

	LastSpawnSlotIndex = SPAWN_POINTS_INVALID_INDEX;
	LastSpawnReservationAt = 0.0;
}

stock CollectSpawnAnchors()
{
	for (new index = 0; index < sizeof SpawnPointClassDefinitions; index++)
	{
		CollectSpawnAnchorsByClass(
			SpawnPointClassDefinitions[index][SpawnPointClassName],
			SpawnPointClassDefinitions[index][SpawnPointClassSource]
		);
	}
}

stock CollectSpawnAnchorsByClass(const entityClass[], SpawnSource:source)
{
	new entity = NULLENT;
	new scannedEntities;

	while ((entity = rg_find_ent_by_class(entity, entityClass)) > 0)
	{
		scannedEntities++;
		if (scannedEntities > SPAWN_POINTS_SCAN_GUARD)
			set_fail_state("SpawnPoints scan exceeded guard for class '%s'.", entityClass);

		RegisterSpawnAnchor(entity, source);
	}
}

stock RegisterSpawnAnchor(entity, SpawnSource:source)
{
	if (!pev_valid(entity))
		set_fail_state("SpawnPoints received invalid anchor entity %d.", entity);

	new spawnAnchor[SpawnAnchorData];
	new Float:origin[3];
	new Float:angles[3];

	get_entvar(entity, var_origin, origin);
	get_entvar(entity, var_angles, angles);

	spawnAnchor[SpawnAnchorEntity] = entity;
	spawnAnchor[SpawnAnchorSource] = source;
	spawnAnchor[SpawnAnchorOriginX] = origin[0];
	spawnAnchor[SpawnAnchorOriginY] = origin[1];
	spawnAnchor[SpawnAnchorOriginZ] = origin[2];
	spawnAnchor[SpawnAnchorAnglesX] = angles[0];
	spawnAnchor[SpawnAnchorAnglesY] = angles[1];
	spawnAnchor[SpawnAnchorAnglesZ] = angles[2];

	ArrayPushArray(SpawnAnchors, spawnAnchor);
}

stock BuildSpawnSlots()
{
	new anchorsCount = ArraySize(SpawnAnchors);
	if (anchorsCount <= 0)
		set_fail_state("SpawnPoints could not find player spawn anchors.");

	new spawnAnchor[SpawnAnchorData];

	for (new anchorIndex = 0; anchorIndex < anchorsCount; anchorIndex++)
	{
		ArrayGetArray(SpawnAnchors, anchorIndex, spawnAnchor);
		BuildSpawnSlotsFromAnchor(spawnAnchor);
	}
}

stock BuildSpawnSlotsFromAnchor(spawnAnchor[SpawnAnchorData])
{
	for (new ring = 0; ring <= SPAWN_POINTS_GRID_RADIUS; ring++)
	{
		for (new gridX = -ring; gridX <= ring; gridX++)
		{
			for (new gridY = -ring; gridY <= ring; gridY++)
			{
				if (!IsGridRingCell(gridX, gridY, ring))
					continue;

				RegisterSpawnSlotCandidate(spawnAnchor, gridX, gridY);
			}
		}
	}
}

stock RegisterSpawnSlotCandidate(spawnAnchor[SpawnAnchorData], gridX, gridY)
{
	new Float:origin[3];

	GetSpawnAnchorOrigin(spawnAnchor, origin);
	origin[0] += float(gridX) * SPAWN_POINTS_GRID_STEP;
	origin[1] += float(gridY) * SPAWN_POINTS_GRID_STEP;

	if (!IsWorldSpawnOriginValid(origin))
		return;

	if (IsOriginUsedBySpawnSlot(origin))
		return;

	RegisterSpawnSlot(spawnAnchor, origin);
}

stock RegisterSpawnSlot(spawnAnchor[SpawnAnchorData], Float:origin[3])
{
	if (!pev_valid(spawnAnchor[SpawnAnchorEntity]))
		set_fail_state("SpawnPoints received invalid slot anchor entity %d.", spawnAnchor[SpawnAnchorEntity]);

	new spawnSlot[SpawnSlotData];
	new Float:angles[3];

	GetSpawnAnchorAngles(spawnAnchor, angles);

	spawnSlot[SpawnSlotEntity] = spawnAnchor[SpawnAnchorEntity];
	spawnSlot[SpawnSlotSource] = spawnAnchor[SpawnAnchorSource];
	spawnSlot[SpawnSlotOriginX] = origin[0];
	spawnSlot[SpawnSlotOriginY] = origin[1];
	spawnSlot[SpawnSlotOriginZ] = origin[2];
	spawnSlot[SpawnSlotAnglesX] = angles[0];
	spawnSlot[SpawnSlotAnglesY] = angles[1];
	spawnSlot[SpawnSlotAnglesZ] = angles[2];

	ArrayPushArray(SpawnSlots, spawnSlot);
}

stock ValidateSpawnSlots()
{
	new spawnSlotsCount = ArraySize(SpawnSlots);
	if (spawnSlotsCount <= 0)
		set_fail_state("SpawnPoints could not build any playable spawn slots.");
}

stock SyncGameSpawnCounts()
{
	new spawnSlotsCount = ArraySize(SpawnSlots);

	set_member_game(m_iSpawnPointCount_Terrorist, spawnSlotsCount);
	set_member_game(m_iSpawnPointCount_CT, spawnSlotsCount);
}

stock bool:SelectSpawnSlot(id, spawnSlot[SpawnSlotData])
{
	new spawnSlotsCount = ArraySize(SpawnSlots);
	if (spawnSlotsCount <= 0)
		set_fail_state("SpawnPoints storage is empty during spawn selection.");

	ResetExpiredSpawnReservations();

	for (new attempt = 0; attempt < spawnSlotsCount; attempt++)
	{
		new index = NextSpawnSlotIndex(spawnSlotsCount);
		ArrayGetArray(SpawnSlots, index, spawnSlot);

		if (!pev_valid(spawnSlot[SpawnSlotEntity]))
			set_fail_state("SpawnPoints stored invalid entity %d.", spawnSlot[SpawnSlotEntity]);

		if (IsSpawnSlotAvailable(id, spawnSlot))
		{
			ReserveSpawnSlot(spawnSlot);
			return true;
		}
	}

	return false;
}

stock NextSpawnSlotIndex(spawnSlotsCount)
{
	LastSpawnSlotIndex = (LastSpawnSlotIndex + 1) % spawnSlotsCount;

	return LastSpawnSlotIndex;
}

stock bool:IsSpawnSlotAvailable(id, spawnSlot[SpawnSlotData])
{
	new Float:origin[3];
	GetSpawnSlotOrigin(spawnSlot, origin);

	if (IsOriginReserved(origin))
		return false;

	if (IsOriginBlockedByPlayer(id, origin))
		return false;

	return IsSpawnHullVacant(id, origin);
}

stock ApplySpawnSlot(id, spawnSlot[SpawnSlotData])
{
	new Float:origin[3];
	new Float:angles[3];
	new Float:zero[3];

	GetSpawnSlotOrigin(spawnSlot, origin);
	GetSpawnSlotAngles(spawnSlot, angles);

	origin[2] += SPAWN_POINTS_ORIGIN_OFFSET_Z;

	engfunc(EngFunc_SetOrigin, id, origin);
	set_entvar(id, var_angles, angles);
	set_entvar(id, var_v_angle, zero);
	set_entvar(id, var_velocity, zero);
	set_entvar(id, var_punchangle, zero);
	set_entvar(id, var_fixangle, SPAWN_POINTS_FIX_ANGLE);
}

stock ResetExpiredSpawnReservations()
{
	new Float:now = get_gametime();

	if (now - LastSpawnReservationAt <= SPAWN_POINTS_RESERVATION_SECONDS)
		return;

	ArrayClear(SpawnReservations);
}

stock ReserveSpawnSlot(spawnSlot[SpawnSlotData])
{
	new spawnReservation[SpawnReservationData];
	new Float:origin[3];

	GetSpawnSlotOrigin(spawnSlot, origin);

	spawnReservation[SpawnReservationOriginX] = origin[0];
	spawnReservation[SpawnReservationOriginY] = origin[1];
	spawnReservation[SpawnReservationOriginZ] = origin[2];

	ArrayPushArray(SpawnReservations, spawnReservation);
	LastSpawnReservationAt = get_gametime();
}

stock bool:IsOriginReserved(Float:origin[3])
{
	new reservationsCount = ArraySize(SpawnReservations);
	new spawnReservation[SpawnReservationData];
	new Float:reservedOrigin[3];

	for (new index = 0; index < reservationsCount; index++)
	{
		ArrayGetArray(SpawnReservations, index, spawnReservation);
		GetSpawnReservationOrigin(spawnReservation, reservedOrigin);

		if (AreOriginsTooClose(origin, reservedOrigin))
			return true;
	}

	return false;
}

stock bool:IsOriginBlockedByPlayer(id, Float:origin[3])
{
	new Float:playerOrigin[3];

	for (new player = 1; player <= MaxClients; player++)
	{
		if (player == id || !is_user_connected(player) || !is_user_alive(player))
			continue;

		get_entvar(player, var_origin, playerOrigin);

		if (AreOriginsTooClose(origin, playerOrigin))
			return true;
	}

	return false;
}

stock bool:IsOriginUsedBySpawnSlot(Float:origin[3])
{
	new spawnSlotsCount = ArraySize(SpawnSlots);
	new spawnSlot[SpawnSlotData];
	new Float:slotOrigin[3];

	for (new index = 0; index < spawnSlotsCount; index++)
	{
		ArrayGetArray(SpawnSlots, index, spawnSlot);
		GetSpawnSlotOrigin(spawnSlot, slotOrigin);

		if (AreOriginsTooClose(origin, slotOrigin))
			return true;
	}

	return false;
}

stock bool:IsWorldSpawnOriginValid(Float:origin[3])
{
	return IsSpawnHullVacant(0, origin);
}

stock bool:IsSpawnHullVacant(ignoredEntity, Float:origin[3])
{
	engfunc(EngFunc_TraceHull, origin, origin, SPAWN_POINTS_TRACE_IGNORE_NONE, HULL_HUMAN, ignoredEntity, SPAWN_POINTS_TRACE_RESULT);

	if (get_tr2(SPAWN_POINTS_TRACE_RESULT, TR_StartSolid))
		return false;

	if (get_tr2(SPAWN_POINTS_TRACE_RESULT, TR_AllSolid))
		return false;

	if (!get_tr2(SPAWN_POINTS_TRACE_RESULT, TR_InOpen))
		return false;

	return true;
}

stock bool:AreOriginsTooClose(Float:firstOrigin[3], Float:secondOrigin[3])
{
	new Float:deltaX = firstOrigin[0] - secondOrigin[0];
	new Float:deltaY = firstOrigin[1] - secondOrigin[1];
	new Float:deltaZ = firstOrigin[2] - secondOrigin[2];
	new Float:distanceSquared = (deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ);

	return distanceSquared < (SPAWN_POINTS_MIN_DISTANCE * SPAWN_POINTS_MIN_DISTANCE);
}

stock bool:IsGridRingCell(gridX, gridY, ring)
{
	if (ring == 0)
		return gridX == 0 && gridY == 0;

	return IntegerAbs(gridX) == ring || IntegerAbs(gridY) == ring;
}

stock IntegerAbs(value)
{
	if (value < 0)
		return -value;

	return value;
}

stock GetSpawnAnchorOrigin(spawnAnchor[SpawnAnchorData], Float:origin[3])
{
	origin[0] = spawnAnchor[SpawnAnchorOriginX];
	origin[1] = spawnAnchor[SpawnAnchorOriginY];
	origin[2] = spawnAnchor[SpawnAnchorOriginZ];
}

stock GetSpawnAnchorAngles(spawnAnchor[SpawnAnchorData], Float:angles[3])
{
	angles[0] = spawnAnchor[SpawnAnchorAnglesX];
	angles[1] = spawnAnchor[SpawnAnchorAnglesY];
	angles[2] = spawnAnchor[SpawnAnchorAnglesZ];
}

stock GetSpawnSlotOrigin(spawnSlot[SpawnSlotData], Float:origin[3])
{
	origin[0] = spawnSlot[SpawnSlotOriginX];
	origin[1] = spawnSlot[SpawnSlotOriginY];
	origin[2] = spawnSlot[SpawnSlotOriginZ];
}

stock GetSpawnSlotAngles(spawnSlot[SpawnSlotData], Float:angles[3])
{
	angles[0] = spawnSlot[SpawnSlotAnglesX];
	angles[1] = spawnSlot[SpawnSlotAnglesY];
	angles[2] = spawnSlot[SpawnSlotAnglesZ];
}

stock GetSpawnReservationOrigin(spawnReservation[SpawnReservationData], Float:origin[3])
{
	origin[0] = spawnReservation[SpawnReservationOriginX];
	origin[1] = spawnReservation[SpawnReservationOriginY];
	origin[2] = spawnReservation[SpawnReservationOriginZ];
}

stock RequireSpawnStorage()
{
	if (SpawnAnchors == Invalid_Array)
		set_fail_state("SpawnPoints anchor storage is not initialized.");

	if (SpawnSlots == Invalid_Array)
		set_fail_state("SpawnPoints slot storage is not initialized.");

	if (SpawnReservations == Invalid_Array)
		set_fail_state("SpawnPoints reservation storage is not initialized.");
}

stock bool:IsPlayableGameTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);

	return team == TEAM_TERRORIST || team == TEAM_CT;
}
