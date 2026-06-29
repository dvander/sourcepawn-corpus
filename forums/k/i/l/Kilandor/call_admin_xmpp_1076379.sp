#include <sourcemod>
#include <socket>
#include <base64>

#define PLUGIN_VERSION "1.1"
public Plugin:myinfo = 
{
	name = "Call Admin via XMPP",
	author = "Kilandor",
	description = "Allows players to call an admin with a message which is sent to XMPP",
	version = PLUGIN_VERSION,
	url = "http://www.kilandor.com/"
};

new Handle:g_Cvar_Host, Handle:g_Cvar_Port, Handle:g_Cvar_BaseURL, Handle:g_Cvar_CallDelay, Handle:g_Cvar_SecKey, Handle:g_Cvar_AnnounceDelay;
new String:ca_host[256], ca_port, String:ca_baseURL[256], String:ca_secKey[256];
new callDelay;
new clientsCallDelay[MAXPLAYERS+1];
new ServerPort;
new String:ServerIp[16];
new String:ServerName[256];
new Handle:ca_socket;
new String:logPath[256];
public OnPluginStart()
{
	LoadTranslations("call_admin_xmpp.phrases.txt")
	
	CreateConVar("sm_caxmpp_version",PLUGIN_VERSION,"Call Admin via XMPP version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_Cvar_Host = CreateConVar("caxmpp_host", "", "Sets the Host to the webserver(ex. example.com).", 0, false, 0.0, false, 0.0);
	g_Cvar_Port = CreateConVar("caxmpp_port", "80", "Sets the Port to the webserver(ex. 80).", 0, false, 0.0, false, 0.0);
	g_Cvar_BaseURL = CreateConVar("caxmpp_url", "", "Sets the URL to the XMPPHP location(ex. xmpphp/index.php).", 0, false, 0.0, false, 0.0);
	g_Cvar_CallDelay = CreateConVar("caxmpp_call_delay", "180", "Amount of time allowed betwen calling an adming by a player(in seconds)", 0, true, 0.0, false, 0.0);
	g_Cvar_SecKey = CreateConVar("caxmpp_seckey", "", "Sets the Security key sent to the webserver to limit requests to prevent unauthorized use", 0, false, 0.0, false, 0.0);
	g_Cvar_AnnounceDelay = CreateConVar("caxmpp_announce_delay", "300.0", "Sets the delay between Call and Admin message(use 0.0 to disable)", 0, false, 0.0, false, 0.0);
	
	HookConVarChange(g_Cvar_Host, ConVarChange);
	HookConVarChange(g_Cvar_Port, ConVarChange);
	HookConVarChange(g_Cvar_BaseURL, ConVarChange);
	HookConVarChange(g_Cvar_SecKey, ConVarChange);
	HookConVarChange(g_Cvar_CallDelay, ConVarChange);
	
	RegConsoleCmd("sm_calladmin", Command_CallAdmin, "Attempt to Call an Admin");
	
	//Thanks to DJ Tsunami for this snippet
	new iIp = GetConVarInt(FindConVar("hostip"));
	ServerPort = GetConVarInt(FindConVar("hostport"));
	Format(ServerIp, sizeof(ServerIp), "%i.%i.%i.%i", (iIp >> 24) & 0x000000FF,
		(iIp >> 16) & 0x000000FF,
		(iIp >>  8) & 0x000000FF,
		iIp         & 0x000000FF);
	
	BuildPath(Path_SM, logPath, sizeof(logPath), "%s", "logs/call_admin_xmpp.log");
}

public OnConfigsExecuted()
{
	GetConVarString(g_Cvar_Host, ca_host, sizeof(ca_host));
	ca_port = GetConVarInt(g_Cvar_Port);
	GetConVarString(g_Cvar_BaseURL, ca_baseURL, sizeof(ca_baseURL));
	GetConVarString(g_Cvar_SecKey, ca_secKey, sizeof(ca_secKey));
	callDelay = GetConVarInt(g_Cvar_CallDelay);
	
	GetConVarString(FindConVar("hostname"), ServerName, sizeof(ServerName));
}

public OnMapStart()
{
	new Float:announceDelay = GetConVarFloat(g_Cvar_AnnounceDelay);
	if(announceDelay > 0.0)
		CreateTimer(announceDelay,Timer_Announce,_,TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientConnected(client)
{
	//Adds delay to prevent spamming/abuse - or rejoining to use again
	clientsCallDelay[client] = GetTime()+callDelay;
}

public Action:Command_CallAdmin(client, args)
{
	new ReplySource:cmdReplyChat = GetCmdReplySource();
	if(strlen(ca_host) <= 0 || strlen(ca_baseURL) <= 0 || strlen(ca_secKey) <= 0)
	{
		LogError("%t", "error_cvars");
		return Plugin_Handled;
	}
	
	if(clientsCallDelay[client] > GetTime())
	{
		if(cmdReplyChat)
		{
			PrintToChat(client, "\x04[\x03CallAdmin\x04]\x01 %t", "call_delay", (clientsCallDelay[client]-GetTime()));
		}
		else
		{
			PrintToConsole(client, "[CallAdmin] %t", "call_delay", (clientsCallDelay[client]-GetTime()));
		}
		return Plugin_Handled;
	}
	
	new String:message[1024];
	GetCmdArgString(message, sizeof(message));
	
	if(strlen(message) > 0)
	{
		//Adds delay to prevent spamming/abuse
		clientsCallDelay[client] = GetTime()+callDelay;
		
		
		new String:headers[1024];
		new String:base64[1024];
		new String:steamId[128];
		GetClientAuthString(client, steamId, sizeof(steamId))
		
		//Logs a copy and information to deal with absue if needed
		LogToFile(logPath, "%t", "called_admin_log", client, steamId, message);
		
		//Formats the outgoing message
		Format(message, sizeof(message), "%t", "xmpp_message", ServerName, ServerIp, ServerPort, client, steamId, message);
		
		//Encodes the message for handling in the URL on the Backend
		EncodeBase64(base64, sizeof(base64), message);

		//Combines the message, and secKey to prevent unauthorized use
		Format(headers, sizeof(headers), "message=%s&seckey=%s", base64, ca_secKey);
		
		//Used to pass the URL to the socket
		new Handle:headers_pack = CreateDataPack();
		WritePackString(headers_pack, headers);
		
		ca_socket = SocketCreate(SOCKET_TCP, OnSocketError);
		SocketSetArg(ca_socket, headers_pack);
		SocketConnect(ca_socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, ca_host, ca_port)
		
		if(cmdReplyChat)
		{
			PrintToChat(client, "\x04[\x03CallAdmin\x04]\x01 %t", "called_admin");
		}
		else
		{
			PrintToConsole(client, "[CallAdmin] %t", "called_admin");
		}
		
		return Plugin_Handled;
	}
	else
	{
		if(cmdReplyChat)
		{
			PrintToChat(client, "\x04[\x03CallAdmin\x04]\x01 %t", "no_message");
		}
		else
		{
			PrintToConsole(client, "[CallAdmin] %t", "no_message");
		}
		return Plugin_Handled;
	}
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == g_Cvar_Host)
	{
		GetConVarString(g_Cvar_Host, ca_host, sizeof(ca_host));
	}
	else if(convar == g_Cvar_Port)
	{
		ca_port = GetConVarInt(g_Cvar_Port);
	}
	else if(convar == g_Cvar_CallDelay)
	{
		callDelay = GetConVarInt(g_Cvar_CallDelay);
	}
	else if(convar == g_Cvar_BaseURL)
	{
		GetConVarString(g_Cvar_BaseURL, ca_baseURL, sizeof(ca_baseURL));
	}
	else if(convar == g_Cvar_SecKey)
	{
		GetConVarString(g_Cvar_SecKey, ca_secKey, sizeof(ca_secKey));
	}
}

public Action:Timer_Announce(Handle:timer,any: client)
{
	PrintToChatAll("\x04[\x03CallAdmin\x04]\x01 %t", "announce", "\x03", "\x01");
	return Plugin_Continue;
}

public OnSocketConnected(Handle:socket, any:headers_pack) {
	// socket is connected, send the http request
	ResetPack(headers_pack)
	new String:headers[1024];
	ReadPackString(headers_pack, headers, sizeof(headers));
	decl String:requestStr[1024];
	Format(requestStr, sizeof(requestStr), "POST /%s HTTP/1.1\nHost: %s\nConnection: close\nContent-type: application/x-www-form-urlencoded\nContent-length: %d\n\n%s", ca_baseURL, ca_host, strlen(headers), headers);
	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:headers_pack) {
}

public OnSocketDisconnected(Handle:socket, any:headers_pack) {
	// Connection: close advises the webserver to close the connection when the transfer is finished
	// we're done here
	CloseHandle(headers_pack);
	CloseHandle(socket);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:headers_pack) {
	// a socket error occured
	LogError("[CallAdmin] socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(headers_pack);
	CloseHandle(socket);
}