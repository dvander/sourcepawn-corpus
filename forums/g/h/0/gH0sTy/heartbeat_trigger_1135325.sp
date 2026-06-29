#pragma semicolon 1

#include <sourcemod>

#define VERSION "1.1"

new bool:hadRecentHb = false;
new bool:recentDisconnect = false;
new Handle:cvarTimeout = INVALID_HANDLE;
new Handle:cvarAutoHB = INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "Heartbeat trigger",
	author = "B-man",
	description = "sm_hb or !hb in chat to force a server heartbeat",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=102052"
}

public OnPluginStart()
{
	CreateConVar("sm_heartbeat_version",VERSION,"Heartbeat trigger version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarAutoHB = CreateConVar ("sm_heartbeat_auto", "1", "Auto heatbeat when someone disconnects", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	cvarTimeout = CreateConVar("sm_heartbeat_timeout", "20", "Timeout value between heartbeats for non-admins", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	RegConsoleCmd("sm_hb", heartbeatAll);
	AutoExecConfig(true);
}

// We need to check the disconnect reason because a killed SI Bot would also trigger a ClientDisconnect
public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvarAutoHB) && !recentDisconnect)
	{
		decl String:reason[128];
		GetEventString(event, "reason", reason, 128);
	
		if (StrEqual(reason, "Disconnect by user.") || StrEqual(reason, "Kicked by Console : You have been voted off") || StrContains(reason, "timed out") != -1)
		{
			recentDisconnect = true;
			ServerCommand("heartbeat");
			PrintToChatAll("\x04[\x03HB\x04] Server heartbeat sent. (ClientDisconnect)");
			CreateTimer(10.0, resetDCCvar);
		}
	}
}


public Action:heartbeatAll(client, args)
{
	if (!hadRecentHb || !recentDisconnect)  //Check for recent disconnect/heartbeat
	{
		if (IsValidClient(client)){
			
			decl String:clientName[64];
			GetClientName(client, clientName, sizeof(clientName));
			ServerCommand("heartbeat");
			PrintToChatAll("\x04[\x03HB\x04] Server heartbeat sent. Requested by \x03%s", clientName);
			PrintToServer("[HB] heartbeat sent. Requested by %s", clientName);
			
			if (GetUserAdmin(client) == INVALID_ADMIN_ID){	// Set timeout for non-admins
				
				CreateTimer(GetConVarFloat(cvarTimeout), resetHbCvar);
				hadRecentHb = true;
			}
		}
	}
	else if (client != 0) // Reply to command in case of recent disconnect/heartbeat
	{
		PrintToChat(client, "Heartbeat requested already, try again later");
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
