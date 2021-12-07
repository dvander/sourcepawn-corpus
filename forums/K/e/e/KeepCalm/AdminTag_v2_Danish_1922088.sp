#include <sourcemod>
#include <cstrike>

public OnPluginStart()
{
	HookEvent("player_team", Event, EventHookMode:1);
	HookEvent("player_spawn", Event, EventHookMode:1);
	return 0;
}

public Action:Event(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	HandleTag(client);
	return Action:0;
}

public OnClientPostAdminCheck(client)
{
	HandleTag(client);
	return 0;
}

HandleTag(client)
{
	if (0 < client)
	{
		if (GetUserFlagBits(client) & 16384)
		{
			CS_SetClientClanTag(client, "[GUV]");
		}
		else
		{
			if (GetUserFlagBits(client) & 2048)
			{
				CS_SetClientClanTag(client, "[PRINCIPAL ADMIN]");
			}
			if (GetUserFlagBits(client) & 2)
			{
				CS_SetClientClanTag(client, "[ADMIN]");
			}
			if (GetUserFlagBits(client) & 1)
			{
				CS_SetClientClanTag(client, "[VIP]");
			}
			CS_SetClientClanTag(client, "");
		}
	}
}

