#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
#define PLUGIN_VERSION "v1.0"

new Handle:cvar = INVALID_HANDLE;

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    SetConVarInt(cvar, 1, true, true);
}

public Plugin:myinfo =
{
	name = "MOTHER ZOMBIE TELEPORT",
	author = "Nano",
	description = "Teleport ALL MOTHERZOMBIES to spawn",
	version = PLUGIN_VERSION,
	url = "http://asozombiemod.wix.com/asozombiemod"
};

public OnPluginStart()
{
	CreateConVar("sm_spec_version", PLUGIN_VERSION, "Spectator Switch Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);		
    if((cvar = FindConVar("zr_infect_mzombie_respawn")) != INVALID_HANDLE)
    {
        SetConVarInt(cvar, 1, true, true);
        HookConVarChange(cvar, ConVarChanged);
    }
}  



