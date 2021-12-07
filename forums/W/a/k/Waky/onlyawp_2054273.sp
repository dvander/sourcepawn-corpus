#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <smlib>
#include <sdkhooks>
#include <waky>

//------------Defines------------
#define PLUGIN_VERSION "1.0"
#define URL "www.area-community.net"
#define AUTOR "Waky"
#define NAME "SpawnHP"
#define DESCRIPTION "Sets Players HP at roundstart"
#define MAX_FILE_LEN 256

new Handle:hEnable = INVALID_HANDLE;
new Handle:hHSEnable = INVALID_HANDLE;
new iEnable;
new iHSEnable;


public Plugin:myinfo = 
{
	name = NAME,
	author = AUTOR,
	description = DESCRIPTION,
	version = PLUGIN_VERSION,
	url = URL
}
public OnPluginStart()
{	
	HookEvent("player_spawn",OnPlayerSpawn);
	hEnable = CreateConVar("onlyawp_enable","1","Enable only AWP? | 1=On, 0=Off");
	hHSEnable = CreateConVar("onlyawp_only_hs","0","Enable Only HS?");
	
	AutoExecConfig(true,"awp-only");
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsClientValid(client))
		{
			SDKHook(client, SDKHook_TraceAttack, OnDamage);
		}
	}
}
public OnConfigsExecuted()
{
	iEnable = GetConVarInt(hEnable);
	iHSEnable = GetConVarInt(hHSEnable);
}
public OnClientPutInServer(client)
{
	if(IsClientValid(client))
	{
		SDKHook(client,SDKHook_TraceAttack,OnDamage);
	}
}
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(iEnable)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsClientValid(client))
		{
			Client_RemoveAllWeapons(client,"weapon_knife",true);
			Client_GiveWeaponAndAmmo(client,"weapon_awp",true,200,-1,10,-1);
		}
	}
}
public Action:OnDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(iHSEnable)
	{
		if(hitgroup == 1)
		{
			damage *= 1.5;
			return Plugin_Changed;
		}
		else
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}