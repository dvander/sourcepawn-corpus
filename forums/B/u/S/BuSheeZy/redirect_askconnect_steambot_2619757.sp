#include <sourcemod>
#include <socket>

#pragma semicolon 1

public Plugin myinfo =
{
	name = "Server Redirect: Ask connect with steambot",
	author = "H3bus",
	description = "Server redirection/follow: Ask connect with steambot",
	version = "Bush 1.0.0",
	url = "http://www.sourcemod.net"
};

enum SocketStatus {
	eSocket_Closed,
	eSocket_Disconnected,
	eSocket_Connecting,
	eSocket_Connected
}

Handle g_hSocketHandle = INVALID_HANDLE;
Handle g_hCommandQueue = INVALID_HANDLE;
Handle g_hCvarSocketAddress = INVALID_HANDLE;
Handle g_hCvarSocketPort = INVALID_HANDLE;
Handle g_hCvarSocketPass = INVALID_HANDLE;

SocketStatus g_SocketStatus = eSocket_Closed;

public void OnPluginStart()
{
	g_hCvarSocketAddress = CreateConVar("redirect_askconnect_steambot_address", "localhost", "Address of the steambot");
	g_hCvarSocketPort = CreateConVar("redirect_askconnect_steambot_port", "19855", "TCP port of the steambot", .hasMin=true, .min=1.0);
	g_hCvarSocketPass = CreateConVar("redirect_askconnect_steambot_pass", "super-secret", "Simple auth", FCVAR_PROTECTED);

	g_hSocketHandle = SocketCreate(SOCKET_TCP, OnSocketError);
	g_SocketStatus = eSocket_Disconnected;

	g_hCommandQueue = CreateArray(4096);
}

public void OnAskClientConnect(int client, char[] ip, char[] password)
{
	decl String:steamId[30];

	if(GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
	{
		decl String:buffer[4096];

		char pass[64];
		GetConVarString(g_hCvarSocketPass, pass, sizeof(pass));

		Format(buffer, sizeof(buffer), "BCMDCHAT%s|%s|Copy and paste the next line into your console.\nconnect %s\nhttps://gooshed.com/servers for servers.\n\n", steamId, pass, ip);
		PushArrayString(g_hCommandQueue, buffer);

		SocketProcess();
	}
}

stock SocketProcess()
{
	if(g_SocketStatus == eSocket_Closed)
	{
		g_hSocketHandle = SocketCreate(SOCKET_TCP, OnSocketError);
		g_SocketStatus = eSocket_Disconnected;
	}

	if(g_SocketStatus == eSocket_Disconnected)
	{
		decl String:host[200];
		GetConVarString(g_hCvarSocketAddress, host, sizeof(host));

		g_SocketStatus = eSocket_Connecting;
		SocketConnect(g_hSocketHandle,
						OnSocketConnected,
						OnSocketReceive,
						OnSocketDisconnect,
						host,
						GetConVarInt(g_hCvarSocketPort));
	}
	else if(g_SocketStatus == eSocket_Connected )
	{
		decl String:buffer[4096];

		while(GetArraySize(g_hCommandQueue) > 0)
		{
			new length = GetArrayString(g_hCommandQueue, 0, buffer, sizeof(buffer));
			SocketSend(g_hSocketHandle, buffer, length);

			RemoveFromArray(g_hCommandQueue, 0);
		}
	}
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg)
{
	CloseHandle(g_hSocketHandle);
	g_SocketStatus = eSocket_Closed;
	ClearArray(g_hCommandQueue);

	LogError("Socket error %d, %d", errorType, errorNum);
}

public OnSocketConnected(Handle:socket, any:arg)
{
	g_SocketStatus = eSocket_Connected;
	SocketProcess();
}

public OnSocketReceive(Handle:socket, const String:receiveData[], const dataSize, any:arg)
{
}

public OnSocketDisconnect(Handle:socket, any:arg)
{
	g_SocketStatus = eSocket_Disconnected;
	if(GetArraySize(g_hCommandQueue) > 0)
	{
		CreateTimer(3.0, Timer_AfterDisconnect, INVALID_HANDLE);
	}
}

public Action:Timer_AfterDisconnect(Handle:timer)
{
	SocketProcess();
}