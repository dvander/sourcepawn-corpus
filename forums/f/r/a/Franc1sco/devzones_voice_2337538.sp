#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <devzones>


new zona[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "SM DEV Zones - Voice",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Evento);
	HookEvent("player_death", Evento);
	CreateTimer(0.2, Timer_UpdateListeners, _, TIMER_REPEAT);
}

public Action:Evento(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	zona[client] = 0;
}

public OnClientPutInServer(client)
{
	zona[client] = 0;
}

public Zone_OnClientEntry(client, String:zone[])
{
	if(StrContains(zone, "voice", false) == 0)
	{
		decl String:zone_uso[64];
		strcopy(zone_uso, 64, zone);
		ReplaceString(zone_uso, 64, "voice", "");
		new numeroz = StringToInt(zone_uso);
		zona[client] = numeroz;

	}
}

public Zone_OnClientLeave(client, String:zone[])
{
	if(StrContains(zone, "voice", false) == 0)
	{
		zona[client] = 0;
	}
}

public Action:Timer_UpdateListeners(Handle:timer) 
{
	for (new receiver = 1; receiver <= MaxClients; receiver++)
	{
		if (!IsClientInGame(receiver))
			continue;
			
		for (new sender = 1; sender <= MaxClients; sender++)
		{
			if (!IsClientInGame(sender))
				continue;
				
			if (sender == receiver)
				continue;
							
			if (zona[sender] == 0 || zona[receiver] == 0)
			{
				SetListenOverride(receiver, sender, Listen_No);
				continue;
			}
			
			SetListenOverride(receiver, sender, (zona[receiver] == zona[sender]) ? Listen_Yes : Listen_No);

		}
	}
}