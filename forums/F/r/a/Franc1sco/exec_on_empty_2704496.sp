#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "Exec Config on Server Empty",
	author = "Franc1sco Franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

ConVar _cvHibernate;

public void OnPluginStart()
{
	_cvHibernate = FindConVar("sv_hibernate_when_empty");
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);	
}

public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if ((client == 0 || !IsFakeClient(client)) && !RealPlayerExist(client)) 
	{
		if(_cvHibernate != null) 
			_cvHibernate.SetInt(0);
			
		CreateTimer(1.0, Timer_CheckPlayers);
	}
}

public Action Timer_CheckPlayers(Handle timer, int UserId)
{
	if (!RealPlayerExist()) {
		if(FileExists("/cfg/server_empty.cfg"))
			ServerCommand("exec server_empty.cfg");
		else
			LogError("server_empty.cfg not found.");
	}
}

bool RealPlayerExist(int iExclude = 0)
{
	for (int client = 1; client < MaxClients; client++)
	{
		if (client != iExclude && IsClientConnected(client))
		{
			if (!IsFakeClient(client)) {
				return (true);
			}
		}
	}
	return (false);
}