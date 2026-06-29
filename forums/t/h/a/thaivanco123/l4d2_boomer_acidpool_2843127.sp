#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION		"1.1.0"
#define PLUGIN_NAME			"l4d2_boomer_acid_pools"

public Plugin myinfo =
{
	name        = "[L4D2] Boomer Vomit - Acid Pools",
	author      = "EliteBiker, JustMe",
	description = "Creates Spitter acid pools under vomited survivors",
	version     = PLUGIN_VERSION,
	url         = ""
}

// ====================================================================================================
//					CONSTANTS
// ====================================================================================================

#define CVAR_FLAGS			FCVAR_NOTIFY
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3
#define ZC_BOOMER			2

#define MAX_POOL_TRACK		64
#define POOL_MATCH_RADIUS	150.0

// Acid damage type values
#define ACID_DMG_NORMAL		263168	// regular tick
#define ACID_DMG_FADEOUT	265216	// tick while pool is fading out

// insect_swarm ticks ~2 times/second in L4D2
#define ACID_TICKS_PER_SEC	2.0

// ====================================================================================================
//					CVARS
// ====================================================================================================

ConVar g_hCvarMPGameMode;
ConVar g_hCvarAllow, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog;
ConVar g_hCvarMaxVomit, g_hCvarDamageDPS;

// ====================================================================================================
//					GLOBALS
// ====================================================================================================

bool  g_bCvarAllow;
bool  g_bMapStarted;
int   g_iCurrentMode;
int   g_iCvarMaxVomit;
float g_fCvarDamageDPS;		// damage per second; per-tick = DPS / ACID_TICKS_PER_SEC

int    g_iVomitCount[MAXPLAYERS + 1];
Handle g_hVomitReset[MAXPLAYERS + 1];

// Pool tracking
int    g_iOurPools[MAX_POOL_TRACK];
int    g_iPoolCount;

// Spawn position queue — stores coordinates before calling L4D2_SpitterPrj,
// used by OnEntityCreated to identify the insect_swarm being created
float  g_fSpawnQueue[MAX_POOL_TRACK][3];
int    g_iSpawnQueue;

// ====================================================================================================
//					PLUGIN START / END
// ====================================================================================================

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin supports L4D2 only.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar(			"l4d2_boomer_acid_version",			PLUGIN_VERSION,	"Plugin version.",																FCVAR_NOTIFY | FCVAR_DONTRECORD);
	g_hCvarAllow =		CreateConVar("l4d2_boomer_acid_allow",			"1",			"0=Plugin off, 1=Plugin on.",													CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarModes =		CreateConVar("l4d2_boomer_acid_modes",			"",				"Allowed game modes, comma-separated. Empty=all.",								CVAR_FLAGS);
	g_hCvarModesOff =	CreateConVar("l4d2_boomer_acid_modes_off",		"",				"Disabled game modes, comma-separated. Empty=none.",							CVAR_FLAGS);
	g_hCvarModesTog =	CreateConVar("l4d2_boomer_acid_modes_tog",		"0",			"Mode flags: 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add together.",	CVAR_FLAGS);
	g_hCvarMaxVomit =	CreateConVar("l4d2_boomer_acid_max_vomit",		"2",			"Max vomited survivors that spawn an acid pool per Boomer. 0=Unlimited.",		CVAR_FLAGS, true, 0.0);
	g_hCvarDamageDPS =	CreateConVar("l4d2_boomer_acid_damage_dps",		"1.0",			"Damage per second dealt by acid pools from this plugin. 0=Use game default.",	CVAR_FLAGS, true, 0.0);
	AutoExecConfig(true, PLUGIN_NAME);

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);

	GetCvars();
	g_hCvarMaxVomit.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarDamageDPS.AddChangeHook(ConVarChanged_Cvars);
}

public void OnPluginEnd()
{
	ResetPlugin();
}

// ====================================================================================================
//					CVARS
// ====================================================================================================

public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarMaxVomit  = g_hCvarMaxVomit.IntValue;
	g_fCvarDamageDPS = g_hCvarDamageDPS.FloatValue;
}

void IsAllowed()
{
	GetCvars();
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();

	if (g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true)
	{
		g_bCvarAllow = true;

		HookEvent("player_now_it", Event_PlayerNowIt);
		HookEvent("round_start",   Event_RoundStart,  EventHookMode_PostNoCopy);
	}
	else if (g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false))
	{
		g_bCvarAllow = false;

		UnhookEvent("player_now_it", Event_PlayerNowIt);
		UnhookEvent("round_start",   Event_RoundStart,  EventHookMode_PostNoCopy);
	}
}

bool IsAllowedGameMode()
{
	if (g_hCvarMPGameMode == null)
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if (iCvarModesTog != 0)
	{
		if (g_bMapStarted == false)
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if (IsValidEntity(entity))
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop",     OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus",   OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if (IsValidEntity(entity))
				RemoveEdict(entity);
		}

		if (g_iCurrentMode == 0)
			return false;

		if (!(iCvarModesTog & g_iCurrentMode))
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) == -1)
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if (sGameModes[0])
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if (StrContains(sGameModes, sGameMode, false) != -1)
			return false;
	}

	return true;
}

void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if      (strcmp(output, "OnCoop")     == 0) g_iCurrentMode = 1;
	else if (strcmp(output, "OnSurvival") == 0) g_iCurrentMode = 2;
	else if (strcmp(output, "OnVersus")   == 0) g_iCurrentMode = 4;
	else if (strcmp(output, "OnScavenge") == 0) g_iCurrentMode = 8;
}

// ====================================================================================================
//					MAP
// ====================================================================================================

public void OnMapStart()
{
	g_bMapStarted = true;
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin();
}

// ====================================================================================================
//					ENTITY CREATED
// ====================================================================================================

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!g_bCvarAllow)             return;
	if (g_fCvarDamageDPS == 0.0)   return;
	if (g_iSpawnQueue == 0)        return;
	if (strcmp(classname, "insect_swarm") != 0) return;

	SDKHook(entity, SDKHook_SpawnPost, OnInsectSwarmSpawnPost);
}

// SpawnPost: position of the insect_swarm
void OnInsectSwarmSpawnPost(int entity)
{
	float poolPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", poolPos);

	for (int i = 0; i < g_iSpawnQueue; i++)
	{
		if (GetVectorDistance(poolPos, g_fSpawnQueue[i]) > POOL_MATCH_RADIUS)
			continue;

		for (int j = i; j < g_iSpawnQueue - 1; j++)
		{
			g_fSpawnQueue[j][0] = g_fSpawnQueue[j + 1][0];
			g_fSpawnQueue[j][1] = g_fSpawnQueue[j + 1][1];
			g_fSpawnQueue[j][2] = g_fSpawnQueue[j + 1][2];
		}
		g_iSpawnQueue--;

		// Track pool
		CleanDeadPools();
		if (g_iPoolCount < MAX_POOL_TRACK)
		{
			g_iOurPools[g_iPoolCount++] = EntIndexToEntRef(entity);

			// Hook damage
			for (int c = 1; c <= MaxClients; c++)
			{
				if (IsValidSurvivor(c) && IsPlayerAlive(c))
					SDKHook(c, SDKHook_OnTakeDamageAlive, OnSurvivorTakeDamage);
			}
		}
		break;
	}
}

// ====================================================================================================
//					EVENTS
// ====================================================================================================

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
}

void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	int survivor = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (!IsValidSurvivor(survivor) || !IsValidBoomer(attacker))
		return;

	if (g_iCvarMaxVomit > 0 && g_iVomitCount[attacker] >= g_iCvarMaxVomit)
		return;

	g_iVomitCount[attacker]++;

	delete g_hVomitReset[attacker];
	g_hVomitReset[attacker] = CreateTimer(0.8, Timer_ResetVomitCount, GetClientUserId(attacker), TIMER_FLAG_NO_MAPCHANGE);

	float fDelay = 0.05 * float(g_iVomitCount[attacker]);

	DataPack pack;
	CreateDataTimer(fDelay, Timer_CreateSpit, pack, TIMER_FLAG_NO_MAPCHANGE);
	pack.WriteCell(GetClientUserId(survivor));
	pack.WriteCell(GetClientUserId(attacker));
}

// ====================================================================================================
//					TIMERS
// ====================================================================================================

Action Timer_ResetVomitCount(Handle timer, int userid)
{
	int boomer = GetClientOfUserId(userid);
	if (boomer > 0)
	{
		g_iVomitCount[boomer] = 0;
		g_hVomitReset[boomer] = null;
	}
	return Plugin_Stop;
}

Action Timer_CreateSpit(Handle timer, DataPack pack)
{
	pack.Reset();
	int survivor = GetClientOfUserId(pack.ReadCell());
	int boomer   = GetClientOfUserId(pack.ReadCell());

	if (!IsValidSurvivor(survivor) || !IsPlayerAlive(survivor))
		return Plugin_Stop;

	float pos[3];
	GetClientAbsOrigin(survivor, pos);

	// Push coordinates into the queue before spawning the projectile.
	// OnEntityCreated will use this to match the insect_swarm about to be created.
	if (g_fCvarDamageDPS != 0.0 && g_iSpawnQueue < MAX_POOL_TRACK)
	{
		g_fSpawnQueue[g_iSpawnQueue][0] = pos[0];
		g_fSpawnQueue[g_iSpawnQueue][1] = pos[1];
		g_fSpawnQueue[g_iSpawnQueue][2] = pos[2];
		g_iSpawnQueue++;
	}

	SpawnAcidPool(survivor, boomer > 0 ? boomer : survivor, pos);

	return Plugin_Stop;
}

// ====================================================================================================
//					DAMAGE HOOK
// ====================================================================================================

Action OnSurvivorTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (g_fCvarDamageDPS == 0.0) return Plugin_Continue;

	if (damagetype != ACID_DMG_NORMAL && damagetype != ACID_DMG_FADEOUT)
		return Plugin_Continue;

	if (inflictor <= MaxClients)   return Plugin_Continue;
	if (!IsValidEntity(inflictor)) return Plugin_Continue;

	int ref = EntIndexToEntRef(inflictor);
	for (int i = 0; i < g_iPoolCount; i++)
	{
		if (g_iOurPools[i] != ref) continue;

		// Flat per-tick damage = DPS / tick rate
		// Example: dps=2.0 → 2.0/2.0 = 1.0 damage/tick → 2.0 damage/second
		damage = g_fCvarDamageDPS / ACID_TICKS_PER_SEC;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

// ====================================================================================================
//					CORE LOGIC
// ====================================================================================================

void SpawnAcidPool(int survivor, int boomer, const float pos[3])
{
	float spawnPos[3], ang[3], vel[3];
	spawnPos    = pos;
	spawnPos[2] += 16.0;
	vel[2]       = -1000.0;

	GetClientEyeAngles(survivor, ang);
	L4D2_SpitterPrj(boomer, spawnPos, ang, vel);
}

// ====================================================================================================
//					HELPERS
// ====================================================================================================

void CleanDeadPools()
{
	int newCount = 0;
	for (int i = 0; i < g_iPoolCount; i++)
	{
		if (EntRefToEntIndex(g_iOurPools[i]) != INVALID_ENT_REFERENCE)
			g_iOurPools[newCount++] = g_iOurPools[i];
	}
	g_iPoolCount = newCount;
}

void ResetPlugin()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iVomitCount[i] = 0;
		delete g_hVomitReset[i];
	}

	g_iPoolCount  = 0;
	g_iSpawnQueue = 0;
}

bool IsValidSurvivor(int client)
{
	return (client > 0 && client <= MaxClients
		 && IsClientInGame(client)
		 && GetClientTeam(client) == TEAM_SURVIVOR);
}

bool IsValidBoomer(int client)
{
	return (client > 0 && client <= MaxClients
		 && IsClientInGame(client)
		 && GetClientTeam(client) == TEAM_INFECTED
		 && GetEntProp(client, Prop_Send, "m_zombieClass") == ZC_BOOMER);
}

// ====================================================================================================
//					CLIENT CONNECT
// ====================================================================================================

public void OnClientPutInServer(int client)
{
	if (g_bCvarAllow && g_fCvarDamageDPS != 0.0 && IsValidSurvivor(client))
		SDKHook(client, SDKHook_OnTakeDamageAlive, OnSurvivorTakeDamage);
}
