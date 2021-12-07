#include <sourcemod>
#include <socket>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = {
	name = "Server Web View",
	author = "Eun",
	description = "Provides an Webinterface for the server",
	version = PLUGIN_VERSION,
	url = "https://github.com/Eun/SM_ServerWebView/"
};

new Handle:var_swv_port;
new Handle:var_swv_update;
new Handle:listen_socket;
new lastUpdate = 0;

new String:HTTPNotFoundBuffer[100+10];
#define HTTPPlayerBufferSize 2048

new String:HTTPPlayerBuffer[HTTPPlayerBufferSize];
 
public OnPluginStart() {
	// enable socket debugging (only for testing purposes!)
	SocketSetOption(INVALID_HANDLE, DebugMode, 1);

	CreateConVar("sm_swv_version", PLUGIN_VERSION, "Server Web View", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	var_swv_port = CreateConVar("sm_swv_port", "0", "Which port to use? 0 = tv_port", FCVAR_PLUGIN, true, 0.0, true, 65535.0);
	var_swv_update = CreateConVar("sm_swv_update", "5", "How often should the data be updated? (in min)", FCVAR_PLUGIN, true, 1.0, true, 60.0);
	HookConVarChange(var_swv_port, Cvar_Changed);
	BuildHTTPErrorResponse();
	StartServer(0);
}

public OnPluginEnd() {
	StopServer();
}
public Cvar_Changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == var_swv_port)
	{
		StartServer(GetConVarInt(var_swv_port));
	}
}


public StartServer(port)
{
	if (listen_socket != INVALID_HANDLE)
	{
		LogError("Server is allready running");
		return;
	}
	if (port <= 0)
	{
		port = GetConVarInt(FindConVar("tv_port"));
	}
	if (port <= 0 || port > 65535)
	{
		LogError("Port is out of range");
		return;
	}
	listen_socket = SocketCreate(SOCKET_TCP, OnSocketError);
	SocketBind(listen_socket, "0.0.0.0", port);
	SocketListen(listen_socket, OnSocketIncoming);
}

public StopServer()
{
	if (listen_socket == INVALID_HANDLE)
	{
		return;
	}
	CloseHandle(listen_socket);
	listen_socket = INVALID_HANDLE;
}

public OnSocketIncoming(Handle:socket, Handle:newSocket, String:remoteIP[], remotePort, any:arg) {
	//PrintToServer("%s:%d connected", remoteIP, remotePort);

	// setup callbacks required to 'enable' newSocket
	// newSocket won't process data until these callbacks are set
	SocketSetReceiveCallback(newSocket, OnChildSocketReceive);
	SocketSetDisconnectCallback(newSocket, OnChildSocketDisconnected);
	SocketSetErrorCallback(newSocket, OnChildSocketError);

	//SocketSend(newSocket, "send quit to quit\n");
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:ary) {
	// a socket error occured

	LogError("socket error %d (errno %d)", errorType, errorNum);
	StopServer();
}

public OnChildSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:hFile) {

	// TODO: Get The Path 
	//if (StrEqual(Path, "/", false))
	{
		if (lastUpdate + GetConVarInt(var_swv_update) * 60 < GetTime())
		{
			BuildHTTPPlayerResponse();
			lastUpdate = GetTime();
		}
		SocketSend(socket, HTTPPlayerBuffer);
	}
	/*else
	{
		SocketSend(socket, HTTPNotFoundBuffer);
	}*/
	CloseHandle(socket);
}

public OnChildSocketDisconnected(Handle:socket, any:hFile) {
	// remote side disconnected

	CloseHandle(socket);
}

public OnChildSocketError(Handle:socket, const errorType, const errorNum, any:ary) {
	// a socket error occured

	LogError("child socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public GetStatusCodeStr(statusCode, String:buffer[], bufferSize)
{
	switch (statusCode)
	{
		case 200:
		{
			strcopy(buffer, bufferSize, "OK");
		}
		case 401:
		{
			strcopy(buffer, bufferSize, "Unathuorized");
		}
		case 403:
		{
			strcopy(buffer, bufferSize, "Forbidden");
		}
		case 404:
		{
			strcopy(buffer, bufferSize, "Not Found");
		}
		case 301:
		{
			strcopy(buffer, bufferSize, "Moved Permanently");
		}
		case 302:
		{
			strcopy(buffer, bufferSize, "Moved Temporarily");
		}
		case 500:
		{
			strcopy(buffer, bufferSize, "Server Error");
		}
		default:
		{
			strcopy(buffer, bufferSize, "Unknown");
		}
	}
}

// always use 100 + html size
public BuildHTTPResponse(String:buffer[], bufferSize, statusCode, String:html[])
{
	decl String:codeBuffer[20];
	GetStatusCodeStr(statusCode, codeBuffer, sizeof(codeBuffer));
	Format(buffer, bufferSize, "HTTP/1.0 %d %s\r\nContent-type: text/html\r\nContent-Length: %d\r\n\r\n%s", statusCode, codeBuffer, strlen(html), html);
}


public BuildPlayerList(String:buffer[], bufferSize, team)
{
	decl String:clientname[MAX_NAME_LENGTH];
	decl String:tmpbuff[60];
	new clients = 0;
	for(new i = 1; i <= GetClientCount() + 1; i++)
	{
		if (IsClientInGame(i))
		{
			new clteam = GetClientTeam(i);
			if (clteam == team || (team == 0 && clteam == 1))
			{
				FormatEx(tmpbuff, sizeof(tmpbuff), "<tr class=\"team%d\"><td>", team);
				StrCat(buffer, bufferSize, tmpbuff);
				IntToString(i, tmpbuff, sizeof(tmpbuff));
				StrCat(buffer, bufferSize, tmpbuff);
				StrCat(buffer, bufferSize, "</td><td>");
				GetClientName(i, clientname, sizeof(clientname));
				StrCat(buffer, bufferSize, clientname);
				StrCat(buffer, bufferSize, "</td><td>");
				IntToString(GetClientFrags(i), tmpbuff, sizeof(tmpbuff));
				StrCat(buffer, bufferSize, tmpbuff);
				StrCat(buffer, bufferSize, "</td><td>");

				if (!IsFakeClient(i))
				{
					new time = RoundToNearest(GetClientTime(i));
					if(time >= 60*60 ) {
						FormatEx(tmpbuff, sizeof(tmpbuff), "%2d:%02d:%02d", time/(60*60), (time/60)%60, time%60 );
					} else {
						FormatEx(tmpbuff, sizeof(tmpbuff), "%02d:%02d", (time/60)%60, time%60 );
					}
				}
				else
				{
					Format(tmpbuff, sizeof(tmpbuff), "BOT");
				}
				StrCat(buffer, bufferSize, tmpbuff);
				StrCat(buffer, bufferSize, "</td></tr>");
				clients++;
			}
		}
	}
	return clients;
}


public BuildHTTPPlayerResponse()
{

	decl String:buffer[HTTPPlayerBufferSize];
	decl String:hostname[80];
	GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));

	Format(buffer, HTTPPlayerBufferSize, "<html><head><meta charset=\"UTF-8\"><title>%s</title></head><body>", hostname);
	StrCat(buffer, HTTPPlayerBufferSize, "<style type=\"text/css\">body{width:50%;margin:auto}h1{text-align:center}h1,h3{padding:0;margin:0}h3 div{display:inline-block;width:50%}h3 div.slots{text-align:left}h3 div.slots{text-align:right}div.date{text-align:right}table{border-spacing:0;width:100%}tr{text-align:center}tr.spacer{padding: .5em 0 .5em 0}tr.team0,tr.team1{background:#c6c6c6}tr.team2{background:#ff3333}tr.team3{background:#3333ff}</style>");


	decl String:header[128];
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	new clientcount = GetClientCount(false);
	FormatEx(header, sizeof(header), "<h1>%s</h1><h3><div class=\"map\">%s</div><div class=\"slots\">%d/%d</div></h3>", hostname, mapname, clientcount, GetMaxHumanPlayers());
	StrCat(buffer, HTTPPlayerBufferSize, header);

	StrCat(buffer, HTTPPlayerBufferSize, "<table><th>#</th><th>Player</th><th>Frags</th><th>Time</th>");

	new clients = 0;
	clients += BuildPlayerList(buffer, HTTPPlayerBufferSize, 2);
	StrCat(buffer, HTTPPlayerBufferSize, "<tr class=\"spacer\"><td></td></tr>");
	clients += BuildPlayerList(buffer, HTTPPlayerBufferSize, 3);
	StrCat(buffer, HTTPPlayerBufferSize, "<tr class=\"spacer\"><td></td></tr>");
	clients += BuildPlayerList(buffer, HTTPPlayerBufferSize, 0);


	while (clients < clientcount)
	{
		StrCat(buffer, HTTPPlayerBufferSize, "<tr class=\"team0\"><td></td><td>?</td><td></td><td></td></tr>");
		clients++;
	}

	StrCat(buffer, HTTPPlayerBufferSize, "</table>")

	if (clients == 0)
	{
		StrCat(buffer, HTTPPlayerBufferSize, "No Players...");
	}


	new String:sFormattedTime[22];
	FormatTime(sFormattedTime, sizeof(sFormattedTime), "%m/%d/%Y - %H:%M:%S", GetTime());

	FormatEx(header, sizeof(header), "</table><div class=\"date\">Updated on %s</div></body></html>", sFormattedTime);
	StrCat(buffer, HTTPPlayerBufferSize, header);
	BuildHTTPResponse(HTTPPlayerBuffer, HTTPPlayerBufferSize, 200, buffer);
}

public BuildHTTPErrorResponse()
{
	BuildHTTPResponse(HTTPNotFoundBuffer, sizeof(HTTPNotFoundBuffer), 404, "Not found!");
}
