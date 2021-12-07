#pragma semicolon 1

#define PLUGIN_NAME "[CSGO] Team Limit Bypass"
#define PLUGIN_AUTHOR "Zephyrus"
#define PLUGIN_DESCRIPTION "Bypasses hardcoded team limits"
#define PLUGIN_VERSION "1.1"
#define PLUGIN_URL ""

#include <sourcemod>
#include <sdktools>
#include <cstrike>

enum EJoinTeamReason
{
	k_OneTeamChange=0,
	k_TeamsFull=1,
	k_TTeamFull=2,
	k_CTTeamFull=3
}

new g_iTSpawns=-1;
new g_iCTSpawns=-1;
new g_iSelectedTeam[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	HookEvent("jointeam_failed", Event_JoinTeamFailed, EventHookMode_Pre);
	AddCommandListener(Command_JoinTeam, "jointeam"); 
}

public OnMapStart()
{
	g_iTSpawns=-1;
	g_iCTSpawns=-1;

	// Give plugins a chance to create new spawns
	CreateTimer(0.1, Timer_OnMapStart);
}

public OnClientConnected(client)
{
	g_iSelectedTeam[client]=0;
}

public Action:Timer_OnMapStart(Handle:timer, any:data)
{
	g_iTSpawns=0;
	g_iCTSpawns=0;

	new ent = -1;
	while((ent = FindEntityByClassname(ent, "info_player_counterterrorist")) != -1) ++g_iCTSpawns;
	ent = -1;
	while((ent = FindEntityByClassname(ent, "info_player_terrorist")) != -1) ++g_iTSpawns;

	return Plugin_Stop;
}

public Action:Event_JoinTeamFailed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;

	new EJoinTeamReason:m_eReason = EJoinTeamReason:GetEventInt(event, "reason");

	new m_iTs = GetTeamClientCount(CS_TEAM_T);
	new m_iCTs = GetTeamClientCount(CS_TEAM_CT);

	switch(m_eReason)
	{
		case k_OneTeamChange:
		{
			return Plugin_Continue;
		}

		case k_TeamsFull:
		{
			if(m_iCTs == g_iCTSpawns && m_iTs == g_iTSpawns)
				return Plugin_Continue;
		}

		case k_TTeamFull:
		{
			if(m_iTs == g_iTSpawns)
				return Plugin_Continue;
		}

		case k_CTTeamFull:
		{
			if(m_iCTs == g_iCTSpawns)
				return Plugin_Continue;
		}

		default:
		{
			return Plugin_Continue;
		}
	}

	ChangeClientTeam(client, g_iSelectedTeam[client]);

	return Plugin_Handled;
}

public Action:Command_JoinTeam(client, const String:command[], argc)
{
	if(!argc || !client || !IsClientInGame(client))
		return Plugin_Continue;

	decl String:m_szTeam[8];
	GetCmdArg(1, m_szTeam, sizeof(m_szTeam));
	new m_iTeam = StringToInt(m_szTeam);

	if(CS_TEAM_SPECTATOR<=m_iTeam<=CS_TEAM_CT)
		g_iSelectedTeam[client]=m_iTeam;

	return Plugin_Continue;
}