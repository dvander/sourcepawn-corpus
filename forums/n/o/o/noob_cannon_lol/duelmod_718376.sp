#include <sourcemod>
#include <sdktools>
#include <tf2>

#define TEAM_SPEC	1
#define TEAM_RED 	2
#define TEAM_BLUE 	3

new Handle:g_hTeamLimit
new Handle:g_hEnableTeamLimit
new Handle:g_hFragLimit

new g_roundmanager

public Plugin:myinfo = 
{
	name = "TF2 Duel Tools",
	author = "noobcannonlol",
	description = "For use on duel maps",
	version = "1.0",
	url = "gamesyn.com"
}

public OnMapStart()
{
	g_roundmanager = FindEntityByClassname(-1, "team_control_point_master")
	if (g_roundmanager == -1)
	{
		g_roundmanager = CreateEntityByName("team_control_point_master")
		DispatchSpawn(g_roundmanager)
		AcceptEntityInput(g_roundmanager, "Enable")
	}
}

public OnPluginStart()
{
	g_hEnableTeamLimit = CreateConVar("mp_enableteamlimit", "1", "1 (on) or 0 (off)")
	g_hTeamLimit = CreateConVar("mp_teamlimit", "1", "Limit teams to this value")
	g_hFragLimit = CreateConVar("mp_fraglimit", "20", "Set the frag limit")
	
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre)
	HookEvent("player_death", Event_PlayerDeath)
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetFragLimit() == 0)
		return Plugin_Continue
	
	new userId = GetEventInt(event, "attacker")
	new attacker = GetClientOfUserId(userId)
	
	if(!IsClientInGame(attacker))
		return Plugin_Continue
	
	new team = GetClientTeam(attacker)
	
	if (GetTeamFragCount(team) >= GetFragLimit())
		EndRound(team) 								// we got a winner
		
	return Plugin_Continue
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(g_hEnableTeamLimit))
		return Plugin_Continue
	
	new userId = GetEventInt(event, "userid")
	new oldteam = GetEventInt(event, "oldteam")
	new newteam = GetEventInt(event, "team")
	
	new player = GetClientOfUserId(userId)
	
	if ((newteam == TEAM_RED) || (newteam == TEAM_BLUE))
	{
		if (GetTeamClientCount(newteam) > GetTeamLimit())
		{
			PrintToChat(player, "That team is full!")
			ChangeClientTeam(player, oldteam)
			
			return Plugin_Handled
		}
			
	}
	
	return Plugin_Continue
}

public GetTeamFragCount(team)
{
	new fragcount = 0
	for (new i = 1; i <= GetMaxClients()); i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && (GetClientTeam(i) == team))
		{
			fragcount += GetClientFrags(i)
		}
			
	}
	return fragcount
}

public GetTeamLimit()
{
	return GetConVarInt(g_hTeamLimit)
}

public GetFragLimit()
{
	return GetConVarInt(g_hFragLimit)
}

public EndRound(winner)
{
	SetVariantInt(winner)
	AcceptEntityInput(g_roundmanager, "SetWinner") 
}