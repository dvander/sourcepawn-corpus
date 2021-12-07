#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new Handle:g_h_respawn = INVALID_HANDLE;
new Handle:g_h_respawn_time = INVALID_HANDLE;
new bool:g_respawn = false;
new Handle:g_h_round_timer; // Store timer

public Plugin:myinfo = {
	name = "[BFG] Respawn Player",
	author = "Versatile_BFG",
	description = "Respawns players automatically for a certain amount of time",
	version = "1.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	g_h_respawn = CreateConVar("sm_respawn", "1", "Enable or disable the respawning of players", FCVAR_NOTIFY);
	g_h_respawn_time = CreateConVar("sm_respawn_time", "120", "Sets the seconds to wait before turning off respawning", FCVAR_NOTIFY, true, 0.0);
	
	HookEvent("player_death",  Event_Player_Death);
	HookEvent("round_freeze_end", Event_Round);
	HookEvent("round_start", Event_Round);
	HookEvent("round_end", Event_Round);
}

public Event_Round(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_h_round_timer != INVALID_HANDLE) // Timer is unfinished!
	{
		KillTimer(g_h_round_timer);
		g_h_round_timer = INVALID_HANDLE;
		g_respawn = false;
	}
	
	if(StrEqual(name, "round_freeze_end", false))
	{
		g_respawn = true;
		g_h_round_timer = CreateTimer(GetConVarFloat(g_h_respawn_time), RoundTimeEnd);
	}
}

public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (g_respawn && GetConVarBool(g_h_respawn))
	{
		// respawn if warmup
		CreateTimer(0.1, RespawnPlayer, victim);
	}
}

public Action:RoundTimeEnd(Handle:timer)
{
	g_h_round_timer = INVALID_HANDLE; // First priority, clear Handle when timer executed last time!
	
	g_respawn = false;
}  

public Action:RespawnPlayer(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		new team = GetClientTeam(client);
		if(IsClientInGame(client) && (team == CS_TEAM_CT || team == CS_TEAM_T))
		{
			CS_RespawnPlayer(client);
		}
	}
}