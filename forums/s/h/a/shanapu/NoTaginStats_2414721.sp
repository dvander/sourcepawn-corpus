#include <sourcemod>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo =
{
	name = "NoTaginStats",
	description = "removes Steam Group Tag in Stats",
	author = "shanapu, KeepCalm",
	version = "1.0",
	url = "shanapu.de"
};


public void OnPluginStart()
{
	HookEvent("player_team", RemoveTag);
	HookEvent("player_spawn", RemoveTag);
}

public void OnClientPutInServer(int client)
{
	HandleTag(client);
}

public Action RemoveTag(Handle event, char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (0 < client)
	{
		HandleTag(client);
	}
}

public Action HandleTag(int client)

{
	CS_SetClientClanTag(client, ""); 
}
