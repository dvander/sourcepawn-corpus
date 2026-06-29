#include <sourcemod>

#define VERSION "1.2.5"

new Handle:g_adtArray;
new bool:g_isMapChange = false;

#define TEAM_SPEC 1

public Plugin:myinfo =
{
	name = "Remember Spectator Team",
	author = "B-man & olj",
	description = "Remembers who was a spectator on map change",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=100978"
}

public OnPluginStart()
{
	CreateConVar("remember_spec_version",VERSION,"Remember Spectator Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("round_end",Event_RoundEnd);
	//HookEvent("player_team",Event_PlayerChangeTeam);
	g_adtArray = CreateArray(ByteCountToCells(32));
}

public OnMapStart()
{
	g_isMapChange = false;	//Server is not changing map
}

public OnMapEnd()
{
	g_isMapChange = true;	//Map is changing
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	ClearArray(g_adtArray);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && GetClientTeam(i) == TEAM_SPEC)	//finds spectators
		{
			decl String:steamID[32];
			GetClientAuthString(i, steamID, sizeof(steamID));	//Gets the steamID
			PushArrayString(g_adtArray, steamID);		//Add the steamID string to the array
		}
	}
}

public OnClientPostAdminCheck(client)
{
	decl String:steamID[32];
	GetClientAuthString(client, steamID, sizeof(steamID));	//Get steamID
	new arrayIndex = FindStringInArray(g_adtArray, steamID);	//Returns the index where steamID was found -1 if not found
	
	if (arrayIndex != -1)	//If the index is not -1
	{
		ChangeClientTeam(client, TEAM_SPEC);		//change team to spectator
		RemoveFromArray(g_adtArray, arrayIndex);	//remove that person from the array
	}
}  

public OnClientDisconnect_Post(client)	//If everyone leaves, clear the array.
{
	if (GetClientCount(false) == 0 && !g_isMapChange)
	{
		ClearArray(g_adtArray);
	}
}

/*public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)	//Player changes team
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsValidClient(client) && GetClientTeam(client) != TEAM_SPEC)	//If the team is not spectator
	{
		decl String:steamID[32];
		GetClientAuthString(client, steamID, sizeof(steamID));	//Get steamID
		new arrayIndex = FindStringInArray(g_adtArray, steamID);	//Returns the index where steamID was found -1 if not found
	
		if (arrayIndex != -1)	//If the client is  found in the array
		{
			RemoveFromArray(g_adtArray, arrayIndex);	//remove that person from the array, they are no longer on spectators.
		}
	}
}*/

public IsValidClient (client)
{
    if (client == 0)
        return false;
    
    if (!IsClientConnected(client))
        return false;
    
    if (IsFakeClient(client))
        return false;
    
    if (!IsClientInGame(client))
        return false;	
		
    return true;
}  