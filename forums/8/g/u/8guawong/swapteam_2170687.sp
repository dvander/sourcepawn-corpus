#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
    name = "Swap Team",
    author = "Original author: raydan Fixed by: ¥Ã¤é Tested & Edited by: 8GuaWong",
    description = "Swap Team",
    version = PLUGIN_VERSION,
    url = "http://www.blackmarke7.com"
};
new Handle:cvar_zx2_swapteam_timer;
new Handle:cvar_zx2_swapteam_round;
new Handle:cvar_mp_restartgame;


new g_round;
new String:Model_CT[4][128];
new String:Model_T[4][128];
new g_score_ct;
new g_score_t;
new bool:IsSwap;
new g_team_side;
new m_iScore;
new bool:IsBlockSwitchTeam[MAXPLAYERS+1];
public OnPluginStart()
{
	cvar_zx2_swapteam_round = CreateConVar("zx2_swapteam_round","8","Number of rounds to play before swapping. 0 = disable",FCVAR_PLUGIN,true,0.0,false);
	cvar_zx2_swapteam_timer = CreateConVar("zx2_swapteam_timer","2.0","timer",FCVAR_PLUGIN,true,0.0,false);
	HookEvent("round_freeze_end",ev_round_freeze_end);
	HookEvent("round_end",ev_round_end);
	HookEvent("round_start",ev_round_start);
	HookEvent("player_team",ev_player_team,EventHookMode_Pre);
	m_iScore = FindSendPropOffs("CCSTeam","m_iScore");
	cvar_mp_restartgame = FindConVar("mp_restartgame");
	HookConVarChange(cvar_mp_restartgame,Cvar_mp_restartgame);
}
public OnMapStart()
{
	for(new i=0;i<=MAXPLAYERS;i++)
	{
		IsBlockSwitchTeam[i] = false;
	}
	g_round = 0;
	g_score_t = 0;
	g_score_ct = 0;
	IsSwap = false;
	g_team_side = CS_TEAM_T;
	PrecacheSound("ambient/misc/brass_bell_C.wav",true);
	
	PrecacheModel("models/player/ct_gign.mdl",true);
	PrecacheModel("models/player/ct_gsg9.mdl",true);
	PrecacheModel("models/player/ct_sas.mdl",true);
	PrecacheModel("models/player/ct_urban.mdl",true);
	
	PrecacheModel("models/player/t_arctic.mdl",true);
	PrecacheModel("models/player/t_guerilla.mdl",true);
	PrecacheModel("models/player/t_leet.mdl",true);
	PrecacheModel("models/player/t_phoenix.mdl",true);
	
	Model_CT[0] = "models/player/ct_gign.mdl";
	Model_CT[1] = "models/player/ct_gsg9.mdl";
	Model_CT[2] = "models/player/ct_sas.mdl";
	Model_CT[3] = "models/player/ct_urban.mdl";
	
	Model_T[0] = "models/player/t_arctic.mdl";
	Model_T[1] = "models/player/t_guerilla.mdl";
	Model_T[2] = "models/player/t_leet.mdl";
	Model_T[3] = "models/player/t_phoenix.mdl";
}
public Cvar_mp_restartgame(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if(cvar_mp_restartgame != INVALID_HANDLE)
	{
		if(StringToInt(newvalue) > 0)
		{
			g_score_t = 0;
			g_score_ct = 0;
			g_round = 0;
			IsSwap = false;
		}
	}
}
public Action:ev_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client > 0)
	{
		if(IsBlockSwitchTeam[client])
		{
			IsBlockSwitchTeam[client] = false;
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}
public ev_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	new GMC = 1;
	for (new i = 1; i <= GMC; i++)
	{
		new team = GetTeamClientCount(2) + GetTeamClientCount(3);
		
		if (team > 1)
		{
			g_round++;
		}
	}
	
	if(g_team_side == CS_TEAM_CT)
	{
		_SetTeamScore(CS_TEAM_CT,g_score_ct);
		_SetTeamScore(CS_TEAM_T,g_score_t);
	} else if(g_team_side == CS_TEAM_T) {
		_SetTeamScore(CS_TEAM_T,g_score_ct);
		_SetTeamScore(CS_TEAM_CT,g_score_t);
	}
}
public ev_round_freeze_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	new max_round = GetConVarInt(cvar_zx2_swapteam_round);
	
	if(max_round <= 0)
	{
		return;
	}
	if(g_round >= max_round)
	{
		IsSwap = true;
		PrintToChatAll("\x04: Round %d, swap teams after this round!",g_round);
		EmitSoundToAll("ambient/misc/brass_bell_C.wav");
	}
	PrintCenterTextAll("Round %d/%d",g_round,max_round);
}
public ev_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl reason;
	reason = GetEventInt(event, "reason");
	decl winner;
	winner = GetEventInt(event, "winner");
	if(winner == 3)
	{
		if(g_team_side == CS_TEAM_CT) g_score_ct++;
		if(g_team_side == CS_TEAM_T) g_score_t++;
	} else if(winner == 2) {
		if(g_team_side == CS_TEAM_T) g_score_ct++;
		if(g_team_side == CS_TEAM_CT) g_score_t++;
	}
	if(g_team_side == CS_TEAM_CT)
	{
		_SetTeamScore(CS_TEAM_CT,g_score_ct);
		_SetTeamScore(CS_TEAM_T,g_score_t);
	} else if(g_team_side == CS_TEAM_T) {
		_SetTeamScore(CS_TEAM_T,g_score_ct);
		_SetTeamScore(CS_TEAM_CT,g_score_t);
	}
	if(IsSwap)
	{
		new Float:timer = GetConVarFloat(cvar_zx2_swapteam_timer);
		CreateTimer(timer, TimeFun);
	}
	if(reason == 16)
	{
		g_score_t = 0;
		g_score_ct = 0;
		g_round = 0;
		IsSwap = false;
	}
}

public Action:TimeFun(Handle:time)
{
	SwapTeam();
	g_round = 0;
	IsSwap = false;
	
	if(g_team_side == CS_TEAM_CT)
	{
		g_team_side = CS_TEAM_T;
	}
	else
	{
		g_team_side = CS_TEAM_CT;
	}
}

stock SwapTeam()
{
	EmitSoundToAll("ambient/misc/brass_bell_C.wav");
	
	for(new i=1;i<=GetMaxClients();i++)
	{
		if(IsClientInGame(i))
		{
			new team = GetClientTeam(i);
			if(team == CS_TEAM_CT)
			{
				IsBlockSwitchTeam[i] = true;
				CS_SwitchTeam(i,CS_TEAM_T);
				if(IsPlayerAlive(i))
				{
					SetEntityModel(i,Model_T[GetRandomInt(0,3)]);
				}
			} else if(team == CS_TEAM_T) {
				IsBlockSwitchTeam[i] = true;
				CS_SwitchTeam(i,CS_TEAM_CT);
				if(IsPlayerAlive(i))
				{
					SetEntityModel(i,Model_CT[GetRandomInt(0,3)]);
				}
			}
		}
	}
}
public bool:_SetTeamScore(index, value)
{
	new team = MAXPLAYERS + 1;
	
	team = FindEntityByClassname(-1, "cs_team_manager");
	while (team != -1)
	{
		if (GetEntProp(team, Prop_Send, "m_iTeamNum", 1) == index)
		{
			SetEntProp(team, Prop_Send, "m_iScore", value, 4);
			ChangeEdictState(team, m_iScore);
			return true;
		}
		team = FindEntityByClassname(team, "cs_team_manager");
	}
	return false;
}