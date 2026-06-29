#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <left4dhooks>

#define PLUGIN_VERSION 		"1.0"

// Setting up ConVAr Handles
ConVar Cvar_On;
ConVar Cvar_Jockey;
ConVar Cvar_Smoker;

// ====================================================================================================
// myinfo - Basic plugin information
// ====================================================================================================

public Plugin myinfo =
{
	name = "Ledge Control",
	author = "$atanic $pirit",
	description	= "Control when survivors will grab ledge",
	version = PLUGIN_VERSION,
	url = ""
}

// ====================================================================================================
// OnPluginStart - Setting CVARS and Configuring Hooks
// ====================================================================================================
	
public void OnPluginStart()
{
	// Setup plugin ConVars
	Cvar_On				= CreateConVar("l4d2_lc",					"1",	"On/Off for the plugin.");	
	Cvar_Jockey			= CreateConVar("l4d2_lc_jockey",			"1",	"On/Off switch for Jockey ledge grab");	
	Cvar_Smoker			= CreateConVar("l4d2_lc_smoker",			"1",	"On/Off switch for Smoker ledge grab");
	
	// Auto create the config file.
	AutoExecConfig(true, "l4d2_ledge_control");
}

// ====================================================================================================
// L4D_OnLedgeGrabbed - Block ledge grab
// ====================================================================================================

public Action L4D_OnLedgeGrabbed(int client)
{	
	if(Cvar_On.BoolValue && L4D_IsPlayerCapped(client))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// ====================================================================================================
// L4D_IsPlayerCapped - Is Player capped by jockey or smoker?
// ====================================================================================================

bool L4D_IsPlayerCapped(int client)
{	
	// Check if client is in the game 
	if(!IsValidClient(client))
		return false;
		
	// Is client being dominated by jockey?	
	if(Cvar_Jockey.BoolValue && GetEntPropEnt(client, Prop_Send, "m_jockeyAttacker") > 0)
		return true;
		
	// Is client being dominated by smoker?
	if(Cvar_Smoker.BoolValue && GetEntPropEnt(client, Prop_Send, "m_tongueOwner") > 0)
		return true;

	return false;
}

// ====================================================================================================
// IsValidClient - Just checking if our client is in the game
// ====================================================================================================

bool IsValidClient(int client)
{
	if(client > 0 && client <= MaxClients)
	{
		if(IsClientInGame(client))
		{
			if(GetClientTeam(client) == 2)
			{
				return true;
			}
		}
	} 
	return false;
}