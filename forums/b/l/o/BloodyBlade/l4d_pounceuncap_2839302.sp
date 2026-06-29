#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.2"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar hMaxPounceDmg, hMinPounceDist, hMaxPounceDist, hPounceDmg;

public Plugin myinfo = 
{
	name = "[L4D] PounceUncap",
	author = "n0limit",
	description = "Makes it easy to properly uncap hunter pounces",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=96546"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" game series.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_pounceuncap_version", PLUGIN_VERSION, "Current version of the plugin", CVAR_FLAGS);
	hPounceDmg = CreateConVar("l4d_pounceuncap_maxdamage", "25", "Sets the new maximum hunter pounce damage.", CVAR_FLAGS);
	hMaxPounceDmg = FindConVar("z_hunter_max_pounce_bonus_damage");
	hMaxPounceDist = FindConVar("z_pounce_damage_range_max");
	hMinPounceDist = FindConVar("z_pounce_damage_range_min");
	AutoExecConfig(true, "l4d_pounceuncap");
	hPounceDmg.AddChangeHook(OnMaxDamageChange);
}

public void OnConfigsExecuted()
{
    OnMaxDamageChange(null, "", "");
}

void OnMaxDamageChange(ConVar cvar, const char[] oldVal, const char[] newVal)
{
    int dist = 0, dmg = hPounceDmg.IntValue;
    dist = 28 * dmg + hMinPounceDist.IntValue;
    hMaxPounceDist.SetInt(dist, false, false);
    hMaxPounceDmg.SetInt(--dmg, false, false);
}
