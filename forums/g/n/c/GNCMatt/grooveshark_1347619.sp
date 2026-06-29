#pragma semicolon 1
#include <sourcemod>
#include <colors>
#include <socket>
#include <regex>

#define PLUGIN_VERSION  "2.0.5"

public Plugin:myinfo = 
{
	name = "Grooveshark",
	author = "[GNC] Matt",
	description = "Play songs from Grooveshark.",
	version = PLUGIN_VERSION,
	url = "http://www.mattsfiles.com"
}
new Handle:g_hcvAPIKey = INVALID_HANDLE;
new Handle:g_hSocket = INVALID_HANDLE;
new Handle:g_hData = INVALID_HANDLE;
new Handle:g_hErrorRegex = INVALID_HANDLE;
new g_iFollow[MAXPLAYERS+1];

new String:g_sHeaderColor[] = "FFFF00";
new String:g_sDefaultColor[] = "4ED2A3";
new String:g_sBoldColor[] = "EF30D8";

new String:g_sAPIKey[64];

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_grooveshark_version", PLUGIN_VERSION, "Grooveshark Version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hcvAPIKey = CreateConVar("sm_gs_apikey", "", "TinySong API Key. Get one at http://tinysong.com/api .");
	HookConVarChange(g_hcvAPIKey, OnConVarChanged);
	AutoExecConfig(true, "grooveshark");
	
	//Client Commands
	RegConsoleCmd("sm_grooveshark", cmdGSPlay, "Format: sm_grooveshark song name");
	RegConsoleCmd("sm_gs", cmdGSPlay, "Alias for sm_grooveshark");
	RegConsoleCmd("sm_gssearch", cmdGSSearch, "Format: sm_gssearch song name");
	RegConsoleCmd("sm_gsid", cmdGSPlayID, "Format: sm_gsid songid");
	RegConsoleCmd("sm_gsid2", cmdGSPlayID2, "Format: sm_gsid2 songid2");
	RegConsoleCmd("sm_gsplay", cmdGSPlayCurrent, "Play currently selected song.");
	RegConsoleCmd("sm_gsfollow", cmdGSFollow, "Follow another player so anything they play, will play for you.");
	RegAdminCmd("sm_gsfollowall", cmdGSFollowAll, ADMFLAG_CHEATS, "Force all players to follow the spesified player.");
	RegConsoleCmd("sm_gsstop", cmdGSStop, "Stops currently playing songs.");
	RegConsoleCmd("sm_gscurrent", cmdGSCurrent, "Display current song information.");
	RegConsoleCmd("sm_gsopen", cmdGSOpen, "Open MOTD panel (tricky to operate properly).");
	
	g_hData = CreateTrie();
	g_hSocket = SocketCreate(SOCKET_TCP, OnSocketError);
	
	g_hErrorRegex = CompileRegex("^{\"error\":\"(.*)\"}$");
	
	for(new i = 0; i <= MaxClients; i++) // Late load.
	{
		InitClient(i);
	}
}

public OnConVarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	if(cvar == g_hcvAPIKey)
		strcopy(g_sAPIKey, sizeof(g_sAPIKey), newValue);
}

public Action:cmdGSOpen(client, args)
{
	ShowVGUIPanel(client, "info");
	return Plugin_Handled;
}

stock InitClient(client)
{
	g_iFollow[client] = -1;
	
	new String:key[10];
	
	Format(key, sizeof(key), "song%i", client);
	RemoveFromTrie(g_hData, key);
	
	Format(key, sizeof(key), "songsize%i", client);
	RemoveFromTrie(g_hData, key);
	
	Format(key, sizeof(key), "search%i", client);
	RemoveFromTrie(g_hData, key);
}

public Action:cmdGSFollowAll(client, args)
{
	if(args < 1)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Requires parameter.", g_sHeaderColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	new String:who[MAX_NAME_LENGTH];
	GetCmdArg(1, who, sizeof(who));
	new target = FindTarget(client, who, true, false);
	if(target == -1)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Player not found.", g_sHeaderColor, g_sDefaultColor);
	}
	else
	{
		for(new i = 1; i < MaxClients; i++)
		{
			if(i != target && IsValidClient(i))
			{
				g_iFollow[i] = target;
				PrintToChat(i, "\x07%s[Grooveshark]\x07%s You are now following \x07%s%N\x07%s.", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, target, g_sDefaultColor);
			}
		}
		PrintToChat(target, "\x07%s[Grooveshark] \x07%sEveryone\x07%s is now following you.", g_sHeaderColor, g_sBoldColor, g_sDefaultColor);
	}

	return Plugin_Handled;
}

public Action:cmdGSFollow(client, args)
{
	if(args < 1)
	{
		g_iFollow[client] = -1;
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Follow disabled.", g_sHeaderColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	new String:who[MAX_NAME_LENGTH];
	GetCmdArg(1, who, sizeof(who));
	new target = FindTarget(client, who, true, false);
	if(target == -1)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Player not found.", g_sHeaderColor, g_sDefaultColor);
	}
	else if(target == client)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s You cannot follow yourself.", g_sHeaderColor, g_sDefaultColor);
	}
	else
	{
		g_iFollow[client] = target;
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s You are now following \x07%s%N\x07%s.", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, target, g_sDefaultColor);
		PrintToChat(target, "\x07%s[Grooveshark]\x07%s %N\x07%s is now following you.", g_sHeaderColor, g_sBoldColor, client, g_sDefaultColor);
		
		CSkipNextClient(client);
		CSkipNextClient(target);
		CPrintToChatAll("\x07%s[Grooveshark]\x07%s %N is now following \x07%s%N\x07%s. Type \x07%s!gsfollow #%i\x07%s to follow.", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, target, g_sDefaultColor, g_sBoldColor, GetClientUserId(target), g_sDefaultColor);
	}

	return Plugin_Handled;
}

public OnPluginEnd()
{
	CloseHandle(g_hSocket);
}

public OnClientDisconnect(client)
{
	InitClient(client);
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
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s You haven't listened to a song yet! Use \x07%s!gs song name\x07%s to play a song.", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	new String:data[size];
	
	Format(key, sizeof(key), "song%i", client);
	GetTrieString(g_hData, key, data, size);
	
	if(StrContains(data, "NSF") != -1)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Song not found.", g_sHeaderColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	decl String:sError[255];
	if(MatchRegex(g_hErrorRegex, data) > 0 && GetRegexSubString(g_hErrorRegex, 1, sError, sizeof(sError)))
	{
		PrintToChatAll("\x07%s[Grooveshark]\x07%s Problem finding song:\x07%s %s", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, sError);
		return Plugin_Handled;
	}
	
	new String:results[7][80];
	ExplodeString(data, ";", results, 7, 80);
	for(new i = 0; i < 7; i++)
		TrimString(results[i]);
	
	decl String:urlparts[4][15]; ExplodeString(results[0], "/", urlparts, 4, 32);
	decl String:id[8]; strcopy(id, sizeof(id), urlparts[3]);
	
	PrintToChat(client, "\x07%s[Grooveshark]\x074B5670 Current Song\n\x07%sTitle:\x07%s %s\n\x07%sArtist:\x07%s %s\n\x07%sAlbum:\x07%s %s\n\x07%sSong ID:\x07%s %s", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, results[2], g_sDefaultColor, g_sBoldColor, results[4], g_sDefaultColor, g_sBoldColor, results[6], g_sDefaultColor, g_sBoldColor, id);
	
	return Plugin_Handled;
}

public Action:cmdGSPlayCurrent(client, args)
{
	new target = client;
	if(args > 0)
	{
		new String:who[MAX_NAME_LENGTH];
		GetCmdArg(1, who, sizeof(who));
		target = FindTarget(client, who, true, false);
		if (target == -1)
			target = client;
	}
	
	new String:key[10];
	new temp;
	Format(key, sizeof(key), "songsize%i", target);
	if(!GetTrieValue(g_hData, key, temp))
	{
		if(client == target)
			PrintToChat(client, "\x07%s[Grooveshark]\x07%s You haven't listened to a song yet! Use \x07%s!gs song name\x07%s to play a song.", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, g_sDefaultColor);
		else
			PrintToChat(client, "\x07%s[Grooveshark]\x07%s %N\x07%s hasn't listened to any songs yet!", g_sHeaderColor, g_sBoldColor, target, g_sDefaultColor);
		
		return Plugin_Handled;
	}
	
	
	PlayStored(client, target);

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

	PrintToChat(client, "\x07%s[Grooveshark]\x07%s Music Stopped.", g_sHeaderColor, g_sDefaultColor);

	return Plugin_Handled;
}

public Action:cmdGSPlayID2(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Invalid number of arguements. Format: \x07%s!gsid songid\x07%s.", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	new String:songid[20];
	GetCmdArg(1, songid, sizeof(songid));
	
	if(SimpleRegexMatch(songid, "([^0-9A-Za-z])") > 0)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Invalid SongID, letters and numbers only (CaSe SeNsiTivE).", g_sHeaderColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	
	PlayID2(client, songid);
	PrintToChatAll("\x07%s[Grooveshark]\x07%s %N\x07%s is now listening to Song ID: \x07%s%s\x07%s.", g_sHeaderColor, g_sBoldColor, client, g_sDefaultColor, g_sBoldColor, songid, g_sDefaultColor);
	
	new followers = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iFollow[i] == client)
		{
			PlayID2(i, songid);
			followers++;
		}
	}
	if(followers > 0)
		PrintToChatAll("\x07%sFollowed by \x07%s%i\x07%s other user(s). Type \x07%s!gsfollow #%i\x07%s to follow.", g_sDefaultColor, g_sBoldColor, followers, g_sDefaultColor, g_sBoldColor, GetClientUserId(client), g_sDefaultColor);
	
	
	return Plugin_Handled;
}

public Action:cmdGSPlayID(client, args)
{
	if(args != 1)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Invalid number of arguements. Format: \x07%s!gsid songid\x07%s.", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	new String:songid[20];
	GetCmdArg(1, songid, sizeof(songid));
	
	if(SimpleRegexMatch(songid, "([^0-9A-Za-z])") > 0)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Invalid SongID, letters and numbers only (CaSe SeNsiTivE).", g_sHeaderColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	
	PlayID(client, songid);
	PrintToChatAll("\x07%s[Grooveshark]\x07%s %N\x07%s is now listening to Song ID: \x07%s%s\x07%s.", g_sHeaderColor, g_sBoldColor, client, g_sDefaultColor, g_sBoldColor, songid, g_sDefaultColor);

	new followers = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iFollow[i] == client)
		{
			PlayID(i, songid);
			followers++;
		}
	}
	if(followers > 0)
		PrintToChatAll("\x07%sFollowed by \x07%s%i\x07%s other user(s). Type \x07%s!gsfollow #%i\x07%s to follow.", g_sDefaultColor, g_sBoldColor, followers, g_sDefaultColor, g_sBoldColor, GetClientUserId(client), g_sDefaultColor);
	
	return Plugin_Handled;
}



public Action:cmdGSSearch(client, args)
{
	if(args == 0)
	{
		ShowMOTDPanel(client, "Grooveshark", "http://grooveshark.com/#!/", MOTDPANEL_TYPE_URL);
		return Plugin_Handled;
	}
	
	decl String:search[200];
	GetCmdArgString(search, sizeof(search));
	
	ReplaceString(search, sizeof(search), " ", "+");
	
	if(SimpleRegexMatch(search, "([^A-Za-z0-9+'-])") > 0)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Search contains invalid characters.", g_sHeaderColor, g_sDefaultColor);
		return Plugin_Handled;
	}
	
	decl String:url[255]; Format(url, sizeof(url), "http://grooveshark.com/#!/search?q=%s", search);
	
	ShowMOTDPanel(client, "Grooveshark", url, MOTDPANEL_TYPE_URL);
	
	return Plugin_Handled;
}
public Action:cmdGSPlay(client, args)
{
	if(args == 0)
	{
		ShowMOTDPanel(client, "Grooveshark", "http://grooveshark.com/#!/", MOTDPANEL_TYPE_URL);
		return Plugin_Handled;
	}

	new String:search[200];
	GetCmdArgString(search, sizeof(search));
	
	ReplaceString(search, sizeof(search), " ", "+");
	
	if(SimpleRegexMatch(search, "([^A-Za-z0-9+'-])") > 0)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Search contains invalid characters.", g_sHeaderColor, g_sDefaultColor);
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
	Format(key, sizeof(key), "search%i", client);
	GetTrieString(g_hData, key, search, sizeof(search));

	decl String:requestStr[512];
	Format(requestStr, sizeof(requestStr), "GET /b/%s?key=%s HTTP/1.0\r\nHost: %s\r\nConnection: close\r\n\r\n", search, g_sAPIKey, "www.tinysong.com");
	SocketSend(socket, requestStr);
}

public OnSocketReceive(Handle:socket, String:receiveData[], const dataSize, any:client)
{
	new String:header[dataSize];
	
	SplitString(receiveData, "\r\n\r\n", header, dataSize);
	Format(header, dataSize, "%s\r\n\r\n", header);
	ReplaceString(receiveData, dataSize, header, "");
	new datalen = strlen(receiveData)+1;

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
	
	PlayStored(client, client);
}

stock PlayStored(client, target)
{
	new String:key[10];
	
	Format(key, sizeof(key), "songsize%i", target);
	new size = 0;
	GetTrieValue(g_hData, key, size);
	
	new String:data[size];
	
	Format(key, sizeof(key), "song%i", target);
	GetTrieString(g_hData, key, data, size);
	
	if(StrContains(data, "NSF") != -1)
	{
		PrintToChat(client, "\x07%s[Grooveshark]\x07%s Song not found.", g_sHeaderColor, g_sDefaultColor);
		return;
	}
	
	decl String:sError[255];
	if(MatchRegex(g_hErrorRegex, data) > 0 && GetRegexSubString(g_hErrorRegex, 1, sError, sizeof(sError)))
	{
		PrintToChatAll("\x07%s[Grooveshark]\x07%s Problem finding song:\x07%s %s", g_sHeaderColor, g_sDefaultColor, g_sBoldColor, sError);
		return;
	}
	
	new String:results[7][80];
	ExplodeString(data, ";", results, 7, 80);
	for(new i = 0; i < 7; i++)
		TrimString(results[i]);
	
	decl String:urlparts[4][15]; ExplodeString(results[0], "/", urlparts, 4, 32);
	decl String:id[8]; strcopy(id, sizeof(id), urlparts[3]);
	
	PlayID(client, id);
	
	PrintToChatAll("\x07%s[Grooveshark]\x07%s %N\x07%s is now listening to \x07%s%s\x07%s by \x07%s%s\x07%s. Type \x07%s!gsid %s\x07%s to listen to this song.", g_sHeaderColor, g_sBoldColor, client, g_sDefaultColor, g_sBoldColor, results[2], g_sDefaultColor, g_sBoldColor, results[4], g_sDefaultColor, g_sBoldColor, id, g_sDefaultColor);
	
	new followers = 0;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(g_iFollow[i] == client)
		{
			PlayID(i, id);
			followers++;
		}
	}
	if(followers > 0)
		PrintToChatAll("\x07%sFollowed by \x07%s%i\x07%s other user(s). Type \x07%s!gsfollow #%i\x07%s to follow.", g_sDefaultColor, g_sBoldColor, followers, g_sDefaultColor, g_sBoldColor, GetClientUserId(client), g_sDefaultColor);
}

stock PlayID(client, String:id[])
{
	new String:url[100];
	Format(url, sizeof(url), "http://tinysong.com/%s", id);
	
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "Grooveshark");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, false);  //Thanks Octo
	CloseHandle(setup);
}

stock PlayID2(client, String:id[])
{
	new String:url[100];
	Format(url, sizeof(url), "http://grooveshark.com/#!/s/~/%s", id);
	
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "Grooveshark");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, false);  // Thanks Octo
	CloseHandle(setup);
}

stock bool:IsValidClient(iClient, bool:bAlive = false)
{
	if (iClient >= 1 && iClient <= MaxClients && IsClientConnected(iClient) && IsClientInGame(iClient) && (bAlive == false || IsPlayerAlive(iClient)))
	{
		return true;
	}
	
	return false;
}