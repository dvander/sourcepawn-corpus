#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "JPLAYS"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "FFA Round End Fix", 
	author = PLUGIN_AUTHOR, 
	description = "The plugin forces the Round to End when only 1 player is alive.", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/jplayss"
};

public void OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
}

int GetLiveCount()
{
	int Counter;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{
			Counter++;
		}
		i++;
	}
	return Counter;
}

bool IsValidAlive(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client))
	{
		return true;
	}
	return false;
}

public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int Winners;
	int Counter = GetLiveCount();
	if (Counter == 1)
	{
		int i = 1;
		while (i <= MaxClients)
		{
			if (IsValidAlive(i))
			{
				Winners = GetClientTeam(i);
			}
			i++;
		}
		if (Winners == 2)
		{
			CS_TerminateRound(7.0, CSRoundEnd_TerroristWin, false);
		}
		else if (Winners == 3)
		{
			CS_TerminateRound(7.0, CSRoundEnd_CTWin, false);
		}
		else
		{
			CS_TerminateRound(7.0, CSRoundEnd_Draw, false);
		}
	}
}