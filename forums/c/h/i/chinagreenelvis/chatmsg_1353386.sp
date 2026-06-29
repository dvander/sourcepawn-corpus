#include <sourcemod>
#include <sdktools>

new bool:HasSpoken[MAXPLAYERS+1];

public OnPluginStart() 
{
	HookEvent("player_say", Event_PlayerSay);
}

public OnClientPutInServer(client)
{
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		HasSpoken[client] = false;
	}
}

public Event_PlayerSay(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	if (IsClientConnected(client) && !IsFakeClient(client))
	{
		if (HasSpoken[client] == false)
		{
			PrintToChat(client, "");
			PrintToChat(client, "This is a custom server. If you have questions about it, press H to read the MOTD.");
			HasSpoken[client] = true;
		}
	}
}