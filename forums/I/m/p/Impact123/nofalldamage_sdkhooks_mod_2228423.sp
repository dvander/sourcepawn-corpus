#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1



#define PLUGIN_VERSION "0.6.2-mod"



// Lateload
new bool:g_bLateLoaded;



new g_bClientImmuneToFallDMG[MAXPLAYERS];


public Plugin:myinfo = 
{
	name = "No Fall Damage v2 modified",
	author = "Impact",
	description = "Prevents players from taking damage by falling to the ground",
	version = PLUGIN_VERSION,
	url = "http://gugyclan.eu"
}





public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoaded = late;
	return APLRes_Success;
}





public OnPluginStart()
{
	RegAdminCmd("sm_nofalldamage", Command_NoFallDamage, ADMFLAG_GENERIC);
	
	
	LoadTranslations("common.phrases");
	
	
	// LateLoad;
	if(g_bLateLoaded)
	{
		for(new i; i <= MaxClients; i++)
		{
			if(IsClientValid(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}





public OnClientPostAdminCheck(client)
{
	if(IsClientValid(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}




public Action:Command_NoFallDamage(client, args)
{
	decl String:buffer[64];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	new target = FindTarget(client, buffer);
	
	if (target == -1 || !IsClientValid(target))
	{
		return Plugin_Handled;
	}
	
	g_bClientImmuneToFallDMG[target] = !g_bClientImmuneToFallDMG[target];
	
	ReplyToCommand(client, "You toggled %N's falldamage to %s", target, g_bClientImmuneToFallDMG[target] ? "On" : "Off");
	
	return Plugin_Handled;
}





public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	// We first check if damage is falldamage and then check the others
	if(damagetype & DMG_FALL)
	{
		if(g_bClientImmuneToFallDMG[client])
		{
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}





stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MaxClients && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}

