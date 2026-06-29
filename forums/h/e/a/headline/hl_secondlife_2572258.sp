#include <sourcemod>
#include <cstrike>

bool didRespawn[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[CS:GO/CS:S] Second Life",
	author = "Headline",
	description = "Allows player to respond twice per round.",
	version = "1.0",
	url = "http://www.michaelwflaherty.com"
}

public void OnPluginStart()
{
	SetAll(didRespawn, sizeof(didRespawn), false);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientDisconnect(int client)
{
	didRespawn[client] = false;
}

public void OnClientPutInServer(int client)
{
	didRespawn[client] = false;
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	SetAll(didRespawn, sizeof(didRespawn), false);
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (0 < client <= MaxClients && IsClientInGame(client))
	{
		if (!didRespawn[client])
		{
			CS_RespawnPlayer(client);
			didRespawn[client] = true;
		}
	}
}

/**
 * Sets all array values (up to count) to the
 * value specified
 *
 * @param array The array.
 * @param count The count (exclusive).
 * @param val Value to set everything.
 */
bool SetAll(any[] array, int count, any val)
{
	for (int i = 0; i < count; i++)
	{
		array[i] = val;
	}
}