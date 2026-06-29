/*

*/

#pragma semicolon 1
#define PLUGIN_VERSION "1.1.0"
#include <sourcemod>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo =
{
	name = "TOG Bot Damage Immunity",
	author = "That One Guy",
	description = "Makes bot/replay clients immune to damage.",
	version = PLUGIN_VERSION,
	url = "https://www.togcoding.com/togcoding/"
}

public void OnPluginStart()
{
	CreateConVar("tbdi_version", PLUGIN_VERSION, "TOG Bot Damage Immunity - version number.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client) || IsClientReplay(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
	}
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public Action Event_OnTakeDamage(int victim, int &attacker, int &inflictor, float &fDamage, int &damagetype, int &weapon, float a_fDmgForce[3], float a_fDmgPosition[3]/*, int damagecustom*/)
{
	fDamage = 0.0;
	return Plugin_Changed;
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	1.0.0
		* Initial creation.
	1.1.0
		* Edit to only hook clients that are bots/replay, thereby removing the need to check within the hook callback. (Credit: Mitchell) 
		
*/