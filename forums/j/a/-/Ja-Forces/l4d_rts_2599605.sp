#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.2"
#define MAX_LINE_WIDTH 64

#define MESSAGE_FOR_PLAYERS_LINE1 "\x04RECEIVED SERVER RESERVATION REQUEST"
#define MESSAGE_FOR_PLAYERS_LINE2 "\x04YOU WILL BE RETURNED TO LOBBY"

char g_sSearchKeyString[MAX_LINE_WIDTH] = "";
char g_sImmuneFlagString[MAX_LINE_WIDTH] = "";
char g_sCurrentMapString[MAX_LINE_WIDTH] = "";

bool g_bMapChange = false;
bool g_bRestartMap = false;

int g_iHibernationValue;
float g_fTimeout;
bool g_bMode;

ConVar g_hCvarSVSearchKey, g_hCvarMode, g_hCvarTimeout, g_hCvarImmuneFlag, g_hCvarGroupExclusive, g_hCvarSearchKey, g_hCvarHibernation;

public Plugin myinfo = 
{
	name = "Reserve The Server",
	author = "Jack'lul [Edited by Dosergen]",
	description = "Frees the server from all players and reserves it.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2084993"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead && test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("l4d_reservetheserver_version", PLUGIN_VERSION, "Reserve The Server plugin version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hCvarMode = CreateConVar("l4d_rts_mode", "1", "0 - only remove players using lobby vote, 1 - remove players using lobby vote and then disconnect server from matchmaking", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_hCvarSVSearchKey = CreateConVar("l4d_rts_searchkey", "", "sv_search_key will be set to this while server is reserved", FCVAR_NOTIFY);
	g_hCvarTimeout = CreateConVar("l4d_rts_timeout", "30", "How long will the server stay disconnected from matchmaking? 0 - never restore matchmaking connection", FCVAR_NOTIFY, true, 0.0, true, 300.0);
	g_hCvarImmuneFlag = CreateConVar("l4d_rts_immuneflag", "d", "If player with this flag is present on the server reservation request will be denied", FCVAR_NOTIFY);

	g_hCvarGroupExclusive = FindConVar("sv_steamgroup_exclusive");
	g_hCvarSearchKey = FindConVar("sv_search_key");
	g_hCvarHibernation = FindConVar("sv_hibernate_when_empty");
	g_hCvarHibernation.AddChangeHook(ConVarChanged_Cvars);

	GetCvars();

	g_hCvarMode.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSVSearchKey.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimeout.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarImmuneFlag.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_rts", Command_MakeReservation, ADMFLAG_ROOT, "Free the server from all players, then reserve it.");
	RegAdminCmd("sm_cr", Command_CancelReservation, ADMFLAG_ROOT, "Cancel reservation and make server public again.");

	AutoExecConfig(true, "l4d_rts");
}

void ConVarChanged_Cvars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bMode = g_hCvarMode.BoolValue;
	g_hCvarSVSearchKey.GetString(g_sSearchKeyString, sizeof(g_sSearchKeyString));
	g_fTimeout = g_hCvarTimeout.FloatValue;
	g_hCvarImmuneFlag.GetString(g_sImmuneFlagString, sizeof(g_sImmuneFlagString));
	g_iHibernationValue = g_hCvarHibernation.IntValue;
}

public void OnClientDisconnect(int client)
{
	if (client == 0 || g_bMapChange || IsFakeClient(client))
		return;
	if (g_bRestartMap)
		CreateTimer(1.0, MapReloadCheck);
}

public void OnMapStart()
{
	g_bMapChange = false;
}

public void OnMapEnd()
{
	g_bMapChange = true;
	g_bRestartMap = false;
}

Action Command_MakeReservation(int client, int args) 
{
	if (IsAdminOnline())
	{
		ReplyToCommand(client, "Server reservation request denied - admin is online!");
		return Plugin_Handled;
	}
	LogMessage("Received server reservation request.");
	if (CountNotConnectedClients() < MaxClients)
	{
		if (g_bMode)
		{
			g_bRestartMap = true;
			ReplyToCommand(client, "Server will be freed from all players and reserved.");
		}
		else
			ReplyToCommand(client, "Server will be freed from all players.");
		NotifyPlayers();
		CreateTimer(5.0, FreeTheServer);
	}
	else if (g_bMode)
	{
		DisconnectFromMatchmaking();
		ReloadMap();
	}
	return Plugin_Handled;
}

Action Command_CancelReservation(int client, int args)
{
	CreateTimer(0.1, MakeServerPublic);
	return Plugin_Handled;
}

Action FreeTheServer(Handle timer)
{
	CallLobbyVote();
	PassVote();
	if (g_bMode)
		DisconnectFromMatchmaking();
	return Plugin_Continue;
}

Action MakeServerPublic(Handle timer) 
{
	ConnectToMatchmaking();
	if (CountNotConnectedClients() == MaxClients)
		ReloadMap();
	if (g_iHibernationValue != 0 && g_hCvarHibernation.IntValue == 0)
		g_hCvarHibernation.SetInt(1);
	return Plugin_Continue;
}

Action MapReloadCheck(Handle timer)
{
	if (!g_bMapChange && g_bRestartMap)
	{
		g_bRestartMap = false;
		ReloadMap();
	}
	return Plugin_Continue;
}

void CallLobbyVote()
{
	ExecuteCommand("callvote returntolobby");
}

void PassVote()
{
	ExecuteCommand("Vote Yes");
}

void ExecuteCommand(const char[] command)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
			FakeClientCommand(iClient, command);
	}
}

void ReloadMap()
{
	GetCurrentMap(g_sCurrentMapString, sizeof(g_sCurrentMapString));
	ServerCommand("map %s", g_sCurrentMapString);
}

void DisconnectFromMatchmaking()
{
	g_hCvarGroupExclusive.SetInt(1);
	g_hCvarSearchKey.SetString(g_sSearchKeyString);
	if (g_iHibernationValue != 0)
		g_hCvarHibernation.SetInt(0);
	if (g_fTimeout > 0)
		CreateTimer(g_fTimeout, MakeServerPublic);
}

void ConnectToMatchmaking()
{
	g_hCvarGroupExclusive.SetInt(0);
	g_hCvarSearchKey.SetString("");
}

bool IsAdminOnline()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient) && (CheckCommandAccess(iClient, "", ReadFlagString(g_sImmuneFlagString), true) || GetUserFlagBits(iClient) & ADMFLAG_ROOT))
			return true;
	}
	return false;
}

int CountNotConnectedClients()
{
	int notConnected = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsClientInGame(iClient))
			notConnected++;
	}
	return notConnected;
}

void NotifyPlayers()
{
	PrintToChatAll(MESSAGE_FOR_PLAYERS_LINE1);
	PrintToChatAll(MESSAGE_FOR_PLAYERS_LINE2);
}
