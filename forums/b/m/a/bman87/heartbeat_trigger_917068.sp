#include <sourcemod>

#define VERSION "1.0"

new bool:hadRecentHb = false;
new bool:recentDisconnect = false;
new Handle:cvarTimeout = INVALID_HANDLE;
new Handle:cvarAutoHB = INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "Heartbeat trigger",
	author = "B-man",
	description = "sm_hb or !hb in chat to send a heartbeat from, every client",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=102052"
}

public OnPluginStart()
{
	CreateConVar("sm_heartbeat_version",VERSION,"Heartbeat trigger version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarAutoHB = CreateConVar ("sm_heartbeat_auto", "1", "Auto heatbeats everyone when someone disconnects", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvarTimeout = CreateConVar("sm_heartbeat_timeout", "20", "Timeout value between heartbeats for non-admins", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_hb", heartbeatAll);
}

public OnClientDisconnect(client)
{
	if (GetConVarBool(cvarAutoHB) && !recentDisconnect)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				ClientCommand(i, "heartbeat");
			}
		}
		recentDisconnect = true;
		CreateTimer(5.0, resetDCCvar);
	}
}

public Action:heartbeatAll(client, args)
{
	if (!hadRecentHb || client == 0 || GetUserAdmin(client) != INVALID_ADMIN_ID)  //True if no recent heartbeat, or client is console, or user is admin
	{
		decl String:clientName[64];
		GetClientName(client, clientName, sizeof(clientName));
	
		ServerCommand("heartbeat");
	
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				ClientCommand(i, "heartbeat");
			}
		}
		
		if (client != 0 && GetUserAdmin(client) == INVALID_ADMIN_ID)  //If the user is not admin or console, create the timer
		{
			CreateTimer(GetConVarFloat(cvarTimeout), resetHbCvar);
			hadRecentHb = true;
		}
	
		if (client != 0)   //If the client is not the console, print info
		{
			PrintToChatAll("\x04[\x03HB\x04] heartbeat sent from all clients");
			PrintToServer("[HB] heartbeat sent from all clients. Requested by %s", clientName);
		}
	}
	else  //User is not admin/console and had a recent heatbeat
	{
		if (client != 0)
		{
			PrintToChat(client, "Heartbeat requested already, try again later"); //Print
		}
	}
}

public Action:resetHbCvar(Handle:timer)
{
	hadRecentHb = false;  //Reset the var
}

public Action:resetDCCvar(Handle:timer)
{
	recentDisconnect = false;  //Reset the var
}

public IsValidClient (client)  //Client validation
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
