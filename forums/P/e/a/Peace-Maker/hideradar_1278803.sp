#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
    name = "Hide Radar",
    author = "Jannik 'Peace-Maker' Hartung",
    description = "Hides all players from the radar.",
    version = PLUGIN_VERSION,
    url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
    CreateConVar("sm_hideradar_version", PLUGIN_VERSION, "Hides the radar", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnClientPutInServer(client)
{
	SetEntProp(client, Prop_Send, "m_iHideHUD", ( 1<<4 ));
}