#include <sourcemod> 
#include <cstrike>


new Handle:hTag;


public OnPluginStart() 
{ 
    hTag = CreateConVar("sm_admintag", "[ADMIN]", "the admin tag"); 
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
    if (GetUserFlagBits(client) & ADMFLAG_GENERIC) 
    { 
        decl String:admintag[32]; 
        GetConVarString(hTag, admintag, 32); 
        CS_SetClientClanTag(client, admintag); 
    } 
    else 
    { 
        CS_SetClientClanTag(client, ""); 
    } 
  }
} 