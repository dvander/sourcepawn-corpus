/**
 * 
 * 						No Team Flash SourceMOD Plugin
 * 						Copyright (c) 2008 SAMURAI 
 * 
**/

#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "No Team Flash",
	author = "SAMURAI",
	description = "Flashbang's thrower and users from his team won't be flashed",
	version = "0.1",
	url = "www.cs-utilz.net"
}


new g_FlashOwner;

#define ALPHA_SET 0.5
new g_iFlashAlpha = -1;

new Handle:g_iConVar = INVALID_HANDLE;

stock const String:sz_AflphaOffset[] = "m_flFlashMaxAlpha";


public OnPluginStart()
{
	HookEvent("weapon_fire",event_weapon_fire);
	HookEvent("player_blind",Event_Flashed,EventHookMode_Pre);
	
	g_iFlashAlpha = FindSendPropOffs("CCSPlayer", sz_AflphaOffset);
	
	g_iConVar = CreateConVar("no_team_flash","1"); // 0 - plugin disabled ; 1 - enabled
}


public Action:event_weapon_fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	decl String:szWeapon[64];
	GetEventString(event,"weapon",szWeapon,sizeof(szWeapon));
	
	if( !IsClientConnected(client) && !IsClientInGame(client) && !IsPlayerAlive(client))
		return Plugin_Continue;
	
	if(!GetConVarInt(g_iConVar))
		return Plugin_Continue;
	
	if(StrContains(szWeapon,"flashbang",false) !=-1)
	{
		g_FlashOwner = client;
	}
	
	return Plugin_Continue;
}


public Action:Event_Flashed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event,"userid"));
	
	if( (!IsClientConnected(client) && !IsClientInGame(client) && !IsPlayerAlive(client))
	|| (!IsClientConnected(g_FlashOwner) && !IsClientInGame(g_FlashOwner) && !IsPlayerAlive(g_FlashOwner)))
		return;
	
	if(!GetConVarInt(g_iConVar))
		return;
	
	if (g_iFlashAlpha != -1)
	{
		if(GetClientTeam(client) == GetClientTeam(g_FlashOwner) || client != g_FlashOwner)
		{
			SetEntDataFloat(client,g_iFlashAlpha,ALPHA_SET);
		}
	}
	
}

		
