#include <sourcemod>
#pragma semicolon 1

new UserMsg:g_FadeUserMsgId;

public OnPluginStart()
{
	//L4D2 check
	decl String:game[12];
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "left4dead2") == -1) SetFailState("Jockey blind will only work with Left 4 Dead 2!");
	
	//hooking events
	HookEvent("jockey_ride", Ride_Event);
	HookEvent("jockey_ride_end", Ride_End_Event);
	HookEvent("player_incapacitated", Incap_Event);
	
	//get usermsgid
	g_FadeUserMsgId = GetUserMessageId("Fade");
}

public Action:Ride_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	//bot?
	//if (IsFakeClient(client_victim)) return Plugin_Continue;
	
	new clients[2];
	clients[0] = client_victim;	
	
	//make almost blind - rgba(0,0,0,202)
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 255);
	BfWriteShort(message, 0);
	BfWriteShort(message, (0x0002 | 0x0008));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 202);
	EndMessage();		
	
	//hud disable
	SetEntProp(client_victim, Prop_Send, "m_iHideHUD", 64);
	
	return Plugin_Continue;
}

public Action:Ride_End_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_victim = GetClientOfUserId(GetEventInt(event, "victim"));
	
	//bot?
	//if (IsFakeClient(client_victim)) return Plugin_Continue;

	new clients[2];
	clients[0] = client_victim;	
	
	//override clear sight
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();		
	
	//hud enable
	SetEntProp(client_victim, Prop_Send, "m_iHideHUD", 0);
	
	return Plugin_Continue;
}

public Action:Incap_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:weapon[32];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (StrContains(weapon, "jockey_claw") == -1) return Plugin_Continue;

	new client_victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new clients[2];
	clients[0] = client_victim;	
	
	//override clear sight
	new Handle:message = StartMessageEx(g_FadeUserMsgId, clients, 1);
	BfWriteShort(message, 1536);
	BfWriteShort(message, 1536);
	BfWriteShort(message, (0x0001 | 0x0010));
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	BfWriteByte(message, 0);
	EndMessage();		
	
	//hud enable
	SetEntProp(client_victim, Prop_Send, "m_iHideHUD", 0);
	
	return Plugin_Continue;
}