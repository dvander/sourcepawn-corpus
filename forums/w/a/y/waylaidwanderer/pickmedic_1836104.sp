#pragma semicolon 1;

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

new Handle:g_hEnabled = INVALID_HANDLE;

new bool:g_bEnabled;

public Plugin:myinfo = {
	name = "Pick a Medic",
	author = "waylaidwanderer",
	description = "Forces a random player to be medic.",
	version = PLUGIN_VERSION,
	url = "www.thectscommunity.com"
}


public OnPluginStart()
{
	CreateConVar("sm_pickmedic_version", PLUGIN_VERSION, "Current Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hEnabled = CreateConVar("sm_pickmedic_enabled", "1", "Enable/disable the plugin.", 0, true, 0.0, true, 1.0);
	HookConVarChange(g_hEnabled, OnConVarEnabledChanged);
	g_bEnabled = GetConVarBool(g_hEnabled);
	
	RegAdminCmd("sm_pickmedic", Command_PickMedic, ADMFLAG_GENERIC, "Picks a random player to be medic.");
}

public OnConVarEnabledChanged(Handle:convar, const String:oldvalue[], const String:newvalue[])
{
	g_bEnabled = (bool:StringToInt(newvalue));
}

public Action:Command_PickMedic(client, args)
{
	if (!g_bEnabled)
	{
		ShowActivity2(client, "[SM] ","This plugin is disabled. Please re-enable to use the command.");
		return Plugin_Continue;
	}
	new rndClient = GetRndClient();
	if (rndClient > -1)
	{
		TF2_SetPlayerClass(rndClient, TFClass_Medic);
		if(IsPlayerAlive(rndClient))
		{
			SetEntityHealth(rndClient, 25);
			TF2_RegeneratePlayer(rndClient);
			new weapon = GetPlayerWeaponSlot(rndClient, TFWeaponSlot_Primary);
			if(IsValidEntity(weapon))
			{
				SetEntPropEnt(rndClient, Prop_Send, "m_hActiveWeapon", weapon);
			}
		}
		ShowActivity2(client, "[SM] ","Set class of %N to medic.", rndClient);
	}
	else
	{
		ShowActivity2(client, "[SM] ","There has been an error of some sort!");
	}
	return Plugin_Continue;
}

GetRndClient()
{
	decl iClients[MaxClients];
	new numClients;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsClientSourceTV(i)) //&& !IsFakeClient(i) - add to skip targetting bots
		{
			iClients[numClients++] = i;
		}
	}
	
	if(numClients)
	{
		return (numClients) ? iClients[GetURandomInt() % numClients] : -1;
	}
	else
	{
		return -1;
	}
}  