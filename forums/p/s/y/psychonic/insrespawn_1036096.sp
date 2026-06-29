#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new Handle:g_cvarUSSpawnTime = INVALID_HANDLE;
new Handle:g_cvarIraqiSpawnTime = INVALID_HANDLE;

new Handle:g_hSpawnFunc = INVALID_HANDLE;

new g_iUSMarineIdx;
new g_iIraqiIdx;

new Float:g_fUSSpawnTime = -1.0;
new Float:g_fIraqiSpawnTime = -1.0;

new bool:g_bEnabled = false;

#define NAME "Insurgency Respawn Timer"
#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = NAME,
	author = "psychonic",
	description = "Controllable respawn timer for Insurgency",
	version = VERSION,
	url = "http://www.nicholashastings.com"
}

public OnPluginStart()
{
	g_cvarUSSpawnTime = CreateConVar("insrespawn_time_us", "-1.0", "Respawn time for U.S. Marines", FCVAR_PLUGIN);
	g_cvarIraqiSpawnTime = CreateConVar("insrespawn_time_iraqi", "-1.0", "Respawn time for Iraqi Insurgents", FCVAR_PLUGIN);
	HookConVarChange(g_cvarUSSpawnTime, CvarCheck);
	HookConVarChange(g_cvarIraqiSpawnTime, CvarCheck);
	
	CreateConVar("insrespawn_version", VERSION, NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	new Handle:gdfile = LoadGameConfigFile("insrespawn.games");
	if (gdfile == INVALID_HANDLE)
	{
		SetFailState("Failed to find gamedata file (gamedata/insrespawn.games.txt)");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	if (!PrepSDKCall_SetFromConf(gdfile, SDKConf_Signature, "Spawn"))
	{
		SetFailState("Couldn't find Spawn signature in gamedata file");
	}
	g_hSpawnFunc = EndPrepSDKCall();
	
	CloseHandle(gdfile);
}

public OnMapStart()
{
	GetTeams();
}

public OnConfigsExecuted()
{
	CvarCheck(INVALID_HANDLE, "", "");
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client))
	{
		new team = GetClientTeam(client);
		if (team == g_iUSMarineIdx && FloatCompare(g_fUSSpawnTime, 0.0) == 1)
		{
			PrintHintText(client, "Respawning in %.1f seconds", g_fUSSpawnTime);
			CreateTimer(g_fUSSpawnTime, SpawnTimer, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
		else if (team == g_iIraqiIdx && FloatCompare(g_fIraqiSpawnTime, 0.0) == 1)
		{
			PrintHintText(client, "Respawning in %.1f seconds", g_fIraqiSpawnTime);
			CreateTimer(g_fIraqiSpawnTime, SpawnTimer, userid, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:SpawnTimer(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		new team = GetClientTeam(client);
		if ((team == g_iUSMarineIdx) || (team == g_iIraqiIdx))
		{
			SDKCall(g_hSpawnFunc, client);
		}
	}
}

public CvarCheck(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_fUSSpawnTime = GetConVarFloat(g_cvarUSSpawnTime);
	g_fIraqiSpawnTime = GetConVarFloat(g_cvarIraqiSpawnTime);
	new bool:bOldValue = g_bEnabled;
	g_bEnabled = !(FloatCompare(g_fUSSpawnTime, 0.0) == -1 && FloatCompare(g_fIraqiSpawnTime, 0.0) == -1);
	
	if (g_bEnabled != bOldValue)
	{
		if (g_bEnabled)
		{
			HookEvent("player_death", EventPlayerDeath);
		}
		else
		{
			UnhookEvent("player_death", EventPlayerDeath);
		}
	}
}

GetTeams()
{
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	if (strcmp(mapname, "ins_karam") == 0 || strcmp(mapname, "ins_baghdad") == 0)
	{
		g_iUSMarineIdx = 2;
		g_iIraqiIdx = 1;
	}
	else
	{
		g_iUSMarineIdx = 1;
		g_iIraqiIdx = 2;
	}
}