#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1;

#define PLUGIN_VERSION "0.5"

public Plugin:myinfo = 
{
	name = "Grenade View",
	author = "Sheepdude",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new bool:ClientView[MAXPLAYERS+1];

public OnPluginStart()
{
	HookEvent("hegrenade_detonate", OnDetonate);
}

public OnEntityCreated(iEntity, const String:classname[]) 
{
	if(StrEqual(classname, "hegrenade_projectile"))
		SDKHook(iEntity, SDKHook_SpawnPost, OnEntitySpawned);
}

public OnEntitySpawned(iGrenade)
{
	new client = GetEntPropEnt(iGrenade, Prop_Send, "m_hOwnerEntity");
	if(!ClientView[client] && IsClientInGame(client))
	{
		SetClientViewEntity(client, iGrenade);
		ClientView[client] = true;
	}
}

public OnDetonate(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ClientView[client])
	{
		ClientView[client] = false;
		if(IsClientInGame(client))
			SetClientViewEntity(client, client);
	}
}