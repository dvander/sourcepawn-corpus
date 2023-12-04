#pragma semicolon 1

#define PLUGIN_AUTHOR "[W]atch [D]ogs"
#define PLUGIN_VERSION "1.0.6"

#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>

#pragma newdecls required

Handle h_bEnable;

public Plugin myinfo = 
{
	name = "Fast Team Balancer",
	author = PLUGIN_AUTHOR,
	description = "Balances teams at start of every rounds",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=298717"
};

public void OnPluginStart()
{
	h_bEnable = CreateConVar("sm_ftb_enable", "1", "Enable / Disable fast team balancing", _, true, 0.0, true, 1.0);
	if(GetEngineVersion() == Engine_CSGO)
		HookEvent("round_prestart", Event_PreRoundStart);
	else
		HookEvent("round_end", Event_PreRoundStart);
}

public Action Event_PreRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	int T_Count = GetTeamClientCount(CS_TEAM_T);
	int CT_Count = GetTeamClientCount(CS_TEAM_CT);
	
	if(!GetConVarBool(h_bEnable) || T_Count == CT_Count || T_Count + 1 == CT_Count || CT_Count + 1 == T_Count)
		return Plugin_Continue;
		
	while(T_Count > CT_Count && T_Count != CT_Count + 1)
	{
		int client = GetRandomPlayer(CS_TEAM_T);
		CS_SwitchTeam(client, CS_TEAM_CT);
		T_Count--;
		CT_Count++;
	}
	while(T_Count < CT_Count && CT_Count != T_Count + 1)
	{
		int client = GetRandomPlayer(CS_TEAM_CT);
		CS_SwitchTeam(client, CS_TEAM_T);
		CT_Count--;
		T_Count++;
	}
	return Plugin_Continue;
}

stock int GetRandomPlayer(int team) 
{ 
    int[] clients = new int[MaxClients]; 
    int clientCount; 
    for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i) && GetClientTeam(i) == team)
        { 
            clients[clientCount++] = i; 
        } 
    } 
    return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)]; 
} 


