//******************************************************************
// sf_Admin_Block_Protection_System.sp
// 17.08.2008 Chanz
// Admin Block Protection System
// With this plugin you can select blocks which shouldn't be unfrozen by normal players.
//******************************************************************

#include <sourcemod>
#include <sdktools>
#include <entity>
#pragma semicolon 1

#define MAXENTITYS 2000
#define PLUGIN_VERSION "1.1"

new bool:gBlockIDProtect[MAXENTITYS];
new Handle:abps_version = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Admin Block Protection System",
	author = "Chanz",
	description = "Admin freezes a block which normal players are not allowed to unfreeze.",
	version = PLUGIN_VERSION,
	url = "www.mannisfunhouse.eu"
}

public OnPluginStart()
{
	abps_version = CreateConVar("abps_version", PLUGIN_VERSION, "Admin Block Protection System Version", FCVAR_PLUGIN|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(abps_version, PLUGIN_VERSION);
	HookEvent("block_unfrozen", Event_Block_Unfrozen);
	RegAdminCmd("sm_protectblock", Admin_Protect_Freeze, ADMFLAG_KICK, "sm_admin_blockprotect - look at a block while using this command");
}


public OnMapStart()
{
	for(new i = 0; i < MAXENTITYS; i++)
	{
		gBlockIDProtect[i] = false;
	}
}


public Action:Admin_Protect_Freeze(client, args)
{
	new blockid = GetClientAimTarget(client, false);
	new String:classname[64];
 	
	if (blockid > 0)
	{
		GetEntityNetClass(blockid, classname, 64);
	}
	
	if (StrEqual(classname, "CPhysicsPropBlock"))
	{
		if(gBlockIDProtect[blockid])
		{
			gBlockIDProtect[blockid] = false;
			AcceptEntityInput(blockid, "enablemovement");
			PrintToChat(client, "[SM] you disabled the Admin Block Protection System on this block ( %i )", blockid);
		}
		else
		{
			gBlockIDProtect[blockid] = true;
			AcceptEntityInput(blockid, "disablemovement");
			PrintToChat(client, "[SM] you enabled the Admin Block Protection System on this block ( %i )", blockid);
		}
	}
	
	return Plugin_Handled;
}



public Action:Event_Block_Unfrozen(Handle:event, const String:name[], bool:dontBroadcast)
{
	new playerid = GetEventInt(event, "userid");
	new blockid = GetEventInt(event, "blockid");
	
	if(gBlockIDProtect[blockid])
	{
		if(GetAdminFlags(GetUserAdmin(playerid), Access_Effective) > 0)
		{
			//PrintToChat(playerid, "[SM] This Block is Admin Protected but you are allowed to unfreeze it ( %i )", blockid); //debug stuff
			return Plugin_Continue;
		}
		else
		{
			PrintToChat(playerid, "[SM] This Block is Admin Protected and you are NOT allowed to unfreeze it ( %i )", blockid);
			//ClientCommand(playerid, "kill");
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

