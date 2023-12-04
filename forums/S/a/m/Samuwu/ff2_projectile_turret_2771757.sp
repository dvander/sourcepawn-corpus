// best viewed with tab width of 8

// GPL blah blah don't sue if something goes wrong blah blah no warranty blah blah

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

// change these to minimize console output
new PRINT_DEBUG_INFO = true;
new PRINT_DEBUG_SPAM = false;

/**
 * Originally I was to have multiple mods in one file here, but this turret ended up being such a major
 * undertaking that it will reside alone in this file.
 *
 * RageProjectileTurret: A versatile rage that allows you to drop turrets that spew various projectiles.
 *	Known Issues: Relative model paths for turret MUST NOT HAVE SPACES. But spaces are the devil, so surely you don't have them in your path.
 *	Credits: Asher "asherkin" Baker wrote the Dodgeball code from which I ripped spawning working rockets from.
 *		 Took the beacon code from RTD mod, since that's the beacon style most players are familiar with.
 */

public Plugin:myinfo = {
	name = "Freak Fortress 2: Projectile Turret",
	author = "sarysa",
	version = "1.1.1",
};

// copied from tf2 sdk
// solid types
#define SOLID_NONE 0 // no solid model
#define SOLID_BSP 1 // a BSP tree
#define SOLID_BBOX 2 // an AABB
#define SOLID_OBB 3 // an OBB (not implemented yet)
#define SOLID_OBB_YAW 4 // an OBB, constrained so that it can only yaw
#define SOLID_CUSTOM 5 // Always call into the entity for tests
#define SOLID_VPHYSICS 6 // solid vphysics object, get vcollide from the model and collide with that

#define FSOLID_CUSTOMRAYTEST 0x0001 // Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST 0x0002 // Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define FSOLID_TRIGGER 0x0008 // This is something may be collideable but fires touch functions
#define FSOLID_NOT_STANDABLE 0x0010 // You can't stand on this
#define FSOLID_VOLUME_CONTENTS 0x0020 // Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED 0x0040 // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS 0x0080 // Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED 0x0100 // Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS 0x0200 // This trigger will touch debris objects

enum // Collision_Group_t in const.h
{
	COLLISION_GROUP_NONE  = 0,
	COLLISION_GROUP_DEBRIS,			// Collides with nothing but world and static stuff
	COLLISION_GROUP_DEBRIS_TRIGGER, // Same as debris, but hits triggers
	COLLISION_GROUP_INTERACTIVE_DEBRIS,	// Collides with everything except other interactive debris or debris
	COLLISION_GROUP_INTERACTIVE,	// Collides with everything except interactive debris or debris
	COLLISION_GROUP_PLAYER,
	COLLISION_GROUP_BREAKABLE_GLASS,
	COLLISION_GROUP_VEHICLE,
	COLLISION_GROUP_PLAYER_MOVEMENT,  // For HL2, same as Collision_Group_Player, for
										// TF2, this filters out other players and CBaseObjects
	COLLISION_GROUP_NPC,			// Generic NPC group
	COLLISION_GROUP_IN_VEHICLE,		// for any entity inside a vehicle
	COLLISION_GROUP_WEAPON,			// for any weapons that need collision detection
	COLLISION_GROUP_VEHICLE_CLIP,	// vehicle clip brush to restrict vehicle movement
	COLLISION_GROUP_PROJECTILE,		// Projectiles!
	COLLISION_GROUP_DOOR_BLOCKER,	// Blocks entities not permitted to get near moving doors
	COLLISION_GROUP_PASSABLE_DOOR,	// ** sarysa TF2 note: Must be scripted, not passable on physics prop (Doors that the player shouldn't collide with)
	COLLISION_GROUP_DISSOLVING,		// Things that are dissolving are in this group
	COLLISION_GROUP_PUSHAWAY,		// ** sarysa TF2 note: I could swear the collision detection is better for this than NONE. (Nonsolid on client and server, pushaway in player code)

	COLLISION_GROUP_NPC_ACTOR,		// Used so NPCs in scripts ignore the player.
	COLLISION_GROUP_NPC_SCRIPTED,	// USed for NPCs in scripts that should not collide with each other

	LAST_SHARED_COLLISION_GROUP
};

#define MAX_PLAYERS_ARRAY 36
#define MAX_PLAYERS (MAX_PLAYERS_ARRAY < (MaxClients + 1) ? MAX_PLAYERS_ARRAY : (MaxClients + 1))

// text string limits
#define MAX_SOUND_FILE_LENGTH 80
#define MAX_MODEL_FILE_LENGTH 80
#define MAX_MATERIAL_FILE_LENGTH 128
#define MAX_WEAPON_NAME_LENGTH 64
#define MAX_WEAPON_ARG_LENGTH 128
#define MAX_EFFECT_NAME_LENGTH 48
#define MAX_ENTITY_CLASSNAME_LENGTH 48

#define FAR_FUTURE 100000000.0
#define IsEmptyString(%1) (%1[0] == 0)

new BossTeam = _:TFTeam_Blue;

// quick way to see if the round is active
new bool:RoundActive = false;

/**
 * Projectile Turret
 */
// turret firing points
#define TURRET_FIRE_FRONT 0
#define TURRET_FIRE_BACK 1
#define TURRET_FIRE_LEFT 2
#define TURRET_FIRE_RIGHT 3
#define MAX_TURRET_FIRING_POINTS 4

// turret types. the first one is only used in the .cfg
#define TURRET_TYPE_INACTIVE 0
#define TURRET_TYPE_ROCKET 1
#define TURRET_TYPE_GRENADE 2
#define TURRET_TYPE_LOOSE_CANNON 3
#define TURRET_TYPE_ARROW 4
// after consideration I'm going to make this just a projectile turret, since I've about hit the limit for params
// at this point and these two would have very different behavior versus projectile.
//#define TURRET_TYPE_BULLET 1
//#define TURRET_TYPE_FIRE 2

// motion sensor types
#define MOTION_SENSOR_NONE 0	// no motion sensing
#define MOTION_SENSOR_RAY 1	// use a simple ray the direction the turret is facing
#define MOTION_SENSOR_ARC 2	// motion sensor trace in a cone, and shoots directly at the nearest valid target (i.e. checks for obstacles first)

// spawn patterns
#define SPAWN_PATTERN_FRONT 0			// spawn directly in front of the hale
#define SPAWN_PATTERN_ANY 1			// spawn anywhere relative to the hale
#define SPAWN_PATTERN_EXCLUDE_FRONT 2		// spawn anywhere relative to the hale except within 45 degrees of the hale's front
#define SPAWN_PATTERN_SPAWN_ON_LOCATION 3	// spawn on location, much like the TARDIS does
// mask for spawn patterns
#define SPAWN_PATTERN_MASK 3			// the actual base spawn pattern
// flag for spawn patterns
#define FLAG_SP_PRESERVE_MOMENTUM 4		// apply the hale's momentum to the turret's movement

// 40 seems like a good number, cause 40 can produce quite a number of server-side entities
#define PT_STRING "rage_projectile_turret"
#define MAX_TURRETS 40
new bool:PT_ActiveThisRound = false;
new bool:PT_TurretValid[MAX_TURRETS]; // is this a valid turret?
new Float:PT_TimePlacedAt[MAX_TURRETS]; // needed to handle an overflow situation
new Float:PT_FreezeTurretAt[MAX_TURRETS]; // time to freeze the turret
new PT_TurretEntityRef[MAX_TURRETS]; // a reference to one turret's entity
new PT_TurretType[MAX_TURRETS]; // one of the TURRET_TYPEs above
new PT_MotionSensor[MAX_TURRETS]; // type of motion sensor
new Float:PT_MotionSensorAngleDeviation[MAX_TURRETS]; // maximum angle to target enemies in a cone. above 90 creates significant problems
new Float:PT_MotionSensorMaxDistance[MAX_TURRETS]; // maximum distance between firing point and enemy. i.e. for grenade launchers, should be set fairly low. rockets can be set higher.
new bool:PT_DieWithOwner[MAX_TURRETS]; // will it die with the owner? note that if the user logs, it must go away
new Float:PT_TurretDieAt[MAX_TURRETS]; // user can opt to have turrets self destruct after a period of time
new PT_TurretOwner[MAX_TURRETS]; // clientIdx of owner
new Float:PT_TurretDPS[MAX_TURRETS]; // damage per shot, not second ;P
new Float:PT_TurretFireRate[MAX_TURRETS]; // delay between shots
new Float:PT_TurretSpeedFactor[MAX_TURRETS]; // speed factor of projectile motion only
new PT_TurretDirs[MAX_TURRETS]; // 1=front only, 2=front and back, 3=front and sides, 4=all four sides
new PT_TurretProjectileSkin[MAX_TURRETS]; // precached model index for the projectile
new Float:PT_TurretFireAt[MAX_TURRETS]; // next time turret can fire
new Float:PT_TurretFireFront[MAX_TURRETS][3]; // front spawner offset from origin
new Float:PT_TurretFireBack[MAX_TURRETS][3]; // back spawner offset from origin
new Float:PT_TurretFireLeft[MAX_TURRETS][3]; // left spawner offset from origin
new Float:PT_TurretFireRight[MAX_TURRETS][3]; // right spawner offset from origin
new Float:PT_NextBeaconAt[MAX_TURRETS]; // next time for beacon to go off

// setting for the hale (replaces the retry timer)
#define PTH_RETRY_INTERVAL 0.3
new Float:PTH_RetryAt;
new PTH_NumTurretsToRetry[MAX_PLAYERS_ARRAY];

// more settings for the turret
#define PTA_STRING "rage_turret_aesthetics"
new bool:PTA_PlayerDeathHooked = false;
new String:PTA_FireSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];
new String:PTA_KillSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];
new String:PTA_MeleeKillSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];
new String:PTA_FireGraphic[MAX_PLAYERS_ARRAY][MAX_EFFECT_NAME_LENGTH];
new bool:PTA_Beacon[MAX_PLAYERS_ARRAY];
new Float:PTA_BeaconDelay[MAX_PLAYERS_ARRAY];
new String:PTA_BeaconSound[MAX_PLAYERS_ARRAY][MAX_SOUND_FILE_LENGTH];
new BEACON_BEAM;
new BEACON_HALO;

public OnPluginStart2()
{
	HookEvent("arena_win_panel", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("arena_round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	
	for (new i = 0; i < MAX_TURRETS; i++)
		PT_TurretEntityRef[i] = -1;
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// drop turret
	TurretCleanup(); // in case round end somehow doesn't execute. if Shining Armor's particle effect can linger between rounds...
	PT_ActiveThisRound = false;
	PTA_PlayerDeathHooked = false;
	PTH_RetryAt = FAR_FUTURE;

	// various array inits
	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		// INITS THAT MUST BE DONE FOR ENTIRE ARRAY, REGARDLESS OF BOSS STATUS
		PTH_NumTurretsToRetry[clientIdx] = 0;
		
		// INITS THAT ONLY APPLY TO BOSSES WITH THESE RAGES
		if (!IsClientInGame(clientIdx) || !IsPlayerAlive(clientIdx))
			continue;
		else if (GetClientTeam(clientIdx) != BossTeam)
			continue;
			
		new bossIdx = FF2_GetBossIndex(clientIdx);
		// determine now if we should execute the loop for the turrets' behavior
		if (FF2_HasAbility(bossIdx, this_plugin_name, PT_STRING))
		{
			// precache the turret models
			PT_ActiveThisRound = true;
			static String:modelName[MAX_MODEL_FILE_LENGTH];
			ReadModel(bossIdx, PT_STRING, 15, modelName);
			ReadModel(bossIdx, PT_STRING, 17, modelName);
		}
		
		// load the aesthetics
		if (FF2_HasAbility(bossIdx, this_plugin_name, PTA_STRING))
		{
			ReadSound(bossIdx, PTA_STRING, 1, PTA_FireSound[clientIdx]);
			ReadSound(bossIdx, PTA_STRING, 2, PTA_KillSound[clientIdx]);
			ReadSound(bossIdx, PTA_STRING, 3, PTA_MeleeKillSound[clientIdx]);
			FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, PTA_STRING, 4, PTA_FireGraphic[clientIdx], MAX_EFFECT_NAME_LENGTH);
			PTA_BeaconDelay[clientIdx] = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PTA_STRING, 5);
			PTA_Beacon[clientIdx] = PTA_BeaconDelay[clientIdx] > 0.0;
			ReadSound(bossIdx, PTA_STRING, 6, PTA_BeaconSound[clientIdx]);
			
			if (strlen(PTA_KillSound[clientIdx]) > 3)
				PTA_PlayerDeathHooked = true;
				
			// precache stuff for beacon
			BEACON_BEAM = PrecacheModel("materials/sprites/laser.vmt");
			BEACON_HALO = PrecacheModel("materials/sprites/halo01.vmt");
		}
		else
		{
			PTA_FireSound[clientIdx][0] = 0;
			PTA_KillSound[clientIdx][0] = 0;
			PTA_MeleeKillSound[clientIdx][0] = 0;
			PTA_Beacon[clientIdx] = false;
			PTA_FireGraphic[clientIdx][0] = 0;
		}
	}
	
	if (PTA_PlayerDeathHooked)
		HookEvent("player_death", PTA_PlayerDeath, EventHookMode_Post);
	
	// round is active
	RoundActive = true;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// round is no longer active
	RoundActive = false;
	
	// destroy the turrets
	TurretCleanup();
	PT_ActiveThisRound = false;
	
	if (PTA_PlayerDeathHooked)
		UnhookEvent("player_death", PTA_PlayerDeath, EventHookMode_Post);
}

public PTA_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid")); // not really user id, is client index
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new killingEntity = GetEventInt(event, "inflictor_entindex");
	//new weapon = GetEventInt(event, "weaponid");
	
	//PrintToServer("Someone died %d / %d / %d / %d", victim, killer, killingEntity, weapon);
	
	if (victim <= 0 || victim >= MAX_PLAYERS || killer <= 0 || killer >= MAX_PLAYERS)
		return;
		
	if (killingEntity != killer && GetClientTeam(victim) != BossTeam && strlen(PTA_KillSound[killer]) > 3)
		EmitSoundToAll(PTA_KillSound[killer]);
	else if (GetClientTeam(victim) != BossTeam && strlen(PTA_MeleeKillSound[killer]) > 3)
		EmitSoundToAll(PTA_MeleeKillSound[killer]);
}

public Action:FF2_OnAbility2(bossIdx, const String:plugin_name[], const String:ability_name[], status)
{
	// don't execute any of this after round is done.
	// you're just asking for bugs.
	if (!RoundActive)
		return Plugin_Continue;

	// strictly enforce the correct plugin is specified.
	// these were working earlier with no specification...eep.
	if (strcmp(plugin_name, this_plugin_name))
		return Plugin_Continue;

	if (!strcmp(ability_name, PT_STRING))
		Rage_ProjectileTurret(ability_name, bossIdx);
		
	return Plugin_Continue;
}

/**
 * Drop turrets
 */
TurretCleanup(clientIdx = -1)
{
	// destroy turrets and reset validity
	for (new i = 0; i < MAX_TURRETS; i++)
	{
		if (PT_TurretValid[i])
		{
			if (clientIdx == -1 || PT_TurretOwner[i] == clientIdx)
			{
				RemoveEntity(INVALID_HANDLE, PT_TurretEntityRef[i]);
				PT_TurretValid[i] = false;
			}
		}
	}
}

// need to prevent turret self-damage
public Action:OnTurretDamaged(turret, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
	// no weapon is assigned to turret damage, so there's one dead giveaway
	if (weapon == -1)
	{
		// valid player check for attacker
		if (attacker > 0 && attacker < MAX_PLAYERS)
		{
			// if attacker is on boss team it should be good
			if (GetClientTeam(attacker) == BossTeam)
			{
				damage = 0.0;
				damagetype |= DMG_PREVENT_PHYSICS_FORCE;
				return Plugin_Changed;
			}
		}
	}
		
	return Plugin_Continue;
}

// DoDropTurret result codes
#define DDT_INVALID_BOSS 0
#define DDT_NOWHERE_TO_SPAWN 1
#define DDT_TOO_MANY_TURRETS 2
#define DDT_SUCCESS 3
bool:ShouldRetryDropTurret(result)
{
	return result == DDT_NOWHERE_TO_SPAWN;
}

#define MIN_TURRET_VEL 200.0
#define MAX_TURRET_VEL 300.0
#define TURRET_SPAWN_DISTANCE 85.0
#define MAX_TURRET_SPAWN_ATTEMPTS 30
#define TURRET_SPAWN_TRY_DIFFERENT_PLAYER_AT 10
//#define PT_TRACEMASK (CONTENTS_SOLID | CONTENTS_WINDOW | CONTENTS_GRATE)
#define PT_TRACEMASK MASK_PLAYERSOLID
DoDropTurret(bossIdx)
{
	new userId = FF2_GetBossUserId(bossIdx);
	if (userId <= 0)
		return DDT_INVALID_BOSS;
	new clientIdx = GetClientOfUserId(userId);
	if (clientIdx <= 0)
		return DDT_INVALID_BOSS;
	if (!IsClientInGame(clientIdx) || !IsPlayerAlive(clientIdx))
		return DDT_INVALID_BOSS;
		
	// enforce the user turret maximum
	new userMaxTurrets = FF2_GetAbilityArgument(bossIdx, this_plugin_name, PT_STRING, 18);
	new turretCount = 0;
	new oldestTurret = -1;
	new Float:oldestTurretTime = 999999.0;
	for (new i = 0; i < MAX_TURRETS; i++)
	{
		if (PT_TurretValid[i])
		{
			turretCount++;
			if (PT_TimePlacedAt[i] < oldestTurretTime)
			{
				oldestTurret = i;
				oldestTurretTime = PT_TimePlacedAt[i];
			}
			if (turretCount >= userMaxTurrets)
			{
				PT_TurretValid[oldestTurret] = false;
				new turretEntity = EntRefToEntIndex(PT_TurretEntityRef[oldestTurret]);
				if (IsValidEntity(turretEntity))
					AcceptEntityInput(turretEntity, "kill");
				if (PRINT_DEBUG_INFO)
					PrintToServer("[projectile_turret] Maximum of turrets (%d) exceeded. Deleting oldest turret %d.", userMaxTurrets, oldestTurret);
				break;
			}
		}
	}

	// find an free turret slot first of all, cause if there is none, we can't spawn the turret
	new newTurretIndex = -1;
	for (new i = 0; i < MAX_TURRETS; i++)
	{
		if (PT_TurretValid[i])
			continue;
			
		newTurretIndex = i;
		break;
	}
	
	if (newTurretIndex == -1)
	{
		PrintToServer("[projectile_turret] WARNING: User(s) spawned too many turrets. Exceeded limit of %d", MAX_TURRETS);
		return DDT_TOO_MANY_TURRETS;
	}
	
	// get the boss' position
	new Float:bossPosition[3];
	GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", bossPosition);
	
	// determine spawn point now. there are few instances where a valid spawn point
	// may be impossible, like in the well on Skeith's map, or in the boss spawn vents on warebloom
	new Float:spawnPoint[3];
	new Float:velocity[3];
	new Float:hullMin[3] = { -35.0, -35.0, 0.0 }; // trace a hull somewhat larger than a player for good measure 
	new Float:hullMax[3] = { 35.0, 35.0, 83.0 }; // trace a hull somewhat larger than a player for good measure
	new Float:bossEyeAngles[3];
	new Float:tmpVec[3];
	GetClientEyeAngles(clientIdx, bossEyeAngles);
	bossEyeAngles[0] = -20.0; // turret should fly up and out of the hale. angle 0 is how that's done.
	new spawnPattern = FF2_GetAbilityArgument(bossIdx, this_plugin_name, PT_STRING, 13);
	new spawnPatternFlags = spawnPattern & ~SPAWN_PATTERN_MASK;
	spawnPattern &= SPAWN_PATTERN_MASK;
	if (spawnPattern == SPAWN_PATTERN_SPAWN_ON_LOCATION) // don't preserve momentum ever if the turret's just going to be dropped somewhere
		spawnPatternFlags &= ~FLAG_SP_PRESERVE_MOMENTUM;
	
	if (spawnPattern == SPAWN_PATTERN_FRONT) // easiest to invalidate
	{
		// first trace a ray to find our end point
		new Handle:trace = TR_TraceRayFilterEx(bossPosition, bossEyeAngles, PT_TRACEMASK, RayType_Infinite, TraceWallsOnly);
		if (!TR_DidHit(trace)) // wtf?
		{
			PrintToServer("Trace ray failed?!");
			CloseHandle(trace);
			return DDT_NOWHERE_TO_SPAWN;
		}
		TR_GetEndPosition(tmpVec, trace);
		CloseHandle(trace);
		
		// now trace our hull
		trace = TR_TraceHullFilterEx(bossPosition, tmpVec, hullMin, hullMax, PT_TRACEMASK, TraceWallsOnly);
		TR_GetEndPosition(tmpVec, trace);
		CloseHandle(trace);
		
		// now get the distance and ensure it's less than our spawn distance
		if (GetVectorDistance(tmpVec, bossPosition) < TURRET_SPAWN_DISTANCE)
		{
			if (PRINT_DEBUG_INFO)
				PrintToServer("Could not spawn turret. Will retry. angles=%f,%f,%f", bossEyeAngles[0], bossEyeAngles[1], bossEyeAngles[2]);
			return DDT_NOWHERE_TO_SPAWN;
		}
	}
	else if (spawnPattern == SPAWN_PATTERN_SPAWN_ON_LOCATION)
	{
		// grab turret dimensions
		new String:turretDimensionsStr[134];
		new String:turretDimensionsStrSplit[2][66];
		new String:turretStrIndividual[3][21];
		FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, PT_STRING, 14, turretDimensionsStr, 134);
		new Float:TurretMinMax[2][3];
		
		// split up and validate the dimensions first of all, necessary for proper spawning and verifying boss is within turret borders
		ExplodeString(turretDimensionsStr, " ", turretDimensionsStrSplit, 2, 66);
		for (new i = 0; i < 2; i++)
		{
			ExplodeString(turretDimensionsStrSplit[i], ",", turretStrIndividual, 3, 21);
			TurretMinMax[i][0] = StringToFloat(turretStrIndividual[0]);
			TurretMinMax[i][1] = StringToFloat(turretStrIndividual[1]);
			TurretMinMax[i][2] = StringToFloat(turretStrIndividual[2]);
		}

		if (TurretMinMax[1][0] <= TurretMinMax[0][0] ||
			TurretMinMax[1][1] <= TurretMinMax[0][1] ||
			TurretMinMax[1][2] <= TurretMinMax[0][2])
		{
			PrintToServer("[projectile_turret] ERROR with %s, dimensions are invalid. Rage will not execute. Must be formatted: minX,minY,minZ maxX,maxY,maxZ", PT_STRING);
			return DDT_INVALID_BOSS;
		}
		
		// some options in the TARDIS I just don't have room to bring in here
		new Float:maxZDifference = 500.0;
		new Float:minSpawnDistance = 100.0;
		new Float:maxSpawnDistance = 350.0;
	
		// find a suitable place for the turret.
		new playerToSpawnTurretAround = clientIdx;
		new bool:exclude[MAX_PLAYERS_ARRAY];
		exclude[clientIdx] = true;
		new Float:bossOrigin[3];
		GetEntPropVector(playerToSpawnTurretAround, Prop_Send, "m_vecOrigin", bossOrigin);
		new Float:turretOrigin[3];
		new Float:testPoint[3];
		new bool:wallTestFailure = false;
		new bool:playerTestFailure = false;
		new Float:testDistanceMinimum = 0.0;
		new Float:testedDistance = 0.0;
		new Float:rayAngles[3];
		new Float:playerOrigin[3];
		new Float:turretAngles[3];
		turretAngles[0] = 0.0;
		turretAngles[1] = 0.0;
		turretAngles[2] = 0.0;

		// need our widths to test. 1.51 is a cheap way to cover even the center point of the turret. (i.e. the 2/2/3 triangle)
		new Float:widthTest = fmax(fabs(TurretMinMax[1][0] - TurretMinMax[0][0]), fabs(TurretMinMax[1][1] - TurretMinMax[0][1])) * 1.51;
		widthTest += 36.0; // 2015-03-22, 1.5 the width of players too. no wonder players were getting stuck!
		for (new attempt = 0; attempt < MAX_TURRET_SPAWN_ATTEMPTS; attempt++)
		{
			if (attempt > 0 && attempt % TURRET_SPAWN_TRY_DIFFERENT_PLAYER_AT == 0)
			{
				playerToSpawnTurretAround = FindNearestLivingPlayer(playerToSpawnTurretAround, exclude);
				if (playerToSpawnTurretAround == -1)
					break; // all possible legal players failed
				GetEntPropVector(playerToSpawnTurretAround, Prop_Send, "m_vecOrigin", bossOrigin);
			}
		
			// placement is simple. Z will always be +80 to account for minor bumps and hills
			// X and Y will be plus or minus some random offset
			turretOrigin[0] = bossOrigin[0] + RandomNegative(GetRandomFloat(minSpawnDistance, maxSpawnDistance));
			turretOrigin[1] = bossOrigin[1] + RandomNegative(GetRandomFloat(minSpawnDistance, maxSpawnDistance));
			turretOrigin[2] = bossOrigin[2] + 80.0;

			// first, the quick test...do ray traces to the four bottom points to ensure there's nothing blocking the turret from spawning
			// we don't care about the top points. it'll fall through a ceiling and I can live with that.
			testPoint[2] = turretOrigin[2];
			wallTestFailure = false;
			for (new testNum = 0; testNum < 4; testNum++)
			{
				// simple way to disperse our four tests
				if (testNum == 0 || testNum == 1)
					testPoint[0] = turretOrigin[0] + TurretMinMax[0][0];
				else
					testPoint[0] = turretOrigin[0] + TurretMinMax[1][0];
				if (testNum == 1 || testNum == 2)
					testPoint[1] = turretOrigin[1] + TurretMinMax[0][1];
				else
					testPoint[1] = turretOrigin[1] + TurretMinMax[1][1];

				// get the distance minimum and our angles
				testDistanceMinimum = GetVectorDistance(bossOrigin, testPoint);
				tmpVec[0] = testPoint[0] - bossOrigin[0];
				tmpVec[1] = testPoint[1] - bossOrigin[1];
				tmpVec[2] = testPoint[2] - bossOrigin[2];
				GetVectorAngles(tmpVec, rayAngles);

				// get the distance a ray can travel
				new Handle:trace = TR_TraceRayFilterEx(bossOrigin, rayAngles, PT_TRACEMASK, RayType_Infinite, TraceWallsOnly);
				TR_GetEndPosition(tmpVec, trace);
				CloseHandle(trace);
				testedDistance = GetVectorDistance(tmpVec, bossOrigin);

				if (testedDistance < testDistanceMinimum) // we hit a wall. this spawn point is no good.
				{
					if (PRINT_DEBUG_SPAM)
						PrintToServer("[projectile_turret] Wall test failed on attempt %d. (%f < %f) angles=%f,%f    tmpVec=%f,%f,%f", attempt, testedDistance, testDistanceMinimum, rayAngles[0], rayAngles[1], tmpVec[0], tmpVec[1], tmpVec[2]);

					wallTestFailure = true;
					break;
				}
			}

			if (wallTestFailure)
				continue;

			// now the player test
			// doing it cheaply as possible by completely ignoring the Z axis.
			// yes it can be problematic with vertical maps. oh well. but OTOH we don't want it falling on players.
			playerTestFailure = false;
			new failPlayer = 0;

			for (new victim = 1; victim < MAX_PLAYERS; victim++)
			{
				// for paranoia's sake I'm including the boss in this test
				if (!IsLivingPlayer(victim))
					continue;

				// need the player's position...
				GetEntPropVector(victim, Prop_Send, "m_vecOrigin", playerOrigin);
				
				// do a simple point-distance test on x and y.
				if (playerOrigin[0] >= turretOrigin[0] - widthTest && playerOrigin[0] <= turretOrigin[0] + widthTest &&
					playerOrigin[1] >= turretOrigin[1] - widthTest && playerOrigin[1] <= turretOrigin[1] + widthTest)
				{
					playerTestFailure = true;
					failPlayer = victim;
					break;
				}
			}

			if (playerTestFailure)
			{
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[projectile_turret] Player test failed on attempt %d with player %d", attempt, failPlayer);
				continue;
			}

			// oh hey, both tests passed. now lets set a good angle rotation for the tardis and get out of here
			// by making it face the player it becomes very unlikely the entrance will be blocked by a wall
			tmpVec[0] = turretOrigin[0] - bossOrigin[0];
			tmpVec[1] = turretOrigin[1] - bossOrigin[1];
			tmpVec[2] = turretOrigin[2] - bossOrigin[2];
			GetVectorAngles(tmpVec, rayAngles);

			new Float:eyeAngles[3];
			GetClientEyeAngles(clientIdx, eyeAngles);
			new Float:testAngle = fixAngle(rayAngles[1] - eyeAngles[1]);
			if (testAngle >= 45.0 && testAngle < 135.0)
				turretAngles[1] = 90.0;
			else if (testAngle >= -45.0 || testAngle < 45.0)
				turretAngles[1] = 180.0;
			else if (testAngle >= -135.0 && testAngle < -45.0)
				turretAngles[1] = -90.0;

			// and lets set a better origin point so it's close to the ground from the get go
			new Float:highestSafeZ = -99999.0;
			new Float:lowestSafeZ = 99999.0;
			new Float:smallestZDiff = 99999.0;
			testPoint[2] = turretOrigin[2];
			rayAngles[1] = 0.0;
			for (new testNum = 0; testNum < 4; testNum++)
			{
				// simple way to disperse our four tests
				if (testNum == 0 || testNum == 1)
					testPoint[0] = turretOrigin[0] + TurretMinMax[0][0];
				else
					testPoint[0] = turretOrigin[0] + TurretMinMax[1][0];
				if (testNum == 1 || testNum == 2)
					testPoint[1] = turretOrigin[1] + TurretMinMax[0][1];
				else
					testPoint[1] = turretOrigin[1] + TurretMinMax[1][1];

				// perform a ray trace straight down
				rayAngles[0] = 89.9;
				new Handle:trace = TR_TraceRayFilterEx(testPoint, rayAngles, PT_TRACEMASK, RayType_Infinite, TraceWallsOnly);
				TR_GetEndPosition(tmpVec, trace);
				CloseHandle(trace);
				if (tmpVec[2] > highestSafeZ)
					highestSafeZ = tmpVec[2];
				if (tmpVec[2] < lowestSafeZ)
					lowestSafeZ = tmpVec[2];

				// also perform a ray trace straight up
				rayAngles[0] = -89.9;
				new Float:oldZ = tmpVec[2];
				trace = TR_TraceRayFilterEx(testPoint, rayAngles, PT_TRACEMASK, RayType_Infinite, TraceWallsOnly);
				TR_GetEndPosition(tmpVec, trace);
				CloseHandle(trace);
				if (fabs(oldZ - tmpVec[2]) < smallestZDiff)
					smallestZDiff = fabs(oldZ - tmpVec[2]);
			}

			// determine our max topple
			new Float:maxTopple = (TurretMinMax[1][0] - TurretMinMax[0][0]) / 3.0;

			// looks like we have one more fail condition. too much variation means the turret will likely topple, and we don't want that
			// so ensure there is no such variation
			if (fabs(highestSafeZ - lowestSafeZ) >= maxTopple)
			{
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[projectile_turret] Topple test failed on attempt %d. Lowest is %f and highest is %f", attempt, lowestSafeZ, highestSafeZ);
				playerTestFailure = true; // lie :P
				continue;
			}

			// yet another fail condition, don't let it spawn in too small of a space
			if (smallestZDiff < 63.0 + maxTopple)
			{
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[projectile_turret] Space test failed on attempt %d. Player needs %f to fit, ended up being %f.", attempt, smallestZDiff, (63.0 + maxTopple));
				playerTestFailure = true; // lie :P
				continue;
			}

			turretOrigin[2] = highestSafeZ + 20.0;

			// and even one more, don't want the turret spawning in a damage pit
			if (fabs(turretOrigin[2] - bossOrigin[2]) > maxZDifference)
			{
				if (PRINT_DEBUG_SPAM)
					PrintToServer("[projectile_turret] Pit test failed on attempt %d. maxZDifference=%f    zDifference=%f", attempt, maxZDifference, fabs(turretOrigin[2] - bossOrigin[2]));
				playerTestFailure = true; // lie :P
				continue;
			}

			break;
		}

		// could not spawn it anywhere, so put it in BLU spawn
		// this could be a problem on rare maps like Mann Co. Headquarters
		if (wallTestFailure || playerTestFailure)
			return DDT_NOWHERE_TO_SPAWN;
			
		spawnPoint[0] = turretOrigin[0];
		spawnPoint[1] = turretOrigin[1];
		spawnPoint[2] = turretOrigin[2];
		velocity[0] = 0.0; velocity[1] = 0.0; velocity[2] = 0.0;
	}
	else
	{
		new Float:testAngles[3];
		testAngles[0] = bossEyeAngles[0];
		new bool:randSpotSuccess = false;
		for (new i = 0; i < 20; i++) // give up after 20 times
		{
			if (spawnPattern == SPAWN_PATTERN_EXCLUDE_FRONT)
				testAngles[1] = fixAngle(GetRandomFloat(0.0, 269.9) + bossEyeAngles[1] + 45.0);
			else
				testAngles[1] = GetRandomFloat(-179.9, 179.9);
			
			// first trace a ray to find our end point
			new Handle:trace = TR_TraceRayFilterEx(bossPosition, testAngles, PT_TRACEMASK, RayType_Infinite, TraceWallsOnly);
			if (!TR_DidHit(trace)) // wtf?
			{
				PrintToServer("[projectile_turret] Trace ray failed?!");
				CloseHandle(trace);
				continue;
			}
			TR_GetEndPosition(tmpVec, trace);
			CloseHandle(trace);

			// now trace our hull
			trace = TR_TraceHullFilterEx(bossPosition, tmpVec, hullMin, hullMax, PT_TRACEMASK, TraceWallsOnly);
			TR_GetEndPosition(tmpVec, trace);
			CloseHandle(trace);

			// now get the distance and ensure it's less than our spawn distance
			if (GetVectorDistance(tmpVec, bossPosition) < TURRET_SPAWN_DISTANCE)
			{
				if (PRINT_DEBUG_INFO)
					PrintToServer("[projectile_turret] Attempt %d failed. angles=%f,%f,%f", i, testAngles[0], testAngles[1], testAngles[2]);
				continue;
			}
			
			randSpotSuccess = true;
			break;
		}
		
		if (!randSpotSuccess)
		{
			if (PRINT_DEBUG_INFO)
				PrintToServer("[projectile_turret] Failed to spawn turret around hale. Is probably in a tight chute or something. Will retry.");
		}
	
		velocity[0] = GetRandomFloat(MIN_TURRET_VEL, MAX_TURRET_VEL) * (GetRandomInt(0, 1) ? 1 : -1);
		velocity[1] = GetRandomFloat(MIN_TURRET_VEL, MAX_TURRET_VEL) * (GetRandomInt(0, 1) ? 1 : -1);
		velocity[2] = GetRandomFloat(MIN_TURRET_VEL, MAX_TURRET_VEL);
	}
	
	// so we have a valid point. now find our spawn point by constraining the distance between our known points
	// this is a bit different from normalizing, which is necessary since we're ensuring our two
	// hitboxes don't touch each other. (with guesswork, anyway...the turret maker needs to make it small)
	if (spawnPattern != SPAWN_PATTERN_SPAWN_ON_LOCATION)
	{
		DistanceConstrain(bossPosition, tmpVec, spawnPoint, TURRET_SPAWN_DISTANCE);

		// and figure out our base velocity
		MakeVectorFromPoints(bossPosition, spawnPoint, velocity);
		NormalizeVector(velocity, velocity);
		velocity[0] *= MAX_TURRET_VEL * 1.5;
		velocity[1] *= MAX_TURRET_VEL * 1.5;
		velocity[2] *= MAX_TURRET_VEL * 1.5;

		// if the flag for adding player velocity is set, do it!
		if ((spawnPatternFlags & FLAG_SP_PRESERVE_MOMENTUM))
		{
			new Float:playerVelocity[3];
			GetEntPropVector(clientIdx, Prop_Data, "m_vecVelocity", playerVelocity);
			velocity[0] += playerVelocity[0];
			velocity[1] += playerVelocity[1];
			velocity[2] += playerVelocity[2];
		}
	}
	
	// turret stat args
	new turretType = FF2_GetAbilityArgument(bossIdx, this_plugin_name, PT_STRING, 2);
	if (turretType == TURRET_TYPE_ARROW)
	{
		PrintToServer("[projectile_turret] Turret Type Arrow is unstable, and probably never will work as spawning functioning arrows has issues. Switching to rocket.");
		turretType = TURRET_TYPE_ROCKET;
	}
	new Float:fireDelay = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PT_STRING, 3);
	new Float:damage = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PT_STRING, 4);
	new Float:speedFactor = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PT_STRING, 5);
	new fireDirections = FF2_GetAbilityArgument(bossIdx, this_plugin_name, PT_STRING, 6);
	new Float:timeToLive = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PT_STRING, 7);
	new turretHealth = FF2_GetAbilityArgument(bossIdx, this_plugin_name, PT_STRING, 8);
	new motionSensor = FF2_GetAbilityArgument(bossIdx, this_plugin_name, PT_STRING, 9);
	new Float:angleDeviation = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PT_STRING, 10);
	new Float:maxDistance = FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, PT_STRING, 11);
	new bool:dieWithOwner = FF2_GetAbilityArgument(bossIdx, this_plugin_name, PT_STRING, 12) == 1;
	
	// no sense using the expensive motion sensor code if the angle set is 0.0
	if (motionSensor == MOTION_SENSOR_ARC && angleDeviation <= 0.0)
	{
		PrintToServer("[projectile_turret] Warning: Specified motion sensor arc for turret but angle deviation is 0.0. Using ray instead.");
		motionSensor = MOTION_SENSOR_RAY;
	}
	
	// turret model args
	new String:modelName[MAX_MODEL_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, PT_STRING, 15, modelName, MAX_MODEL_FILE_LENGTH);
	new projectileOverride = -1;
	new String:projectileModelName[MAX_MODEL_FILE_LENGTH];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, PT_STRING, 17, projectileModelName, MAX_MODEL_FILE_LENGTH);
	if (strlen(projectileModelName) > 3)
		projectileOverride = PrecacheModel(projectileModelName);
		
	// if turret health is 0, it means indestructible. in reality, we're just setting it to something obscenely high
	if (turretHealth <= 0)
		turretHealth = 999999;

	// create our physics object and set it to take damage 
	new turret = CreateEntityByName("prop_physics");
	SetEntProp(turret, Prop_Data, "m_takedamage", 2);
	
	// give it the same starting angle of rotation as the player. once it bumps around it will change a little.
	new Float:playerAngles[3];
	GetEntPropVector(clientIdx, Prop_Data, "m_angRotation", playerAngles);
	SetEntPropVector(turret, Prop_Data, "m_angRotation", playerAngles);

	// tweak the model
	SetEntityModel(turret, modelName);

	// spawn and move it
	GetEntProp(turret, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	DispatchSpawn(turret);
	TeleportEntity(turret, spawnPoint, NULL_VECTOR, velocity);
	SetEntProp(turret, Prop_Data, "m_takedamage", 2);
	
	// damage hook it
	SDKHook(turret, SDKHook_OnTakeDamage, OnTurretDamaged);
	
	// gotta set its health after it's spawned. just how it is
	//PrintToServer("Spawned at %f, %f, %f    with vel %f, %f, %f", bossPosition[0], bossPosition[1], bossPosition[2], velocity[0], velocity[1], velocity[2]);
	SetEntProp(turret, Prop_Data, "m_iMaxHealth", turretHealth);
	SetEntProp(turret, Prop_Data, "m_iHealth", turretHealth);
	//PrintToServer("Health is %d", GetEntProp(turret, Prop_Data, "m_iHealth"));
	//PrintToServer("solid stuff: 0x%x / %d / %d", GetEntProp(turret, Prop_Send, "m_usSolidFlags"), GetEntProp(turret, Prop_Send, "m_CollisionGroup"), GetEntProp(turret, Prop_Send, "m_nSolidType"));
	//SetEntProp(turret, Prop_Send, "m_usSolidFlags", GetEntProp(turret, Prop_Send, "m_usSolidFlags") | FSOLID_NOT_SOLID);
	
	// store the turret's info in the array
	PT_FreezeTurretAt[newTurretIndex] = GetEngineTime() + (spawnPattern == SPAWN_PATTERN_SPAWN_ON_LOCATION ? 1.0 : 3.0);
	PT_TurretValid[newTurretIndex] = true;
	PT_TurretEntityRef[newTurretIndex] = EntIndexToEntRef(turret);
	PT_TurretType[newTurretIndex] = turretType;
	PT_MotionSensor[newTurretIndex] = motionSensor;
	PT_MotionSensorAngleDeviation[newTurretIndex] = angleDeviation;
	PT_MotionSensorMaxDistance[newTurretIndex] = maxDistance;
	PT_DieWithOwner[newTurretIndex] = dieWithOwner;
	PT_TurretDieAt[newTurretIndex] = GetEngineTime() + (timeToLive == 0.0 ? 3600.0 : timeToLive);
	PT_TurretDirs[newTurretIndex] = fireDirections;
	PT_TurretSpeedFactor[newTurretIndex] = speedFactor;
	PT_TurretDPS[newTurretIndex] = damage;
	PT_TurretFireRate[newTurretIndex] = fireDelay;
	PT_TurretOwner[newTurretIndex] = clientIdx;
	PT_TurretProjectileSkin[newTurretIndex] = projectileOverride;
	PT_TurretFireAt[newTurretIndex] = GetEngineTime() + 2.0; // enforce a 2 second delay before turret can fire, give it time to land and right itself
	PT_NextBeaconAt[newTurretIndex] = GetEngineTime() + PTA_BeaconDelay[clientIdx];
	PT_TimePlacedAt[newTurretIndex] = GetEngineTime();
	
	// oh, and get the firing locations
	new String:fireLocations[256];
	new String:vectorSets[4][64];
	new String:floatSets[3][16];
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, PT_STRING, 16, fireLocations, 256);
	new vCount = ExplodeString(fireLocations, " ", vectorSets, 4, 64);
	for (new i = 0; i < vCount; i++)
	{
		ExplodeString(vectorSets[i], ",", floatSets, 3, 16);
		new Float:x = StringToFloat(floatSets[0]);
		new Float:y = StringToFloat(floatSets[1]);
		new Float:z = StringToFloat(floatSets[2]);
		
		if (i == TURRET_FIRE_FRONT) { PT_TurretFireFront[newTurretIndex][0] = x; PT_TurretFireFront[newTurretIndex][1] = y; PT_TurretFireFront[newTurretIndex][2] = z; }
		else if (i == TURRET_FIRE_BACK) { PT_TurretFireBack[newTurretIndex][0] = x; PT_TurretFireBack[newTurretIndex][1] = y; PT_TurretFireBack[newTurretIndex][2] = z; }
		else if (i == TURRET_FIRE_LEFT) { PT_TurretFireLeft[newTurretIndex][0] = x; PT_TurretFireLeft[newTurretIndex][1] = y; PT_TurretFireLeft[newTurretIndex][2] = z; }
		else if (i == TURRET_FIRE_RIGHT) { PT_TurretFireRight[newTurretIndex][0] = x; PT_TurretFireRight[newTurretIndex][1] = y; PT_TurretFireRight[newTurretIndex][2] = z; }
	}
	
	//PrintToServer("front: %f,%f,%f", PT_TurretFireFront[newTurretIndex][0], PT_TurretFireFront[newTurretIndex][1], PT_TurretFireFront[newTurretIndex][2]);
	//PrintToServer("back: %f,%f,%f", PT_TurretFireBack[newTurretIndex][0], PT_TurretFireBack[newTurretIndex][1], PT_TurretFireBack[newTurretIndex][2]);
	//PrintToServer("left: %f,%f,%f", PT_TurretFireLeft[newTurretIndex][0], PT_TurretFireLeft[newTurretIndex][1], PT_TurretFireLeft[newTurretIndex][2]);
	//PrintToServer("right: %f,%f,%f", PT_TurretFireRight[newTurretIndex][0], PT_TurretFireRight[newTurretIndex][1], PT_TurretFireRight[newTurretIndex][2]);
	
	// print this crap out
	if (PRINT_DEBUG_INFO)
		PrintToServer("%f: [projectile_turret] Generated a turret: type=%d  motion=%d  dieWithOwner=%d  dieAt=%f  dirs=%d  projSpeed=%f  damagePerShot=%f  fireRate=%f  skin=%d",
				GetEngineTime(), PT_TurretType[newTurretIndex], PT_MotionSensor[newTurretIndex], PT_DieWithOwner[newTurretIndex],
				PT_TurretDieAt[newTurretIndex], PT_TurretDirs[newTurretIndex], PT_TurretSpeedFactor[newTurretIndex],
				PT_TurretDPS[newTurretIndex], PT_TurretFireRate[newTurretIndex], PT_TurretProjectileSkin[newTurretIndex]);
				
	return DDT_SUCCESS;
}

Rage_ProjectileTurret(const String:ability_name[], bossIdx)
{
	if (!RoundActive)
		return;

	new turretCount = FF2_GetAbilityArgument(bossIdx, this_plugin_name, ability_name, 1);
	new clientIdx = GetClientOfUserId(FF2_GetBossUserId(bossIdx));
	
	// drop our first turret
	new result = DoDropTurret(bossIdx);
	
	// if turrent count is above zero, start a timer to drop the others
	// this is necessary because spawning multiple turrets at the exact same time will often get some stuck inside the player
	if (!ShouldRetryDropTurret(result))
		turretCount--;
	if (turretCount > 0)
	{
		PTH_NumTurretsToRetry[clientIdx] += turretCount;
		PTH_RetryAt = GetEngineTime() + PTH_RETRY_INTERVAL;
	}
}

new bool:tracePlayersSuccess = false;
public bool:TracePlayersAndBuildings(entity, contentsMask)
{
	if (!IsValidEntity(entity))
		return false;

	// check for mercs
	if (entity > 0 && entity < MAX_PLAYERS)
	{
		if (IsPlayerAlive(entity) && !TF2_IsPlayerInCondition(entity, TFCond_Cloaked))
			tracePlayersSuccess = tracePlayersSuccess || GetClientTeam(entity) != BossTeam;
	}
	else
	{
		new String:classname[MAX_ENTITY_CLASSNAME_LENGTH];
		GetEntityClassname(entity, classname, MAX_ENTITY_CLASSNAME_LENGTH);
		if (!strcmp("obj_sentrygun", classname) || !strcmp("obj_dispenser", classname) || !strcmp("obj_teleporter", classname))
			tracePlayersSuccess = true;
	}
	
	return false;
}

//new turretIdxTmp = -1;
public bool:CheckArcTurretTarget(targetEntity, Float:firingPoint[3], Float:firingAngles[3], Float:maxAngle, &nearestValidTarget, Float:nvtOrigin[3], Float:nvtAngles[3], &Float:nvtDistance)
{
	static Float:targetOrigin[3];
	static Float:pointToTargetAngles[3];
	static Float:tmpVec[3];

	// first ensure that this target is not farther away than the previous valid target
	GetEntPropVector(targetEntity, Prop_Data, "m_vecOrigin", targetOrigin);
	targetOrigin[2] += 50.0; // don't aim at their feet
	new Float:distance = GetVectorDistance(firingPoint, targetOrigin, true);
	if (distance > nvtDistance)
		return false;

	// get our angles by treating the firing point as 0,0,0 and getting the angles of the difference
	tmpVec[0] = targetOrigin[0] - firingPoint[0];
	tmpVec[1] = targetOrigin[1] - firingPoint[1];
	tmpVec[2] = targetOrigin[2] - firingPoint[2];
	GetVectorAngles(tmpVec, pointToTargetAngles);
	//turretIdxTmp++; turretIdxTmp %= 4;
	//if (targetEntity == 23)
	//	PrintToServer("%d: pttAngles=%f,%f,%f  diffPoint=%f,%f,%f  firingAngles=%f,%f,%f", turretIdxTmp, pointToTargetAngles[0], pointToTargetAngles[1], pointToTargetAngles[2], tmpVec[0], tmpVec[1], tmpVec[2], firingAngles[0], firingAngles[1], firingAngles[2]);
	
	// checking if these angles are within constraint is very simple...well except for the fact GetVectorAngles is 0-360 but other angles are -180-180. bah...
	tmpVec[0] = fabs(fixAngle(pointToTargetAngles[0] - firingAngles[0]));
	tmpVec[1] = fabs(fixAngle(pointToTargetAngles[1] - firingAngles[1]));
	// third angle is not used.
	//tmpVec[2] = fabs(pointToTargetAngles[2] - firingAngles[2]);
	if (tmpVec[0] > maxAngle || tmpVec[1] > maxAngle)// || tmpVec[2] > maxAngle)
		return false;
		
	// finally, ensure no wall between the firing point and its target
	new Handle:trace = TR_TraceRayFilterEx(firingPoint, pointToTargetAngles, PT_TRACEMASK, RayType_Infinite, TraceWallsOnly);
	if (!TR_DidHit(trace)) // wtf?
	{
		CloseHandle(trace);
		return false;
	}
	TR_GetEndPosition(tmpVec, trace);
	CloseHandle(trace);
	new Float:traceDistance = GetVectorDistance(firingPoint, tmpVec, true);
	if (traceDistance < distance) // we hit a wall.
		return false;
		
	// all tests passed. this is our new best target!
	nearestValidTarget = targetEntity;
	nvtOrigin[0] = targetOrigin[0];
	nvtOrigin[1] = targetOrigin[1];
	nvtOrigin[2] = targetOrigin[2];
	nvtAngles[0] = pointToTargetAngles[0];
	nvtAngles[1] = pointToTargetAngles[1];
	nvtAngles[2] = pointToTargetAngles[2];
	nvtDistance = distance;
	
	return true;
}
 
//new bool:m_positionTest;
public FireTurretProjectiles(turretEntity, turretIdx, dirs, type, bossEntity, Float:damage, Float:speedFactor, reskinModelIdx)
{
	decl Float:firingPoint[3];
	decl Float:firingAngles[3];
	decl Float:pivotOrigin[3];
	decl Float:pivotAngles[3];
	decl Float:offset[3];
	
	GetEntPropVector(turretEntity, Prop_Data, "m_vecOrigin", pivotOrigin);
	GetEntPropVector(turretEntity, Prop_Data, "m_angRotation", pivotAngles);
	
	// detected a player in line of sight?
	new bool:motionSensorSuccess = false;
	
	for (new i = 0; i < MAX_TURRET_FIRING_POINTS; i++)
	{
		// weed out invalid directions
		if (dirs == 1 && i > TURRET_FIRE_FRONT)
			continue;
		else if (dirs == 2 && i > TURRET_FIRE_BACK)
			continue;
		else if (dirs == 3 && i == TURRET_FIRE_BACK)
			continue;
	
		// for all that I copied from the source SDK, I figured out how to alter the angles myself. :P
		// gimme a cookie.
		if (i == TURRET_FIRE_FRONT)
		{
			offset[0] = PT_TurretFireFront[turretIdx][0];
			offset[1] = PT_TurretFireFront[turretIdx][1];
			offset[2] = PT_TurretFireFront[turretIdx][2];
			firingAngles[0] = pivotAngles[0];
			firingAngles[1] = pivotAngles[1];
			firingAngles[2] = pivotAngles[2];
		}
		else if (i == TURRET_FIRE_RIGHT)
		{
			offset[0] = PT_TurretFireRight[turretIdx][0];
			offset[1] = PT_TurretFireRight[turretIdx][1];
			offset[2] = PT_TurretFireRight[turretIdx][2];
			firingAngles[0] = pivotAngles[2];
			firingAngles[1] = fixAngle(pivotAngles[1] - 90.0);
			firingAngles[2] = pivotAngles[0];
		}
		else if (i == TURRET_FIRE_BACK)
		{
			offset[0] = PT_TurretFireBack[turretIdx][0];
			offset[1] = PT_TurretFireBack[turretIdx][1];
			offset[2] = PT_TurretFireBack[turretIdx][2];
			firingAngles[0] = -pivotAngles[0];
			firingAngles[1] = fixAngle(pivotAngles[1] - 180.0);
			firingAngles[2] = -pivotAngles[2];
		}
		else if (i == TURRET_FIRE_LEFT)
		{
			offset[0] = PT_TurretFireLeft[turretIdx][0];
			offset[1] = PT_TurretFireLeft[turretIdx][1];
			offset[2] = PT_TurretFireLeft[turretIdx][2];
			firingAngles[0] = -pivotAngles[2];
			firingAngles[1] = fixAngle(pivotAngles[1] - 270.0);
			firingAngles[2] = -pivotAngles[0];
		}
		
		VectorRotate(offset, pivotAngles, firingPoint);
		AddVectors(pivotOrigin, firingPoint, firingPoint);
		
		// motion detection, if applicable
		if (PT_MotionSensor[turretIdx] == MOTION_SENSOR_RAY)
		{
			// just a simple trace ray
			tracePlayersSuccess = false;
			new Handle:trace = TR_TraceRayFilterEx(firingPoint, firingAngles, PT_TRACEMASK, RayType_Infinite, TracePlayersAndBuildings);
			CloseHandle(trace);
			
			if (!tracePlayersSuccess)
				continue;
			motionSensorSuccess = true;
		}
		else if (PT_MotionSensor[turretIdx] == MOTION_SENSOR_ARC)
		{
			// efficiency
			new Float:maxDistanceSquared = PT_MotionSensorMaxDistance[turretIdx] * PT_MotionSensorMaxDistance[turretIdx];
		
			// as we go through, gotta find the nearest valid target
			new nearestValidTarget = -1; // entity
			new Float:nvtOrigin[3]; // coords
			new Float:nvtAngles[3]; // new firing angle
			new Float:nvtDistance = maxDistanceSquared; // distance (squared)
		
			// got to go through every enemy client
			for (new client = 1; client < MAX_PLAYERS; client++)
			{
				if (!IsClientInGame(client) || !IsPlayerAlive(client))
					continue;
				
				// comment this out if you want to more easily verify angle's working, but ideally the boss shouldn't trigger this
				if (GetClientTeam(client) == BossTeam)
					continue;
					
				// ensure the potential target is not cloaked or invis. I don't think any of these cover the halloween invis, though...can't test that.
				if (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Stealthed) || TF2_IsPlayerInCondition(client, TFCond_HalloweenGhostMode))
					continue;
				
				CheckArcTurretTarget(client, firingPoint, firingAngles, PT_MotionSensorAngleDeviation[turretIdx], nearestValidTarget, nvtOrigin, nvtAngles, nvtDistance);
			}
			
			// and every sentry...
			new building = MAX_PLAYERS;
			while ((building = FindEntityByClassname(building, "obj_sentrygun")) != -1)
				CheckArcTurretTarget(building, firingPoint, firingAngles, PT_MotionSensorAngleDeviation[turretIdx], nearestValidTarget, nvtOrigin, nvtAngles, nvtDistance);
			
			// and every dispenser...
			building = MAX_PLAYERS;
			while ((building = FindEntityByClassname(building, "obj_dispenser")) != -1)
				CheckArcTurretTarget(building, firingPoint, firingAngles, PT_MotionSensorAngleDeviation[turretIdx], nearestValidTarget, nvtOrigin, nvtAngles, nvtDistance);
			
			// and every teleporter...
			building = MAX_PLAYERS;
			while ((building = FindEntityByClassname(building, "obj_teleporter")) != -1)
				CheckArcTurretTarget(building, firingPoint, firingAngles, PT_MotionSensorAngleDeviation[turretIdx], nearestValidTarget, nvtOrigin, nvtAngles, nvtDistance);
				
			// no potential target, at least not for this side of the turret
			if (nearestValidTarget == -1)
				continue;
				
			// target found. all necessary now is to change the firing angles and signal success
			firingAngles[0] = nvtAngles[0];
			firingAngles[1] = nvtAngles[1];
			firingAngles[2] = nvtAngles[2];
			motionSensorSuccess = true;
		}
		
		//PrintToServer("fireAt=%f,%f,%f  origin=%f,%f,%f  angles=%f,%f,%f", firingPoint[0], firingPoint[1], firingPoint[2], pivotOrigin[0], pivotOrigin[1], pivotOrigin[2], pivotAngles[0], pivotAngles[1], pivotAngles[2]);
		
		FireTurretProjectile(turretEntity, firingPoint, firingAngles, type, bossEntity, damage, speedFactor, reskinModelIdx);
	}
	
	// if no target found, try again next frame
	if (PT_MotionSensor[turretIdx] > 0 && !motionSensorSuccess)
		PT_TurretFireAt[turretIdx] = GetEngineTime();
}

// credit to Asherkin and voogru for much of this (rockets particularly)
public FireTurretProjectile(turretEntity, Float:vPosition[3], Float:vAngles[3], type, bossEntity, Float:damageFactor, Float:speedFactor, reskinModelIdx)
{
	new Float:speed;
	new Float:damage;
	new String:classname[MAX_ENTITY_CLASSNAME_LENGTH] = "";
	new String:entname[MAX_ENTITY_CLASSNAME_LENGTH] = "";
	
	if (type == TURRET_TYPE_ROCKET)
	{
		speed = 1100.0 * speedFactor;
		//damage = 90 * damageFactor;
		damage = damageFactor;
		classname = "CTFProjectile_Rocket";
		entname = "tf_projectile_rocket";
	}
	else if (type == TURRET_TYPE_GRENADE || type == TURRET_TYPE_LOOSE_CANNON)
	{
		speed = 1215.0 * speedFactor;
		//damage = 103 * damageFactor;
		damage = damageFactor;
		classname = "CTFGrenadePipebombProjectile";
		entname = "tf_projectile_pipe";
	}
	else if (type == TURRET_TYPE_ARROW)
	{
		//speed = 1875.0 * speedFactor;
		speed = 1475.0 * speedFactor;
		damage = 120 * damageFactor;
		classname = "CTFProjectile_Arrow";
		entname = "tf_projectile_arrow";
	}
	else
	{
		PrintToServer("[projectile_turret] Invalid projectile specified. Blame sarysa for this. Not firing.");
		return -1;
	}

	new projectileEntity = CreateEntityByName(entname);
	
	if (!IsValidEntity(projectileEntity))
	{
		PrintToServer("[projectile_turret] Error: Invalid entity %s. Won't spawn projectile.", entname);
		return -1;
	}
	
	decl Float:vVelocity[3];
	decl Float:vBuffer[3];
	
	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
	
	vVelocity[0] = vBuffer[0] * speed;
	vVelocity[1] = vBuffer[1] * speed;
	vVelocity[2] = vBuffer[2] * speed;
	
	// give arrow a hard 50 extra z-lift to counter gravity slightly
	if (type == TURRET_TYPE_ARROW)
		vVelocity[2] += 50.0;
		
	// give grenades an extra 75, cause without this they'll hit nothing...
	if (type == TURRET_TYPE_GRENADE || type == TURRET_TYPE_LOOSE_CANNON)
		vVelocity[2] += 75.0;
	
	// grenades have to be moved AFTER they spawn into the world, here's why.
	// CPhysicsCannister::CannisterActivate in the TF2 code
	// properties of all physics cannisters (i.e. grenade, loose cannon, etc) are determined after spawn
	// and are somewhat linked to some weapon. since this grenade's being spawned on the fly and has no weapon
	// it just chooses the default physics cannister (grenade) but with no weapon with properties to draw from
	// the projectile's velocity defaults to 0.
	if (type == TURRET_TYPE_GRENADE || type == TURRET_TYPE_LOOSE_CANNON)
	{
		TeleportEntity(projectileEntity, vPosition, vAngles, NULL_VECTOR);
		if (type == TURRET_TYPE_LOOSE_CANNON)
			SetEntProp(projectileEntity, Prop_Send, "m_iType", 3); // type 0 is grenade, type 3 is loose cannon. 1 is probably sticky and 2 is probably scottish resistance.
	}
	else
		TeleportEntity(projectileEntity, vPosition, vAngles, vVelocity);
	
	//PrintToServer("spawning projectile. pos=%f,%f,%f  angles=%f,%f,%f  velocity=%f,%f,%f", vPosition[0], vPosition[1], vPosition[2], vAngles[0], vAngles[1], vAngles[2], vVelocity[0], vVelocity[1], vVelocity[2]);
	
	SetEntProp(projectileEntity, Prop_Send, "m_bCritical", false); // I have no idea if this overrides random crits. I hope it does. (later note: it appears to)

	// only grenade has a simple convenient netprop to set
	if (type == TURRET_TYPE_GRENADE || type == TURRET_TYPE_LOOSE_CANNON)
		SetEntPropFloat(projectileEntity, Prop_Send, "m_flDamage", damage);
	else if (type == TURRET_TYPE_ARROW)
	{
		// TODO, fix this mess. arrow's a train wreck at the moment
		SetEntDataFloat(projectileEntity, FindSendPropOffs(classname, "m_iDeflected") + 4, damage, true);
		SetEntProp(projectileEntity, Prop_Send, "m_nHitboxSet", 1);
		//SetEntPropFloat(projectileEntity, Prop_Send, "m_flDamage", damage);
		//SetEntProp(projectileEntity, Prop_Send, "m_iDamage", 100);//damage);
	}
	else if (type == TURRET_TYPE_ROCKET)
	{
		// Credit to voogru
		// sarysa's additional comments: THIS is how you change damage? Geez...and I can't even find m_iDeflected in the source SDK.
		// guess it's TF2 specific. Now -that- is hacking. ;P well done.
		// update to comment above, guess I really should rely more on my netprops dump than staring at the 2013 source SDK :P
		// though said SDK -does- have a few nifty props, with comments explaining them!
		// p.s. still great hackin', takes a lot of experimentation to find a hidden netprop!
		// p.p.s. seems that arrow derived from similar classes as rocket, so offset is same
		SetEntDataFloat(projectileEntity, FindSendPropOffs(classname, "m_iDeflected") + 4, damage, true);
	}
	
	SetEntProp(projectileEntity, Prop_Send, "m_nSkin", 1); // set skin to blue team's
	
	SetEntPropEnt(projectileEntity, Prop_Send, "m_hOwnerEntity", bossEntity);
	
	SetVariantInt(BossTeam);
	AcceptEntityInput(projectileEntity, "TeamNum", -1, -1, 0);

	SetVariantInt(BossTeam);
	AcceptEntityInput(projectileEntity, "SetTeam", -1, -1, 0); 
	
	DispatchSpawn(projectileEntity);
	
	// must reskin after spawn
	if (reskinModelIdx != -1)
	{
		// so much easier to mess with the model when you're just spawning the thing. I think.
		SetEntProp(projectileEntity, Prop_Send, "m_nModelIndex", reskinModelIdx);
		
		// todo, maybe get rid of effect?
		// however I've tried m_hEffectEntity, m_nRenderFX, and m_nRenderMode to no avail. so for now, I'll leave it as is.
	}
	
	// grenade must be moved after it spawns
	if (type == TURRET_TYPE_GRENADE || type == TURRET_TYPE_LOOSE_CANNON)
		TeleportEntity(projectileEntity, vPosition, vAngles, vVelocity);
	else if (type == TURRET_TYPE_ARROW)
	{
		// need to create its trail manually, modified from alongub's code for player trails
		new arrowTrail = CreateEntityByName("env_spritetrail");

		if (IsValidEntity(arrowTrail)) 
		{
			DispatchKeyValueFloat(arrowTrail, "lifetime", 0.03);
			DispatchKeyValueFloat(arrowTrail, "endwidth", 1.0);
			DispatchKeyValueFloat(arrowTrail, "startwidth", 1.0);
			DispatchKeyValue(arrowTrail, "spritename", "materials/effects/arrowtrail_blu.vmt");
			DispatchKeyValue(arrowTrail, "renderamt", "255");
			DispatchKeyValue(arrowTrail, "rendermode", "5");
			DispatchSpawn(arrowTrail);

			// set to same position and angles as the arrow
			TeleportEntity(arrowTrail, vPosition, vAngles, NULL_VECTOR);

			// attach it to the arrow
			SetEntPropEnt(arrowTrail, Prop_Send, "m_hAttachedToEntity", projectileEntity);
			//SetEntPropEnt(arrowTrail, Prop_Send, "m_hOwnerEntity", projectileEntity);
			SetEntPropEnt(projectileEntity, Prop_Send, "m_hEffectEntity", arrowTrail);
		}
		else if (PRINT_DEBUG_INFO)
			PrintToServer("[projectile_turret] WARNING: Could not create arrow trail.");
	}
	
	// play the firing sound
	if (strlen(PTA_FireSound[bossEntity]) > 3)
		EmitAmbientSound(PTA_FireSound[bossEntity], vPosition, turretEntity);
		
	// display the firing graphic TODO
	//new String:PTA_FireGraphic[MAX_PLAYERS_ARRAY][MAX_EFFECT_NAME_LENGTH];
	
	return projectileEntity;
}

/**
 * Best to use OnGameFrame() for the turrets.
 */
public OnGameFrame()
{
	// front_spawner, back_spawner, left_spawner, right_spawner
	// cycle through all the turrets
	if (PT_ActiveThisRound)
	{
		new Float:curTime = GetEngineTime();
		
		// any turrets pending spawn?
		if (curTime >= PTH_RetryAt)
		{
			new totalRemaining = 0;
			for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
			{
				if (!IsLivingPlayer(clientIdx) || GetClientTeam(clientIdx) != BossTeam)
					continue;
				else if (PTH_NumTurretsToRetry[clientIdx] <= 0)
					continue;
					
				new bossIdx = FF2_GetBossIndex(clientIdx);
				if (bossIdx < 0)
					continue;

				new result = DoDropTurret(bossIdx);
				if (!ShouldRetryDropTurret(result))
					PTH_NumTurretsToRetry[clientIdx]--;
				
				totalRemaining += PTH_NumTurretsToRetry[clientIdx];
			}
			
			if (totalRemaining <= 0)
				PTH_RetryAt = FAR_FUTURE;
			else
				PTH_RetryAt = curTime + PTH_RETRY_INTERVAL;
		}
	
		for (new i = 0; i < MAX_TURRETS; i++)
		{
			// skip invalid turrets
			if (!PT_TurretValid[i])
				continue;
				
			// ensure entity hasn't been destroyed
			new turret = EntRefToEntIndex(PT_TurretEntityRef[i]);
			if (turret == -1)
			{
				PT_TurretValid[i] = false;
				continue;
			}
			
			// ensure entity isn't about to be destroyed (it is PROBABLY instantaneous but need to be sure)
			if (GetEntProp(turret, Prop_Data, "m_iHealth") <= 0)
			{
				PT_TurretValid[i] = false;
				continue;
			}
			
			// ensure the turret hasn't reached its preset lifespan
			if (curTime >= PT_TurretDieAt[i])
			{
				AcceptEntityInput(turret, "kill");
				PT_TurretValid[i] = false;
				continue;
			}
			
			// ensure the owner is in game
			new clientIdx = PT_TurretOwner[i];
			if (!IsClientInGame(clientIdx))
			{
				AcceptEntityInput(turret, "kill");
				PT_TurretValid[i] = false;
				continue;
			}
			
			// ensure that owner is alive, if that's a condition
			if (PT_DieWithOwner[i] && !IsPlayerAlive(clientIdx))
			{
				AcceptEntityInput(turret, "kill");
				PT_TurretValid[i] = false;
				continue;
			}
			
			// skip decoys
			if (PT_TurretType[i] == TURRET_TYPE_INACTIVE)
				continue;
				
			// is it time to freeze the turret?
			if (curTime >= PT_FreezeTurretAt[i])
			{
				PT_FreezeTurretAt[i] = FAR_FUTURE;
				SetEntityMoveType(turret, MOVETYPE_NONE);
				SetEntProp(turret, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_NONE);
				//SetEntProp(turret, Prop_Send, "m_usSolidFlags", 4); // not solid
				//SetEntProp(turret, Prop_Send, "m_nSolidType", 0); // not solid
			}
				
			// is it time to display the beacon?
			new Float:turretOrigin[3];
			GetEntPropVector(turret, Prop_Send, "m_vecOrigin", turretOrigin);
			if (PT_NextBeaconAt[i] <= curTime && PTA_Beacon[clientIdx])
			{
				// ripped straight from RTD beacon, since it's the kind everyone's familiar with already
				new Float:beaconPos[3];
				beaconPos[0] = turretOrigin[0];
				beaconPos[1] = turretOrigin[1];
				beaconPos[2] = turretOrigin[2] + 10.0;

				TE_SetupBeamRingPoint(beaconPos, 10.0, 200.0, BEACON_BEAM, BEACON_HALO, 0, 15, 0.5, 5.0, 0.0, {128,128,128,255}, 10, 0);
				TE_SendToAll();
				TE_SetupBeamRingPoint(beaconPos, 10.0, 200.0, BEACON_BEAM, BEACON_HALO, 0, 10, 0.6, 10.0, 0.5, {75,75,255,255}, 10, 0);
				TE_SendToAll();

				if (strlen(PTA_BeaconSound[clientIdx]) > 3)
				{
					EmitSoundToAll(PTA_BeaconSound[clientIdx], turret);
					EmitSoundToAll(PTA_BeaconSound[clientIdx], turret);
					EmitSoundToAll(PTA_BeaconSound[clientIdx], turret);
				}

				PT_NextBeaconAt[i] = curTime + PTA_BeaconDelay[clientIdx];
			}

			// now see if we can fire
			if (curTime < PT_TurretFireAt[i])
				continue; // note: motion sensor is detected later, and will fudge with the firing time if necessary.
				
			// increment timer for next shot
			PT_TurretFireAt[i] += PT_TurretFireRate[i];
			
			// fire!
			FireTurretProjectiles(turret, i, PT_TurretDirs[i], PT_TurretType[i], PT_TurretOwner[i], PT_TurretDPS[i], PT_TurretSpeedFactor[i], PT_TurretProjectileSkin[i]);
		}
	}
}

/**
 * Various reusable helper methods
 */
stock CopyVector(Float:dst[3], Float:src[3])
{
	dst[0] = src[0];
	dst[1] = src[1];
	dst[2] = src[2];
}

stock DistanceConstrain(Float:startPoint[3], Float:endPoint[3], Float:targetVector[3], Float:distanceMax)
{
	new Float:constraintFactor = 1.0;
	new Float:diffs[3];
	diffs[0] = fabs(startPoint[0] - endPoint[0]);
	diffs[1] = fabs(startPoint[1] - endPoint[1]);
	diffs[2] = fabs(startPoint[2] - endPoint[2]);
	if (diffs[0] > diffs[1] && diffs[0] > diffs[2])
		constraintFactor = diffs[0] > distanceMax ? (distanceMax / diffs[0]) : 1.0;
	else if (diffs[1] > diffs[0] && diffs[1] > diffs[2])
		constraintFactor = diffs[1] > distanceMax ? (distanceMax / diffs[1]) : 1.0;
	else if (diffs[2] > diffs[1] && diffs[2] > diffs[0])
		constraintFactor = diffs[2] > distanceMax ? (distanceMax / diffs[2]) : 1.0;
		
	targetVector[0] = startPoint[0] + ((endPoint[0] - startPoint[0]) * constraintFactor);
	targetVector[1] = startPoint[1] + ((endPoint[1] - startPoint[1]) * constraintFactor);
	targetVector[2] = startPoint[2] + ((endPoint[2] - startPoint[2]) * constraintFactor);
}

/**
 * Taken from default_abilities
 */
public Action:RemoveEntity(Handle:timer, any:entid)
{
	RemoveEntityNoRef(EntRefToEntIndex(entid));
}

public RemoveEntityNoRef(any:entity)
{
	if (IsValidEdict(entity) && entity > MaxClients)
	{
		AcceptEntityInput(entity, "Kill");
	}
}

stock AttachParticle(entity, String:particleType[], Float:offset=0.0, bool:attach=true)
{
	new particle = CreateEntityByName("info_particle_system");

	if (!IsValidEntity(particle))
		return -1;
		
	decl String:targetName[128];
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2] += offset;
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if (attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
}

stock ParticleEffectAt(Float:position[3], String:effectName[], Float:duration = 0.0)
{
	if (strlen(effectName) < 3)
		return -1; // nothing to display
		
	new particle = CreateEntityByName("info_particle_system");
	if (particle != -1)
	{
		TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "effect_name", effectName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if (duration > 0.0)
			CreateTimer(duration, RemoveEntity, EntIndexToEntRef(particle), TIMER_FLAG_NO_MAPCHANGE);
	}
	return particle;
}

/**
 * Various stocks
 */
// assumes you've only performed one operation on it that could take it out of range
// don't pass in stuff anything abs(x)>=480.0
public Float:fixAngle(Float:angle)
{
	new sanity = 0;
	while (angle < -180.0 && (sanity++) <= 10)
		angle = angle + 360.0;
	while (angle > 180.0 && (sanity++) <= 10)
		angle = angle - 360.0;
		
	return angle;
}

stock Float:fabs(Float:x)
{
	return x < 0.0 ? -x : x;
}

public bool:TraceWallsOnly(entity, contentsMask)
{
	return false;
}

stock ReadSound(bossIdx, const String:ability_name[], argInt, String:soundFile[MAX_SOUND_FILE_LENGTH])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, soundFile, MAX_SOUND_FILE_LENGTH);
	if (strlen(soundFile) > 3)
		PrecacheSound(soundFile);
}

stock ReadModel(bossIdx, const String:ability_name[], argInt, String:modelFile[MAX_MODEL_FILE_LENGTH])
{
	FF2_GetAbilityArgumentString(bossIdx, this_plugin_name, ability_name, argInt, modelFile, MAX_MODEL_FILE_LENGTH);
	if (strlen(modelFile) > 3)
		PrecacheModel(modelFile);
}

/**
 * 3D VECTOR ROTATION
 *
 * Which I stole from the deepest layers of the Source SDK code.
 * This little excursion made me feel like a complete scrub. :P
 */
#define PITCH 0
#define YAW 1
#define ROLL 2
 
stock Float:DEG2RAD(Float:n) { return n * 0.017453; }

stock Float:DotProduct(Float:v1[3], Float:v2[4])
{
	return v1[0]*v2[0] + v1[1]*v2[1] + v1[2]*v2[2];
}

// don't call this directly, call the one with two params
stock VectorRotate2( Float:in1[3], Float:in2[3][4], Float:out[3] )
{
	out[0] = DotProduct( in1, in2[0] );
	out[1] = DotProduct( in1, in2[1] );
	out[2] = DotProduct( in1, in2[2] );
}

stock AngleMatrix(Float:angles[3], Float:matrix[3][4])
{
	new Float:sr, Float:sp, Float:sy, Float:cr, Float:cp, Float:cy;

	//SinCos( DEG2RAD( angles[YAW] ), &sy, &cy );
	//SinCos( DEG2RAD( angles[PITCH] ), &sp, &cp );
	//SinCos( DEG2RAD( angles[ROLL] ), &sr, &cr );
	sy = Sine(DEG2RAD(angles[YAW]));
	cy = Cosine(DEG2RAD(angles[YAW]));
	sp = Sine(DEG2RAD(angles[PITCH]));
	cp = Cosine(DEG2RAD(angles[PITCH]));
	sr = Sine(DEG2RAD(angles[ROLL]));
	cr = Cosine(DEG2RAD(angles[ROLL]));

	// matrix = (YAW * PITCH) * ROLL
	matrix[0][0] = cp*cy;
	matrix[1][0] = cp*sy;
	matrix[2][0] = -sp;

	new Float:crcy = cr*cy;
	new Float:crsy = cr*sy;
	new Float:srcy = sr*cy;
	new Float:srsy = sr*sy;
	matrix[0][1] = sp*srcy-crsy;
	matrix[1][1] = sp*srsy+crcy;
	matrix[2][1] = sr*cp;

	matrix[0][2] = (sp*crcy+srsy);
	matrix[1][2] = (sp*crsy-srcy);
	matrix[2][2] = cr*cp;

	matrix[0][3] = 0.0;
	matrix[1][3] = 0.0;
	matrix[2][3] = 0.0;
}

//void VectorRotate( const Vector &in1, const QAngle &in2, Vector &out )
stock VectorRotate(Float:inPoint[3], Float:angles[3], Float:outPoint[3])
{
	new Float:matRotate[3][4];
	AngleMatrix(angles, matRotate);
	VectorRotate2(inPoint, matRotate, outPoint);
}

stock bool:IsLivingPlayer(clientIdx)
{
	if (clientIdx <= 0 || clientIdx >= MAX_PLAYERS)
		return false;
		
	return IsClientInGame(clientIdx) && IsPlayerAlive(clientIdx);
}

stock bool:IsValidBoss(clientIdx)
{
	if (!IsLivingPlayer(clientIdx))
		return false;
		
	return GetClientTeam(clientIdx) == BossTeam;
}

stock Float:RandomNegative(Float:val)
{
	return val * (GetRandomInt(0, 1) == 1 ? 1.0 : -1.0);
}

stock Float:fmax(Float:x1, Float:x2)
{
	return x1 > x2 ? x1 : x2;
}

stock FindNearestLivingPlayer(playerToSpawnTurretAround, bool:exclude[MAX_PLAYERS_ARRAY])
{
	if (!IsLivingPlayer(playerToSpawnTurretAround))
		return -1;
		
	new Float:playerOrigin[3];
	new Float:testOrigin[3];
	new bestPlayer = -1;
	new Float:bestDistance = 99999.0;
	GetEntPropVector(playerToSpawnTurretAround, Prop_Send, "m_vecOrigin", playerOrigin);

	for (new clientIdx = 1; clientIdx < MAX_PLAYERS; clientIdx++)
	{
		if (!IsLivingPlayer(clientIdx) || exclude[clientIdx])
			continue;
			
		GetEntPropVector(clientIdx, Prop_Send, "m_vecOrigin", testOrigin);
		new Float:distance = GetVectorDistance(playerOrigin, testOrigin);
		if (distance < bestDistance)
		{
			bestPlayer = clientIdx;
			bestDistance = distance;
		}
	}
	
	if (bestPlayer != -1)
		exclude[bestPlayer] = true;
	
	return bestPlayer;
}
