#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define PLUGIN_VERSION "1.3"

public Plugin myinfo = 
{
	name = "[L4D] Hunter Finale Spawn",
	author = "Dragokas",
	description = "Spawn a lot of hunter when finale vehicle is about to incoming",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

bool g_bIsFinale;
bool g_bHunterSpawnHooked;
float g_HunterPos[3];
Handle g_hTimer, g_hTimer2;
bool g_bLeft4Dead2;
int g_iDeltaHunterCount;

ConVar g_hCvarEnable;
ConVar g_hCvarHealth;
ConVar g_hCvarMaxCount;
ConVar g_hCvarHunterHealth;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;	  
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarEnable 			= CreateConVar(	"l4d_hunter_finale_spawn_enable",	"1",		"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	g_hCvarHealth 			= CreateConVar(	"l4d_hunter_finale_health",			"1500",		"Health of finale multi-spawned hunters", CVAR_FLAGS );
	g_hCvarMaxCount			= CreateConVar(	"l4d_hunter_finale_maxcount",		"15",		"Maximum simultaneous count of multi-spawned hunters", CVAR_FLAGS );
	
	CreateConVar("l4d_hunter_finale_spawn_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD );
	
	AutoExecConfig(true,			"l4d_hunter_finale_spawn");
	
	g_hCvarHunterHealth = FindConVar("z_hunter_health");
	
	//RegAdminCmd("sm_t", CmdT, ADMFLAG_ROOT);
	
	HookConVarChange(g_hCvarEnable,			ConVarChanged);
	GetCvars();
}

public Action CmdT(int client, int args)
{
	ForceInfiniteHunters();
	return Plugin_Handled;
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	InitHook();
}

public void OnMapStart()
{
	static char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	
	g_bIsFinale = false;
	
	if (
		StrEqual(sMap, "l4d_hospital05_rooftop") ||
		StrEqual(sMap, "l4d_garage02_lots") ||
		StrEqual(sMap, "l4d_smalltown05_houseboat") ||
		StrEqual(sMap, "l4d_airport05_runway") ||
		StrEqual(sMap, "l4d_farm05_cornfield") ||
		StrEqual(sMap, "c1m4_atrium") ||
		StrEqual(sMap, "c2m5_concert") ||
		StrEqual(sMap, "c3m4_plantation") ||
		StrEqual(sMap, "c4m5_milltown_escape") ||
		StrEqual(sMap, "c5m5_bridge") ||
		StrEqual(sMap, "c6m3_port") ||
		StrEqual(sMap, "c7m3_port") ||
		StrEqual(sMap, "c8m5_rooftop") ||
		StrEqual(sMap, "c9m2_lots") ||
		StrEqual(sMap, "c10m5_houseboat") ||
		StrEqual(sMap, "c11m5_runway") ||
		StrEqual(sMap, "C12m5_cornfield") ||
		StrEqual(sMap, "c13m4_cutthroatcreek") ||
		StrEqual(sMap, "l4d_river03_port")
		) {
		g_bIsFinale = true;
	}
	
	Reset();
}

public void OnMapEnd()
{
	Reset();
}

void Reset()
{
	if ( g_bHunterSpawnHooked )
	{
		UnhookEvent("player_spawn", 			Event_PlayerSpawn);
		g_bHunterSpawnHooked = false;
		g_HunterPos[0] = 0.0;
		g_HunterPos[1] = 0.0;
		g_HunterPos[2] = 0.0;
		delete g_hTimer;
		delete g_hTimer2;
		g_iDeltaHunterCount = 0;
	}
}

void InitHook()
{
	static bool bHooked;
	
	if (g_hCvarEnable.BoolValue) {
		if (!bHooked) {
			HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
			HookEvent("finale_escape_start",	Event_EscapeStart,	EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
			UnhookEvent("finale_escape_start",	Event_EscapeStart,	EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Reset();
}

public void Event_EscapeStart(Event event, const char[] name, bool dontBroadcast)
{
	if ( g_bIsFinale )
	{
		ForceInfiniteHunters();
	}
}

void ForceInfiniteHunters()
{
	delete g_hTimer;
	delete g_hTimer2;
	g_hTimer = CreateTimer(1.0, Timer_SpawnHunters, _, TIMER_REPEAT);
	g_hTimer2 = CreateTimer(15.0, Timer_IncreaseCount, _, TIMER_REPEAT); // increase max. number of hunters each 15 sec.

	HookEvent("player_spawn", 			Event_PlayerSpawn);
	g_bHunterSpawnHooked = true;
	
	int client = GetAnySurvivor();
	if ( client )
	{
		StripAndExecuteClientCommand(client, g_bLeft4Dead2 ? "z_spawn_old" : "z_spawn", "hunter auto");
	}
	if ( g_hCvarHunterHealth != null )
	{
		g_hCvarHunterHealth.SetInt(g_hCvarHealth.IntValue);
	}
}

Action Timer_IncreaseCount(Handle timer)
{
	g_iDeltaHunterCount++;
	return Plugin_Continue;
}

Action Timer_SpawnHunters(Handle timer)
{
	if ( g_HunterPos[0] != 0.0 && g_HunterPos[1] != 0.0 && g_HunterPos[2] != 0.0 )
	{
		int countReq = RoundToCeil(GetAliveSurvivorsCount() * 1.5) + g_iDeltaHunterCount;
		
		int countOnField = GetHuntersCount();
		
		if ( countOnField < g_hCvarMaxCount.IntValue )
		{
			if ( countOnField < countReq )
			{
				SpawnInfectedAt(g_HunterPos, "hunter");
			}
		}
	}
	return Plugin_Continue;
}

public void Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ( client && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		if ( !IsTank(client) )
		{
			GetClientAbsOrigin(client, g_HunterPos);
		}
	}
}

stock int SpawnInfectedAt(float position[3], char[] sClass)
{
	int spawner = CreateEntityByName("commentary_zombie_spawner");
	if( spawner != -1 )
	{
		DispatchSpawn(spawner);
		ActivateEntity(spawner);
		DispatchKeyValue(spawner, "targetname", "pet_witch_spawner");
		TeleportEntity(spawner, position, view_as<float>({0.0, 90.0, 0.0}), NULL_VECTOR);
		SetVariantString("OnSpawnedZombieDeath !self:Kill::5:-1");
		AcceptEntityInput(spawner, "AddOutput");
		SetVariantString(sClass);
		AcceptEntityInput(spawner, "SpawnZombie");
	}
	return spawner;
}

stock int GetAnySurvivor()
{
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
		{
			return i;
		}
	}
	return 0;
}

stock int GetAliveSurvivorsCount()
{
	int cnt;
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
		{
			cnt++;
		}
	}
	return cnt;
}

stock int GetHuntersCount()
{
	int ent = -1, cnt = 0;
	while( -1 != (ent = FindEntityByClassname(ent, "hunter")))
	{
		cnt++;
	}
	return cnt;
}

void StripAndExecuteClientCommand(int client, const char[] command, const char[] arguments)
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags | FCVAR_CHEAT);
}

stock bool IsTank(int &client)
{
	if( client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 )
	{
		int class = GetEntProp(client, Prop_Send, "m_zombieClass");
		if( class == (g_bLeft4Dead2 ? 8 : 5 ))
			return true;
	}
	return false;
}
