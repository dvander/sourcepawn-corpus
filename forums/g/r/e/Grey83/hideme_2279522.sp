#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#define PLUGIN_VERSION "1.0.1"

new bool:g_bHideMe[MAXPLAYERS+1] = {false,...};

new g_iPlayerManager;
new g_iConnectedOffset;
new g_iAliveOffset;
new g_iTeamOffset;
new g_iPingOffset;
new g_iScoreOffset;
new g_iDeathsOffset;
new g_iHealthOffset;

public Plugin:myinfo = 
{
	name = "HideMe",
	author = "fluxX", /*Thx to Peace-Maker*/
	description = "Hide admins from scoreboard.",
	version = PLUGIN_VERSION,
	url = "http://wcfan.de"
}

public OnPluginStart()
{
	LoadTranslations("hideme.phrases");
	new Handle:hVersion = CreateConVar("sm_hideme_version",  PLUGIN_VERSION, "HideMe Version",  FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
	{
		SetConVarString(hVersion, PLUGIN_VERSION);
		HookConVarChange(hVersion, OnConVarVersionChange);
	}
	
	AddCommandListener(CmdLstnr_JoinTeam, "jointeam");
	
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	
	RegAdminCmd("sm_hideme", Cmd_HideMe, ADMFLAG_GENERIC);
	
	g_iConnectedOffset = FindSendPropOffs("CCSPlayerResource", "m_bConnected");
	g_iAliveOffset = FindSendPropOffs("CCSPlayerResource", "m_bAlive");
	g_iTeamOffset = FindSendPropOffs("CCSPlayerResource", "m_iTeam");
	g_iPingOffset = FindSendPropOffs("CCSPlayerResource", "m_iPing");
	g_iScoreOffset = FindSendPropOffs("CCSPlayerResource", "m_iScore");
	g_iDeathsOffset = FindSendPropOffs("CCSPlayerResource", "m_iDeaths");
	g_iHealthOffset = FindSendPropOffs("CCSPlayerResource", "m_iHealth");
}

public OnConVarVersionChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SetConVarString(convar, PLUGIN_VERSION);
}

public OnMapStart()
{
	g_iPlayerManager = FindEntityByClassname(-1, "cs_player_manager");
	if(g_iPlayerManager != -1)
	{
		SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PMThink);
	}
}

public OnClientDisconnect(client)
{
	g_bHideMe[client] = false;
}

public Action:Cmd_HideMe(client, args)
{
	if(!client)
		ReplyToCommand(client, "[SM] command in-game only");
	
	if(!g_bHideMe[client])
	{
		decl String:sName[MAX_NAME_LENGTH];
		
		GetClientName(client, sName, sizeof(sName));
		g_bHideMe[client] = true;
		
		if(GetClientTeam(client) != CS_TEAM_SPECTATOR)
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		
		PrintToChatAll("%t", "Disconnect", sName);
	}
	else
		g_bHideMe[client] = false;
}

public Action:CmdLstnr_JoinTeam(client, const String:command[], argc)
{
	if(g_bHideMe[client])
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bHideMe[client])
	{
		// Don't show teamchange message in chat
		dontBroadcast = true;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Hook_PMThink(entity)
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && g_bHideMe[i])
		{
			SetEntData(g_iPlayerManager, g_iAliveOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iConnectedOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iTeamOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iPingOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iScoreOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iDeathsOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iHealthOffset + (i * 4), 0, 4, true);
		}
	}
}

public OnGameFrame()
{
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && g_bHideMe[i])
		{
			SetEntData(g_iPlayerManager, g_iAliveOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iConnectedOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iTeamOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iPingOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iScoreOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iDeathsOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iHealthOffset + (i * 4), 0, 4, true);
		}
	}
}  