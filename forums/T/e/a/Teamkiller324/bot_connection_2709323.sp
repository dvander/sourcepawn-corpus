#pragma semicolon 1
#include <sourcemod>

public	Plugin:myinfo	=
{
	name		=	"Restrict Bot Messages",
	author		=	"Tk /id/Teamkiller324",
	description	=	"Testing",
	version		=	"0.1",
	url			=	""
}

public OnPluginStart()
{
	HookEvent("player_connect",			connect,	EventHookMode_Pre);
	HookEvent("player_connect_client",	connect,	EventHookMode_Pre);
	HookEvent("player_disconnect",		disconnect,	EventHookMode_Pre);
}

//Connect
public Action:connect(Handle:event, const String:name[], bool dontBroadcast)
{
	SetEventBroadcast(event, true);
}

public void OnClientAuthorized(client)
{
	if (IsFakeClient(client))
	{
	}
	else if (IsClientAuthorized(client))
	{
		PrintToChatAll("%N has joined the game", client);
	}
}

//Disconnect
public Action:disconnect(Handle:event, const String:name[], bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsFakeClient(client))
	{
		return Plugin_Continue;
	}
	else
	{
		PrintToChatAll("%N has left the game", client);
	}
	SetEventBroadcast(event, true);
	
	return Plugin_Handled;
}