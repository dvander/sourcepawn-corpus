#include <sourcemod>
#include <sdktools>
#include <socket>
#include <colors>
#include <scp>

#define PLUGIN_AUTHOR "Arkarr"
#define PLUGIN_VERSION "1.00"
#define PLUGIN_TAG "{green}[SteamBot Talk]{default}"

Handle clientSocket;
Handle CVAR_SteambotServerIP;
Handle CVAR_SteambotServerPort;
Handle CVAR_SteambotTCPPassword;
Handle TimerReconnect;

char steambotIP[100];
char steambotPort[10];
char steambotPassword[25];

public Plugin myinfo = 
{
	name = "[ANY] Steambot - Chat Listener Module",
	author = PLUGIN_AUTHOR,
	description = "Rellay chat message to the steambot.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};

public void OnPluginStart()
{
	CVAR_SteambotServerIP = CreateConVar("sm_steambot_server_ip", "XXX.XXX.XXX.XXX", "The ip of the server where the steambot is hosted.");
	CVAR_SteambotServerPort = CreateConVar("sm_steambot_server_port", "11000", "The port of the server where the steambot is hosted, WATCH OUT ! In version 1.0 of the bot, the port is hardcoded and is 11000 !!");
	CVAR_SteambotTCPPassword = CreateConVar("sm_steambot_tcp_password", "Pa$Sw0Rd", "The password to allow TCP data to be read / send (TCPPassword in settings.json)");

	AutoExecConfig(true, "SteamBot_ChatListener");
}

public void OnConfigsExecuted()
{
	GetConVarString(CVAR_SteambotServerIP, steambotIP, sizeof(steambotIP));
	GetConVarString(CVAR_SteambotServerPort, steambotPort, sizeof(steambotPort));
	GetConVarString(CVAR_SteambotTCPPassword, steambotPassword, sizeof(steambotPassword));
	
	AttemptSteamBotConnection();	
}

public Action OnChatMessage(&author, Handle recipients, char[] name, char[] message)
{
	char finalMessage[225];
	Format(finalMessage, sizeof(finalMessage), "%sLISTENER%s : %s", steambotPassword, name, message);
	SocketSend(clientSocket, finalMessage, sizeof(finalMessage));
	return Plugin_Continue;
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
	PrintToServer("Steambot - Chat Listener Module connected");
	
	//Destroying the reconnect timer on failure :
	if(TimerReconnect != INVALID_HANDLE)
	{
		KillTimer(TimerReconnect);
		TimerReconnect = INVALID_HANDLE;
	}
}

public OnClientSocketError(Handle socket, const int errorType, const int errorNum, any ary)
{
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public OnChildSocketReceive(Handle socket, char[] receiveData, const int dataSize, any hFile)
{
	if(StrContains(receiveData, steambotPassword) != -1 && StrContains(receiveData, "LISTENER") != -1)
	{
		ReplaceString(receiveData, dataSize, steambotPassword, "");
		ReplaceString(receiveData, dataSize, "LISTENER", "");
		if(strlen(receiveData) > 0)
			PrintToChatAll("STEAMBOT: %s", receiveData);
	}
}

public OnChildSocketDisconnected(Handle socket, any hFile)
{
	//Connection to steam bot lost !
	PrintToServer("Steambot - Chat Listener Module disconnected");
	CloseHandle(socket);
}

public Action TMR_TryReconnection(Handle timer, any none)
{
	AttemptSteamBotConnection();
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