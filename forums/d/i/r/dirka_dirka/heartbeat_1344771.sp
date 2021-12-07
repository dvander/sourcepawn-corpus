#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.2"

/*
	Version notes for 1.2:
	- Removed the player_disconnect hook and use OnClientDisconnect..
		I have NEVER seen the auto-hb with the v1.1 method.
	- Changed the sm_heartbeat_timeout to have a min of 1 second.
	- Changed sm_hb command:
		Admins now have to wait 1 second (have had plenty of cases where 2 admins issue command at same time).
		If issued as client 0 (eg: remote rcon), will try to find an in-game client before doing anything.
	- Changed the auto-config filename, delete old file.
	- Changed color scheme (95% orange with 5% light green - bleah). Tag is now light green, request names are orange.
	- Added check for L4D2 to not send client heartbeats.. any other game that doesn't allow clients to heartbeat can be added.
*/

static	bool:	g_bHadRecentHb			=	false;
static	bool:	g_bHadRecentDisconnect	=	false;
static	Handle:	g_hCvar_Timeout			=	INVALID_HANDLE;
static	Float:	g_fCvar_Timeout			=	0.0;
static	Handle:	g_hCvar_AutoHb			=	INVALID_HANDLE;
static	bool:	g_bCvar_AutoHb			=	false;
static	bool:	g_bSendClientHb			=	false;

public Plugin:myinfo = {
	name			= "Heartbeat trigger",
	author			= "B-man & Dirka_Dirka",
	description	= "sm_hb or !hb in chat to force a server heartbeat",
	version			= VERSION,
	url				= "http://forums.alliedmods.net/showthread.php?t=102052"
}

public OnPluginStart() {
	decl String:game_name[12];
	GetGameFolderName(game_name, sizeof(game_name));
	if (StrEqual(game_name, "left4dead2", false))
		g_bSendClientHb = false;
	else
		g_bSendClientHb = true;
	
	CreateConVar(
		"sm_heartbeat_version", VERSION,
		"Heartbeat trigger version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	g_hCvar_AutoHb = CreateConVar(
		"sm_heartbeat_auto", "1",
		"Auto heatbeat when someone disconnects",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,
		true, 0.0, true, 1.0 );
	g_bCvar_AutoHb = GetConVarBool(g_hCvar_AutoHb);
	g_hCvar_Timeout = CreateConVar(
		"sm_heartbeat_timeout", "20.0",
		"Timeout value between heartbeats for non-admins (min is 1.0 second for everyone).",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY,
		true, 1.0 );
	g_fCvar_Timeout = GetConVarFloat(g_hCvar_Timeout);
	
	RegConsoleCmd("sm_hb", Command__HeartBeat);
	AutoExecConfig(true, "plugin.heartbeat");
}

public OnClientDisconnect(client) {
	if ((client < 1) || (client > MaxClients))
		return;
	if (IsFakeClient(client))
		return;
	
	if (g_bCvar_AutoHb && !g_bHadRecentDisconnect) {
		g_bHadRecentDisconnect = true;
		ServerCommand("heartbeat");
		PrintToChatAll("\x03[HB]\x01 Server heartbeat sent (OnClientDisconnect).");
		if (g_bSendClientHb)
			SendClientHeartbeats();
		CreateTimer(g_fCvar_Timeout, _Timer__Reset_RecentDisconnect);
	}
}

public Action:Command__HeartBeat(client, args) {
	if (!IsValidClient(client)) {
		if (!FindValidClient()) {
			ReplyToCommand(client, "[HB] Could not find a valid client in-game. Command is invalid.");
		} else {
			ServerCommand("heartbeat");
			ReplyToCommand(client, "[HB] Server heartbeat sent (sm_hb).");
			PrintToChatAll("\x03[HB]\x01 Server heartbeat sent (console).");
			g_bHadRecentHb = true;
		}
		return;
	}
	new bool:isAdmin = true;
	if (GetUserAdmin(client) == INVALID_ADMIN_ID)
		isAdmin = false;
	if (!g_bHadRecentHb || !g_bHadRecentDisconnect) {
		ServerCommand("heartbeat");
		if (g_bSendClientHb)
			SendClientHeartbeats();
		PrintToChatAll("\x03[HB]\x01 Server heartbeat sent (sm_hb). Requested by \x04%N\x01.", client);
		PrintToServer("[HB] Heartbeat sent (sm_hb). Requested by %N.", client);
		if (!isAdmin)
			CreateTimer(g_fCvar_Timeout, _Timer__Reset_RecentHB);
		else
			CreateTimer(1.0, _Timer__Reset_RecentHB);
		g_bHadRecentHb = true;
	} else {
		new retry;
		if (!isAdmin)
			retry = RoundFloat(g_fCvar_Timeout);
		else
			retry = 1;
		if (retry == 1)
			ReplyToCommand(client, "[HB] Heartbeat recently requested, try again in about %i second.", retry);
		else
			ReplyToCommand(client, "[HB] Heartbeat recently requested, try again in about %i seconds.", retry);
	}
}

public Action:_Timer__Reset_RecentHB(Handle:timer) {
	g_bHadRecentHb = false;
}

public Action:_Timer__Reset_RecentDisconnect(Handle:timer) {
	g_bHadRecentDisconnect = false;
}

static SendClientHeartbeats() {
	new sent = 0;
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (!IsFakeClient(i)) {
				ClientCommand(i, "heartbeat");
				sent++;
			}
		}
	}
	if (sent) {
		PrintToChatAll("\x03[HB]\x01 Client heartbeats sent by everyone (%i times).", sent);
		PrintToServer("[HB] %i client heartbeats sent.", sent);
	}
}

static IsValidClient(client) {
	if ((client > 0) && (client <= MaxClients)) {
		if (IsClientInGame(client)) {
			if (!IsFakeClient(client))
				return true;
		}
	}
	return false;
}

static FindValidClient() {
	for (new i=1; i<=MaxClients; i++) {
		if (IsClientInGame(i)) {
			if (!IsFakeClient(i))
				return i;
		}
	}
	return 0;
}
