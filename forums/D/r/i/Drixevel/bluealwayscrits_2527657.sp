//Pragma
#pragma semicolon 1
#pragma newdecls required

//Includes
#include <sourcemod>
#include <tf2_stocks>

//ConVars
ConVar convar_Status;

public Plugin myinfo = 
{
	name = "[TF2] Blue Always Crits", 
	author = "Keith Warren (Drixevel)", 
	description = "Grants crits to blues all the time.", 
	version = "1.0.0", 
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	convar_Status = CreateConVar("sm_bluealwayscrits_status", "1", "Status of the plugin.\n(1 = on, 0 = off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public Action TF2_CalcIsAttackCritical(int client, int weapon, char[] weaponname, bool &result)
{
	if (GetConVarBool(convar_Status) && TF2_GetClientTeam(client) == TFTeam_Blue)
	{
		result = true;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}