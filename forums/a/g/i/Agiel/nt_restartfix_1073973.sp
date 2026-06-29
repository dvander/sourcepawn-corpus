/**************************************************************
--------------------------------------------------------------
 NEOTOKYO° Restart Fix

 Plugin licensed under the GPLv3
 
 Coded by Agiel.
--------------------------------------------------------------

Changelog

	1.0.0
		* Initial release
**************************************************************/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION	"1.0.01"

public Plugin:myinfo =
{
    name = "NEOTOKYO° Restart Fix",
    author = "Agiel",
    description = "Resets deaths on neo_restart_this 1 in NEOTOKYO°",
    version = PLUGIN_VERSION,
    url = ""
};

new Handle:convar_nt_restart_fix_version = INVALID_HANDLE;

public OnPluginStart()
{
	convar_nt_restart_fix_version = CreateConVar("sm_nt_restart_fix_version", PLUGIN_VERSION, "NEOTOKYO° Restart Fix.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	AutoExecConfig(true);
	SetConVarString(convar_nt_restart_fix_version, PLUGIN_VERSION, true, true);
	
	HookConVarChange(FindConVar("neo_restart_this"), Event_Restart);
}

public Event_Restart(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) == 1)
	{
		for (new i = 0; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				//PrintToServer("Resetting deaths for %N.", i);
				SetEntProp(i, Prop_Data, "m_iDeaths", 0);
			}
		}
	}
}	

bool:IsValidClient(client)
{
	
	if (client == 0)
		return false;
	
	if (!IsClientConnected(client))
		return false;
	
	if (IsFakeClient(client))
		return false;
	
	if (!IsClientInGame(client))
		return false;
	
	return true;
}