#include <sourcemod>
#include <sdktools> 
#include <sdkhooks> 

#define MAX_2D_DIST 112
#define MAX_VERTICAL_DIST 104

new bool:g_showPlayer[MAXPLAYERS+1][MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Manic idiot hider",
	author = "Jeremy Johanessohn Barnes",
	description = "Disguises humans as nothingness.",
	version = "1.2.3",
	url = "http://www.burgerking.com/"
};

public OnPluginStart()
{ 
	CreateTimer(0.2, ComputeDistances, _, TIMER_REPEAT);

	for (new i = 1; i <= MaxClients; i++) 
	{ 
		if (IsClientInGame(i)) 
		{
			OnClientPutInServer(i); 
		}
	}
}

public OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action:ComputeDistances(Handle Timer) 
{
	for (new i = 1; i < MaxClients; i++) 
	{
		for (new j = i + 1; j <= MaxClients; j++) 
		{
			if (IsClientInGame(i) &&
				IsClientInGame(j) &&
				IsPlayerAlive(i) && 
				IsPlayerAlive(j)) 
			{
				new Float:observer[3];
				new Float:observed[3];
				GetClientAbsOrigin(i, Float:observer);
				GetClientAbsOrigin(j, Float:observed);

				// Get the distance
				new Float:dist[3];
				SubtractVectors(observer, observed, dist);

				// Check whether the players see eachother or not
				new bool:seeEachother = (dist[0] * dist[0] + dist[1] * dist[1] < MAX_2D_DIST * MAX_2D_DIST && FloatAbs(dist[2]) < MAX_VERTICAL_DIST);

				// Set the symmetrical blocks to whatever state
				g_showPlayer[i][j] = seeEachother;
				g_showPlayer[j][i] = seeEachother;
			}
		}
	}
}

public Action Hook_SetTransmit(int entity, int client)
{
	if (client != entity && 0 < entity && entity <= MaxClients && g_showPlayer[client][entity] && IsPlayerAlive(client) && IsPlayerAlive(entity) && GetClientTeam(client) == GetClientTeam(entity)) 
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}