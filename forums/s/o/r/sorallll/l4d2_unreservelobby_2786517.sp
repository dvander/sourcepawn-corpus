#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

#define UNRESERVE_VERSION "2.0.0"

#define L4D_MAXHUMANS_LOBBY_VERSUS 8
#define L4D_MAXHUMANS_LOBBY_OTHER 4

ConVar
	g_hUnreserve,
	g_hAutoLobby;

bool
	g_bUnreserved;

public Plugin myinfo =
{
	name = "L4D 1/2 Remove Lobby Reservation",
	author = "Downtown1, Anime4000",
	description = "Removes lobby reservation when server is full",
	version = UNRESERVE_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=87759"
}

public void OnPluginStart()
{
	CreateConVar("l4d_unreserve_version", UNRESERVE_VERSION, "Version of the Lobby Unreserve plugin.", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hUnreserve = CreateConVar("l4d_unreserve_full", "1", "Automatically unreserve server after a full lobby joins", FCVAR_SPONLY|FCVAR_NOTIFY);
	g_hAutoLobby = CreateConVar("l4d_autolobby", "1", "Automatically adjust sv_allow_lobby_connect_only. When lobby full it set to 0, when server empty it set to 1", FCVAR_SPONLY|FCVAR_NOTIFY);
	
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

	RegAdminCmd("sm_unreserve", cmdUnreserve, ADMFLAG_BAN, "sm_unreserve - manually force removes the lobby reservation");
}

Action cmdUnreserve(int client, int args)
{
	if (g_bUnreserved)
		ReplyToCommand(client, "[UL] Server has already been unreserved.");
	else {
		L4D_LobbyUnreserve();
		g_bUnreserved = true;
		vSetAllowLobby(0);
		ReplyToCommand(client, "[UL] Lobby reservation has been removed.");
	}

	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	if (!g_bUnreserved && g_hUnreserve.BoolValue && bIsServerLobbyFull()) {
		if (FindConVar("sv_hosting_lobby").IntValue > 0) {
			LogMessage("[UL] A full lobby has connected, automatically unreserving the server.");
			L4D_LobbyUnreserve();
			g_bUnreserved = true;
			vSetAllowLobby(0);
		}
	}
}

//OnClientDisconnect will fired when changing map, issued by gH0sTy at http://docs.sourcemod.net/api/index.php?fastload=show&id=390&
void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || IsFakeClient(client) || bRealClientsInServer(client))
		return;

	PrintToServer("[UL] No human want to play in this server. :(");
	g_bUnreserved = false;
	vSetAllowLobby(1);
}

void vSetAllowLobby(int value)
{
	if (g_hAutoLobby.BoolValue)
		FindConVar("sv_allow_lobby_connect_only").IntValue = value;
}

bool bIsServerLobbyFull()
{
	int iHumans = iGetHumanCount();

	if (L4D_IsVersusMode() || L4D2_IsScavengeMode())
		return iHumans >= L4D_MAXHUMANS_LOBBY_VERSUS;

	return iHumans >= L4D_MAXHUMANS_LOBBY_OTHER;
}

int iGetHumanCount()
{
	int iHumans;
	for (int i = 1; i < MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i))
			iHumans++;
	}
	return iHumans;
}

bool bRealClientsInServer(int client)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (i != client && IsClientConnected(i) && !IsFakeClient(i))
			return true;
	}
	return false;
}