#include <sourcemod>
#include <tf2>

#pragma semicolon 1
#pragma newdecls required

ConVar	crits, chance;

#define PLUGIN_VERSION "0.2"

public Plugin myinfo = 
{
	name = "SM Crits chance",
	author = "pRED*, Tk /id/Teamkiller324",
	description = "Change critical hit %",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public void OnPluginStart()
{
	crits	= CreateConVar("sm_crits_enabled",	"1");
	chance	= CreateConVar("sm_crits_chance",	"1.00");
	
	CreateConVar("sm_crits_version", PLUGIN_VERSION, "Crits Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}


public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (!GetConVarBool(crits))
		return Plugin_Continue;	
	
	if (GetConVarFloat(chance) > GetRandomFloat(0.0, 1.0))
	{
		result = true;
		return Plugin_Handled;	
	}
	
	result = false;
	
	return Plugin_Handled;
}