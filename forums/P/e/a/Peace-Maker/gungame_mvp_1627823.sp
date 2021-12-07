#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <gungame>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVShowLeaderMVP;
new Handle:g_hCVShowLevelScoreB;
new bool:g_bShowLevelScoreBoard;

new g_iPlayerLevel[MAXPLAYERS+1] = {-1,...};
new g_iLeader = -1;

public Plugin:myinfo = 
{
	name = "Gungame: Show level as MVP stars",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Shows the player level as MVP stars",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_ggmvp_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hCVShowLeaderMVP = CreateConVar("sm_ggmvp_showleader", "1", "Always show the leader as the best player on round end in the winning panel?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_hCVShowLevelScoreB = CreateConVar("sm_ggmvp_showlevel", "1", "Show the current player's level as MVP stars in the scoreboard next to their name?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	g_bShowLevelScoreBoard = GetConVarBool(g_hCVShowLevelScoreB);
	HookConVarChange(g_hCVShowLevelScoreB, ConVar_ChangeShowLevel);
	
	HookEvent("round_mvp", Event_OnRoundMVP, EventHookMode_Pre);
	
	AutoExecConfig();
}

public OnClientDisconnect(client)
{
	g_iPlayerLevel[client] = -1;
	// He's been the leader? Reset. There's going to be a new one any second:)
	if(g_iLeader == client)
		g_iLeader = -1;
}

public OnMapStart()
{
	new iEnt = FindEntityByClassname(MaxClients+1, "cs_player_manager");
	if(iEnt == -1)
		SetFailState("Can't find cs_player_manager entity.");
	
	SDKHook(iEnt, SDKHook_ThinkPost, Hook_ThinkPost);
}

public Action:GG_OnClientLevelChange(client, level, difference, bool:steal, bool:last, bool:knife)
{
	// Level start at 0 in this callback..
	g_iPlayerLevel[client] = level+1;
}

public Hook_ThinkPost(entity)
{
	if(!g_bShowLevelScoreBoard)
		return;
	
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && g_iPlayerLevel[i] != -1)
			SetEntProp(entity, Prop_Send, "m_iMVPs", g_iPlayerLevel[i], 4, i);
	}
}

public GG_OnLeaderChange(client, level, totalLevels)
{
	g_iLeader = client;
}

public Event_OnRoundMVP(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_iLeader != -1 && GetConVarBool(g_hCVShowLeaderMVP))
	{
		SetEventInt(event, "userid", GetClientUserId(g_iLeader));
		SetEventInt(event, "reason", 0); // "Best player of the round"
	}
}

public ConVar_ChangeShowLevel(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_bShowLevelScoreBoard = GetConVarBool(convar);
}