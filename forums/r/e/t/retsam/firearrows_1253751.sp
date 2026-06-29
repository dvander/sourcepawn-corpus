/*
* Fire Arrows (TF2) 
* Author(s): retsam
* File: firearrows.sp
* Description: Gives huntsman users flaming arrows!
*
*
*
* 0.2 - Added root flag check.
*
* 0.1	- Initial release. 
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION "0.2"

new Handle:Cvar_Firearrow_Enabled = INVALID_HANDLE;
new Handle:Cvar_Firearrow_AdminFlag = INVALID_HANDLE;
new Handle:Cvar_Firearrow_AdminOnly = INVALID_HANDLE;

new g_cvarAdminOnly;

new bool:g_bIsPlayerAdmin[MAXPLAYERS + 1] = { false, ... };
new bool:g_bIsEnabled = true;

new String:g_sCharAdminFlag[32];

public Plugin:myinfo = 
{
	name = "Fire Arrows",
	author = "retsam",
	description = "Gives huntsman users flaming arrows!",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=133698"
}

public OnPluginStart()
{
	CreateConVar("sm_firearrows_version", PLUGIN_VERSION, "Version of Fire Arrows", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Cvar_Firearrow_Enabled = CreateConVar("sm_firearrows_enabled", "1", "Enable firearrows plugin?(1/0 = yes/no)");
	Cvar_Firearrow_AdminOnly = CreateConVar("sm_firearrows_adminonly", "0", "Enable firearrows for admins only? (1/0 = yes/no)");
	Cvar_Firearrow_AdminFlag = CreateConVar("sm_firearrows_adminflag", "b", "Admin flag to use if adminonly is enabled (only one).  Must be a in char format.");

	HookConVarChange(Cvar_Firearrow_Enabled, Cvars_Changed);
	HookConVarChange(Cvar_Firearrow_AdminOnly, Cvars_Changed);

	//AutoExecConfig(true, "plugin.firearrows");
}

public OnClientPostAdminCheck(client)
{
	if(IsValidAdmin(client, g_sCharAdminFlag))
	{
		g_bIsPlayerAdmin[client] = true;
	}
	else
	{
		g_bIsPlayerAdmin[client] = false;
	}
}

public OnClientDisconnect(client)
{
	g_bIsPlayerAdmin[client] = false;
}

public OnConfigsExecuted()
{
	g_bIsEnabled = GetConVarBool(Cvar_Firearrow_Enabled);
	GetConVarString(Cvar_Firearrow_AdminFlag, g_sCharAdminFlag, sizeof(g_sCharAdminFlag));

	g_cvarAdminOnly = GetConVarInt(Cvar_Firearrow_AdminOnly);
}

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if(!g_bIsEnabled)
	return Plugin_Continue;

	if(IsValidEntity(weapon) && strcmp(weaponname, "tf_weapon_compound_bow") == 0)
	{
		if(g_cvarAdminOnly && !g_bIsPlayerAdmin[client])
		return Plugin_Continue;

		SetEntProp(weapon, Prop_Send, "m_bArrowAlight", 1);
	}
	
	return Plugin_Continue;
}

stock bool:IsValidAdmin(client, const String:flags[])
{
	if(!IsClientConnected(client))
	return false;
	
	new ibFlags = ReadFlagString(flags);
	if(!StrEqual(flags, ""))
	{
		if((GetUserFlagBits(client) & ibFlags) == ibFlags)
		{
			return true;
		}
	}

	if(GetUserFlagBits(client) & ADMFLAG_ROOT) 
	{
		return true;
	}
	
	return false;
}

public Cvars_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == Cvar_Firearrow_Enabled)
	{
		if(StringToInt(newValue) == 0)
		{
			g_bIsEnabled = false;
		}
		else
		{
			g_bIsEnabled = true;
		}
	}
	else if(convar == Cvar_Firearrow_AdminOnly)
	{
		g_cvarAdminOnly = StringToInt(newValue);
	}
}
