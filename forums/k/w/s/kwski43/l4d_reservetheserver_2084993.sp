#define PLUGIN_VERSION	"1.1.0"
#define MAX_LINE_WIDTH	 64

#define MESSAGE_FOR_PLAYERS_LINE1	""
#define MESSAGE_FOR_PLAYERS_LINE2	"\x04RECEIVED SERVER RESERVATION REQUEST"
#define MESSAGE_FOR_PLAYERS_LINE3	"\x05YOU WILL BE RETURNED TO LOBBY"
#define MESSAGE_FOR_PLAYERS_LINE4	"\x01SORRY!"
#define MESSAGE_FOR_PLAYERS_LINE5	""

#pragma semicolon 1

#include <sourcemod>

new Handle:PluginCvarSearchKey = INVALID_HANDLE;
new Handle:PluginCvarMode = INVALID_HANDLE;
new Handle:PluginCvarTimeout = INVALID_HANDLE;
new Handle:PluginCvarImmuneFlag = INVALID_HANDLE;

new Handle:SteamGroupExclusiveCvar = INVALID_HANDLE;
new Handle:SearchKeyCvar = INVALID_HANDLE;
new Handle:HibernationCvar = INVALID_HANDLE;

new HibernationCvarValue;
new bool:isMapChange = false;
new bool:doRestartMap = false;
new String:PluginSearchKeyString[MAX_LINE_WIDTH] = "";
new String:PluginCvarImmuneFlagString[MAX_LINE_WIDTH] = "";
new String:CurrentMapString[MAX_LINE_WIDTH] = "";

public Plugin:myinfo =
{
	name = "Reserve The Server",
	author = "Jack'lul",
	description = "Frees the server from all players and reserves it.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2084993"
}

public OnPluginStart() 
{
	decl String:game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) &&	!StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Plugin only supports Left 4 Dead and Left 4 Dead 2!");
		return;
	}
	
	CreateConVar("l4d_reservetheserver_version", PLUGIN_VERSION, "Reserve The Server plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_DONTRECORD);	
	PluginCvarMode = CreateConVar("l4d_reservetheserver_mode", "1", "0 - only remove players using lobby vote, 1 - remove players using lobby vote and then disconnect server from matchmaking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	PluginCvarSearchKey = CreateConVar("l4d_reservetheserver_searchkey", "", "sv_search_key will be set to this while server is reserved", FCVAR_PLUGIN);
	PluginCvarTimeout = CreateConVar("l4d_reservetheserver_timeout", "30", "How long will the server stay disconnected from matchmaking? 0 - never restore matchmaking connection", FCVAR_PLUGIN, true, 0.0, true, 300.0);
	PluginCvarImmuneFlag = CreateConVar("l4d_reservetheserver_immuneflag", "d", "If player with this flag is present on the server reservation request will be denied", FCVAR_PLUGIN);

	RegAdminCmd("sm_reservetheserver", Command_MakeReservation, ADMFLAG_ROOT, "Free the server from all players, then reserve it.");
	RegAdminCmd("sm_cancelreservation", Command_CancelReservation, ADMFLAG_ROOT, "Cancel reservation and make server public again.");
	
	SteamGroupExclusiveCvar	= FindConVar("sv_steamgroup_exclusive");
	SearchKeyCvar = FindConVar("sv_search_key");
	HibernationCvar = FindConVar("sv_hibernate_when_empty");
	HibernationCvarValue = GetConVarInt(HibernationCvar);
	
	AutoExecConfig(true, "l4d_reservetheserver");
}

public OnClientDisconnect(client)
{
	if (client == 0 || isMapChange || IsFakeClient(client))
		return;
	
	if(doRestartMap == true)
		CreateTimer(1.0, MapReloadCheck);
}

public OnMapEnd()
{
	isMapChange = true;
	doRestartMap = false;
}

public OnMapStart()
{
	isMapChange = false;
}

public Action:Command_MakeReservation(client, args) 
{
	new isAdminOnline = 0, notConnected = 0, iMaxClients = GetMaxClients();
	
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
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
			PrintToChatAll(MESSAGE_FOR_PLAYERS_LINE5);
			
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

public Action:Command_CancelReservation(client, args) 
{
	CreateTimer(0.1, MakeServerPublic);
}

public Action:FreeTheServer(Handle:timer) 
{
	CallLobbyVote();
	PassVote();
	
	if(GetConVarInt(PluginCvarMode)==1)
	{
		DisconnectFromMatchmaking();
	}
}

public Action:MakeServerPublic(Handle:timer) 
{
	ConnectToMatchmaking();
	
	new notConnected = 0, iMaxClients = GetMaxClients();
	for (new iClient = 1; iClient <= iMaxClients; iClient++)
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
}

public Action:MapReloadCheck(Handle:timer)
{
	if (isMapChange)
		return;
	
	if(doRestartMap == true)
	{
		doRestartMap = false;
		ReloadMap();
	}
}

CallLobbyVote()
{
	for (new iClient = 1; iClient <= GetMaxClients(); iClient++)
	{
		if (IsClientConnected (iClient) && IsClientInGame (iClient))
		{
			FakeClientCommand (iClient, "callvote returntolobby");
		}
	}
}

PassVote()
{
	for(new iClient = 1; iClient <= GetMaxClients(); iClient++)
	{
		if (IsClientConnected (iClient) && IsClientInGame (iClient))
		{
			FakeClientCommand(iClient, "Vote Yes");
		}
	}
}

ReloadMap() 
{
	GetCurrentMap(CurrentMapString, sizeof(CurrentMapString));
	ServerCommand("map %s", CurrentMapString);
}

DisconnectFromMatchmaking()
{
	GetConVarString(PluginCvarSearchKey, PluginSearchKeyString, sizeof(PluginSearchKeyString));
	SetConVarInt(SteamGroupExclusiveCvar, 1);
	SetConVarString(SearchKeyCvar, PluginSearchKeyString);
	
	if(HibernationCvarValue != 0)
		SetConVarInt(HibernationCvar, 0);	
	
	if(GetConVarFloat(PluginCvarTimeout)>0)
		CreateTimer(GetConVarFloat(PluginCvarTimeout), MakeServerPublic);
}

ConnectToMatchmaking()
{
	SetConVarInt(SteamGroupExclusiveCvar, 0);
	SetConVarString(SearchKeyCvar, "");
}
