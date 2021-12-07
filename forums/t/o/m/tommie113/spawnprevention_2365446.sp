#include <sourcemod>

ConVar g_CvarDuration;
Handle SpawnTimer[MAXPLAYERS] = {INVALID_HANDLE, ...};
bool g_SpawnPrevention = false;

public Plugin:myinfo = {
	name = "Spawn prevention",
	author = "tommie113",
	description = "Prevents spawning after a given time.",
	version = "1.0",
	url = "http://www.sourcemod.net"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
	HookEvent("round_end", OnRoundEnd);
	
	g_CvarDuration = CreateConVar("sm_spawnprevention_time", "15", "Time before spawn protection will be enabled.");
}

public Action OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_SpawnPrevention = false;
	
	for(new i = 1; i < MAXPLAYERS; i++)
	{
		if(SpawnTimer[i] != INVALID_HANDLE)
		{
			CloseHandle(SpawnTimer[i]);
			SpawnTimer[i] = INVALID_HANDLE;
		}
	}
}

public Action OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_SpawnPrevention == true)
	{
		return Plugin_Handled;
	}
	
	int userid;
	userid = GetEventInt(event, "userid");
	
	if(SpawnTimer[userid] != INVALID_HANDLE)
	{
		return Plugin_Handled;
	}
	
	int duration;
	duration = g_CvarDuration.IntValue;
	float fduration;
	fduration = float(duration);
	
	SpawnTimer[userid] = CreateTimer(fduration, SpawnPrevention);
	
	return Plugin_Continue;
}

public Action SpawnPrevention(Handle timer)
{
	g_SpawnPrevention = true;
}