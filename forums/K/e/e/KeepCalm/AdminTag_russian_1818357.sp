#include <sourcemod> 
#include <cstrike>

public Plugin:myinfo = 
{
    name = "Admin Clan Tag - Russian",
    author = "KeepCalm",
    description = "Private PLugin",
}

public OnPluginStart() 
{  
    HookEvent("player_team", Event); 
    HookEvent("player_spawn", Event); 
} 

public Action:Event(Handle:event, String:name[], bool:dontBroadcast) 
{ 
    new client = GetClientOfUserId(GetEventInt(event, "userid")); 
    HandleTag(client); 
} 

public OnClientPostAdminCheck(client) 
{ 
	HandleTag(client);
} 

HandleTag(client) 
{ 
  if (client > 0) 
  { 
    if (GetUserFlagBits(client) & ADMFLAG_ROOT) 
    { 
        CS_SetClientClanTag(client, "[владелец]");
    }
		else
				if (GetUserFlagBits(client) & ADMFLAG_GENERIC) 
				{ 
					CS_SetClientClanTag(client, "[администратор]"); 
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
} 