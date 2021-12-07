#define PLUGIN_VERSION		"1.0"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <l4d_god_frames>

public Plugin myinfo =
{
	name = "[L4D & L4D2] God Frames - Forward Test",
	author = "SilverShot",
	description = "Prevent common infected from damaging invulnerable players.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=320023"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead && test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnAllPluginsLoaded()
{
	if( LibraryExists("l4d_god_frames") == false )
	{
		SetFailState("God Frames - Forward Test 'l4d_god_frames.core.smx' plugin not loaded.");
	}
}

public Action OnTakeDamage_Invulnerable(int client, int attacker, float &damage)
{
	if( attacker > MaxClients && GetClientTeam(client) == 2 && GetEntProp(client, Prop_Send, "m_isIncapacitated", 1) )
	{
		char classname[10];
		GetEdictClassname(attacker, classname, sizeof classname);
		if( strcmp(classname, "infected") == 0 )
		{
			damage = 0.0;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}