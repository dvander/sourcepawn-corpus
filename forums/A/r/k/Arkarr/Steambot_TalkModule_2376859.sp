#include <sourcemod>
#include <sdktools>
#include <socket>
#include <colors>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"
#define PLUGIN_TAG "{green}[SteamBot Talk]{default}"

Handle clientSocket;
Handle CVAR_SteambotServerIP;
Handle CVAR_SteambotServerPort;
Handle CVAR_SteambotTCPPassword;
Handle CVAR_SteambotName;
Handle TimerReconnect;
Handle ARRAY_RequestID;

char steambotIP[100];
char steambotPort[10];
char steambotPassword[25];
char steambotName[50];

int requestID[MAXPLAYERS+1];

bool connected;

public Plugin myinfo = 
{
	name = "[ANY] Steambot - Talk Module",
	author = PLUGIN_AUTHOR,
	description = "Allow you to message the steambot in game",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

public void OnPluginStart()
{
	ARRAY_RequestID = CreateArray();
	
	CVAR_SteambotServerIP = CreateConVar("sm_steambot_server_ip", "XXX.XXX.XXX.XXX", "The ip of the server where the steambot is hosted.");
	CVAR_SteambotServerPort = CreateConVar("sm_steambot_server_port", "11000", "The port of the server where the steambot is hosted, WATCH OUT ! In version 1.0 of the bot, the port is hardcoded and is 11000 !!");
	CVAR_SteambotTCPPassword = CreateConVar("sm_steambot_tcp_password", "Pa$Sw0Rd", "The password to allow TCP data to be read / send (TCPPassword in settings.json)");
	CVAR_SteambotName = CreateConVar("sm_steambot_name", "[Steambot]", "The name of the steambot to display in the chat.");
	
	RegConsoleCmd("sm_talk", CMD_SendQuestion, "Send a data to the steambot");

	AutoExecConfig(true, "SteamBot_TalkModule");
}

public void OnConfigsExecuted()
{
	GetConVarString(CVAR_SteambotServerIP, steambotIP, sizeof(steambotIP));
	GetConVarString(CVAR_SteambotServerPort, steambotPort, sizeof(steambotPort));
	GetConVarString(CVAR_SteambotTCPPassword, steambotPassword, sizeof(steambotPassword));
	GetConVarString(CVAR_SteambotName, steambotName, sizeof(steambotName));
	
	AttemptSteamBotConnection();	
}

public Action CMD_SendQuestion(client, args)
{
	if(!connected)
	{
		CPrintToChat(client, "%s Bot is disconnected yet, try later.", PLUGIN_TAG);
		return Plugin_Continue;	
	}
	
	if(args < 1)
	{
		CPrintToChat(client, "%s Usage: sm_talk [text]", PLUGIN_TAG);
		return Plugin_Continue;	
	}
	
	char arguments[400];
	GetCmdArgString(arguments, sizeof(arguments));
	
	requestID[client] = GetRandomInt(0, 99999);
	while(FindValueInArray(ARRAY_RequestID, requestID[client]) != -1)
		requestID[client] = GetRandomInt(0, 99999);
	
	PushArrayCell(ARRAY_RequestID, requestID[client]);
	Format(arguments, sizeof(arguments), "%sSPEAK_WITH_MEREQUEST#%i|%s", steambotPassword, requestID[client], arguments);
	
	SocketSend(clientSocket, arguments, sizeof(arguments));
	
	return Plugin_Handled;
}

public void ProcessMessage(char[] message, int dataSize)
{
	char requestid[20];
	for(int i = 0; i < MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			Format(requestid, sizeof(requestid), "REQUEST#%i|", requestID[i]);
			if(StrContains(message, requestid) != -1)
			{
				ReplaceString(message, dataSize, requestid, "");
				CPrintToChat(i, "%s %s", steambotName, message);
				RemoveFromArray(ARRAY_RequestID, FindValueInArray(ARRAY_RequestID, requestID[i]))
				break;
			}
		}
	}
}

//Steam bot related stuff (template)
public void AttemptSteamBotConnection()
{
	clientSocket = SocketCreate(SOCKET_TCP, OnClientSocketError);
	PrintToServer("Attempt to connect to %s:%i ...", steambotIP, StringToInt(steambotPort));
	SocketConnect(clientSocket, OnClientSocketConnected, OnChildSocketReceive, OnChildSocketDisconnected, steambotIP, StringToInt(steambotPort));
}

public OnClientSocketConnected(Handle socket, any arg)
{
	PrintToServer("Steambot - Talk Module connected");
	connected = true;
	
	char data[200];
	char map[100];
	GetHostName(map, sizeof(map));
	Format(data, sizeof(data), "%sREQUEST_CONNECTION%s", steambotPassword, map);
	SocketSend(clientSocket, data, sizeof(data));
	//Destroying the reconnect timer on failure :
	if(TimerReconnect != INVALID_HANDLE)
	{
		KillTimer(TimerReconnect);
		TimerReconnect = INVALID_HANDLE;
	}
}

public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	connected = false;
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	ProcessMessage(receiveData, dataSize);
}

public OnChildSocketDisconnected(Handle socket, any hFile)
{
	//Connection to steam bot lost !
	PrintToServer("Steambot - Talk Module disconnected");
	connected = false;
	CloseHandle(socket);
}

public Action TMR_TryReconnection(Handle timer, any none)
{
	AttemptSteamBotConnection();
}

stock void GetHostName(char[] str, size)
{
    Handle hHostName;
    
    if(hHostName == INVALID_HANDLE)
        if( (hHostName = FindConVar("hostname")) == INVALID_HANDLE)
            return;
    
    GetConVarString(hHostName, str, size);
}

stock bool IsValidClient(iClient, bool bReplay = true)
{
	if (iClient <= 0 || iClient > MaxClients)
		return false;
	if (!IsClientInGame(iClient))
		return false;
	if (bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
		
	return true;
}