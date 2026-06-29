#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

ConVar mp_roundtime = null;

public Plugin myinfo =
{
	name = "[CSS] Remove mp_roundtime upper Limit",
	author = "XeroX",
	description = "Allows setting the round time beyond the 8 minute limit",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};


public void OnPluginStart()
{
    mp_roundtime = FindConVar("mp_roundtime");
    mp_roundtime.SetBounds(ConVarBound_Upper, false);
}