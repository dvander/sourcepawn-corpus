/**
* Projectiles Fix by Root
*
* Description:
*   Simply fixes projectiles not flying through team mates in Team Fortress 2.
*
* Version 1.0.0
* Changelog & more info at http://goo.gl/4nKhJ
*/

#pragma semicolon 1

// ====[ INCLUDES ]================================================
#include <sdkhooks>
#include <sdktools_trace>
#undef REQUIRE_PLUGIN
#include <updater>

// ====[ CONSTANTS ]===============================================
#define PLUGIN_NAME    "[TF2] Projectiles Fix"
#define PLUGIN_VERSION "1.0.0"

#define UPDATE_URL     "https://raw.github.com/zadroot/TF2_ProjectilesFix/master/updater.txt"
#define GetTeam(%1)    (GetEntProp(%1, Prop_Send, "m_iTeamNum"))

enum
{
	arrow,           // 24
	//ball_ornament, // 13 // Other than 24 are not (yet) supported
	//cleaver,       // 20
	energy_ball,     // 24
	energy_ring,     // 24
	flare,           // 24
	//healing_bolt,  // 24  // Pointless and not working anyways
	//jar,           // 20
	//jar_milk,      // 20
	//pipe,          // 20
	//pipe_remote,   // 20
	rocket,          // 24
	sentryrocket     // 24
	//stun_ball,     // 13
	//syringe,       // 13
	//throwable      // 20?
}

static const String:tf_projectiles[][] =
{
	"arrow",
	//"ball_ornament",
	//"cleaver",
	"energy_ball",
	"energy_ring",
	"flare",
	//"healing_bolt",
	//"jar",
	//"jar_milk",
	//"pipe",
	//"pipe_remote",
	"rocket",
	"sentryrocket"
	//"stun_ball",
	//"syringe",
	//"throwable"
};

// ====[ VARIABLES ]===============================================
new	Handle:ProjectilesTrie,
	m_vecOrigin,      // origin of a projectile
	m_vecAbsOrigin,   // abs origin of a projectile
	m_CollisionGroup; // to set collision group

// ====[ PLUGIN ]==================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Simply fixes projectiles not flying through team mates",
	version     = PLUGIN_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=221955"
};


/* OnPluginStart()
 *
 * When the plugin starts up.
 * ---------------------------------------------------------------- */
public OnPluginStart()
{
	// Create Version ConVar
	CreateConVar("tf_projectiles_fix_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Register ConVars. But I dont want to use global handles!
	decl Handle:Registar, String:cvarname[32];

	// Create trie with projectile names and the keys
	ProjectilesTrie = CreateTrie();

	// Format a name of the ConVar
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[arrow]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow arrow to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[arrow], arrow);

	/* Not yet supported
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[ball_ornament]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow ball ornament to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[ball_ornament], ball_ornament);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[cleaver]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow cleaver to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[cleaver], cleaver);
	*/

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[energy_ball]);

	// Register ConVar and hook changes immediate
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow energy ball to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[energy_ball], energy_ball);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[energy_ring]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow energy ring to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);

	// Also set appropriate value in trie
	SetTrieValue(ProjectilesTrie, tf_projectiles[energy_ring], energy_ring);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[flare]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow flare to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[flare], flare);

	/*
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[healing_bolt]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow crossbow bolt to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[healing_bolt], healing_bolt);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[jar]);
	HookConVarChange((Registar = CreateConVar(cvarname, "0", "Allow jarate to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[jar], jar);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[jar_milk]);
	HookConVarChange((Registar = CreateConVar(cvarname, "0", "Allow mad milk to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[jar_milk], jar_milk);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[pipe]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow pipebomb projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[pipe], pipe);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[pipe_remote]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow sticky projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[pipe_remote], pipe_remote);
	*/

	// I call this 'KyleS StylE', and that's good because you dont need to always retrieve ConVar handle
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[rocket]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow rocket projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[rocket], rocket);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[sentryrocket]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow sentry rocket projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);

	// It saves memory much when many CVars are created, and its very important in our case when OnEntityCreated() forward is used
	SetTrieValue(ProjectilesTrie, tf_projectiles[sentryrocket], sentryrocket);

	/*
	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[stun_ball]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow stun ball to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[stun_ball], stun_ball);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[syringe]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow syringe to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[syringe], syringe);

	FormatEx(cvarname, sizeof(cvarname), "sm_fix_%s", tf_projectiles[throwable]);
	HookConVarChange((Registar = CreateConVar(cvarname, "1", "Allow throwable projectile to fly through team mates?", FCVAR_PLUGIN, true, 0.0, true, 1.0)), OnConVarChange);
	SetTrieValue(ProjectilesTrie, tf_projectiles[throwable], throwable);
	*/

	// Add CVars into config
	AutoExecConfig(true, "tf_projectiles_fix");

	// I HATE Handles (c) KyleS
	CloseHandle(Registar);

	// Find a networkable send property offset for projectiles collision
	if ((m_CollisionGroup = FindSendPropOffs("CBaseEntity", "m_CollisionGroup")) == -1)
	{
		SetFailState("Fatal Error: Unable to find property offset: \"CBaseEntity::m_CollisionGroup\" !");
	}
}

/* OnConVarChange()
 *
 * Called when ConVar value has changed.
 * ---------------------------------------------------------------- */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Declare new and old keys from trie and the cvar name
	decl oldNum, newNum, i, String:cvarName[32];

	// This callback will not automatically hook changes for every single CVar, so we have to check which CVar value has changed via name
	GetConVarName(convar, cvarName, sizeof(cvarName));

	// Skip the first 7 characters in name string to avoid comparing with the "sm_fix_"
	GetTrieValue(ProjectilesTrie, cvarName[7], oldNum);

	for (i = 0; i < sizeof(tf_projectiles); i++)
	{
		// If cvarname is equal to any which is in projectiles trie,
		if (StrEqual(cvarName[7], tf_projectiles[i]))
		{
			// Assign new trie value and break the loop
			newNum = i;
			break;
		}
	}

	// Value is bool
	switch (StringToInt(newValue))
	{
		case false: RemoveFromTrie(ProjectilesTrie, tf_projectiles[oldNum]);  // Remove a key from projectiles trie
		case true: SetTrieValue(ProjectilesTrie, cvarName[7], newNum, false); // Register new key, but dont overwrite previous one on match
	}
}

/* OnEntityCreated()
 *
 * When an entity is created.
 * ---------------------------------------------------------------- */
public OnEntityCreated(entity, const String:classname[])
{
	decl projectile;

	// Skip the first 14 characters in classname string to avoid comparing with the "tf_projectile_" prefix (optimizations)
	if (GetTrieValue(ProjectilesTrie, classname[14], projectile))
	{
		// If I'd use not Post hook (with new collision group), plugin would never detect when projectile collides with a players
		SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawned);
	}
}

/* OnProjectileSpawned()
 *
 * When a projectile successfully spawned.
 * ---------------------------------------------------------------- */
public OnProjectileSpawned(projectile)
{
	// Find datamap property offset for m_vecOrigin to define starting position for trace
	if (!m_vecOrigin && (m_vecOrigin = FindDataMapOffs(projectile, "m_vecOrigin")) == -1)
	{
		LogError("Error: Unable to find datamap offset: \"m_vecOrigin\" !");
		return;
	}

	// Find datamap property offset for m_vecAbsOrigin to define direction angle for trace
	if (!m_vecAbsOrigin && (m_vecAbsOrigin = FindDataMapOffs(projectile, "m_vecAbsOrigin")) == -1)
	{
		// If not found - just dont do anything and error out
		LogError("Error: Unable to find datamap offset: \"m_vecAbsOrigin\" !");
		return;
	}

	// Set the collision group for created projectile depends on own group
	switch (GetEntData(projectile, m_CollisionGroup))
	{
		//case 20: // CG for cleaver, jars, pipe bombs and probably throwable ?
		case 24: SetEntData(projectile, m_CollisionGroup, 3, 4, true); // CG for or arrows, flares, rockets and unused crossbow bolt
		//default: // Real projectiles (such as syringes and scout ballz)
	}

	// Hook 'ShouldCollide' for this projectile
	SDKHook(projectile, SDKHook_ShouldCollide, OnProjectileCollide);
}

/* OnProjectileCollide()
 *
 * A ShouldCollide hook for given projectile.
 * ---------------------------------------------------------------- */
public bool:OnProjectileCollide(entity, collisiongroup, contentsmask, bool:result)
{
	// ShouldCollide called 66 times per second, but for projectiles only once when it hits player
	decl Float:vecPos[3], Float:vecAng[3], owner;

	GetEntDataVector(entity, m_vecOrigin,    vecPos);
	GetEntDataVector(entity, m_vecAbsOrigin, vecAng);

	// Get the rocket owner (it automatically detects deflector as well)
	owner = GetProjectileOwner(entity);

	// Create TraceRay to check whether or not projectiles goes through a valid player
	// TR(StartPos, DirectPos, player contentsmask, for infinite time and with filter (which includes owner index))
	TR_TraceRayFilter(vecPos, vecAng, MASK_PLAYERSOLID, RayType_Infinite, TraceFilter, owner);

	if (TR_DidHit())
	{
		// We hit something! Get the index
		new entidx = TR_GetEntityIndex();

		// Make sure player is valid and teams are different
		if (IsValidClient(entidx) && GetTeam(entidx) != GetTeam(entity))
		{
			// Retrieve the changed collision group for hit projectile
			switch (GetEntData(entity, m_CollisionGroup))
			{
				//case num: // Cleaver, jars, pipe bombs
				case 3: SetEntData(entity, m_CollisionGroup, 24, 4, true); // Use 3 for projectiles to prevent flying through buildings
				//default: // Syringes, scout ballz
			}
		}
	}
}

/* TraceFilter()
 *
 * Whether or not we should trace through 'this'.
 * ---------------------------------------------------------------- */
public bool:TraceFilter(this, contentsMask, any:client)
{
	// Both projectile and player should be valid and didnt hit itselfs
	if (IsValidEntity(this) && IsValidClient(client)
	&& this != client && GetTeam(this) == GetTeam(client))
	{
		return false;
	}

	return true;
}

/* GetProjectileOwner()
 *
 * Retrieves an 'owner' of projectile.
 * ---------------------------------------------------------------- */
GetProjectileOwner(entity)
{
	static offsetOwner;

	// Find the owner offset
	if (!offsetOwner && (offsetOwner = FindDataMapOffs(entity, "m_hOwnerEntity")) == -1)
	{
		// If datamap offset was not found - set owner as a world
		LogError("Error: Unable to find datamap offset: \"m_hOwnerEntity\" !");
		return 0;
	}

	// m_hOwnerEntity is always a player so we have to use GetEntDataEnt2
	return GetEntDataEnt2(entity, offsetOwner);
}

/* IsValidClient()
 *
 * Default 'valid client' check.
 * ---------------------------------------------------------------- */
bool:IsValidClient(client) return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) ? true : false;