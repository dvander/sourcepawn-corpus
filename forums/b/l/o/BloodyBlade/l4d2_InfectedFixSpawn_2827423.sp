#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <l4d2_InfectedSpawnApi>

#if defined InfectedApiVersion1_6
#else
	#error Plugin required Infected Api Version 1.6 (get it http://forums.alliedmods.net/showthread.php?t=114979)
#endif


/**
* ChangeLog
* 1.3.1 
* - Recompiled with new version of Infected API version 1.6.1
* 1.2
* - Speedup optimizations in InfectedSpawnApi
* 1.1
* - Fix IsPlayerAlive after ghost spawn (DLC bug)
* 1.0
* - Command sm_infectedchange allowed to use anytime with admin flag ROOT
* - Plugin name in plugins list corrected
* - Use Infected API version 1.5
* - Fix bug when plugin don't works correctly sometimes
* 0.8
* - Use Infected API version 1.4
* - Command sm_infectedchange compilation fixed
* - Simple fix compatiblity
* - Fixed MAXPLAYERS to MaxClients
* 0.7
* - Added cvar with version number. (l4d2_inffixspawn_version)
* - Added cvar for plugin wait(no actions) x seconds from round start. (sm_inffixspawn_wait)
* 0.6
* - All plugin code rewrited.
* - All bugs fixed.
* - Use Infected API version 1.3
* 0.5
* - Added debug log to file
* 0.4
* - Use Infected API version 1.2
* - Added cheking infected on finales
* - Added hard change class if director can't give another class more 5 times
* - Fixed bug with l4dtoolz and sv_force_normal_respawn (thanks to Visual77)
* - Added library for spawn ghost in finale without l4d2toolz (not required)
* 0.3
* - Fixed known bugs
* - Temporary infected not checked in finales
* 0.2
* -  Fix bug at round_end
* 0.1 
* - Initial release.
*/

#define PLUGIN_VERSION "1.3.1"
#define MAX_CLASS_RECHECKS 5
#define DEBUG 0
#define CVAR_FLAGS FCVAR_NOTIFY

int LastClass[MAXPLAYERS + 1] = {0, ...}, ClassRechecks[MAXPLAYERS + 1] = {0, ...};
ConVar g_hCvarAllow, g_hCvarWait;
bool g_bCvarAllow = false, g_bWaiting = false;
float g_fCvarWait = 0.0;

public Plugin myinfo =
{
	name = "[L4D2] Infected Fix Spawn",
	author = "V10",
	description = "Fixes the bug when infected spawn always same class",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1048720"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{	
	CreateConVar("l4d2_inffixspawn_version", PLUGIN_VERSION, "InfectedFixSpawn plugin version", CVAR_FLAGS|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_hCvarAllow = CreateConVar("sm_inffixspawn", "1", "0 = Plugin off, 1 = Plugin on.", CVAR_FLAGS);
	g_hCvarWait = CreateConVar("sm_inffixspawn_wait", "5.0", "Plugin wait(no actions) this value seconds from round start.", CVAR_FLAGS);

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarWait.AddChangeHook(ConVarChanged_Cvars);

	AutoExecConfig(true, "l4d2_inffixspawn");

	RegAdminCmd("sm_infectedchange", Command_ChangeTest, ADMFLAG_ROOT);
	InitInfectedSpawnAPI();
}

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

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	if(!g_bCvarAllow && bCvarAllow)
	{
		g_bCvarAllow = true;
		GetCvars();
		HookEvent("ghost_spawn_time", Event_GhostSpawnTime);
		HookEvent("versus_round_start", Event_RoundStart);
		HookEvent("scavenge_round_start", Event_RoundStart);
		HookEvent("round_start", Event_RoundStart);
	}
	else if(g_bCvarAllow && !bCvarAllow)
	{
		g_bCvarAllow = false;
		UnhookEvent("ghost_spawn_time", Event_GhostSpawnTime);
		UnhookEvent("versus_round_start", Event_RoundStart);
		UnhookEvent("scavenge_round_start", Event_RoundStart);
		UnhookEvent("round_start", Event_RoundStart);
	}
}

void GetCvars()
{
	g_fCvarWait = g_hCvarWait.FloatValue;
}

Action Command_ChangeTest(int client, int args) 
{
	if (client > 0 && g_bCvarAllow)
	{
		int CurrentClass = GenerateZombieId(LastClass[client]);
		InfectedChangeClass(client,CurrentClass);
		LastClass[client] = CurrentClass;
	}
	return Plugin_Handled;
}

Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		LastClass[i] = 0;
		ClassRechecks[i] = 0;
	}

	if(g_fCvarWait > 0.0)
	{
		g_bWaiting = true;
		CreateTimer(g_fCvarWait, Timer_StopWait);
	}
	return Plugin_Continue;
}

Action Timer_StopWait(Handle timer)
{
	g_bWaiting = false;
	return Plugin_Stop;
}

Action Event_GhostSpawnTime(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bWaiting)
	{
		int client = GetClientOfUserId(event.GetInt("userid"));
		if(client > 0)
		{
			CreateTimer(event.GetFloat("spawntime") - 1.0, PreDelayedTestClass, client);
			ClassRechecks[client] = 0;
			#if DEBUG
				DebugPrint("GhostSpawnTime, cl = %N, time = %d", client, spawntime);
			#endif
		}
	}
	return Plugin_Continue;
}

Action PreDelayedTestClass(Handle timer, any client)
{
	#if DEBUG
		DebugPrint("PreDelayed test class, cl=%N, alive=%d",client,IsPlayerAlive(client));
	#endif
	if (IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) == TEAM_INFECTED) 
	{
		CreateTimer(1.0, DelayedTestClass, client);
	}
	return Plugin_Stop;
}

Action DelayedTestClass(Handle timer, any client)
{
	if (IsClientConnected(client) && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED)
	{
		//check class
		int CurrentClass = GetInfectedClass(client);	
		#if DEBUG
			DebugPrint("Delayed test class, cl=%N, class=%s, alive=%d",client,g_sBossNames[CurrentClass],IsPlayerAlive(client));
		#endif
		
		if (CurrentClass != ZC_TANK)
		{
			if (!IsPlayerAlive(client))
			{
				if (ClassRechecks[client] < MAX_CLASS_RECHECKS)
				{
					//If player after spawn ghost and is not alive then recheck in 0.1
					CreateTimer(0.1, DelayedTestClass, client);
					ClassRechecks[client]++;
				}
				// if after max check steel not alive - do nothing
				return Plugin_Stop;
			}
			
			if (CurrentClass == LastClass[client])
			{
				CurrentClass = GenerateZombieId(LastClass[client]);
				InfectedChangeClass(client, CurrentClass);
				#if DEBUG
					DebugPrint("Delayed change class, cl=%N, change=%s", client, g_sBossNames[CurrentClass]);
				#endif
			}
			LastClass[client] = CurrentClass;
		}
	}
	return Plugin_Stop;
}

#if DEBUG
void DebugPrint(const char[] format, any ...)
{
	char buffer[300], logPath[256];
	static File hLogFile = null;
	VFormat(buffer, sizeof(buffer), format, 2);	
	if (hLogFile == null)
	{
		BuildPath(Path_SM, logPath, sizeof(logPath), "logs/l4d2_InfectedFixSpawn.log");
		hLogFile = OpenFile(logPath, "a");
	}
	LogToOpenFileEx(hLogFile, buffer);
	if(hLogFile != null) delete hLogFile;
}
#endif
