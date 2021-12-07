#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.1"
#define DEVELOPER_INFO false

new timercount = 0;

public Plugin:myinfo = 
{
	name = "[L4D] Bots Autokick",
	author = "Jonny",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("round_start_post_nav", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public KickBots()
{
	decl String:ClientSteamID[12];
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == 2)
			{
				GetClientAuthString(i, ClientSteamID, sizeof(ClientSteamID));
				if (StrEqual(ClientSteamID, "BOT", false))
				{
					KickClient(i);
				}
			}
		}
	}
}

public Action:NextTimer(Handle:timer, any:client)
{
	if (timercount == -1)
	{
		timercount = 0;
		return;
	}

	if (timercount > 60)
	{
		if (GetPlayersFromTeam(2) > 16)
		{
			KickBots();
		}
		timercount = 0;
	}
	
	if (timercount < 0)
		return;

	timercount++;
	CreateTimer(1.0, NextTimer);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	timercount = 0;
	CreateTimer(120.0, NextTimer);
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetPlayersFromTeam(2) > 16)
	{
		KickBots();
	}
	timercount = -1;
}

stock GetPlayersFromTeam(const Team)
{
	new players_count = 0;
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i))
		{
			if (GetClientTeam(i) == Team)
			{
				players_count++;
			}
		}
	}
	return players_count;
}