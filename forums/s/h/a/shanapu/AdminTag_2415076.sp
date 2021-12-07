#include <sourcemod>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "AdminTag",
	description = "Give admin tags & remove all steam tags",
	author = "shanapu, KeepCalm,Dragonidas",
	version = "4.1.1",
	url = "shanapu.de"
};


public void OnPluginStart()
{
	HookEvent("player_connect", TagIt);
	HookEvent("player_team", TagIt);
	HookEvent("player_spawn", TagIt);
	return;
}

public void OnClientPutInServer(int client)
{
	HandleTag(client);
}

public Action TagIt(Handle event, char [] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (0 < client)
	{
		HandleTag(client);
	}
}

public int HandleTag(int client)

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
								CS_SetClientClanTag(client, "");  // No Flag No Tag
							}
}