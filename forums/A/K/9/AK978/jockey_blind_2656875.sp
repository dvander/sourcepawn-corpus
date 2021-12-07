#pragma semicolon 1
#include <sourcemod>


new UserMsg:g_FadeUserMsgId;
new screen_change[MAXPLAYERS+1];
new ride[MAXPLAYERS+1];

public OnPluginStart() 
{
  HookEvent("jockey_ride", Event_Jockey_Ride);
  HookEvent("jockey_ride_end", Event_Jockey_Ride_End);
  HookEvent("player_incapacitated", Event_Incap);
  HookEvent("player_death", Event_death);
  HookEvent("jockey_killed", Event_jockey_killed);
  
  g_FadeUserMsgId = GetUserMessageId("Fade");
}

public Action:Event_jockey_killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (ride[client] == 1)
	{
		new victim = GetEntPropEnt(client, Prop_Send, "m_jockeyVictim");		
		if (IsValidClient(victim) && screen_change[victim] == 1)
		{
			screen_change[victim] = 0;
			PerformBlind(victim, 0);
		}
	}
	return Plugin_Continue;
}

public Action:Event_Jockey_Ride(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "userid");
	new victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	if (IsValidClient(client))
	{
		ride[client] = 1;
	}
	
	if (IsValidClient(victim))
	{
		screen_change[victim] = 1;
		PerformBlind(victim, 255);
	}	
	return Plugin_Continue;
}

public Action:Event_Jockey_Ride_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "userid");
	new victims = GetClientOfUserId(GetEventInt(event, "victim"));

	if (IsValidClient(client))
	{
		ride[client] = 0;
	}
	
	if (IsValidClient(victims))
	{
		screen_change[victims] = 0;
		PerformBlind(victims, 0);		
	}
	return Plugin_Continue;
}

public Action:Event_Incap(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && screen_change[client] == 1)
	{
		screen_change[client] = 0;
		PerformBlind(client, 0);		
	}
	return Plugin_Continue;
}

public Action:Event_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsValidClient(client) && screen_change[client] == 1)
	{
		screen_change[client] = 0;
		PerformBlind(client, 0);		
	}
	return Plugin_Continue;
}

PerformBlind(target, amount)
{
	new targets[2];
	targets[0] = target;
	
	new Handle:message = StartMessageEx(g_FadeUserMsgId, targets, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	
	if (amount == 0)
	{
		BfWriteShort(message, (0x0001 | 0x0010));
	}
	else
	{
		BfWriteShort(message, (0x0002 | 0x0008));
	}
	
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, amount);
	
	EndMessage();
}

stock bool:IsValidClient(client) 
{
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}
