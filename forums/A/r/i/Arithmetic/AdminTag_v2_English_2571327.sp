#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
	name = "AdminTag",
	description = "Private plugin",
	author = "KeepCalm",
	version = "2.0",
	url = ""
};


public OnPluginStart()
{
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
        CS_SetClientClanTag(client, "[OWNER]"); 
    }
    else
		if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
		{ 
			CS_SetClientClanTag(client, "[STAFF]"); 
		}
		else
				if (GetUserFlagBits(client) & ADMFLAG_GENERIC)
				{ 
					CS_SetClientClanTag(client, "[ADMIN]"); 
				}
				else
					if (GetUserFlagBits(client) & ADMFLAG_RESERVATION)
					{ 
						CS_SetClientClanTag(client, "[MVP]"); 
					}	
							if (GetUserFlagBits(client) & ADMFLAG_VOTE)
							{ 
								CS_SetClientClanTag(client, "[MVP+]"); 
							}
							else	
								if (GetUserFlagBits(client) & ADMFLAG_CUSTOM3)
								{ 
									CS_SetClientClanTag(client, "[T H O T]"); 
								}
								else								
									if (GetUserFlagBits(client) & ADMFLAG_CUSTOM4)
									{ 
										CS_SetClientClanTag(client, "[MEMBER]"); 
									}
									else								
}										if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
										{ 
											CS_SetClientClanTag(client, "[DJ]"); 
										}
										else