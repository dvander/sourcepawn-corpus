#include <sourcemod>

#define VERSION "1.0"

new Handle:g_adtArray;
new roundCount = 0;
new bool:g_isMapChange = false;

public Plugin:myinfo =
{
	name = "Remember Spectator Team",
	author = "B-man",
	description = "Remembers who was a spectator on map change",
	version = VERSION,
	url = "http://www.tchalo.com"
};

public OnPluginStart()
{
	HookEvent("round_end",Event_RoundEnd);
	g_adtArray = CreateArray(64);
}

public OnMapStart()
{
	roundCount = 0;	//Reset round count
	g_isMapChange = false;	//Server is not changing map
}

public OnMapEnd()
{
	g_isMapChange = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundCount++;
	
	decl String:steamID[64];
	
	if (roundCount == 2)
	{
		for (new i = 1; i <= MaxClients; i++)
        {
			if (GetClientTeam(i) == 1)
            {
				new client = GetClientOfUserId(i)
				GetClientAuthString(client, steamID, 64);
				PushArrayString(g_adtArray, steamID);
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	decl String:steamID[64];
	GetClientAuthString(client, steamID, 64);
	new arrayIndex = FindStringInArray(g_adtArray, steamID);
	
	if (arrayIndex != -1)
	{
		ChangeClientTeam(client, 1);
		RemoveFromArray(g_adtArray, arrayIndex);
	}
}  

public OnClientDisconnect_Post(client)
{
	if (GetClientCount(false) == 0 && !g_isMapChange)
	{
		ClearArray(g_adtArray);
	}
}