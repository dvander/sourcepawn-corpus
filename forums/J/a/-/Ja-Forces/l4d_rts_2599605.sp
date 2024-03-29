#define PLUGIN_VERSION	"1.1.0"
#define MAX_LINE_WIDTH	 64

#define MESSAGE_FOR_PLAYERS_LINE1	""
#define MESSAGE_FOR_PLAYERS_LINE2	"\x04RECEIVED SERVER RESERVATION REQUEST"
#define MESSAGE_FOR_PLAYERS_LINE3	"\x04YOU WILL BE RETURNED TO LOBBY"
#define MESSAGE_FOR_PLAYERS_LINE4	""

#pragma semicolon 1

#include <sourcemod>

#pragma newdecls required

ConVar PluginCvarSearchKey, PluginCvarMode, PluginCvarTimeout, PluginCvarImmuneFlag, 
       SteamGroupExclusiveCvar, SearchKeyCvar, HibernationCvar;

int HibernationCvarValue;
bool isMapChange = false, doRestartMap = false;
char PluginSearchKeyString[MAX_LINE_WIDTH] = "";
char PluginCvarImmuneFlagString[MAX_LINE_WIDTH] = ""; 
char CurrentMapString[MAX_LINE_WIDTH] = "";

public Plugin myinfo =
{
	name = "Reserve The Server",
	author = "Jack'lul [Edited by Dosergen]",
	description = "Frees the server from all players and reserves it.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2084993"
}

public void OnPluginStart() 
{
	char game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) &&	!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin only supports Left 4 Dead and Left 4 Dead 2!");
		return;
	}
	
	CreateConVar("l4d_rts_version", PLUGIN_VERSION, "Reserve The Server plugin version", 0|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);	
	PluginCvarMode = CreateConVar("l4d_rts_mode", "1", "0 - only remove players using lobby vote, 1 - remove players using lobby vote and then disconnect server from matchmaking", 0, true, 0.0, true, 1.0);
	PluginCvarSearchKey = CreateConVar("l4d_rts_searchkey", "", "sv_search_key will be set to this while server is reserved", 0);
	PluginCvarTimeout = CreateConVar("l4d_rts_timeout", "30", "How long will the server stay disconnected from matchmaking? 0 - never restore matchmaking connection", 0, true, 0.0, true, 300.0);
	PluginCvarImmuneFlag = CreateConVar("l4d_rts_immuneflag", "d", "If player with this flag is present on the server reservation request will be denied", 0);

	RegAdminCmd("sm_rts", Command_MakeReservation, ADMFLAG_ROOT, "Free the server from all players, then reserve it.");
	RegAdminCmd("sm_cr", Command_CancelReservation, ADMFLAG_ROOT, "Cancel reservation and make server public again.");
	
	SteamGroupExclusiveCvar	= FindConVar("sv_steamgroup_exclusive");
	SearchKeyCvar = FindConVar("sv_search_key");
	HibernationCvar = FindConVar("sv_hibernate_when_empty");
	HibernationCvarValue = GetConVarInt(HibernationCvar);
	
	AutoExecConfig(true, "l4d_rts");
}

public void OnClientDisconnect(int client)
{
	if (client == 0 || isMapChange || IsFakeClient(client))
		return;
	
	if(doRestartMap == true)
		CreateTimer(1.0, MapReloadCheck);
}

public void OnMapEnd()
{
	isMapChange = true;
	doRestartMap = false;
}

public void OnMapStart()
{
	isMapChange = false;
}

public Action Command_MakeReservation(int client, int args) 
{
	int isAdminOnline = 0, notConnected = 0, iMaxClients = MaxClients;
	
	for (int iClient = 1; iClient <= iMaxClients; iClient++)
	{
		if (IsClientConnected (iClient) && IsClientInGame (iClient))
		{
			GetConVarString(PluginCvarImmuneFlag, PluginCvarImmuneFlagString, sizeof(PluginCvarImmuneFlagString));
			if (CheckCommandAccess(iClient, "", ReadFlagString(PluginCvarImmuneFlagString) , true) || GetUserFlagBits(iClient) & ADMFLAG_ROOT) 
			{
				isAdminOnline = 1;
				break;
			}
		}
		else
			notConnected++;
	}
	
	if(!isAdminOnline)
	{
		LogMessage("Received server reservation request.");
		if(notConnected < iMaxClients)
		{	
			if(GetConVarInt(PluginCvarMode)==1)
			{
				doRestartMap = true;
				ReplyToCommand(client, "Server will be freed from all players and reserved."); 
			}
			else
				ReplyToCommand(client, "Server will be freed from all players."); 	
			
			PrintToChatAll(MESSAGE_FOR_PLAYERS_LINE1);
			PrintToChatAll(MESSAGE_FOR_PLAYERS_LINE2);
			PrintToChatAll(MESSAGE_FOR_PLAYERS_LINE3);
			PrintToChatAll(MESSAGE_FOR_PLAYERS_LINE4);
			
			CreateTimer(5.0, FreeTheServer);
		}
		else if(GetConVarInt(PluginCvarMode)==1)
		{
			DisconnectFromMatchmaking();
			ReloadMap();
		}
	}
	else
		ReplyToCommand(client, "Server reservation request denied - admin is online!");
	
	return Plugin_Handled;
}

public Action Command_CancelReservation(int client, int args)
{
	CreateTimer(0.1, MakeServerPublic);
	return Plugin_Handled;
}

public Action FreeTheServer(Handle timer) 
{
	CallLobbyVote();
	PassVote();
	
	if(GetConVarInt(PluginCvarMode)==1)
	{
		DisconnectFromMatchmaking();
	}
	
	return Plugin_Handled;
}

public Action MakeServerPublic(Handle timer) 
{
	ConnectToMatchmaking();
	
	int notConnected = 0, iMaxClients = MaxClients;
	for (int iClient = 1; iClient <= iMaxClients; iClient++)
	{
		if (IsClientConnected (iClient) && IsClientInGame (iClient))
			break;
		else
			notConnected++;
	}
	
	if(notConnected==iMaxClients)
		ReloadMap();
	
	if(HibernationCvarValue != 0 && GetConVarInt(HibernationCvar) == 0)
		SetConVarInt(HibernationCvar, 1);
	
	return Plugin_Handled;
}

public Action MapReloadCheck(Handle timer)
{
	if (isMapChange)
		return Plugin_Handled;
	
	if(doRestartMap == true)
	{
		doRestartMap = false;
		ReloadMap();
	}
	
	return Plugin_Handled;
}

void CallLobbyVote()
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientConnected (iClient) && IsClientInGame (iClient))
		{
			FakeClientCommand (iClient, "callvote returntolobby");
		}
	}
}

void PassVote()
{
	for(int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientConnected (iClient) && IsClientInGame (iClient))
		{
			FakeClientCommand(iClient, "Vote Yes");
		}
	}
}

void ReloadMap() 
{
	GetCurrentMap(CurrentMapString, sizeof(CurrentMapString));
	ServerCommand("map %s", CurrentMapString);
}

void DisconnectFromMatchmaking()
{
	GetConVarString(PluginCvarSearchKey, PluginSearchKeyString, sizeof(PluginSearchKeyString));
	SetConVarInt(SteamGroupExclusiveCvar, 1);
	SetConVarString(SearchKeyCvar, PluginSearchKeyString);
	
	if(HibernationCvarValue != 0)
		SetConVarInt(HibernationCvar, 0);	
	
	if(GetConVarFloat(PluginCvarTimeout)>0)
		CreateTimer(GetConVarFloat(PluginCvarTimeout), MakeServerPublic);
}

void ConnectToMatchmaking()
{
	SetConVarInt(SteamGroupExclusiveCvar, 0);
	SetConVarString(SearchKeyCvar, "");
}
