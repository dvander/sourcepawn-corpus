#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#include <tf2_stocks>

public Plugin:myinfo = {
	name        = "Round End Enforcer",
	author      = "flobbo (credits go to langeh)",
	description = "ends the round after mp_timelimit is reached",
	version     = "1.0.0",
	url         = "flobboshood.de"
};

//Time limit enforcement
new Handle:g_tCheckTimeLeft = INVALID_HANDLE;
        

public OnPluginStart()
{
		CreateTimeCheck();
}

public Action:CheckTime(Handle:timer)
{

        new iTimeLeft;
        new iTimeLimit;
        GetMapTimeLeft(iTimeLeft);
        GetMapTimeLimit(iTimeLimit);
        
        // If mp_timelimit != 0, and the timeleft is < 0, change the map to sm_nextmap in 15 seconds.
        if (iTimeLeft <= 0 && iTimeLimit > 0) 
        {        
                if(GetRealClientCount() > 0) // Prevents a constant map change issue present on a small number of servers.
                {
                        CreateTimer(15.0, ChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
                        if(g_tCheckTimeLeft != INVALID_HANDLE)
                        {
                                KillTimer(g_tCheckTimeLeft);
                                g_tCheckTimeLeft = INVALID_HANDLE;
                        }
                }
        }
}

public Action:ChangeMap(Handle:timer)
{
	// If sm_nextmap isn't set or isn't registered, abort because there is nothing to change to.
	if (FindConVar("sm_nextmap") == INVALID_HANDLE)
	{
		LogError("[SOAP] FATAL: Could not find sm_nextmap cvar. Cannot force a map change!");
		return;
	}
	
	new iTimeLeft;
	new iTimeLimit;
	GetMapTimeLeft(iTimeLeft);
	GetMapTimeLimit(iTimeLimit);
	
	// Check that mp_timelimit != 0, and timeleft < 0 again, because something could have changed in the last 15 seconds.
	if(iTimeLeft <= 0 &&  iTimeLimit > 0)
	{
		new String:newmap[65];
		GetNextMap(newmap, sizeof(newmap));
		ForceChangeLevel(newmap, "Enforced Map Timelimit");
		PrintToServer("Enforced Map Timelimit");
	} else {  // Turns out something did change.
		LogMessage("[SOAP] Aborting forced map change due to soap_forcetimelimit 1 or timelimit > 0.");
		PrintToServer("Aborting forced map change due to soap_forcetimelimit 1 or timelimit > 0.");
		
		if(iTimeLeft > 0)
			CreateTimeCheck();
	}
}

CreateTimeCheck()
{

	if(g_tCheckTimeLeft != INVALID_HANDLE)
	{
		KillTimer(g_tCheckTimeLeft);
		g_tCheckTimeLeft = INVALID_HANDLE;
	}
		
	g_tCheckTimeLeft = CreateTimer(15.0, CheckTime, _, TIMER_REPEAT);
}

stock GetRealClientCount()
{

	new clients = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			clients++;
		}
	}
	
	return clients;
}

bool:IsValidClient(iClient)
{
	if (iClient < 1 || iClient > MaxClients)
		return false;
	if (!IsClientConnected(iClient))
		return false;
	return IsClientInGame(iClient);
}