#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo =
{
	name = "[L4D & L4D2] Infected SpawnTime adjuster",
	author = "glhf3000",
	description = "Instead of random spawn moments, spawns are shifted to occur at mid-intervals every 10 seconds",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/"
}

#define DEBUG 0

#define TEAM_UNASSIGNED		0
#define TEAM_SPECTATORS		1
#define TEAM_SURVIVORS		2
#define TEAM_INFECTED		3

ConVar	cvSpawnTimeThresold, cvSpawnTimeWindow;
float	fSpawnTimeThresold, fSpawnTimeWindow;

public void OnPluginStart()
{
	HookEvent("ghost_spawn_time", 	Event_GhostSpawnTime, 	EventHookMode_Pre);
	
	cvSpawnTimeThresold	= CreateConVar("l4d_spawn_time_adjuster_thresold",	"10.0",	"The minimum respawn time which should be adjusted, lower - ignored", FCVAR_NOTIFY, true, 5.1);
	cvSpawnTimeWindow	= CreateConVar("l4d_spawn_time_adjuster_window",	"10.0",	"Shift spawns to every X seconds (mid-X actually)", FCVAR_NOTIFY, true, 10.0);
	
	CreateConVar("l4d_spawn_time_adjuster_version", PLUGIN_VERSION, "Infected SpawnTime adjuster plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	AutoExecConfig(true, "l4d_spawn_time_adjuster");
	
	cvSpawnTimeThresold.AddChangeHook(ConVarChanged);
	cvSpawnTimeWindow.AddChangeHook(ConVarChanged);
	
	setVars();
}

void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	setVars();
}

void setVars()
{
	fSpawnTimeThresold	 = cvSpawnTimeThresold.FloatValue;
	fSpawnTimeWindow	 = cvSpawnTimeWindow.FloatValue;
}

public void Event_GhostSpawnTime(Event hEvent, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	float oldDelay = L4D_GetPlayerSpawnTime(client);
	
	if(oldDelay < fSpawnTimeThresold)
	{
		#if DEBUG
			LogDebug("Event_GhostSpawnTime> %N - spawn delay: %.1f < %.1f sec, skip", client, oldDelay, fSpawnTimeThresold);
		#endif
		
		return;
	}

	float newDelay;
	if((newDelay = setDelay(client, oldDelay)) > 0.0)
	{
		hEvent.SetInt("spawntime", RoundToCeil(newDelay));
		
		#if DEBUG
			LogDebug("Event_GhostSpawnTime> %N - spawn delay: %.1f -> %.1f", client, oldDelay, newDelay);
		#endif
	}
	
	return;
}

float setDelay(int client, float spawnDelay)
{
	if(!IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED) return -1.0;
	
	float 	time = GetGameTime();

	float 	defaultSpawnTime = time + spawnDelay;
	float	window = RoundToFloor(defaultSpawnTime / fSpawnTimeWindow) * fSpawnTimeWindow;
	float	adjusted = window + fSpawnTimeWindow / 2;
	float	relativeAdjusted = adjusted - time;
	
	L4D_SetPlayerSpawnTime(client, relativeAdjusted, true);
	
	#if DEBUG
		LogDebug("setDelay> %N", client);
		LogDebug("setDelay> current: %.2f", time);
		LogDebug("setDelay> spawnDelay: %.2f", spawnDelay);
		LogDebug("setDelay> defaultSpawnTime: %.2f", defaultSpawnTime);
		LogDebug("setDelay> window: %.2f", window);
		LogDebug("setDelay> adjusted: %.2f", adjusted);
		LogDebug("setDelay> relative: %.2f", relativeAdjusted);
	#endif
	
	return relativeAdjusted;
}






#if DEBUG

	char sLogFilePath[PLATFORM_MAX_PATH];

	public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
	{
		char sDate[16];
		
		FormatTime(sDate, sizeof(sDate), "%Y%m%d", GetTime());
		BuildPath(Path_SM, sLogFilePath, sizeof(sLogFilePath), "logs/spawn_time_adjuster_%s.log", sDate);

		return APLRes_Success;
	}

	public void L4D_OnEnterGhostState(int client)
	{
		LogDebug("L4D_OnEnterGhostState> %N - %.2f", client, GetGameTime());
	}

	void LogDebug(const char[] szFormat, any ...)
	{
		int iLen = strlen(szFormat) + 255; 
		char[] szBuffer = new char[iLen];
		VFormat(szBuffer, iLen, szFormat, 2);
			
		LogToFile(sLogFilePath, szBuffer);
			
		// PrintToChatAll(szBuffer);
	}

#endif
