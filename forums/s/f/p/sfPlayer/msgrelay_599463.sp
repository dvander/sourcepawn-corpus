#pragma semicolon 1

#include <sourcemod>
#include <socket>

public Plugin:myinfo = {
	name = "Message Relay",
	author = "sfPlayer",
	description = "relays messages between servers",
	version = "1.0.1",
	url = "http://www.player.to/"
};

new Handle:g_Socket = INVALID_HANDLE;

new Handle:cvLocalHost = INVALID_HANDLE;
new Handle:cvRemoteHost = INVALID_HANDLE;
new Handle:cvPassword = INVALID_HANDLE;

public OnPluginStart() {
	cvLocalHost = CreateConVar("sm_mr_localhost", "0.0.0.0:48476", "Local IP for incoming connections (port must not be the Gameserver port)", FCVAR_PLUGIN|FCVAR_PROTECTED);
	cvRemoteHost = CreateConVar("sm_mr_remotehost", "127.0.0.1:48476", "Remote IP:port to send messages to (port must not be the Gameserver port)", FCVAR_PLUGIN|FCVAR_PROTECTED);
	cvPassword = CreateConVar("sm_mr_password", "password", "password to prevent 3rd party from message injection", FCVAR_PLUGIN|FCVAR_PROTECTED);

	RegConsoleCmd("say", cmdSay);
}

public OnConfigsExecuted() {
	new Handle:socket = SocketCreate(SOCKET_UDP, OnSocketError);
	SocketSetOption(socket, SocketReuseAddr, 1);

	decl String:localHost[25];
	GetConVarString(cvLocalHost, localHost, sizeof(localHost));
	decl String:localIP[16];
	new pos = StrContains(localHost, ":");

	if (pos > 0 && pos < strlen(localHost)-1 && pos < sizeof(localIP)) {
		strcopy(localIP, pos+1, localHost);
		new localPort = StringToInt(localHost[pos+1]);

		SocketBind(socket, localIP, localPort);
		connect(socket);
		g_Socket = socket;
	}
}

public Action:TimerConnect(Handle:timer, any:arg) {
	connect(arg);
}

connect(Handle:socket) {
	if (!SocketIsConnected(socket)) {
		decl String:remoteHost[25];
		GetConVarString(cvRemoteHost, remoteHost, sizeof(remoteHost));
		decl String:remoteIP[16];
		new pos = StrContains(remoteHost, ":");

		if (pos > 0 && pos < strlen(remoteHost)-1 && sizeof(remoteIP) > pos) {
			strcopy(remoteIP, pos+1, remoteHost);
			new remotePort = StringToInt(remoteHost[pos+1]);

			SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, remoteIP, remotePort);
		}
	}
}

public OnSocketConnected(Handle:socket, any:arg) {
	// nothing to do
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {
	// udp packet: password\0nick\0message\0

	new c = 0;
	for (new i=0; i<dataSize; i++) {
		if (receiveData[i] == '\0') c++;
	}

	if (c == 3) {
		decl String:password[30];
		GetConVarString(cvPassword, password, sizeof(password));
		new pwLen = strlen(password);

		if (dataSize > pwLen+3 && StrEqual(receiveData, password)) {
			new msgOffset = pwLen+strlen(receiveData[pwLen+1])+2;
			if (msgOffset < dataSize) {
				PrintToChatAll("relayed message: %s: %s", receiveData[pwLen+1], receiveData[msgOffset]);
			}
		}
	}
}

public Action:cmdSay(client, args) {
	decl String:msg[160];
	if (GetCmdArgString(msg, sizeof(msg))) {
		if (msg[0] == '"') {
			new len = strlen(msg);
			if (len > 2 && msg[len-1] == '"') {
				strcopy(msg, len-1, msg[1]);
				msg[len-1] = '\0';
			} else {
				return Plugin_Continue;
			}
		}

		if (msg[0] == '+') {
			if (g_Socket != INVALID_HANDLE && SocketIsConnected(g_Socket)) {
				decl String:password[30];
				GetConVarString(cvPassword, password, sizeof(password));

				decl String:nick[MAX_NAME_LENGTH];
				if (client != 0) {
					GetClientName(client, nick, sizeof(nick));
				} else {
					strcopy(nick, sizeof(nick), "Console");
				}

				decl String:finalMsg[256];
				new offset = strcopy(finalMsg, sizeof(finalMsg), password)+1;
				offset += strcopy(finalMsg[offset], sizeof(finalMsg)-offset, nick)+1;
				if (offset < sizeof(finalMsg)) offset+= strcopy(finalMsg[offset], sizeof(finalMsg)-offset, msg[1])+1;

				SocketSend(g_Socket, finalMsg, offset);
			}
		}
	}

	return Plugin_Continue;
}

public OnSocketDisconnected(Handle:socket, any:arg) {
	// reconnect
	CreateTimer(120.0, TimerConnect, socket, TIMER_HNDL_CLOSE);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg) {
	// reconnect
	LogError("[MR] Socket error: %d (errno %d)", errorType, errorNum);
	CreateTimer(120.0, TimerConnect, socket, TIMER_HNDL_CLOSE);
}
