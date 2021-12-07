#pragma semicolon 1
#include <sourcemod>
#include <morecolors>

#define PLUGIN_VERSION "1.1"

new Handle:hEnable = INVALID_HANDLE;
new Handle:hBroadcastMode = INVALID_HANDLE;
new Handle:hBroadcastChat = INVALID_HANDLE;
new Handle:hBroadcastCenter = INVALID_HANDLE;
new Handle:hNotifyMode = INVALID_HANDLE;
new Handle:hNotifyChat = INVALID_HANDLE;
new Handle:hNotifyCenter = INVALID_HANDLE;
new Handle:hFirstTimeOnly = INVALID_HANDLE;

new bool:FirstTime[MAXPLAYERS+1] = { true, ... };
new bool:ThruFavs[MAXPLAYERS+1] = { false, ... };

public Plugin:myinfo =
{
	name = "Favorite Connections: Messages",
  	author = "Nanochip",
	version = PLUGIN_VERSION,
  	description = "Detect when a player connects to the server via favorites and prints messages.",
	url = "http://thecubeserver.org/"
};

public OnPluginStart()
{
	CreateConVar("favoriteconnections_messages_version", PLUGIN_VERSION, "Favorite Connections: Messages Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	hEnable = CreateConVar("favoriteconnections_messages_enable", "1", "Enable the plugin? 1 = Enable, 0 = Disable", FCVAR_NOTIFY);
	hBroadcastMode = CreateConVar("favoriteconnections_messages_broadcastmode", "1", "How should we broadcast to all players on the server about the player joining through favorites? 0 = Do nothing 1 = Print to the chat 2 = Print to the center of the screen 3 = Both print to chat and center of the screen. (1 is the default)", 0, true, 0.0, true, 3.0);
	hNotifyMode = CreateConVar("favoriteconnections_messages_notifymode", "1", "How should we notify the player who joined through favorites? 0 = Do nothing 1 = Print to the chat 2 = Print to the center of the screen 3 = Both print to chat and center of the screen. (1 is the default)", 0, true, 0.0, true, 3.0);
	hBroadcastChat = CreateConVar("favoriteconnections_messages_broadcastchat", "{green}%PLAYER_NAME% {orange}joined the server through his/her {blue}favorites{orange}!", "This is the chat text that is sent to all players on the server about the player joining through favorites (Supports colors).");
	hBroadcastCenter = CreateConVar("favoriteconnections_messages_broadcastcenter", "%PLAYER_NAME% joined the server through his/her favorites!", "This is the center text that is sent to all playeres on the server about the player joining through favorites (Doesn't support colors).");
	hNotifyChat = CreateConVar("favoriteconnections_messages_notifychat", "{orange}Thank you, {green}%PLAYER_NAME%{orange}, for adding us to your favorites!", "This is the chat text that is sent to only the player when he/she joins the game via favorites (Supports colors).");
	hNotifyCenter = CreateConVar("favoriteconnections_messages_notifycenter", "Thank you, %PLAYER_NAME%, for adding us to your favorites!", "This is the center text that is sent to only the player when he/she joins the game via favorites (Doesn't support colors).");
	hFirstTimeOnly = CreateConVar("favorite_connections_messages_firsttimelonly", "1", "Only announce the message the first time they join thru favorites. 1 = Yes, 0 = No", 0, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "FavoriteConnections_Messages");
	
	HookEvent("player_team", OnPlayerTeam);
}

public Action:ClientConnectedViaFavorites(client)
{
	if (!GetConVarBool(hEnable)) 
	{
		return Plugin_Continue;
	}
	
	ThruFavs[client] = true;
	if (GetUserFlagBits(client) != 0)
	{
		FirstTime[client] = false;
		return Plugin_Continue;
	}
	
	decl String:broadcastChat[256], String:broadcastCenter[256], String:name[32];
	GetClientName(client, name, sizeof(name));
	GetConVarString(hBroadcastChat, broadcastChat, sizeof(broadcastChat));
	GetConVarString(hBroadcastCenter, broadcastCenter, sizeof(broadcastCenter));
	
	ReplaceString(broadcastChat, sizeof(broadcastChat), "%PLAYER_NAME%", name);
	ReplaceString(broadcastCenter, sizeof(broadcastCenter), "%PLAYER_NAME%", name);
	
	if (GetConVarInt(hBroadcastMode) == 1)
	{
		CPrintToChatAll(broadcastChat);
	}
	if (GetConVarInt(hBroadcastMode) == 2)
	{
		PrintCenterTextAll(broadcastCenter);
	}
	if (GetConVarInt(hBroadcastMode) == 3)
	{
		CPrintToChatAll(broadcastChat);
		PrintCenterTextAll(broadcastCenter);
	}
	
	return Plugin_Continue;
}

public OnPlayerTeam(Handle:event, const String:teamName[], bool:dontBroadcast)
{
	if (!GetConVarBool(hEnable)) 
	{
		return;
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:notifyChat[256], String:notifyCenter[256], String:name[32];
	if (ThruFavs[client] && (FirstTime[client] || !GetConVarBool(hFirstTimeOnly)))
	{
		GetClientName(client, name, sizeof(name));
		GetConVarString(hNotifyChat, notifyChat, sizeof(notifyChat));
		GetConVarString(hNotifyCenter, notifyCenter, sizeof(notifyCenter));
		
		ReplaceString(notifyChat, sizeof(notifyChat), "%PLAYER_NAME%", name);
		ReplaceString(notifyCenter, sizeof(notifyCenter), "%PLAYER_NAME%", name);
		
		if (GetConVarInt(hNotifyMode) == 1)
		{
			CPrintToChat(client, notifyChat);
		}
		if (GetConVarInt(hNotifyMode) == 2)
		{
			PrintCenterText(client, notifyCenter);
		}
		if (GetConVarInt(hNotifyMode) == 3)
		{
			CPrintToChat(client, notifyChat);
			PrintCenterText(client, notifyCenter);
		}
		FirstTime[client] = false;
	}
	return;
}

public OnClientDisconnect(client)
{
	if (ThruFavs[client]) ThruFavs[client] = false;
}