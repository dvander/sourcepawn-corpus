#include <sourcemod>
#include <cstrike>
#include <sdktools>

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++) if(IsClientInGame(%1))

public Plugin:myinfo =
{
	name = "[Scoreboard] Tags",
	description = "ScoreboardTags",
	author = "Mansionz",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_team", EventDeath, EventHookMode:1);
	HookEvent("player_spawn", EventSpawn, EventHookMode:1);
	HookEvent("round_start", RoundStart, EventHookMode:1);
	return 0;
}
 
public void OnClientPutInServer(client)
{
	LoopClients(client)
	{
		if(client > 0)
		{
			HandleTag(client);
		}
	}
}

public Action RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	LoopClients(client)
	{
		if(client > 0)
		{
			HandleTag(client);
		}
	}
}

public Action EventSpawn(Event event, const char[] name, bool dontBroadcast)
{
	LoopClients(client)
	{
		if(client > 0)
		{
			HandleTag(client);
		}
	}
}

public Action EventDeath(Event event, const char[] name, bool dontBroadcast)
{
	LoopClients(client)
	{
		if(client > 0)
		{
			HandleTag(client);
		}
	}
}
 
void HandleTag(client)
{
    if (CheckCommandAccess(client, "owner", ADMFLAG_ROOT))
    {
        CS_SetClientClanTag(client, "[Owner]");
    }
    else if (CheckCommandAccess(client, "headadmin", ADMFLAG_CHEATS))
	{
		CS_SetClientClanTag(client, "[Head-Admin]");
	}
	else if (CheckCommandAccess(client, "admin", ADMFLAG_GENERIC))
	{
		CS_SetClientClanTag(client, "[Admin]");
	}
	else if (CheckCommandAccess(client, "vip", ADMFLAG_CUSTOM1))
	{
		CS_SetClientClanTag(client, "[VIP]");
	}
		else if (CheckCommandAccess(client, "dj", ADMFLAG_CUSTOM2))
	{
		CS_SetClientClanTag(client, "[DJ]");
	}
}