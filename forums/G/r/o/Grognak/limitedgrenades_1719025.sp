/*
 * [CSS] Limited Grenades
 * 
 * Author:  Grognak
 * Version: 1.0
 * Date:    5/25/12
 *
 */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME         "Limited Grenades"
#define PLUGIN_AUTHOR       "Grognak"
#define PLUGIN_DESCRIPTION  "Prevents grenade spam on 16k servers."
#define PLUGIN_VERSION      "1.0"
#define PLUGIN_CONTACT      "grognak.tf2@gmail.com"

new iHE[MAXPLAYERS+1]    = {0, ...};
new iFlash[MAXPLAYERS+1] = {0, ...};
new iSmoke[MAXPLAYERS+1] = {0, ...};

new Handle:cvarEnabled    = INVALID_HANDLE;
new Handle:cvarLimitHE    = INVALID_HANDLE;
new Handle:cvarLimitFlash = INVALID_HANDLE;
new Handle:cvarLimitSmoke = INVALID_HANDLE;

public Plugin:myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_CONTACT
};

public OnPluginStart()
{
	CreateConVar("grenadelimit_version", PLUGIN_VERSION, "Grenade Limit version", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);

	cvarEnabled = CreateConVar("grenadelimit_enabled", "1", "Enable the Plugin?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvarLimitHE = CreateConVar("grenadelimit_helimit", "1", "Amount of HE Grenades allowed per round. -1 for no limit.", FCVAR_PLUGIN, true, -1.0);
	cvarLimitFlash = CreateConVar("grenadelimit_flashlimit", "2", "Amount of Flash Grenades allowed per round. -1 for no limit.", FCVAR_PLUGIN, true, -1.0);
	cvarLimitSmoke = CreateConVar("grenadelimit_smokelimit", "1", "Amount of Smoke Grenades allowed per round. -1 for no limit.", FCVAR_PLUGIN, true, -1.0);

	HookEvent("round_start", Event_RoundStart);
	RegConsoleCmd("buy", cmdBuy);

	AutoExecConfig(true);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetGrenadeCount();
}

public Action:cmdBuy(iClient, args)
{
	if (!GetConVarBool(cvarEnabled))
		return Plugin_Continue;

	decl String:sWeapon[128], iLimitHE, iLimitFlash, iLimitSmoke;
	
	iLimitHE    = GetConVarInt(cvarLimitHE);
	iLimitFlash = GetConVarInt(cvarLimitFlash);
	iLimitSmoke = GetConVarInt(cvarLimitSmoke);
	
	GetCmdArgString(sWeapon, sizeof(sWeapon));

	if (StrContains(sWeapon, "weapon_hegrenade", false))
	{
		if (iHE[iClient] < iLimitHE || iLimitHE == -1)
		{
			iHE[iClient]++;
			return Plugin_Continue;
		}
		else
		{
			PrintToChat(iClient, "\x04 HE Grenades are restricted to %i per round.", iLimitHE);
			return Plugin_Handled;
		}
	}	
	else if (StrContains(sWeapon, "weapon_flashbang", false))
	{
		if (iFlash[iClient] < iLimitFlash || iLimitFlash == -1)
		{
			iFlash[iClient]++;
			return Plugin_Continue;
		}
		else
		{
			PrintToChat(iClient, "\x04 Flashbangs are restricted to %i per round.", iLimitFlash);
			return Plugin_Handled;
		}
	}	
	else if (StrContains(sWeapon, "weapon_smokegrenade", false))
	{
		if (iSmoke[iClient] < iLimitSmoke || iLimitSmoke == -1)
		{
			iSmoke[iClient]++;
			return Plugin_Continue;
		}
		else
		{
			PrintToChat(iClient, "\x04 Smoke Grenades are restricted to %i per round.", iLimitSmoke);
			return Plugin_Handled;
		}
	}	

	return Plugin_Continue;
}

ResetGrenadeCount()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		iHE[i]    = 0;
		iFlash[i] = 0;
		iSmoke[i] = 0;
	} 
}
