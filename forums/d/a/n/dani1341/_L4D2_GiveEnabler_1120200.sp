//Includes:
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new bool:onlyadmins = false
new Handle:CV_onlyadmins = INVALID_HANDLE
new bool:clientadminstate[MAXPLAYERS + 1]

public Plugin:myinfo = 
{
	name = "L4D Give enabler",
	author = "dani1341",
	description = "L4D2 Give Enabler",
	version = PLUGIN_VERSION,
	url = "http://compactaim.de"
};
public OnPluginStart()
{
	CreateConVar("sm_give_enabler_onlyadmin", PLUGIN_VERSION, "L4D2 Give Enabler", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("give", Command_give)
	
	SetCommandFlags("give",GetCommandFlags("give")^FCVAR_CHEAT)
	
	
	CV_onlyadmins = CreateConVar("sm_give_enabler_onlyadmin","0","0 = everybody can use give commands, 1 = only admins with the Cheat Flag");
	
	HookConVarChange(CV_onlyadmins,OnCVChangeonlyadmins)
}
public OnCVChangeonlyadmins(Handle:convar, const String:oldValue[], const String:newValue[])
{
	onlyadmins = GetConVarBool(CV_onlyadmins)
}
public OnConfigsExecuted()
{
	onlyadmins = GetConVarBool(CV_onlyadmins)
}

public OnClientPostAdminCheck(client)
{
	if (GetAdminFlag(GetUserAdmin(client),Admin_Cheats,Access_Effective))
	{
		clientadminstate[client] = true
	}
	else
	{
		clientadminstate[client] = false
	}
}
public Action:Command_give(client, args)
{
	if (onlyadmins)
	{
	if (!clientadminstate[client])
	{
	return Plugin_Handled
	}
	}
	return Plugin_Continue
}




