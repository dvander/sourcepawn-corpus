//Beacon Timer!
//Made by Pigophone
//Version 1.3

#define TEAM_T 2
#define TEAM_CT 3

new Handle:BeaconTimer;
new Handle:cvarPluginEnable = INVALID_HANDLE;
new Handle:cvarTime = INVALID_HANDLE;
new Handle:cvarPlayersToActivate = INVALID_HANDLE;
new g_time;

public Plugin:myinfo =
{
	name = "Pigophones Beacon Timer",
	author = "Pigophone",
	description = "Pigophones Beacon Timer",
	version = "1.3",
	url = ""
};

public OnPluginStart()
{
	HookEvent("round_start", SetTimerFunc, EventHookMode_Post);
	HookEvent("round_end", KillTimerFunc, EventHookMode_Post);
	cvarPluginEnable = CreateConVar("sm_beacontimer_enabled", "1", "Enables and Disables The Timer", _, true, 0.0, true, 1.0);
	cvarTime = CreateConVar("sm_beacontimer_time", "60.0", "Wait time for the Timer", _, true, 5.0, true, 600.0);
	cvarPlayersToActivate = CreateConVar("sm_beacontimer_playerstoactivate", "0", "How many players are needed for the Timer to be activated", _, true, 0.0, true, 1.0);
}
 
public SetTimerFunc(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarPluginEnable))
	{	
		if(GetPlayerCount >= GetConVarInt(cvarPlayersToActivate))
		{
			g_time = GetConVarFloat(cvarTime);
			BeaconTimer = CreateTimer(g_time, BeaconAll);
		}
	}
}


public KillTimerFunc(Handle:event, const String:name[], bool:dontBroadcast)
{
	KillTimer(BeaconTimer);
}


public Action:BeaconAll(Handle:timer)
{
	ServerCommand("sm_beacon @alive");
}

GetPlayerCount()
{
    new players;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
            players++;
    }
    return players;
}  