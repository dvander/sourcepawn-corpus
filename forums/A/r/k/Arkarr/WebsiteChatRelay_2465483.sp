#include <sourcemod>
#include <websocket>
#include <chat-processor>

#define PLUGIN_AUTHOR 	"Arkarr"
#define PLUGIN_VERSION 	"1.0"

WebsocketHandle ServerSocket = INVALID_WEBSOCKET_HANDLE;

Handle CVAR_WebsocketPort;

Handle ClientSockets;

public Plugin myinfo = 
{
	name = "Websocket Sample",
	author = PLUGIN_AUTHOR,
	description = "Websocket sample usage",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	CVAR_WebsocketPort = CreateConVar("sm_wcr_websocket_port", "7897", "Set the websoket port that should be usued for the website connection.");
	
	ClientSockets = CreateArray();
}

public void OnPluginEnd()
{
	if(ServerSocket != INVALID_WEBSOCKET_HANDLE)
		Websocket_Close(ServerSocket);
}

public OnAllPluginsLoaded()
{
	char serverIP[40];
	int longip = GetConVarInt(FindConVar("hostip"));
	FormatEx(serverIP, sizeof(serverIP), "%d.%d.%d.%d", (longip >> 24) & 0x000000FF, (longip >> 16) & 0x000000FF, (longip >> 8) & 0x000000FF, longip & 0x000000FF);

	if(ServerSocket == INVALID_WEBSOCKET_HANDLE)
		ServerSocket = Websocket_Open(serverIP, GetConVarInt(CVAR_WebsocketPort), OnWebsocketIncoming, OnWebsocketMasterError, OnWebsocketMasterClose);
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
	char clientName[MAX_NAME_LENGTH];
	char clientSID[64];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientAuthId(client, AuthId_SteamID64, clientSID, sizeof(clientSID));
	
	char finalMsg[MAX_NAME_LENGTH + MAXLENGTH_MESSAGE + 3];
	Format(finalMsg, sizeof(finalMsg), "%s|%s : %s", clientSID, clientName, sArgs);
	
	//PrintToServer("Sending \"%s\" (%i) to %i clients", finalMsg, sizeof(finalMsg), GetArraySize(ClientSockets));
	for(new i = 0; i < GetArraySize(ClientSockets); i++)
		Websocket_Send(GetArrayCell(ClientSockets, i), SendType_Text, finalMsg);
		
}

public Action OnWebsocketIncoming(WebsocketHandle websocket, WebsocketHandle newWebsocket, const char[] remoteIP, int remotePort, char protocols[256])
{
	Format(protocols, sizeof(protocols), "");
	
	Websocket_HookChild(newWebsocket, OnWebsocketReceive, OnWebsocketDisconnect, OnChildWebsocketError);
	
	PushArrayCell(ClientSockets, newWebsocket);
	
	return Plugin_Continue;
}

public OnWebsocketMasterError(WebsocketHandle websocket, const errorType, const errorNum)
{
	LogError("MASTER SOCKET ERROR: handle: %d type: %d, errno: %d", _:websocket, errorType, errorNum);
	ServerSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnWebsocketMasterClose(WebsocketHandle websocket)
{
	ServerSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnChildWebsocketError(WebsocketHandle websocket, const errorType, const errorNum)
{
	LogError("CHILD SOCKET ERROR: handle: %d, type: %d, errno: %d", _:websocket, errorType, errorNum);
	
	RemoveFromArray(ClientSockets, FindValueInArray(ClientSockets, websocket));
}

public OnWebsocketReceive(WebsocketHandle websocket, WebsocketSendType iType, const char[] receiveData, const dataSize)
{
	//PrintToServer("Socket %d: %s (%d)", _:websocket, receiveData, dataSize);
	if(iType == SendType_Text)
	{
		PrintToChatAll("%s", receiveData);
		
		for(new i = 0; i < GetArraySize(ClientSockets); i++)
			if(GetArrayCell(ClientSockets, i) != websocket)
				Websocket_Send(GetArrayCell(ClientSockets, i), SendType_Text, receiveData);
	}
}

public OnWebsocketDisconnect(WebsocketHandle:websocket)
{
	RemoveFromArray(ClientSockets, FindValueInArray(ClientSockets, websocket));
}