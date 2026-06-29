#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <voiceannounce_ex>

new g_unClientSprite[MAXPLAYERS+1]={INVALID_ENT_REFERENCE,...};

public Plugin:myinfo =
{
	name = "SM Speaker Icon",
	author = "Franc1sco steam: franug",
	description = "",
	version = "2.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{

	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	AddFileToDownloadsTable("materials/sprites/sg_micicon64.vmt");
	AddFileToDownloadsTable("materials/sprites/sg_micicon64.vtf");
	PrecacheModel("materials/sprites/sg_micicon64.vmt", true);
}

public OnClientConnected(client)
{
	g_unClientSprite[client]=INVALID_ENT_REFERENCE;
}

public OnClientDisconnect(client)
{
	ResetSprite(client);

}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	ResetSprite(client);

	return Plugin_Continue;
}

public ResetSprite(client)
{
	if(g_unClientSprite[client] == INVALID_ENT_REFERENCE)
		return;

	new m_unEnt = EntRefToEntIndex(g_unClientSprite[client]);
	g_unClientSprite[client] = INVALID_ENT_REFERENCE;
	if(m_unEnt == INVALID_ENT_REFERENCE)
		return;

	AcceptEntityInput(m_unEnt, "Kill");
}

public CreateSprite(client)
{
	if(g_unClientSprite[client] != INVALID_ENT_REFERENCE)
		return;

	new m_unEnt = CreateEntityByName("env_sprite");
	if (IsValidEntity(m_unEnt))
	{
		DispatchKeyValue(m_unEnt, "model", "materials/sprites/sg_micicon64.vmt");
		DispatchSpawn(m_unEnt);

		decl Float:m_flPosition[3];
		GetClientEyePosition(client, m_flPosition);
		m_flPosition[2] += 20.0;

		TeleportEntity(m_unEnt, m_flPosition, NULL_VECTOR, NULL_VECTOR);
	   
		SetVariantString("!activator");
		AcceptEntityInput(m_unEnt, "SetParent", client, m_unEnt, 0);
		
		SetEntPropEnt(m_unEnt, Prop_Data, "m_hOwnerEntity", client);
	  
		g_unClientSprite[client] = EntIndexToEntRef(m_unEnt);
		
		SDKHook(m_unEnt, SDKHook_SetTransmit, OnTrasnmit);
	}
}

public Action:OnTrasnmit(entity, client)
{
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (owner == client || GetListenOverride(client, owner) == Listen_No || IsClientMuted(client, owner))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public OnClientSpeakingEx(client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;
		
	CreateSprite(client);
}

public OnClientSpeakingEnd(client)
{
	ResetSprite(client);
}