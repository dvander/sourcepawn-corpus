#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#pragma semicolon 1

/* 
	Current plugin version
*/
#define PLUGIN_VERSION "v3"


/*


/*
	Bools
*/
new bool:bFF;
/*

/* 
	Plugin information
*/
public Plugin:myinfo =
{
	name = "Friendly Fire CSGO",
	author = "Dk--",
	description = "enable / disable the friendly fire",
	version = PLUGIN_VERSION,
}

public OnPluginStart()
{
	 RegAdminCmd("sm_ff", FF_Command, ADMFLAG_GENERIC);
	HookEvent("round_start", OnRoundStart);
}

 
public Action:FF_Command(client, args)
{
	new Handle:ffMenu = CreateMenu(ffMenu_Action);
	SetMenuTitle(ffMenu, "Friendly Fire:");
	AddMenuItem(ffMenu, "enable", "On");
	AddMenuItem(ffMenu, "disable", "Off");
	DisplayMenu(ffMenu, client, 20);
	return Plugin_Handled;	
  }
public ffMenu_Action(Handle:ffMenu, MenuAction:action, client, param2) 
{
	if (action == MenuAction_Select) 
	{
		new String:option[32];
		GetMenuItem(ffMenu, param2, option, sizeof(option));
		
	    if(strcmp(option, "enable") == 0)
		{
			bFF = true;
			SetConVarInt(FindConVar("mp_autokick"), 0);
			SetConVarInt(FindConVar("mp_tkpunish"), 0);
			SetConVarInt(FindConVar("ff_damage_reduction_bullets"), 0.33);
			SetConVarInt(FindConVar("ff_damage_reduction_grenade"), 0.85);
			SetConVarInt(FindConVar("ff_damage_reduction_grenade_self"), 1);
			SetConVarInt(FindConVar("ff_damage_reduction_other"), 0);
	         PrintToChatAll("[FF] Friendly Fire enabled");
		}
		if(strcmp(option, "disable") == 0)
		{
			bFF = false;
			SetConVarInt(FindConVar("mp_autokick"), 0);
			SetConVarInt(FindConVar("mp_tkpunish"), 0);
			SetConVarInt(FindConVar("ff_damage_reduction_bullets"), 0);
			SetConVarInt(FindConVar("ff_damage_reduction_grenade"), 0);
			SetConVarInt(FindConVar("ff_damage_reduction_grenade_self"), 0);
			SetConVarInt(FindConVar("ff_damage_reduction_other"), 0);
	         PrintToChatAll("[FF] Friendly Fire");
		}
    }
}
public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	bFF = false;
	ServerCommand("sm_cvar ff_damage_reduction_bullets 0"); 
	ServerCommand("sm_cvar ff_damage_reduction_grenade 0"); 
	ServerCommand("sm_cvar ff_damage_reduction_grenade_self 0"); 
	ServerCommand("sm_cvar ff_damage_reduction_other 0"); 
}
