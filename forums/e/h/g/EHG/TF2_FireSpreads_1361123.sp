#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

new offsPlyrCond = -1;

new Handle:h_Enabled;
new Handle:h_AdminI;


public Plugin:myinfo = 
{
	name = "Caution: Fire Spreads!",
	author = "EHG",
	description = "Fire spreads from player to player on touch",
	version = PLUGIN_VERSION,
	url = ""
}


public OnPluginStart()
{
	new String:game[10];
	GetGameFolderName(game, sizeof(game));
	if(!StrEqual(game, "tf"))
	{
		SetFailState("This plugin only works for Team Fortress 2");
	}
	
	if ((offsPlyrCond = FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) == -1)
	{
		SetFailState("Failed to find m_nPlayerCond");
	}
	
	CreateConVar("tf2_fire_spreads_version", PLUGIN_VERSION, "Caution: Fire Spreads! Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	h_Enabled = CreateConVar("tf2_fire_spreads", "1", "Enable/Disable fire spreading", FCVAR_PLUGIN);
	
	h_AdminI = CreateConVar("tf2_fire_spreads_admin_immunity", "0", "Enable/Disable admin immunity", FCVAR_PLUGIN);
	
	
}


public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_Touch, SpreadFire);
}


public SpreadFire(entity, other)
{
	if (GetConVarInt(h_Enabled) == 1 && entity <= MaxClients && entity >= 1 && other <= MaxClients && other >= 1)
	{
		if (GetConVarInt(h_AdminI) == 1 && GetUserAdmin(other) != INVALID_ADMIN_ID && GetAdminFlag(GetUserAdmin(other), Admin_Generic))
		{
			return;
		}
		new cond = GetEntData(entity, offsPlyrCond);
		if ((cond & TF_CONDFLAG_ONFIRE) == TF_CONDFLAG_ONFIRE)
		{
			TF2_IgnitePlayer(other, entity);
		}
	}
}