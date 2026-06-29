#include <sourcemod>
#include <tf2attributes>

#define PYROVISION_ATTRIBUTE "vision opt in flags"

#define VERSION "1.2"

#pragma semicolon 1

new Handle:cvar_Enabled = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Pyrovision",
	author = "Powerlord",
	description = "Attempt to give players Pyrovision",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=188646"
}

public OnPluginStart()
{
	CreateConVar("pyrovision_version", VERSION, "PyroVision Version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvar_Enabled = CreateConVar("pyrovision_enabled", "1", "Enable Pyrovision for all players?", FCVAR_NONE, true, 0.0, true, 1.0);
	
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
				TF2Attrib_SetByName(i, PYROVISION_ATTRIBUTE, 1.0);
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
	
	TF2Attrib_SetByName(client, PYROVISION_ATTRIBUTE, 1.0);
}
