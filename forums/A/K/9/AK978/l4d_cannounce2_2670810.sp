#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required


static int hCount;

public void OnPluginStart()
{
	HookEvent("player_disconnect", PlayerDisconnect, EventHookMode_Pre);
}

public Action PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{	
	char reason[256];
	char timedOut[256];
	
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && !IsFakeClient(client) && !dontBroadcast)
	{
		hCount --;
		GetEventString(event, "reason", reason, sizeof(reason));
		Format(timedOut, sizeof(timedOut), "%s timed out", client);
		
		if (strcmp(reason, timedOut) == 0)
		{
			char file[PLATFORM_MAX_PATH];
			int iPort = GetConVarInt(FindConVar("hostport"));
			BuildPath(Path_SM, file, sizeof(file), "logs/Disconnect_%d.log", iPort);					
			LogToFileEx(file, "玩家 %N 已連線超時(Timed Out).", client);
			
 			Format(reason, sizeof(reason), "連線超時(Timed Out).");
		}
		else if (strcmp(reason, "No Steam logon") == 0)
		{
			char file[PLATFORM_MAX_PATH];
			int iPort = GetConVarInt(FindConVar("hostport"));
			BuildPath(Path_SM, file, sizeof(file), "logs/Disconnect_%d.log", iPort);					
			LogToFileEx(file, "玩家 %N 已遊戲崩潰(Game crashed).", client);

			Format(reason, sizeof(reason), "遊戲崩潰(Game crashed).");
		}
		
		PrintToChatAll("%N %s", client, reason);
	}
	return event_PlayerDisconnect_Suppress( event, name, dontBroadcast );
}

public Action event_PlayerDisconnect_Suppress(Handle event, const char[] name, bool dontBroadcast)
{
	if (!dontBroadcast)
	{
		char clientName[33], networkID[22], reason[65];
		GetEventString(event, "name", clientName, sizeof(clientName));
		GetEventString(event, "networkid", networkID, sizeof(networkID));
		GetEventString(event, "reason", reason, sizeof(reason));
		
		Handle newEvent = CreateEvent("player_disconnect", true);
		SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
		SetEventString(newEvent, "reason", reason);
		SetEventString(newEvent, "name", clientName);        
		SetEventString(newEvent, "networkid", networkID);
		
		FireEvent(newEvent, true);
		
		return Plugin_Handled;
	}
	return Plugin_Continue;
}