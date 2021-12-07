#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <devzones>

public Plugin myinfo =
{
	name = "SM DEV Zones - Spawnkill",
	author = "SHITLER",
	description = "",
	version = "1.00",
	url = "http://www.hvgamers.com"
};

ConVar cvar_start_after;
Handle timer_handle;
bool is_active = false;

public OnPluginStart() 
{
	cvar_start_after = CreateConVar("sm_spawnkill_wait_time", "60", "Time to wait before activating kill zone");

    HookEvent("round_start", on_round_start, EventHookMode_PostNoCopy);
    HookEvent("round_end", on_round_end, EventHookMode_PostNoCopy);
}

public void on_round_start(Handle:event, const String:name[], bool:dontBroadcast) 
{
    if(timer_handle != null) 
    {
        KillTimer(timer_handle);
        timer_handle = null;
    }

    float start_after = cvar_start_after.FloatValue;
    timer_handle = CreateTimer(start_after, activate_spawnkill);
}

public void on_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
    is_active = false;

    KillTimer(timer_handle);
    timer_handle = null;
}

public Action activate_spawnkill (Handle timer) 
{
	is_active = true;
	
    for(int i = 1; i <= MaxClients; i++){
        if(IsClientInGame(i) && IsPlayerAlive(i)){
            if(Zone_IsClientInZone(i, "Spawnkiller", true, false)) {
		        ForcePlayerSuicide(i);
	        }
        }
    }
}

//DevZones forward
public Zone_OnClientEntry(client, String:zone[])
{
	if(!IsClientInGame(client)) return;
		
	else if(strncmp(zone, "Spawnkiller", 9, false) == 0 && is_active == true)
    {
		ForcePlayerSuicide(client);
    }
}