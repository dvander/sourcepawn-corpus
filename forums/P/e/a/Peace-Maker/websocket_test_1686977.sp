#pragma semicolon 1
#include <sourcemod>
#include <websocket>

#define PLUGIN_VERSION "1.0"

// The handle to the master socket
new WebsocketHandle:g_hListenSocket = INVALID_WEBSOCKET_HANDLE;

// An adt_array of all child socket handles
new Handle:g_hChilds;

public Plugin:myinfo = 
{
	name = "Websocket Sample",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Websocket sample usage",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	// Create the array
	g_hChilds = CreateArray();
	
	AddCommandListener(CmdLstnr_Say, "say");
}

public OnAllPluginsLoaded()
{
	decl String:sServerIP[40];
	new longip = GetConVarInt(FindConVar("hostip"));
	FormatEx(sServerIP, sizeof(sServerIP), "%d.%d.%d.%d", (longip >> 24) & 0x000000FF, (longip >> 16) & 0x000000FF, (longip >> 8) & 0x000000FF, longip & 0x000000FF);
	
	// Open a new child socket
	if(g_hListenSocket == INVALID_WEBSOCKET_HANDLE)
		g_hListenSocket = Websocket_Open(sServerIP, 12345, OnWebsocketIncoming, OnWebsocketMasterError, OnWebsocketMasterClose);
}

public Action:CmdLstnr_Say(client, const String:command[], argc)
{
	decl String:sBuffer[128];
	GetCmdArgString(sBuffer, sizeof(sBuffer));
	
	StripQuotes(sBuffer);
	if(strlen(sBuffer) == 0)
		return Plugin_Continue;
	
	Format(sBuffer, sizeof(sBuffer), "%N: %s", client, sBuffer);
	
	new iSize = GetArraySize(g_hChilds);
	for(new i=0;i<iSize;i++)
		Websocket_Send(GetArrayCell(g_hChilds, i), SendType_Text, sBuffer);
	
	return Plugin_Continue;
}

public OnPluginEnd()
{
	if(g_hListenSocket != INVALID_WEBSOCKET_HANDLE)
		Websocket_Close(g_hListenSocket);
}

public Action:OnWebsocketIncoming(WebsocketHandle:websocket, WebsocketHandle:newWebsocket, const String:remoteIP[], remotePort, String:protocols[256])
{
	Format(protocols, sizeof(protocols), "");
	Websocket_HookChild(newWebsocket, OnWebsocketReceive, OnWebsocketDisconnect, OnChildWebsocketError);
	PushArrayCell(g_hChilds, newWebsocket);
	//PrintToServer("readyState: %d", _:Websocket_GetReadyState(newWebsocket));
	return Plugin_Continue;
}

public OnWebsocketMasterError(WebsocketHandle:websocket, const errorType, const errorNum)
{
	LogError("MASTER SOCKET ERROR: handle: %d type: %d, errno: %d", _:websocket, errorType, errorNum);
	g_hListenSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnWebsocketMasterClose(WebsocketHandle:websocket)
{
	g_hListenSocket = INVALID_WEBSOCKET_HANDLE;
}

public OnChildWebsocketError(WebsocketHandle:websocket, const errorType, const errorNum)
{
	LogError("CHILD SOCKET ERROR: handle: %d, type: %d, errno: %d", _:websocket, errorType, errorNum);
	RemoveFromArray(g_hChilds, FindValueInArray(g_hChilds, websocket));
}

public OnWebsocketReceive(WebsocketHandle:websocket, WebsocketSendType:iType, const String:receiveData[], const dataSize)
{
	if(iType == SendType_Text)
	{
		PrintToServer("Socket %d: %s (%d)", _:websocket, receiveData, dataSize);
		PrintToChatAll("Socket %d: %s", _:websocket, receiveData);
		
		// Need some more space in that string to add that "Socket %d: ..." stuff
		decl String:sBuffer[dataSize+30];
		Format(sBuffer, dataSize+30, "Socket %d: %s", _:websocket, receiveData);
		
		// relay this chat to other sockets connected
		new iSize = GetArraySize(g_hChilds);
		for(new i=0;i<iSize;i++)
			// Don't echo the message back to the user sending it!
			if(GetArrayCell(g_hChilds, i) != websocket)
				Websocket_Send(GetArrayCell(g_hChilds, i), SendType_Text, sBuffer);
	}
}

public OnWebsocketDisconnect(WebsocketHandle:websocket)
{
	RemoveFromArray(g_hChilds, FindValueInArray(g_hChilds, websocket));
}