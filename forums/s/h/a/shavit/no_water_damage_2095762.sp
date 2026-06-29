#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new bool:gB_Enabled;
new Handle:gH_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[ANY] No Water Damage",
	author = "shavit",
	description = "Disable damaging from water idling.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=163134"
}

public OnPluginStart()
{
	CreateConVar("sm_nowaterdamage_version", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN);
	
	gH_Enabled = CreateConVar("sm_nowaterdamage_enabled", "1", "Disabled damage received from water?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Enabled = GetConVarBool(gH_Enabled);
	
	HookConVarChange(gH_Enabled, OnConVarChanged);
	
	AutoExecConfig();
}

public OnConVarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = StringToInt(newVal)? true:false;
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!gB_Enabled)
	{
		return Plugin_Continue;
	}
	
	if(damagetype == DMG_DROWN || damagetype == DMG_DROWNRECOVER)
	{
		damage = 0.0;
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
