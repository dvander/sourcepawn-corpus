#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.2h"

static	bool 	g_bHadRecentHb			=	false;
static	bool 	g_bHadRecentDisconnect	=	false;
static	Handle 	g_hCvar_Timeout			=	INVALID_HANDLE;
static	float 	g_fCvar_Timeout			=	0.0;
static	Handle 	g_hCvar_AutoHb			=	INVALID_HANDLE;
static	bool 	g_bCvar_AutoHb			=	false;
static	bool 	g_bSendClientHb			=	false;

public Plugin myinfo = {
	name			= "L4D2 Heartbeat Trigger",
	author			= "B-man & Dirka_Dirka modded by lippnc",
	description		= "Autosends and type sm_hb or !hb in chat to force send a server heartbeat",
	version			= VERSION,
	url				= "http://forums.alliedmods.net/showthread.php?t=102052"
}

public void OnPluginStart() {
	char game_name[12];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead2", false))
		g_bSendClientHb = false;
	else
		g_bSendClientHb = true;
	
	CreateConVar("sm_heartbeat_version", VERSION, "L4D2 Heartbeat version", FCVAR_REPLICATED|FCVAR_DONTRECORD);
	g_hCvar_AutoHb = CreateConVar("sm_heartbeat_auto", "1",	"Autosend server heartbeat when player disconnects. 0:Disable, 1:Enable", _, true, 0.0, true, 1.0);
	g_bCvar_AutoHb = GetConVarBool(g_hCvar_AutoHb);
	g_hCvar_Timeout = CreateConVar("sm_heartbeat_timeout", "5.0", "Timeout value in seconds between heartbeats for non-admin players. Min:1.0, Max:30.0", _, true, 1.0, true, 30.0);
	g_fCvar_Timeout = GetConVarFloat(g_hCvar_Timeout);
	
	RegAdminCmd("sm_hb", Command_HeartBeat, ADMFLAG_ROOT, "Admin can send server heartbeat");
	AutoExecConfig(true, "l4d2_heartbeat");
}

public void OnClientDisconnect(int client) {
	if ((client < 1) || (client > MaxClients))
		return;
	if (IsFakeClient(client))
		return;
	
	if (g_bCvar_AutoHb && !g_bHadRecentDisconnect) {
		g_bHadRecentDisconnect = true;
		ServerCommand("heartbeat");
		PrintToChatAll("\x03Server heartbeat sent (OnClientDisconnect).");
		if (g_bSendClientHb)
			SendClientHeartbeats();
		CreateTimer(g_fCvar_Timeout, Timer_Reset_RecentDisconnect);
	}
}

public Action Command_HeartBeat(int client, int args) {
	if (!IsValidClient(client)) {
		if (!FindValidClient()) {
			ReplyToCommand(client, "Could not find a valid client in-game. Command is invalid.");
		} else {
			ServerCommand("heartbeat");
			//ReplyToCommand(client, "Server heartbeat sent (sm_hb).");
			PrintToChatAll("\x03Server heartbeat sent (console).");
			g_bHadRecentHb = true;
		}
		return Plugin_Continue;
	}
	bool isAdmin = true;
	if (GetUserAdmin(client) == INVALID_ADMIN_ID)
		isAdmin = false;
	if (!g_bHadRecentHb || !g_bHadRecentDisconnect) {
		ServerCommand("heartbeat");
		if (g_bSendClientHb)
			SendClientHeartbeats();
		PrintToChatAll("\x03Server heartbeat sent (sm_hb). Requested by \x04%N\x01.", client);
		PrintToServer("Heartbeat sent (sm_hb). Requested by %N.", client);
		if (!isAdmin)
			CreateTimer(g_fCvar_Timeout, Timer_Reset_RecentHB);
		else
			CreateTimer(1.0, Timer_Reset_RecentHB);
		g_bHadRecentHb = true;
	} else {
		int retry;
		if (!isAdmin)
			retry = RoundFloat(g_fCvar_Timeout);
		else
			retry = 1;
		if (retry == 1)
			ReplyToCommand(client, "Heartbeat recently requested, try again in about %i second.", retry);
		else
			ReplyToCommand(client, "Heartbeat recently requested, try again in about %i seconds.", retry);
	}
	return Plugin_Continue;
}

public Action Timer_Reset_RecentHB(Handle timer) {
	g_bHadRecentHb = false;
	return Plugin_Continue;
}

public Action Timer_Reset_RecentDisconnect(Handle timer) {
	g_bHadRecentDisconnect = false;
	return Plugin_Continue;
}

static void SendClientHeartbeats()
{
	int sent = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			ClientCommand(i, "heartbeat");
			sent++;
		}
	}

	if (sent)
	{
		PrintToChatAll("\x03Client heartbeats sent by everyone (%i times).", sent);
		PrintToServer("%i client heartbeats sent.", sent);
	}
}

static bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			return true;
		}
	}

	return false;
}

static int FindValidClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			return i;
		}
	}

	return 0;
}