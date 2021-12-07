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
	version = "1.2",
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
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_Round(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_h_round_timer != INVALID_HANDLE) // Timer is unfinished!
	{
		KillTimer(g_h_round_timer);
		g_h_round_timer = INVALID_HANDLE;
		g_respawn = false;
	}
	
	if (StrEqual(name, "round_freeze_end", false))
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
	if (IsClientInGame(client))
	{
		new team = GetClientTeam(client);
		if (IsClientInGame(client) && (team == CS_TEAM_CT || team == CS_TEAM_T))
		{
			CS_RespawnPlayer(client);
		}
	}
}

// This will block any respawns after sm_respawn_time is up.
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new team = GetClientTeam(client);

    if (team == 2 || team == 3)
    {
        if (!g_respawn && GetConVarBool(g_h_respawn) && GetPlayerTeamCount() > 4)
        {
            new kills = GetClientFrags(client) + 1;
            new deaths = GetClientDeaths(client) - 1;

            ForcePlayerSuicide(client);

            SetEntProp(client, Prop_Data, "m_iFrags", kills);
            SetEntProp(client, Prop_Data, "m_iDeaths", deaths);

            PrintToChat(client, "[Server] You will have to wait till next round");
        }
    }
}

GetPlayerTeamCount() 
{ 
	new iCount = 0; 
	for (new i = 1; i <= MAXPLAYERS; i++)
	{
		if (IsClientInGame(i))
		{
			new team = GetClientTeam(i);
			if (IsClientInGame(i) && (team == CS_TEAM_CT || team == CS_TEAM_T))
			{
				iCount++; 
			}
		}
	}
	return iCount; 
} 