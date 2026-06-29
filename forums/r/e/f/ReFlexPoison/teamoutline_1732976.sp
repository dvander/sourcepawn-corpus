#pragma semicolon 1

#include <sourcemod>
#include <tf2>

#define PLUGIN_VERSION "1.0.1"

new Handle:enabled;
new Handle:red;
new Handle:blue;

public Plugin:myinfo =
{
	name = "Team Outlines",
	author = "ReFlexPoison",
	description = "Set outline on all players of specified team(s).",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_teamoutline_version", PLUGIN_VERSION, "Team Outlines Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	enabled = CreateConVar("sm_teamoutline_enabled", "1", "Enable Team Outlines", FCVAR_NONE, true, 0.0, true, 1.0);
	red = CreateConVar("sm_teamoutline_red", "1", "Enable Outlines on Red", FCVAR_NONE, true, 0.0, true, 1.0);
	blue = CreateConVar("sm_teamoutline_blue", "1", "Enable Outlines on Blue", FCVAR_NONE, true, 0.0, true, 1.0);

	HookEvent("player_spawn", Event_Start);
	HookEvent("teamplay_round_start", Event_Start);
}

///////////
//ACTIONS//
///////////

public Event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(enabled) && GetConVarBool(red))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Red)
			{
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
	}
	if(GetConVarBool(enabled) && GetConVarBool(blue))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i) && GetClientTeam(i) == _:TFTeam_Blue)
			{
				SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
			}
		}
	}
}

//////////
//STOCKS//
//////////


stock IsValidClient(client, bool:replaycheck = true)
{
	if(client <= 0 || client > MaxClients)
	{
		return false;
	}
	if(!IsClientInGame(client))
	{
		return false;
	}
	if(GetEntProp(client, Prop_Send, "m_bIsCoaching"))
	{
		return false;
	}
	if(replaycheck)
	{
		if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	}
	return true;
}