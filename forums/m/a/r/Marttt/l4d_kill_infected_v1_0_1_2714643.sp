#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "[L4D] Kill for Infected",
	author = "Danny & FlamFlam",
	description = "use the !kill command in chat",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2714198"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_explode", Kill_Me);
	RegConsoleCmd("sm_kill", Kill_Me);
}

// kill
public Action:Kill_Me(client, args)
{
	if (!IsValidClient(client))
		return;
	
	if (GetClientTeam(client) != 3)
	{
		PrintToChat(client, "You have to be Infected");
		return;
	}
	
	if (!IsPlayerAlive(client))
		return;
		
	if (IsPlayerGhost(client))
	{
		PrintToChat(client, "You can't kill yourself in Ghost mode");
		return;
	}
	
	ForcePlayerSuicide(client);
}

//Timed Message
public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
		CreateTimer(60.0, Timer_Advertise, GetClientUserId(client));
}

public Action:Timer_Advertise(Handle:timer, any:client)
{
	client = GetClientOfUserId(client);
	
	if (IsValidClient(client))
		PrintHintText(client, "Type in chat !kill to kill yourself");
}

/**
 * Validates if is a valid client.
 *
 * @param client    Client index.
 * @return          True if client is valid, false otherwise.
 */
bool IsValidClient(int client)
{
    return (1 <= client <= MaxClients && IsClientInGame(client));
}

/**
 * Validates if the client is a ghost.
 *
 * @param client    Client index.
 * @return          True if client is a ghost, false otherwise.
 */
bool IsPlayerGhost(int client)
{
    return GetEntProp(client, Prop_Send, "m_isGhost", 1) == 1;
}