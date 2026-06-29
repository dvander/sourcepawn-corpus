/**
 * 
 * 						No Team Flash SourceMOD Plugin
 * 						Copyright (c) 2008 SAMURAI
 *						
 *            If you don't have what to to visit http://www.cs-utilz.net
 *            Thanks to Kigen for fixing some issues
 * 
**/

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "No Team Flash",
	author = "SAMURAI and Kigen",
	description = "Flashbang's thrower and users from his team won't be flashed",
	version = "0.3",
	url = "www.cs-utilz.net"
}


new g_FlashOwner = -1;

#define ALPHA_SET 0.5
new g_iFlashAlpha = -1;

new Handle:g_iConVar = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("flashbang_detonate", Event_Flashbang_detonate);
	HookEvent("player_blind", Event_Flashed);
	
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", "m_flFlashMaxAlpha");
	if ( g_iFlashAlpha == -1 )
		SetFailState("Failed to find \"m_flFlashMaxAlpha\".");
	
	g_iConVar = CreateConVar("no_team_flash","1"); // 0 - plugin disabled ; 1 - enabled
}


public Action:Event_Flashbang_detonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if( !client || !IsClientConnected(client) || !IsClientInGame(client) || !IsPlayerAlive(client) )
	{
		g_FlashOwner = -1; 
		return Plugin_Continue;
	}
	
	g_FlashOwner = client;
	
	return Plugin_Continue;
}


public Action:Event_Flashed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));

	if ( !GetConVarBool(g_iConVar) || !client || !IsClientInGame(client) )
		return Plugin_Continue;

	if ( !IsPlayerAlive(client) ) 
	{ 
		//PrintToChat(client, "Flash!");
		SetEntDataFloat(client, g_iFlashAlpha, ALPHA_SET);
		return Plugin_Continue;
	}
	
	CreateTimer(0.01, BlindTime, client);
	return Plugin_Continue;
}

public Action:BlindTime(Handle:timer, any:client)
{
	if ( g_FlashOwner != -1 && client != g_FlashOwner && IsClientInGame(client)  && IsPlayerAlive(client) && IsClientInGame(g_FlashOwner) && IsPlayerAlive(g_FlashOwner) && GetClientTeam(client) == GetClientTeam(g_FlashOwner) )
		SetEntDataFloat(client, g_iFlashAlpha, ALPHA_SET);
	
	return Plugin_Stop;
}