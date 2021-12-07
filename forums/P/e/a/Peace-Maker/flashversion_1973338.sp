#pragma semicolon 1
#include <sourcemod>
#include <regex>
#include <socket>
#include <flashversion>

enum
{
	MOTDPANEL_CMD_NONE,
	MOTDPANEL_CMD_JOIN,
	MOTDPANEL_CMD_CHANGE_TEAM,
	MOTDPANEL_CMD_IMPULSE_101,
	MOTDPANEL_CMD_MAPINFO,
	MOTDPANEL_CMD_CLOSED_HTMLPAGE,
	MOTDPANEL_CMD_CHOOSE_TEAM,
};

#define REQUEST_LENGTH 4
enum PluginRequest {
	PL_client,
	Handle:PL_plugin,
	Function:PL_func,
	any:PL_data
};

new Handle:g_hCVTimeout;
new Handle:g_hCVHost;

new Handle:g_hServerSocket;
new String:g_sServerIP[16];
new g_iPort;

new Handle:g_hGETEx;
new g_iPlayerCookie[MAXPLAYERS+1] = {-1,...};
new g_iFlashVersion[MAXPLAYERS+1][4];
new bool:g_bVersionCached[MAXPLAYERS+1];
new bool:g_bCheckFailed[MAXPLAYERS+1];

new Handle:g_hPluginRequests;
new Handle:g_hRequestTimeout[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Detect Flash Version",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "Checks the flash player version of players",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("flashversion");
	CreateNative("Flash_GetClientVersion", Native_GetClientVersion);
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_hCVTimeout = CreateConVar("sm_flashversion_timeout", "5", "How many seconds to wait for an answer before considering the request as failed?", _, true, 1.0);
	g_hCVHost = CreateConVar("sm_flashversion_host", "wcfan.de/flash/", "Where is the flash detection html script located?");
	
	g_hPluginRequests = CreateArray(REQUEST_LENGTH);
	
	// Regular expression to read the http response
	g_hGETEx = CompileRegex("^GET \\/\\?cookie=([0-9abcdef]+)\\&fmaj=([0-9]+)\\&fmin=([0-9]+)\\&frel=([0-9]+)\\&fbui=([0-9]+) HTTP");
	if(g_hGETEx == INVALID_HANDLE)
	{
		SetFailState("Failed compiling GET parsing regex.");
		return;
	}
	
	// Our listen socket
	g_hServerSocket = SocketCreate(SOCKET_TCP, Socket_OnMasterError);
	if(g_hServerSocket == INVALID_HANDLE)
	{
		SetFailState("Can't create server socket.");
		return;
	}
	
	// Get the server ip
	new longip = GetConVarInt(FindConVar("hostip"));
	Format(g_sServerIP, sizeof(g_sServerIP), "%d.%d.%d.%d", (longip>>24)&0xff, (longip>>16)&0xff, (longip>>8)&0xff, longip&0xff);
	
	// Find an available port?
	do
	{
		g_iPort = GetRandomInt(14646, 14686);
	}
	while(!SocketBind(g_hServerSocket, g_sServerIP, g_iPort));
	SocketListen(g_hServerSocket, Socket_OnMasterIncoming);
}

public OnClientDisconnect(client)
{
	g_iPlayerCookie[client] = -1;
	g_bVersionCached[client] = false;
	g_bCheckFailed[client] = false;
	ClearHandle(g_hRequestTimeout[client]);
	// Remove all waiting requests for his flash version.
	new iRequest[REQUEST_LENGTH], iSize = GetArraySize(g_hPluginRequests);
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(g_hPluginRequests, i, iRequest, REQUEST_LENGTH);
		if(iRequest[PL_client] == client)
		{
			RemoveFromArray(g_hPluginRequests, i);
			i--;
			iSize--;
		}
	}
}

// This guy has html motds disabled or something?
public Action:Timer_OnRequestTimeout(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	if(!client)
		return Plugin_Handled;
	
	g_hRequestTimeout[client] = INVALID_HANDLE;
	
	if(g_iPlayerCookie[client] == -1)
		return Plugin_Handled;
	
	for(new i=0;i<4;i++)
		g_iFlashVersion[client][i] = 0;
	
	g_iPlayerCookie[client] = -1;
	g_bVersionCached[client] = true;
	g_bCheckFailed[client] = true;
	
	// Notify all waiting plugins
	new iRequest[REQUEST_LENGTH], iSize = GetArraySize(g_hPluginRequests);
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(g_hPluginRequests, i, iRequest, REQUEST_LENGTH);
		if(iRequest[PL_client] != client)
			continue;
		
		CallFlashVersionFunction(client, iRequest[PL_plugin], iRequest[PL_func], true, iRequest[PL_data]);
		RemoveFromArray(g_hPluginRequests, i);
		i--;
		iSize--;
	}
	return Plugin_Handled;
}


public Socket_OnMasterError(Handle:socket, const errorType, const errorNum, any:arg)
{
	//LogError("server socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public Socket_OnMasterIncoming(Handle:socket, Handle:newSocket, String:remoteIP[], remotePort, any:arg)
{
	SocketSetReceiveCallback(newSocket, Socket_OnChildSocketReceive);
	SocketSetDisconnectCallback(newSocket, Socket_OnChildSocketDisconnected);
	SocketSetErrorCallback(newSocket, Socket_OnChildSocketError);
}

public Socket_OnChildSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:arg)
{
	if(MatchRegex(g_hGETEx, receiveData) != -1)
	{
		decl String:sBuffer[20];
		GetRegexSubString(g_hGETEx, 1, sBuffer, sizeof(sBuffer));
		new iCookie = StringToInt(sBuffer, 16);
		
		new iFlashVersion[4];
		for(new i=0;i<4;i++)
		{
			GetRegexSubString(g_hGETEx, i+2, sBuffer, sizeof(sBuffer));
			iFlashVersion[i] = StringToInt(sBuffer);
		}
		
		for(new client=1;client<=MaxClients;client++)
		{
			if(g_iPlayerCookie[client] == iCookie)
			{
				g_iFlashVersion[client] = iFlashVersion;
				g_bVersionCached[client] = true;
				g_iPlayerCookie[client] = -1;
				
				// Notify all waiting plugins
				new iRequest[REQUEST_LENGTH], iSize = GetArraySize(g_hPluginRequests);
				for(new i=0;i<iSize;i++)
				{
					GetArrayArray(g_hPluginRequests, i, iRequest, REQUEST_LENGTH);
					if(iRequest[PL_client] != client)
						continue;
					
					CallFlashVersionFunction(client, iRequest[PL_plugin], iRequest[PL_func], false, iRequest[PL_data]);
					RemoveFromArray(g_hPluginRequests, i);
					i--;
					iSize--;
				}
				
				break;
			}
		}
	}
	else
	{
		decl String:sPath[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPath, sizeof(sPath), "logs/flashversion_response.log");
		LogToFile(sPath, receiveData);
	}
	
	// Just close the connection >:)
	CloseHandle(socket);
}

public Socket_OnChildSocketDisconnected(Handle:socket, any:arg) {
	// remote side disconnected
	CloseHandle(socket);
}

public Socket_OnChildSocketError(Handle:socket, const errorType, const errorNum, any:arg) {
	// a socket error occured
	//LogError("child socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public Native_GetClientVersion(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index %d.", client);
		return;
	}
	
	new bool:bShow = GetNativeCell(2);
	new Function:iFunction = GetNativeCell(3);
	new any:iData = GetNativeCell(4);
	
	// If we already cached that version, call the function right away.
	if(g_bVersionCached[client])
	{
		CallFlashVersionFunction(client, plugin, iFunction, g_bCheckFailed[client], iData);
		return;
	}
	
	new iRequest[REQUEST_LENGTH];
	iRequest[PL_client] = client;
	iRequest[PL_plugin] = plugin;
	iRequest[PL_func] = iFunction;
	iRequest[PL_data] = iData;
	
	PushArrayArray(g_hPluginRequests, iRequest, REQUEST_LENGTH);
	
	// We already requested that version number. Just have the calling plugin notified too.
	if(g_iPlayerCookie[client] != -1)
		return;
	
	// Get an unique player cookie.
	new bool:bDuplicate;
	do
	{
		bDuplicate = false;
		g_iPlayerCookie[client] = GetRandomInt(0, 99999999);
		for(new i=1;i<=MaxClients;i++)
			if(i != client && g_iPlayerCookie[i] == g_iPlayerCookie[client])
				bDuplicate = true;
	}
	while(bDuplicate);
	
	
	decl String:sBuffer[128];
	GetConVarString(g_hCVHost, sBuffer, sizeof(sBuffer));
	Format(sBuffer, sizeof(sBuffer), "http://%s?ip=%s&port=%d&cookie=%x", sBuffer, g_sServerIP, g_iPort, g_iPlayerCookie[client]);
	
	ShowMOTDPanelEx(client, "Checking Flash Player version...", sBuffer, MOTDPANEL_TYPE_URL, MOTDPANEL_CMD_NONE, bShow, USERMSG_BLOCKHOOKS|USERMSG_RELIABLE);
	
	g_hRequestTimeout[client] = CreateTimer(GetConVarFloat(g_hCVTimeout), Timer_OnRequestTimeout, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

CallFlashVersionFunction(client, Handle:plugin, Function:pl_flashVersion, bool:bError, any:data)
{
	if(!IsValidPlugin(plugin))
		return;
	
	Call_StartFunction(plugin, pl_flashVersion);
	Call_PushCell(client);
	Call_PushArray(g_iFlashVersion[client], 4);
	Call_PushCell(bError);
	Call_PushCell(data);
	Call_Finish();
}

// IsValidHandle() is deprecated, let's do a real check then...
// From tEasyFTP by Thrawn2
stock bool:IsValidPlugin(Handle:hPlugin) {
	if(hPlugin == INVALID_HANDLE)
		return false;

	new Handle:hIterator = GetPluginIterator();

	new bool:bPluginExists = false;
	while(MorePlugins(hIterator)) {
		new Handle:hLoadedPlugin = ReadPlugin(hIterator);
		if(hLoadedPlugin == hPlugin) {
			bPluginExists = true;
			break;
		}
	}

	CloseHandle(hIterator);

	return bPluginExists;
}

// Extended ShowMOTDPanel with options for Command and Show
// From PinionAdverts
stock ShowMOTDPanelEx(client, const String:title[], const String:msg[], type=MOTDPANEL_TYPE_INDEX, cmd=MOTDPANEL_CMD_NONE, bool:show=true, usermessageFlags=0)
{
	new Handle:Kv = CreateKeyValues("data");

	KvSetString(Kv, "title", title);
	KvSetNum(Kv, "type", type);
	KvSetString(Kv, "msg", msg);
	KvSetNum(Kv, "cmd", cmd); //http://forums.alliedmods.net/showthread.php?p=1220212
	ShowVGUIPanelEx(client, "info", Kv, show, usermessageFlags);
	CloseHandle(Kv);
}

ShowVGUIPanelEx(client, const String:name[], Handle:kv=INVALID_HANDLE, bool:show=true, usermessageFlags=0)
{
	new Handle:msg = StartMessageOne("VGUIMenu", client, usermessageFlags);
	
	if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(msg, "name", name);
		PbSetBool(msg, "show", true);

		if (kv != INVALID_HANDLE && KvGotoFirstSubKey(kv, false))
		{
			new Handle:subkey;

			do
			{
				decl String:key[128], String:value[128];
				KvGetSectionName(kv, key, sizeof(key));
				KvGetString(kv, NULL_STRING, value, sizeof(value), "");
				
				subkey = PbAddMessage(msg, "subkeys");
				PbSetString(subkey, "name", key);
				PbSetString(subkey, "str", value);

			} while (KvGotoNextKey(kv, false));
		}
	}
	else //BitBuffer
	{
		BfWriteString(msg, name);
		BfWriteByte(msg, show);
		
		if (kv == INVALID_HANDLE)
		{
			BfWriteByte(msg, 0);
		}
		else
		{	
			if (!KvGotoFirstSubKey(kv, false))
			{
				BfWriteByte(msg, 0);
			}
			else
			{
				new keyCount = 0;
				do
				{
					++keyCount;
				} while (KvGotoNextKey(kv, false));
				
				BfWriteByte(msg, keyCount);
				
				if (keyCount > 0)
				{
					KvGoBack(kv);
					KvGotoFirstSubKey(kv, false);
					do
					{
						decl String:key[128], String:value[128];
						KvGetSectionName(kv, key, sizeof(key));
						KvGetString(kv, NULL_STRING, value, sizeof(value), "");
						
						BfWriteString(msg, key);
						BfWriteString(msg, value);
					} while (KvGotoNextKey(kv, false));
				}
			}
		}
	}
	
	EndMessage();
}

stock ClearHandle(&Handle:hndl)
{
	if(hndl != INVALID_HANDLE)
	{
		CloseHandle(hndl);
		hndl = INVALID_HANDLE;
	}
}