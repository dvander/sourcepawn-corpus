#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
	name = "AdminTag",
	description = "Private plugin",
	author = "KeepCalm,Dragonidas",
	version = "4.1",
	url = ""
};


public OnPluginStart()
{
	HookEvent("player_connect", Event, EventHookMode:1);
	HookEvent("player_team", Event, EventHookMode:1);
	HookEvent("player_spawn", Event, EventHookMode:1);
	return 0;
}

public OnClientPutInServer(client)
{
	HandleTag(client);
	return 0;
}

public Action:Event(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (0 < client)
	{
		HandleTag(client);
	}
	return Action:0;
}

HandleTag(client)

{ 
    if (GetUserFlagBits(client) & ADMFLAG_ROOT) 
    { 
        CS_SetClientClanTag(client, "[HEAD ADMIN]"); 
    }
    else
		if (GetUserFlagBits(client) & ADMFLAG_CUSTOM6)
		{ 
			CS_SetClientClanTag(client, "[CHIEF ADMIN]"); 
		}
		else
			if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
			{ 
				CS_SetClientClanTag(client, "[ADMIN]"); 
			}
			else
				if (GetUserFlagBits(client) & ADMFLAG_CUSTOM4)
				{ 
				CS_SetClientClanTag(client, "[ULTRA VIP]"); 
				}
				else
					if (GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
					{ 
						CS_SetClientClanTag(client, "[SUPER VIP]"); 
					}
					else
						if (GetUserFlagBits(client) & ADMFLAG_RESERVATION)
						{ 
							CS_SetClientClanTag(client, "[VIP]"); 
						}	
						else
							{ 
								CS_SetClientClanTag(client, ""); 
							}						
}