#include <sourcemod>
#include <tf2attributes>

#define PYROVISION_ATTRIBUTE "vision opt in flags"

#define VERSION "1.3"

#pragma semicolon 1

new Handle:cvar_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Romevision",
	author = "Powerlord",
	description = "Attempt to give players Romevision",
	version = VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("romevision_version", VERSION, "RomeVision Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvar_Enabled = CreateConVar("romevision_enabled", "1", "Enable Romevision for all players?", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookConVarChange(cvar_Enabled, Change_Enabled);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Change_Enabled(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (GetConVarBool(cvar_Enabled))
	{
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				TF2Attrib_SetByName(i, PYROVISION_ATTRIBUTE, 4.0);
			}
		}
	}
	else
	{
		for (new i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				TF2Attrib_RemoveByName(i, PYROVISION_ATTRIBUTE);
			}
		}
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvar_Enabled))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	TF2Attrib_SetByName(client, PYROVISION_ATTRIBUTE, 4.0);
}
