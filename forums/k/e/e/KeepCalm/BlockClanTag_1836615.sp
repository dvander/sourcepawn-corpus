#include <sourcemod> 
#include <cstrike>

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
	CS_SetClientClanTag(client, ""); 
  }
} 