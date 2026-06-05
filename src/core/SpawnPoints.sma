#include <rezombie>
#include <reapi>
#include <fakemeta>

#pragma semicolon 1
#pragma compress 1

const SPAWN_POINTS_INVALID_INDEX = -1;
const SPAWN_POINTS_ANCHOR_RESERVED_COUNT = 64;
const SPAWN_POINTS_SLOT_RESERVED_COUNT = 384;
const SPAWN_POINTS_CLUSTER_RESERVED_COUNT = 64;
const SPAWN_POINTS_RESERVATION_RESERVED_COUNT = 64;
const SPAWN_POINTS_MAX_PLAYERS = 32;
const SPAWN_POINTS_SCAN_GUARD = 2048;
const SPAWN_POINTS_TRACE_IGNORE_NONE = 0;
const SPAWN_POINTS_TRACE_RESULT = 0;
const SPAWN_POINTS_FIX_ANGLE = 1;
const SPAWN_POINTS_EXPANSION_RADIUS = 2;
const SPAWN_POINTS_RECENT_USE_WINDOW = 12;

const Float:SPAWN_POINTS_EXPANSION_STEP = 128.0;
const Float:SPAWN_POINTS_DUPLICATE_DISTANCE = 48.0;
const Float:SPAWN_POINTS_CLUSTER_DISTANCE = 512.0;
const Float:SPAWN_POINTS_RESERVATION_SECONDS = 10.0;
const Float:SPAWN_POINTS_MIN_DISTANCE = 96.0;
const Float:SPAWN_POINTS_ORIGIN_OFFSET_Z = 1.0;
const Float:SPAWN_POINTS_MAX_DISTANCE_SCORE = 999999999.0;
const Float:SPAWN_POINTS_SCORE_CLUSTER_RESERVATION_WEIGHT = 4.0;
const Float:SPAWN_POINTS_SCORE_CLUSTER_USE_WEIGHT = 0.75;
const Float:SPAWN_POINTS_SCORE_SLOT_USE_WEIGHT = 1.5;
const Float:SPAWN_POINTS_SCORE_RECENT_USE_WEIGHT = 2.0;

new const Float:SpawnDistanceSteps[] =
{
	160.0,
	128.0,
	SPAWN_POINTS_MIN_DISTANCE
};

enum SpawnSource
{
	SpawnSourceCounterTerrorist,
	SpawnSourceTerrorist
};

enum SpawnSlotKind
{
	SpawnSlotNative,
	SpawnSlotExpanded
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

enum _:SpawnClusterData
{
	Float:SpawnClusterOriginX,
	Float:SpawnClusterOriginY,
	Float:SpawnClusterOriginZ,
	SpawnClusterUseCount,
	SpawnClusterLastUsedOrder
};

enum _:SpawnSlotData
{
	SpawnSlotEntity,
	SpawnSource:SpawnSlotSource,
	SpawnSlotKind:SpawnSlotKindValue,
	SpawnSlotAnchorIndex,
	SpawnSlotClusterIndex,
	SpawnSlotUseCount,
	SpawnSlotLastUsedOrder,
	Float:SpawnSlotOriginX,
	Float:SpawnSlotOriginY,
	Float:SpawnSlotOriginZ,
	Float:SpawnSlotAnglesX,
	Float:SpawnSlotAnglesY,
	Float:SpawnSlotAnglesZ
};

enum _:SpawnReservationData
{
	SpawnReservationSlotIndex,
	SpawnReservationClusterIndex,
	Float:SpawnReservationExpiresAt,
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
new Array:SpawnClusters = Invalid_Array;
new Array:SpawnSlots = Invalid_Array;
new Array:SpawnReservations = Invalid_Array;
new SpawnSelectionOrder;
new bool:PlayerSpawnAssigned[SPAWN_POINTS_MAX_PLAYERS + 1];
new PlayerSpawnAssignments[SPAWN_POINTS_MAX_PLAYERS + 1][SpawnSlotData];

public plugin_precache()
{
	register_plugin("Core: Spawn Points", "0.1.0", "BRUN0");

	InitializeSpawnStorage();
}

public plugin_init()
{
	RegisterHookChain(RG_CSGameRules_RestartRound, "OnRestartRoundPost", true);
	RegisterHookChain(RG_CSGameRules_GetPlayerSpawnSpot, "OnGetPlayerSpawnSpotPre", false);
	RegisterHookChain(RG_CBasePlayer_Spawn, "OnPlayerSpawnPost", true);
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

public client_disconnected(id)
{
	ClearPlayerSpawnAssignment(id);
}

public OnGetPlayerSpawnSpotPre(id)
{
	if (!CanManagePlayerSpawn(id))
		return HC_CONTINUE;

	new spawnSlot[SpawnSlotData];
	if (!SelectSpawnSlot(id, spawnSlot))
		set_fail_state("SpawnPoints could not reserve a distributed spawn slot for player %d.", id);

	AssignPlayerSpawnSlot(id, spawnSlot);
	SetHookChainReturn(ATYPE_INTEGER, spawnSlot[SpawnSlotEntity]);

	return HC_SUPERCEDE;
}

public OnPlayerSpawnPost(id)
{
	if (!CanManagePlayerSpawn(id))
		return;

	if (!is_user_alive(id))
	{
		ClearPlayerSpawnAssignment(id);
		return;
	}

	new spawnSlot[SpawnSlotData];
	if (!TakePlayerSpawnAssignment(id, spawnSlot) && !SelectSpawnSlot(id, spawnSlot))
		set_fail_state("SpawnPoints could not find a distributed spawn slot for player %d.", id);

	ApplySpawnSlot(id, spawnSlot);
}

stock InitializeSpawnStorage()
{
	SpawnAnchors = ArrayCreate(SpawnAnchorData, SPAWN_POINTS_ANCHOR_RESERVED_COUNT);
	SpawnClusters = ArrayCreate(SpawnClusterData, SPAWN_POINTS_CLUSTER_RESERVED_COUNT);
	SpawnSlots = ArrayCreate(SpawnSlotData, SPAWN_POINTS_SLOT_RESERVED_COUNT);
	SpawnReservations = ArrayCreate(SpawnReservationData, SPAWN_POINTS_RESERVATION_RESERVED_COUNT);

	if (SpawnAnchors == Invalid_Array)
		set_fail_state("SpawnPoints anchor storage could not be initialized.");

	if (SpawnClusters == Invalid_Array)
		set_fail_state("SpawnPoints cluster storage could not be initialized.");

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

	if (SpawnClusters != Invalid_Array)
		ArrayDestroy(SpawnClusters);

	if (SpawnAnchors != Invalid_Array)
		ArrayDestroy(SpawnAnchors);
}

stock InitializeSpawnPoints()
{
	RequireSpawnStorage();
	ResetSpawnState();
	CollectSpawnAnchors();
	RegisterNativeSpawnSlots();
	RegisterExpandedSpawnSlots();
	ValidateSpawnCatalog();
	SyncGameSpawnCounts();
}

stock ResetSpawnState()
{
	ArrayClear(SpawnAnchors);
	ArrayClear(SpawnClusters);
	ArrayClear(SpawnSlots);
	ArrayClear(SpawnReservations);

	SpawnSelectionOrder = 0;
	ClearPlayerSpawnAssignments();
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

stock RegisterNativeSpawnSlots()
{
	new anchorsCount = ArraySize(SpawnAnchors);
	if (anchorsCount <= 0)
		set_fail_state("SpawnPoints could not find player spawn anchors.");

	new spawnAnchor[SpawnAnchorData];
	new Float:origin[3];

	for (new anchorIndex = 0; anchorIndex < anchorsCount; anchorIndex++)
	{
		ArrayGetArray(SpawnAnchors, anchorIndex, spawnAnchor);
		GetSpawnAnchorOrigin(spawnAnchor, origin);

		if (!IsWorldSpawnOriginValid(origin))
			continue;

		RegisterSpawnSlot(spawnAnchor, anchorIndex, SpawnSlotNative, origin);
	}
}

stock RegisterExpandedSpawnSlots()
{
	new anchorsCount = ArraySize(SpawnAnchors);
	new spawnAnchor[SpawnAnchorData];

	for (new anchorIndex = 0; anchorIndex < anchorsCount; anchorIndex++)
	{
		ArrayGetArray(SpawnAnchors, anchorIndex, spawnAnchor);
		RegisterExpandedSpawnSlotsFromAnchor(spawnAnchor, anchorIndex);
	}
}

stock RegisterExpandedSpawnSlotsFromAnchor(spawnAnchor[SpawnAnchorData], anchorIndex)
{
	for (new ring = 1; ring <= SPAWN_POINTS_EXPANSION_RADIUS; ring++)
	{
		for (new gridX = -ring; gridX <= ring; gridX++)
		{
			for (new gridY = -ring; gridY <= ring; gridY++)
			{
				if (!IsGridRingCell(gridX, gridY, ring))
					continue;

				RegisterExpandedSpawnSlotCandidate(spawnAnchor, anchorIndex, gridX, gridY);
			}
		}
	}
}

stock RegisterExpandedSpawnSlotCandidate(spawnAnchor[SpawnAnchorData], anchorIndex, gridX, gridY)
{
	new Float:origin[3];

	GetSpawnAnchorOrigin(spawnAnchor, origin);
	origin[0] += float(gridX) * SPAWN_POINTS_EXPANSION_STEP;
	origin[1] += float(gridY) * SPAWN_POINTS_EXPANSION_STEP;

	if (!IsWorldSpawnOriginValid(origin))
		return;

	if (IsOriginUsedBySpawnSlot(origin, SPAWN_POINTS_DUPLICATE_DISTANCE))
		return;

	RegisterSpawnSlot(spawnAnchor, anchorIndex, SpawnSlotExpanded, origin);
}

stock RegisterSpawnSlot(spawnAnchor[SpawnAnchorData], anchorIndex, SpawnSlotKind:kind, Float:origin[3])
{
	if (!pev_valid(spawnAnchor[SpawnAnchorEntity]))
		set_fail_state("SpawnPoints received invalid slot anchor entity %d.", spawnAnchor[SpawnAnchorEntity]);

	new spawnSlot[SpawnSlotData];
	new Float:angles[3];

	GetSpawnAnchorAngles(spawnAnchor, angles);

	spawnSlot[SpawnSlotEntity] = spawnAnchor[SpawnAnchorEntity];
	spawnSlot[SpawnSlotSource] = spawnAnchor[SpawnAnchorSource];
	spawnSlot[SpawnSlotKindValue] = kind;
	spawnSlot[SpawnSlotAnchorIndex] = anchorIndex;
	spawnSlot[SpawnSlotClusterIndex] = FindOrCreateSpawnCluster(origin);
	spawnSlot[SpawnSlotUseCount] = 0;
	spawnSlot[SpawnSlotLastUsedOrder] = 0;
	spawnSlot[SpawnSlotOriginX] = origin[0];
	spawnSlot[SpawnSlotOriginY] = origin[1];
	spawnSlot[SpawnSlotOriginZ] = origin[2];
	spawnSlot[SpawnSlotAnglesX] = angles[0];
	spawnSlot[SpawnSlotAnglesY] = angles[1];
	spawnSlot[SpawnSlotAnglesZ] = angles[2];

	ArrayPushArray(SpawnSlots, spawnSlot);
}

stock FindOrCreateSpawnCluster(Float:origin[3])
{
	new clusterIndex = FindSpawnCluster(origin);
	if (clusterIndex != SPAWN_POINTS_INVALID_INDEX)
		return clusterIndex;

	new spawnCluster[SpawnClusterData];
	spawnCluster[SpawnClusterOriginX] = origin[0];
	spawnCluster[SpawnClusterOriginY] = origin[1];
	spawnCluster[SpawnClusterOriginZ] = origin[2];
	spawnCluster[SpawnClusterUseCount] = 0;
	spawnCluster[SpawnClusterLastUsedOrder] = 0;

	new insertedIndex = ArraySize(SpawnClusters);
	ArrayPushArray(SpawnClusters, spawnCluster);

	return insertedIndex;
}

stock FindSpawnCluster(Float:origin[3])
{
	new clustersCount = ArraySize(SpawnClusters);
	new spawnCluster[SpawnClusterData];
	new Float:clusterOrigin[3];
	new Float:minDistanceSquared = SPAWN_POINTS_CLUSTER_DISTANCE * SPAWN_POINTS_CLUSTER_DISTANCE;
	new bestClusterIndex = SPAWN_POINTS_INVALID_INDEX;
	new Float:bestDistanceSquared = SPAWN_POINTS_MAX_DISTANCE_SCORE;

	for (new index = 0; index < clustersCount; index++)
	{
		ArrayGetArray(SpawnClusters, index, spawnCluster);
		GetSpawnClusterOrigin(spawnCluster, clusterOrigin);

		new Float:distanceSquared = GetOriginDistanceSquared(origin, clusterOrigin);
		if (distanceSquared > minDistanceSquared)
			continue;

		if (distanceSquared < bestDistanceSquared)
		{
			bestClusterIndex = index;
			bestDistanceSquared = distanceSquared;
		}
	}

	return bestClusterIndex;
}

stock ValidateSpawnCatalog()
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

	new selectedSlotIndex = FindBestSpawnSlot(id);
	if (selectedSlotIndex == SPAWN_POINTS_INVALID_INDEX)
		return false;

	ArrayGetArray(SpawnSlots, selectedSlotIndex, spawnSlot);

	if (!pev_valid(spawnSlot[SpawnSlotEntity]))
		set_fail_state("SpawnPoints stored invalid entity %d.", spawnSlot[SpawnSlotEntity]);

	ReserveSpawnSlot(selectedSlotIndex, spawnSlot);
	TrackSpawnSlotUse(selectedSlotIndex, spawnSlot);

	return true;
}

stock FindBestSpawnSlot(id)
{
	for (new distanceIndex = 0; distanceIndex < sizeof SpawnDistanceSteps; distanceIndex++)
	{
		new Float:minDistance = SpawnDistanceSteps[distanceIndex];
		new selectedSlotIndex = FindBestSpawnSlotByKind(id, SpawnSlotNative, minDistance);

		if (selectedSlotIndex != SPAWN_POINTS_INVALID_INDEX)
			return selectedSlotIndex;

		selectedSlotIndex = FindBestSpawnSlotByKind(id, SpawnSlotExpanded, minDistance);
		if (selectedSlotIndex != SPAWN_POINTS_INVALID_INDEX)
			return selectedSlotIndex;
	}

	return SPAWN_POINTS_INVALID_INDEX;
}

stock FindBestSpawnSlotByKind(id, SpawnSlotKind:kind, Float:minDistance)
{
	new slotsCount = ArraySize(SpawnSlots);
	new spawnSlot[SpawnSlotData];
	new bestSlotIndex = SPAWN_POINTS_INVALID_INDEX;
	new Float:bestScore = -SPAWN_POINTS_MAX_DISTANCE_SCORE;

	for (new index = 0; index < slotsCount; index++)
	{
		ArrayGetArray(SpawnSlots, index, spawnSlot);

		if (spawnSlot[SpawnSlotKindValue] != kind)
			continue;

		if (!IsSpawnSlotCandidateValid(id, spawnSlot, minDistance))
			continue;

		new Float:score = GetSpawnSlotScore(id, spawnSlot, minDistance);
		if (bestSlotIndex == SPAWN_POINTS_INVALID_INDEX || score > bestScore)
		{
			bestSlotIndex = index;
			bestScore = score;
		}
	}

	return bestSlotIndex;
}

stock bool:IsSpawnSlotCandidateValid(id, spawnSlot[SpawnSlotData], Float:minDistance)
{
	if (!pev_valid(spawnSlot[SpawnSlotEntity]))
		set_fail_state("SpawnPoints stored invalid entity %d.", spawnSlot[SpawnSlotEntity]);

	new Float:origin[3];
	GetSpawnSlotOrigin(spawnSlot, origin);

	if (!IsSpawnPlacementHullVacant(id, origin))
		return false;

	return IsSpawnSpacingAccepted(id, origin, minDistance);
}

stock bool:IsSpawnSpacingAccepted(id, Float:origin[3], Float:minDistance)
{
	new Float:minDistanceSquared = minDistance * minDistance;

	if (GetMinimumPlayerDistanceSquared(id, origin) < minDistanceSquared)
		return false;

	if (GetMinimumReservationDistanceSquared(origin) < minDistanceSquared)
		return false;

	return true;
}

stock Float:GetSpawnSlotScore(id, spawnSlot[SpawnSlotData], Float:minDistance)
{
	new Float:origin[3];
	GetSpawnSlotOrigin(spawnSlot, origin);

	new Float:spacingScore = GetMinimumSpawnDistanceSquared(id, origin);
	new Float:unitScore = minDistance * minDistance;
	new clusterIndex = spawnSlot[SpawnSlotClusterIndex];

	spacingScore -= float(CountClusterReservations(clusterIndex)) * unitScore * SPAWN_POINTS_SCORE_CLUSTER_RESERVATION_WEIGHT;
	spacingScore -= GetClusterUsePenalty(clusterIndex, unitScore);
	spacingScore -= float(spawnSlot[SpawnSlotUseCount]) * unitScore * SPAWN_POINTS_SCORE_SLOT_USE_WEIGHT;
	spacingScore -= GetRecentUsePenalty(spawnSlot[SpawnSlotLastUsedOrder], unitScore);

	return spacingScore;
}

stock Float:GetClusterUsePenalty(clusterIndex, Float:unitScore)
{
	if (clusterIndex == SPAWN_POINTS_INVALID_INDEX)
		return 0.0;

	new spawnCluster[SpawnClusterData];
	ArrayGetArray(SpawnClusters, clusterIndex, spawnCluster);

	new Float:penalty = float(spawnCluster[SpawnClusterUseCount]) * unitScore * SPAWN_POINTS_SCORE_CLUSTER_USE_WEIGHT;
	penalty += GetRecentUsePenalty(spawnCluster[SpawnClusterLastUsedOrder], unitScore);

	return penalty;
}

stock Float:GetRecentUsePenalty(lastUsedOrder, Float:unitScore)
{
	if (lastUsedOrder <= 0)
		return 0.0;

	new age = SpawnSelectionOrder - lastUsedOrder;
	if (age >= SPAWN_POINTS_RECENT_USE_WINDOW)
		return 0.0;

	return float(SPAWN_POINTS_RECENT_USE_WINDOW - age) * unitScore * SPAWN_POINTS_SCORE_RECENT_USE_WEIGHT;
}

stock Float:GetMinimumSpawnDistanceSquared(id, Float:origin[3])
{
	new Float:playerDistanceSquared = GetMinimumPlayerDistanceSquared(id, origin);
	new Float:reservationDistanceSquared = GetMinimumReservationDistanceSquared(origin);

	if (playerDistanceSquared < reservationDistanceSquared)
		return playerDistanceSquared;

	return reservationDistanceSquared;
}

stock Float:GetMinimumPlayerDistanceSquared(id, Float:origin[3])
{
	new Float:minimumDistanceSquared = SPAWN_POINTS_MAX_DISTANCE_SCORE;
	new Float:playerOrigin[3];
	new bool:foundPlayer = false;

	for (new player = 1; player <= MaxClients; player++)
	{
		if (player == id || !is_user_connected(player) || !is_user_alive(player))
			continue;

		get_entvar(player, var_origin, playerOrigin);

		new Float:distanceSquared = GetOriginDistanceSquared(origin, playerOrigin);
		if (distanceSquared < minimumDistanceSquared)
			minimumDistanceSquared = distanceSquared;

		foundPlayer = true;
	}

	if (!foundPlayer)
		return SPAWN_POINTS_MAX_DISTANCE_SCORE;

	return minimumDistanceSquared;
}

stock Float:GetMinimumReservationDistanceSquared(Float:origin[3])
{
	new reservationsCount = ArraySize(SpawnReservations);
	new spawnReservation[SpawnReservationData];
	new Float:reservationOrigin[3];
	new Float:minimumDistanceSquared = SPAWN_POINTS_MAX_DISTANCE_SCORE;

	if (reservationsCount <= 0)
		return SPAWN_POINTS_MAX_DISTANCE_SCORE;

	for (new index = 0; index < reservationsCount; index++)
	{
		ArrayGetArray(SpawnReservations, index, spawnReservation);
		GetSpawnReservationOrigin(spawnReservation, reservationOrigin);

		new Float:distanceSquared = GetOriginDistanceSquared(origin, reservationOrigin);
		if (distanceSquared < minimumDistanceSquared)
			minimumDistanceSquared = distanceSquared;
	}

	return minimumDistanceSquared;
}

stock CountClusterReservations(clusterIndex)
{
	new count;
	new reservationsCount = ArraySize(SpawnReservations);
	new spawnReservation[SpawnReservationData];

	for (new index = 0; index < reservationsCount; index++)
	{
		ArrayGetArray(SpawnReservations, index, spawnReservation);

		if (spawnReservation[SpawnReservationClusterIndex] == clusterIndex)
			count++;
	}

	return count;
}

stock ReserveSpawnSlot(slotIndex, spawnSlot[SpawnSlotData])
{
	new spawnReservation[SpawnReservationData];
	new Float:origin[3];

	GetSpawnSlotOrigin(spawnSlot, origin);

	spawnReservation[SpawnReservationSlotIndex] = slotIndex;
	spawnReservation[SpawnReservationClusterIndex] = spawnSlot[SpawnSlotClusterIndex];
	spawnReservation[SpawnReservationExpiresAt] = get_gametime() + SPAWN_POINTS_RESERVATION_SECONDS;
	spawnReservation[SpawnReservationOriginX] = origin[0];
	spawnReservation[SpawnReservationOriginY] = origin[1];
	spawnReservation[SpawnReservationOriginZ] = origin[2];

	ArrayPushArray(SpawnReservations, spawnReservation);
}

stock TrackSpawnSlotUse(slotIndex, spawnSlot[SpawnSlotData])
{
	SpawnSelectionOrder++;

	spawnSlot[SpawnSlotUseCount]++;
	spawnSlot[SpawnSlotLastUsedOrder] = SpawnSelectionOrder;
	ArraySetArray(SpawnSlots, slotIndex, spawnSlot);

	new clusterIndex = spawnSlot[SpawnSlotClusterIndex];
	if (clusterIndex == SPAWN_POINTS_INVALID_INDEX)
		return;

	new spawnCluster[SpawnClusterData];
	ArrayGetArray(SpawnClusters, clusterIndex, spawnCluster);
	spawnCluster[SpawnClusterUseCount]++;
	spawnCluster[SpawnClusterLastUsedOrder] = SpawnSelectionOrder;
	ArraySetArray(SpawnClusters, clusterIndex, spawnCluster);
}

stock AssignPlayerSpawnSlot(id, spawnSlot[SpawnSlotData])
{
	if (!IsPlayerIndex(id))
		set_fail_state("SpawnPoints received invalid player index %d for assignment.", id);

	PlayerSpawnAssigned[id] = true;
	PlayerSpawnAssignments[id] = spawnSlot;
}

stock bool:TakePlayerSpawnAssignment(id, spawnSlot[SpawnSlotData])
{
	if (!IsPlayerIndex(id))
		return false;

	if (!PlayerSpawnAssigned[id])
		return false;

	spawnSlot = PlayerSpawnAssignments[id];
	PlayerSpawnAssigned[id] = false;

	return true;
}

stock ClearPlayerSpawnAssignment(id)
{
	if (!IsPlayerIndex(id))
		return;

	PlayerSpawnAssigned[id] = false;
}

stock ClearPlayerSpawnAssignments()
{
	for (new id = 1; id <= SPAWN_POINTS_MAX_PLAYERS; id++)
		ClearPlayerSpawnAssignment(id);
}

stock ResetExpiredSpawnReservations()
{
	new Float:now = get_gametime();

	for (new index = ArraySize(SpawnReservations) - 1; index >= 0; index--)
	{
		new spawnReservation[SpawnReservationData];
		ArrayGetArray(SpawnReservations, index, spawnReservation);

		if (spawnReservation[SpawnReservationExpiresAt] <= now)
			ArrayDeleteItem(SpawnReservations, index);
	}
}

stock ApplySpawnSlot(id, spawnSlot[SpawnSlotData])
{
	new Float:origin[3];
	new Float:angles[3];
	new Float:zero[3];

	GetSpawnSlotOrigin(spawnSlot, origin);
	GetSpawnPlacementOrigin(origin, origin);
	GetSpawnSlotAngles(spawnSlot, angles);

	engfunc(EngFunc_SetOrigin, id, origin);
	set_entvar(id, var_angles, angles);
	set_entvar(id, var_v_angle, zero);
	set_entvar(id, var_velocity, zero);
	set_entvar(id, var_punchangle, zero);
	set_entvar(id, var_fixangle, SPAWN_POINTS_FIX_ANGLE);
}

stock bool:IsWorldSpawnOriginValid(Float:origin[3])
{
	return IsSpawnPlacementHullVacant(0, origin);
}

stock bool:IsSpawnPlacementHullVacant(ignoredEntity, Float:origin[3])
{
	new Float:placementOrigin[3];

	GetSpawnPlacementOrigin(origin, placementOrigin);

	return IsSpawnHullVacant(ignoredEntity, placementOrigin);
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

stock bool:IsOriginUsedBySpawnSlot(Float:origin[3], Float:minDistance)
{
	new spawnSlotsCount = ArraySize(SpawnSlots);
	new spawnSlot[SpawnSlotData];
	new Float:slotOrigin[3];
	new Float:minDistanceSquared = minDistance * minDistance;

	for (new index = 0; index < spawnSlotsCount; index++)
	{
		ArrayGetArray(SpawnSlots, index, spawnSlot);
		GetSpawnSlotOrigin(spawnSlot, slotOrigin);

		if (GetOriginDistanceSquared(origin, slotOrigin) < minDistanceSquared)
			return true;
	}

	return false;
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

stock Float:GetOriginDistanceSquared(Float:firstOrigin[3], Float:secondOrigin[3])
{
	new Float:deltaX = firstOrigin[0] - secondOrigin[0];
	new Float:deltaY = firstOrigin[1] - secondOrigin[1];
	new Float:deltaZ = firstOrigin[2] - secondOrigin[2];

	return (deltaX * deltaX) + (deltaY * deltaY) + (deltaZ * deltaZ);
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

stock GetSpawnClusterOrigin(spawnCluster[SpawnClusterData], Float:origin[3])
{
	origin[0] = spawnCluster[SpawnClusterOriginX];
	origin[1] = spawnCluster[SpawnClusterOriginY];
	origin[2] = spawnCluster[SpawnClusterOriginZ];
}

stock GetSpawnSlotOrigin(spawnSlot[SpawnSlotData], Float:origin[3])
{
	origin[0] = spawnSlot[SpawnSlotOriginX];
	origin[1] = spawnSlot[SpawnSlotOriginY];
	origin[2] = spawnSlot[SpawnSlotOriginZ];
}

stock GetSpawnPlacementOrigin(Float:origin[3], Float:placementOrigin[3])
{
	placementOrigin[0] = origin[0];
	placementOrigin[1] = origin[1];
	placementOrigin[2] = origin[2] + SPAWN_POINTS_ORIGIN_OFFSET_Z;
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

	if (SpawnClusters == Invalid_Array)
		set_fail_state("SpawnPoints cluster storage is not initialized.");

	if (SpawnSlots == Invalid_Array)
		set_fail_state("SpawnPoints slot storage is not initialized.");

	if (SpawnReservations == Invalid_Array)
		set_fail_state("SpawnPoints reservation storage is not initialized.");
}

stock bool:CanManagePlayerSpawn(id)
{
	return IsPlayerIndex(id) && is_user_connected(id) && IsPlayableGameTeam(id);
}

stock bool:IsPlayableGameTeam(id)
{
	new TeamName:team = get_member(id, m_iTeam);

	return team == TEAM_TERRORIST || team == TEAM_CT;
}
