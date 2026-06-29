#pragma semicolon 1

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0.1"

#include <sourcemod>

#pragma newdecls required

Handle b_Enable;

public Plugin myinfo = 
{
	name = "[TF2] Auto Blues GodMode",
	author = PLUGIN_AUTHOR,
	description = "Gives godmode on blue team",
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	b_Enable = CreateConVar("sm_abg_enable", "1", "Enable/Disable Godmode on blue team.", _, true, 0.0, true, 1.0);
	HookEvent("player_spawn", TF2_PlayerSpawn);
}

public Action TF2_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	if(GetEventInt(event, "team") == 3 && GetConVarBool(b_Enable))
	{
		any client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client != 0) 
		{
			SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		}
	}
}
