/*
	Round End Protection

		This Plugin Will Stop Playhers From Being Harmed/Killed After The R0und Has Ended
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.3"

new Handle:Switch;
new bool:RoundEnded;

public Plugin:myinfo =
{
	name = "Round End Protection",
	author = "Peoples Army",
	description = "Keeps Players From Being Killed At R0und End",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	Switch = CreateConVar("sm_roundend","1","Protection for players at the end of the round [0=off|1=on]", FCVAR_NOTIFY);
	HookEvent("round_end", StopKills, EventHookMode_Pre);
	HookEvent("round_start", ResetMode);
	HookEvent("player_spawn", SpawnEvent);
}

public Action:StopKills(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Switch))
	{
		new PLAYERS = GetMaxClients();
		RoundEnded = true;

		for (new i = 1; i <= PLAYERS; i++)
		{
			if (IsClientConnected(i))
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
			}
		}
	}
}

public ResetMode(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(Switch))
	{
		new PLAYERS = GetMaxClients();
		RoundEnded = false;

		for (new i = 1; i <= PLAYERS; i++)
		{
			if (IsClientConnected(i))
			{
				SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
			}
		}
	}
}

public SpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new clientID = GetEventInt(event, "userid");
	new client = GetClientOfUserId(clientID);

	if (RoundEnded == true)
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
}