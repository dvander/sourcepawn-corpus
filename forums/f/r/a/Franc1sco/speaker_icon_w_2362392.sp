#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <voiceannounce_ex>
#include <basecomm>

new g_unClientSprite[MAXPLAYERS+1]={INVALID_ENT_REFERENCE,...};

public Plugin:myinfo =
{
	name = "SM Speaker Icon",
	author = "Franc1sco steam: franug",
	description = "",
	version = "2.1",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{

	HookEvent("player_death", Event_PlayerDeath);
}

public OnMapStart()
{
	//AddFileToDownloadsTable("materials/sprites/sg_micicon64.vmt");
	//AddFileToDownloadsTable("materials/sprites/sg_micicon64.vtf");
	PrecacheModel("materials/particle/voice_icon_particle.vmt", true);
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
		decl String:iTarget[16];
		Format(iTarget, 16, "client%d", client);
		DispatchKeyValue(client, "targetname", iTarget);
		//DispatchKeyValue(m_unEnt, "model", "materials/sprites/sg_micicon64.vmt");
		DispatchKeyValue(m_unEnt, "classname", "env_sprite");
		DispatchKeyValue(m_unEnt, "scale", "0.25");
		DispatchKeyValue(m_unEnt, "rendermode", "1");		//to use the rendercolor
		DispatchKeyValue(m_unEnt, "rendercolor", "0 255 0");
		DispatchKeyValue(m_unEnt, "model", "particle/voice_icon_particle.vmt");
		DispatchSpawn(m_unEnt);

		new Float:m_flPosition[3];
		GetClientAbsOrigin(client, m_flPosition);
		m_flPosition[2]+=80.0;

		TeleportEntity(m_unEnt, m_flPosition, NULL_VECTOR, NULL_VECTOR);
	   
		//SetVariantString("!activator");
		//AcceptEntityInput(m_unEnt, "SetParent", client, m_unEnt, 0);
		
		//SetVariantString("francisco");
		SetVariantString(iTarget);
		AcceptEntityInput(m_unEnt, "SetParent", m_unEnt, m_unEnt, 0);
	  
		g_unClientSprite[client] = EntIndexToEntRef(m_unEnt);
	}
}

public bool:OnClientSpeakingEx(client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || BaseComm_IsClientMuted(client))
		return;
		
	CreateSprite(client);
}

public OnClientSpeakingEnd(client)
{
	ResetSprite(client);
}