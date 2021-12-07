#pragma semicolon 1
#include <sourcemod>

/* Defines */
#define	DESCRIPTION		"Remaining Zombies/Humans/HP."
#define	VERSION			"1.0"

/* Globals */
new Handle:g_hDisplayHandle[MAXPLAYERS+2] = INVALID_HANDLE;
new g_iHumanCount, g_iZombieCount;

public Plugin:myinfo =
{
    name 		=		"Humans/Zombies/HP Left display",			// http://www.thesixtyone.com/s/9uVgZczXSCj/
    author		=		"Kyle Sanderson", 
    description	=		DESCRIPTION, 
    version		=		VERSION, 
    url			=		"http://PlagueFest.com"
};

public OnPluginStart()
{
	CreateConVar("sm_humanzombiehpdisplay_version", VERSION, DESCRIPTION, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_death",	ReCount,	EventHookMode_PostNoCopy);
	HookEvent("player_spawn",	ReCount,	EventHookMode_PostNoCopy);
	HookEvent("player_team",	ReCount,	EventHookMode_PostNoCopy);
}

public OnPluginEnd()
{
	UnhookEvent("player_death",	ReCount,	EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn", ReCount,	EventHookMode_PostNoCopy);
	UnhookEvent("player_team",	ReCount,	EventHookMode_PostNoCopy);
}

public OnMapEnd()
{
	for(new i; i <=MaxClients; i++)
	{
		if(g_hDisplayHandle[i] != INVALID_HANDLE)
		{
			KillTimer(g_hDisplayHandle[i]);
			g_hDisplayHandle[i] = INVALID_HANDLE;
		}
	}
}

public OnClientPutInServer(client)
{
	if(!IsFakeClient(client))
	{
		g_hDisplayHandle[client] = CreateTimer(1.0, PrintInformation, client, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnClientDisconnect(client)
{
	if(g_hDisplayHandle[client] != INVALID_HANDLE)
	{
		KillTimer(g_hDisplayHandle[client]);
		g_hDisplayHandle[client] = INVALID_HANDLE;
	}
}

public Action:PrintInformation(Handle:timer, any:client)
{
	if(IsPlayerAlive(client))
	{
		PrintHintText(client, "Health: %i\nHumans: %i\nZombies: %i", GetClientHealth(client), g_iHumanCount, g_iZombieCount);
	}
	return Plugin_Continue;
}

public Action:ReCount(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Team;
	g_iHumanCount = 0;
	g_iZombieCount = 0;
	for(new i = 1; i <=MaxClients; i++)
	{
		if(IsClient(i))
		{
			Team = GetClientTeam(i);
			switch(Team)
			{
				case 2:
				{
					g_iZombieCount++;
				}
				
				case 3:
				{
					g_iHumanCount++;
				}
			}
		}
	}
	return Plugin_Continue;
}

stock bool:IsClient(any:client)
{
	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		return true;
	}
	return false;
}