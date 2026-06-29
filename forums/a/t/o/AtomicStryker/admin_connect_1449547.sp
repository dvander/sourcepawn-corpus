#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
	HookEvent("player_team", _Event__Player_Team);
}

public OnClientConnected(client)
{
	if (IsHumanClient(client))
	{
		PrintToChatAllAdmins("\x04%N\x01 has connected to the server.", client);
	}
}

public OnClientDisconnect(client)
{
	if (IsHumanClient(client))
	{
		PrintToChatAllAdmins("\x04%N\x01 has left the server.", client);
	}
}

public Action:_Event__Player_Team(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (IsHumanClient(client))
	{
		new team = GetEventInt(event, "team");
		PrintToChatAllAdmins("\x04%N\x01 has switched his team, now on team %i", team);
	}
}

stock bool:IsHumanClient(client)
{
	return (client && !IsFakeClient(client));
}

stock PrintToChatAllAdmins(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	
	for (new i = 1; i < MaxClients+1; i++)
	{
		if (IsHumanClient(i) && (GetUserAdmin(i) != INVALID_ADMIN_ID))
		{
			PrintToChat(i, "%s", buffer);
		}
	}
}