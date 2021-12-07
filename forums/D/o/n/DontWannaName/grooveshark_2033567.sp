#pragma semicolon 1
#include <sourcemod>
#include <socket>
#include <regex>

#define PLUGIN_VERSION  "1.2.4"


public Plugin:myinfo = 
{
	name = "Grooveshark",
	author = "[GNC] Matt, Evinly Scratch, (-TN) DontWannaName",
	description = "Play songs from Grooveshark.",
	version = PLUGIN_VERSION,
	url = "http://colgateisbestpony.com"
}
new Handle:g_hSocket = INVALID_HANDLE;
new Handle:g_hData = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_gs_version", PLUGIN_VERSION, "Grooveshark Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	//Client Commands
	RegConsoleCmd("sm_grooveshark", cmdGSPlay, "Format: sm_grooveshark song name");
	RegConsoleCmd("sm_gs", cmdGSPlay, "Alias for sm_grooveshark");
	RegConsoleCmd("sm_gsplay", cmdGSPlayCurrent, "Play currently selected song.");
	RegConsoleCmd("sm_gsstop", cmdGSStop, "Stops currently playing songs.");
	RegConsoleCmd("sm_gscurrent", cmdGSCurrent, "Display current song information.");
	CreateConVar("sm_tinysong_api_key","","API key for Tinysong (REQUIRED)");
	
	g_hData = CreateTrie();
	g_hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
	AutoExecConfig(true,"grooveshark");
}

public OnPluginEnd()
{
	CloseHandle(g_hSocket);
}

public OnClientDisconnect(client)
{
	new String:key[10];
	
	Format(key, sizeof(key), "song%i", client);
	RemoveFromTrie(g_hData, key);
	
	Format(key, sizeof(key), "songsize%i", client);
	RemoveFromTrie(g_hData, key);
	
	Format(key, sizeof(key), "search%i", client);
	RemoveFromTrie(g_hData, key);
}

public OnSocketError(Handle:socket, const errorType, const errorNum, any:hFile) {
	LogError("socket error %d (errno %d)", errorType, errorNum);
	CloseHandle(socket);
}

public Action:cmdGSCurrent(client, args)
{
	new String:key[10];
	new size = 0;
	Format(key, sizeof(key), "songsize%i", client);
	if(!GetTrieValue(g_hData, key, size))
	{
		ReplyToCommand(client, "\x04[Grooveshark]\x01 You haven't listened to a song yet! Use \x03!gs song name\x01 to play a song.");
		return Plugin_Handled;
	}
	
	new String:data[size];
	
	Format(key, sizeof(key), "song%i", client);
	GetTrieString(g_hData, key, data, size);
	
	if(StrContains(data, "NSF") != -1)
	{
		ReplyToCommand(client, "\x04[Grooveshark]\x01 Song not found.");
		return Plugin_Handled;
	}
	
	new String:results[7][80];
	ExplodeString(data, ";", results, 7, 80);
	for(new i = 0; i < 7; i++)
		TrimString(results[i]);
	
	ReplyToCommand(client, "\x04[Grooveshark]\x03 Current Song\n\x03Title:\x01 %s\n\x03Artist:\x01 %s\n\x03Album:\x01 %s", results[2], results[4], results[6]);
	
	return Plugin_Handled;
}

public Action:cmdGSPlayCurrent(client, args)
{
	new String:key[10];
	new temp;
	Format(key, sizeof(key), "songsize%i", client);
	if(!GetTrieValue(g_hData, key, temp))
	{
		ReplyToCommand(client, "\x04[Grooveshark]\x01 You haven't listened to a song yet! Use \x03!gs song name\x01 to play a song.");
		return Plugin_Handled;
	}
	
	PlayStored(client, true);

	return Plugin_Handled;
}

public Action:cmdGSStop(client, args)
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "Grooveshark");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", "about:blank");
	
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);

	ReplyToCommand(client, "\x04[Grooveshark]\x01 Music Stopped.");

	return Plugin_Handled;
}

public Action:cmdGSPlay(client, args)
{
	if(args == 0)
	{
		ShowMOTDPanel(client, "Grooveshark", "http://retro.grooveshark.com", MOTDPANEL_TYPE_URL);
		return Plugin_Handled;
	}

	new String:search[200];
	GetCmdArgString(search, sizeof(search));
	
	ReplaceString(search, sizeof(search), " ", "+");
	
	if(SimpleRegexMatch(search, "([^A-Za-z0-9+'])") > 0)
	{
		ReplyToCommand(client, "\x04[Grooveshark]\x01 Search contains invalid characters.");
		return Plugin_Handled;
	}
	
	new String:key[10];
	Format(key, sizeof(key), "search%i", client);
	SetTrieString(g_hData, key, search, true);
	
	
	new Handle:socket = g_hSocket;
	
	if(SocketIsConnected(socket))
	{
		socket = SocketCreate(SOCKET_TCP, OnSocketError);
	}
	
	SocketSetArg(socket, client);
	SocketConnect(socket, OnSocketConnected, OnSocketReceive, OnSocketDisconnected, "www.tinysong.com", 80);
	
	return Plugin_Handled;
}

public OnSocketConnected(Handle:socket, any:client)
{
	new String:search[200];
	new String:key[10];
	new String:apikey[35];
	GetConVarString(FindConVar("sm_tinysong_api_key"),apikey,35);
	//PrintToChatAll("apikey = %s",apikey);
	Format(key, sizeof(key), "search%i", client);
	GetTrieString(g_hData, key, search, sizeof(search));

	decl String:requestStr[512];
	Format(requestStr, sizeof(requestStr), "GET /b/%s?key=%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", search, apikey, "www.tinysong.com");
	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:client)
{
	new String:header[dataSize];
	SplitString(receiveData, "\r\n\r\n", header, dataSize);
	ReplaceString(receiveData, dataSize, header, "");
	
	new datalen = strlen(receiveData);

	new String:key[10];
	Format(key, sizeof(key), "song%i", client);
	SetTrieString(g_hData, key, receiveData);
	
	Format(key, sizeof(key), "songsize%i", client);
	SetTrieValue(g_hData, key, datalen);
	
}

public OnSocketDisconnected(Handle:socket, any:client)
{
	if(socket != g_hSocket)
		CloseHandle(socket);
	
	PlayStored(client, true);
}

PlayStored(client, bool:notify=true)
{
	new String:key[10];
	
	Format(key, sizeof(key), "songsize%i", client);
	new size = 0;
	GetTrieValue(g_hData, key, size);
	
	new String:data[size];
	
	Format(key, sizeof(key), "song%i", client);
	GetTrieString(g_hData, key, data, size);
	
	//PrintToChatAll("Data: %s",data);
	
	if(StrContains(data, "NSF") != -1)
	{
		PrintToChat(client, "\x04[Grooveshark]\x01 Song not found.");
		return;
	}
	
	new String:results[7][80];
	ExplodeString(data, ";", results, 7, 80);
	for(new i = 0; i < 7; i++)
		TrimString(results[i]);
	
	PlayID(client, results[1]);
	
	if(notify)
		PrintToChatAll("\x04[Grooveshark]\x03 %N\x01 is now listening to \x03%s\x01 by \x03%s\x01.", client, results[2], results[4]);
	
}

PlayID(client, String:url[])
{
	
	new Handle:setup = CreateKeyValues("data");
	
	decl String:buffer[200];
	Format(buffer, sizeof(buffer), "https://grooveshark.com/facebookWidget.swf?songID=%s", url);
	
	KvSetString(setup, "title", "Grooveshark");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", buffer);
	
	//PrintToChatAll("%s",buffer);
	
	ShowVGUIPanel(client, "info", setup, false);  //Thanks Octo
	CloseHandle(setup);
}
