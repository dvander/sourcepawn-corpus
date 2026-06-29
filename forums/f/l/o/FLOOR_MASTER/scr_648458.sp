/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Server Chat Relay
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */


#pragma semicolon 1

#include <sourcemod>
#include <socket>

#define CVAR_VERSION	    0
#define CVAR_SERVER	    1
#define CVAR_IP		    2
#define CVAR_PORT	    3
#define CVAR_TAG	    4
#define CVAR_RELAYSAY	    5
#define CVAR_ALLOWEDFILE    6
#define CVAR_NUM_CVARS	    7

#define VERSION	    "0.2"

enum Mod {
    Mod_Unknown = 0,
    Mod_TF2,
    Mod_DOD
};

new Handle:g_cvars[CVAR_NUM_CVARS];
new Handle:g_socket = INVALID_HANDLE;
new Handle:g_clients = INVALID_HANDLE;
new bool:g_server = false;
new Mod:g_mod = Mod_Unknown;
new Handle:g_allowedServers = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Server Chat Relay",
    author = "Ryan \"FLOOR_MASTER\" Mannion",
    description = "Enable multi-server chat",
    version = VERSION,
    url = "http://www.2fort2furious.com"
};

public OnPluginStart() {
    g_cvars[CVAR_VERSION] = CreateConVar(
	"sm_scr_version",
	VERSION,
	"Server Chat Relay Version",
	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[CVAR_SERVER] = CreateConVar(
	"sm_scr_server",
	"0",
	"When non-zero, this game server becomes the Server Chat Relay server",
	FCVAR_PLUGIN);

    g_cvars[CVAR_IP] = CreateConVar(
	"sm_scr_ip",
	"127.0.0.1",
	"IP of the Server Chat Relay server (ignored when sm_scr_server is 0)",
	FCVAR_PLUGIN);

    g_cvars[CVAR_PORT] = CreateConVar(
	"sm_scr_port",
	"51000",
	"Port of the Server Chat Relay server",
	FCVAR_PLUGIN);

    g_cvars[CVAR_TAG] = CreateConVar(
	"sm_scr_tag",
	"Server 1",
	"Tag to prefix messages broadcast from this server",
	FCVAR_PLUGIN);

    g_cvars[CVAR_RELAYSAY] = CreateConVar(
	"sm_scr_relaysay",
	"0",
	"When non-zero, broadcast all say messages from this server (except those that begin with '!')",
	FCVAR_PLUGIN);

    g_cvars[CVAR_ALLOWEDFILE] = CreateConVar(
	"sm_scr_clients_file",
	"scr_clients.txt",
	"The text file containing a list of allowed client IPs",
	FCVAR_PLUGIN);

    RegConsoleCmd("sm_bc", Command_Broadcast);
    RegConsoleCmd("say", Command_Say);

    decl String:game[32];
    GetGameDescription(game, sizeof(game));
    if (StrEqual(game, "Team Fortress")) {
	g_mod = Mod_TF2;
    }
}

stock CloseSocket() {
    if (g_socket != INVALID_HANDLE) {
	CloseHandle(g_socket);
	g_socket = INVALID_HANDLE;
	LogMessage("Closed local Server Chat Relay socket");
    }
    if (g_clients != INVALID_HANDLE) {
	CloseHandle(g_clients);
	g_clients = INVALID_HANDLE;
    }
}

public OnPluginEnd() {
    CloseSocket();

    if (g_allowedServers != INVALID_HANDLE) {
	CloseHandle(g_allowedServers);
    }
}

public Action:Command_Broadcast(client, args) {
    decl String:text[256];
    GetCmdArgString(text, sizeof(text));
    ProcessText(client, text, sizeof(text));
    return Plugin_Continue;
}

public Action:Command_Say(client, args) {
    if (GetConVarInt(g_cvars[CVAR_RELAYSAY])) {
	decl String:text[256];
    	GetCmdArgString(text, sizeof(text));

	if (text[0] && (
	    (text[0] != '\"' && text[0] != '!' && text[0] != '/')  ||
	    (text[0] == '\"' && text[1] && text[1] != '!' && text[1] != '/'))) {
	   ProcessText(client, text, sizeof(text));
	}
    }
    return Plugin_Continue;
}

stock ProcessText(client, String:text[], text_length) {
    if (text[0] == '\"') {
	new length = strlen(text);
	text[length - 1] = 0;
	Format(text, text_length, "%N: %s", client, text[1]);
    }
    else {
	Format(text, text_length, "%N: %s", client, text);
    }
    InitiateBroadcast(text);
}

stock GetServerIP(String:ip[], ip_length) {
    new hostip = GetConVarInt(FindConVar("hostip"));

    Format(ip, ip_length, "%d.%d.%d.%d",
	(hostip >> 24 & 0xFF),
	(hostip >> 16 & 0xFF),
	(hostip >> 8 & 0xFF),
	(hostip & 0xFF)
    );
}

stock RemoveClient(Handle:client) {

    if (g_clients == INVALID_HANDLE) {
	LogError("Attempted to remove client while g_clients was invalid. This should never happen!");
	return;
    }

    new size = GetArraySize(g_clients);
    for (new i = 0; i < size; i++) {
	if (Handle:GetArrayCell(g_clients, i) == client) {
	    RemoveFromArray(g_clients, i);
	    return;
	}
    }

    LogError("Could not find client in RemoveClient. This should never happen!");
}

public OnConfigsExecuted() {
    if (g_socket == INVALID_HANDLE) {
	if (GetConVarInt(g_cvars[CVAR_SERVER])) {
	    decl String:ip[24];
	    new port = GetConVarInt(g_cvars[CVAR_PORT]);

	    GetServerIP(ip, sizeof(ip));
	    g_socket = SocketCreate(SOCKET_TCP, OnSocketError);
	    SocketBind(g_socket, ip, port);
	    SocketListen(g_socket, OnSocketIncoming);

	    g_clients = CreateArray();
	    g_server = true;

	    LogMessage("Started Server Chat Relay server on port %d", port);

	    decl String:fileName[32];
	    GetConVarString(g_cvars[CVAR_ALLOWEDFILE], fileName, sizeof(fileName));
	    new Handle:fh = OpenFile(fileName, "r");
	    if (fh == INVALID_HANDLE) {
		LogMessage("Could not open \"%s\". Allowing any client to connect.", fileName);
	    }
	    else {
		decl String:line[16];
		g_allowedServers = CreateArray(16);
		while (ReadFileLine(fh, line, sizeof(line))) {
		    TrimString(line);
		    if (strlen(line)) {
			PushArrayString(g_allowedServers, line);
			PrintToServer("%d: %s", GetArraySize(g_allowedServers), line);
		    }
		}
		CloseHandle(fh);
		LogMessage("Read %d entries in \"%s\"", GetArraySize(g_allowedServers), fileName);
	    }
	}
	else {
	    decl String:ip[24];
	    new port = GetConVarInt(g_cvars[CVAR_PORT]);
	    GetConVarString(g_cvars[CVAR_IP], ip, sizeof(ip));

	    g_socket = SocketCreate(SOCKET_TCP, OnSocketError);
	    SocketConnect(g_socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ip, port);
	    g_server = false;

	    LogMessage("Connected to Server Chat Relay server on %s:%d", ip, port);
	}
    }
}

stock InitiateBroadcast(const String:message[]) {
    decl String:tag[32];
    decl String:message_tagged[288];

    if (g_socket == INVALID_HANDLE) {
	return;
    }

    GetConVarString(g_cvars[CVAR_TAG], tag, sizeof(tag));

    Format(message_tagged, sizeof(message_tagged), "%s | %s", tag, message);

    if (g_server) {
	Broadcast(INVALID_HANDLE, message_tagged);
    }
    else if (g_socket != INVALID_HANDLE) {
	SocketSend(g_socket, message_tagged);
    }
}

public OnMapStart() {
    decl String:map[32];
    decl String:text[64];
    GetCurrentMap(map, sizeof(map));
    Format(text, sizeof(text), "Server is now playing %s", map);
    InitiateBroadcast(text);
}

stock Broadcast(Handle:socket, const String:message[]) {
    if (g_clients == INVALID_HANDLE) {
	LogError("In Broadcast, g_clients was invalid. This should never happen!");
	return;
    }

    PrintToServer("[SCR] Broadcasting \"%s\" from %x", message, socket);

    new size = GetArraySize(g_clients);
    new Handle:dest_socket = INVALID_HANDLE;
    for (new i = 0; i < size; i++) {
	dest_socket = Handle:GetArrayCell(g_clients, i);
	if (dest_socket != socket) {
	    SocketSend(dest_socket, message);
	}
    }

    if (socket != INVALID_HANDLE) {
	PrintChatColored(message);
    }
}

stock PrintChatColored(const String:text[]) {
    if (g_mod == Mod_TF2) {
	PrintToChatAll("\x04%s", text);
    }
    else {
    	PrintToChatAll("\x01\x04%s", text);
    }
}

public OnSocketConnected(Handle:socket, any:arg) {
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:arg) {
    PrintChatColored(receiveData);
    PrintToServer("[SCR] Received \"%s\"", receiveData);
}

public OnSocketDisconnected(Handle:socket, any:arg) {
    CloseSocket();
}

public OnSocketIncoming(Handle:socket, Handle:newSocket, String:remoteIP[], remotePort, any:arg) {

    new bool:found = false;
    if (g_allowedServers != INVALID_HANDLE) {
	new size = GetArraySize(g_allowedServers);
    	decl String:allowedServer[16];
    	for (new i = 0; i < size && !found; i++) {
    	    GetArrayString(g_allowedServers, i, allowedServer, sizeof(allowedServer));
    	    if (StrEqual(remoteIP, allowedServer)) {
    	        found = true;
    	    }
    	}
    }

    if (found) {
	LogMessage("Client %s:%d connected", remoteIP, remotePort);
    }
    else {
	LogMessage("Rejected connection from %s:%d", remoteIP, remotePort);
	CloseHandle(newSocket);
	return;
    }

    if (g_clients == INVALID_HANDLE) {
	LogError("In OnSocketIncoming, g_clients was invalid. This should never happen!");
    }
    else {
	PushArrayCell(g_clients, newSocket);
    }

    SocketSetReceiveCallback(newSocket, OnChildSocketReceive);
    SocketSetDisconnectCallback(newSocket, OnChildSocketDisconnected);
    SocketSetErrorCallback(newSocket, OnChildSocketError);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:arg) {
    LogError("Socket error %d (errno %d)", errorType, errorNum);
    CloseSocket();
}

/* Server Functions {{{ */
public OnChildSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:arg) {
    Broadcast(socket, receiveData);
}

public OnChildSocketDisconnected(Handle:socket, any:arg) {
    RemoveClient(socket);
    CloseHandle(socket);
}

public OnChildSocketError(Handle:socket, const errorType, const errorNum, any:arg) {
    LogError("Child socket error %d (errno %d)", errorType, errorNum);
    RemoveClient(socket);
    CloseHandle(socket);
}
/* }}} */

