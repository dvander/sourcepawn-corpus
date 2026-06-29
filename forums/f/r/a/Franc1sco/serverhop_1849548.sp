/*
**
** Server Hop (c) 2009, 2010 [GRAVE] rig0r
**			 www.gravedigger-company.nl
**
*/

#pragma semicolon 1
#include <regex>
#include <socket>

#define PLUGIN_VERSION "0.8.2"
#define MAX_SERVERS 35
#define REFRESH_TIME 60.0
#define SERVER_TIMEOUT 10.0
#define MAX_STR_LEN 160
#define MAX_INFO_LEN 200

new g_iServerCount;

new String:g_sEngineQuery[] = "\xFF\xFF\xFF\xFF\x54Source Engine Query";

new Handle:g_hCvarRegEx = INVALID_HANDLE;
new Handle:g_hRegEx = INVALID_HANDLE;

new String:g_sServerDefaultName[MAX_SERVERS][MAX_STR_LEN];
new String:g_sServerAddress[MAX_SERVERS][MAX_STR_LEN];
new g_iServerPort[MAX_SERVERS];
new String:g_sServerInfo[MAX_SERVERS][MAX_INFO_LEN];

new Handle:g_hSocket[MAX_SERVERS];
new bool:g_bSocketError[MAX_SERVERS];

new Handle:g_hCvarAltTrigger = INVALID_HANDLE;
new String:g_sAltTrigger[MAX_STR_LEN];

new Handle:g_hCvarServerFormat = INVALID_HANDLE;
new String:g_sServerFormat[MAX_STR_LEN];

new Handle:g_hCvarBroadcastHops = INVALID_HANDLE;
new g_bBroadcastHops;

new Handle:g_hCvarBroadcastPrefix = INVALID_HANDLE;
new String:g_sBroadcastPrefix[MAX_STR_LEN];

new Handle:g_hCvarAdvert = INVALID_HANDLE;
new g_iAdvert;

new Handle:g_hCvarAdvertPrefix = INVALID_HANDLE;
new String:g_sAdvertPrefix[MAX_STR_LEN];

new Handle:g_hCvarAdvertInterval = INVALID_HANDLE;
new Float:g_fAdvertInterval;
new Handle:msg_join = INVALID_HANDLE;

new Handle:g_hCvarExcludeCurSrv = INVALID_HANDLE;
new bool:g_bExcludeCurServer;

new String:g_sHostIP[17];
new g_iHostPort;

new String:CTag[][] = {"{default}", "{green}", "{lightgreen}", "{olive}"};
new String:CTagCode[][] = {"\x01", "\x04", "\x03", "\x05"};

public Plugin:myinfo =
{
	name = "Server Hop",
	author = "[GRAVE] rig0r",
	description = "Provides live server info with join option",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1735818#247"
};

public OnPluginStart()
{
	LoadTranslations("serverhop.phrases");

	g_hCvarAltTrigger = CreateConVar("sm_hop_trigger", "!servers", "What players have to type in chat to activate the plugin (besides !hop)");
	OnCvarsChanged(g_hCvarAltTrigger, "", "");
	HookConVarChange(g_hCvarAltTrigger, OnCvarsChanged);
	
	g_hCvarServerFormat = CreateConVar("sm_hop_serverformat", "%name - %map (%numplayers/%maxplayers)", "Defines how the server info should be presented");
	OnCvarsChanged(g_hCvarServerFormat, "", "");
	HookConVarChange(g_hCvarServerFormat, OnCvarsChanged);
	
	g_hCvarBroadcastHops = CreateConVar("sm_hop_broadcasthops", "1", "Set to 1 if you want a broadcast message when a player hops to another server");
	OnCvarsChanged(g_hCvarBroadcastHops, "", "");
	HookConVarChange(g_hCvarBroadcastHops, OnCvarsChanged);
	
	g_hCvarBroadcastPrefix = CreateConVar("sm_hop_broadcast_prefix", "{green}[{lightgreen}hop{green}]{default} ", "The prefix to broadcasts for when a player hops to another server");
	OnCvarsChanged(g_hCvarBroadcastPrefix, "", "");
	HookConVarChange(g_hCvarBroadcastPrefix, OnCvarsChanged);
	
	g_hCvarAdvert = CreateConVar("sm_hop_advertise", "1", "Set to 1 to enable server advertisements | 2 = Exclude empty servers.");
	OnCvarsChanged(g_hCvarAdvert, "", "");
	HookConVarChange(g_hCvarAdvert, OnCvarsChanged);
	
	g_hCvarAdvertPrefix = CreateConVar("sm_hop_advertise_prefix", "{green}[{lightgreen}hop{green}]{default} ", "The prefix to advertisment messages");
	OnCvarsChanged(g_hCvarAdvertPrefix, "", "");
	HookConVarChange(g_hCvarAdvertPrefix, OnCvarsChanged);
	
	g_hCvarAdvertInterval = CreateConVar("sm_hop_advertisement_interval", "1", "Advertisement interval: advertise a server every x minute(s)");
	OnCvarsChanged(g_hCvarAdvertInterval, "", "");
	HookConVarChange(g_hCvarAdvertInterval, OnCvarsChanged);
	
	g_hCvarRegEx = CreateConVar("sm_hop_regex", "", "This extracts the server name using regex. Leave blank to use the server name set in the config.");
	OnCvarsChanged(g_hCvarRegEx, "", "");
	HookConVarChange(g_hCvarRegEx, OnCvarsChanged);
	
	msg_join = CreateConVar("sm_hop_joinmsg", "The Server IP is:", "Messege in chat for the client that choose a server, After this message appear the IP");
		
	new Handle:hostip = FindConVar("hostip");
	new Handle:hostport = FindConVar("hostport");
	
	if (hostip != INVALID_HANDLE && hostport != INVALID_HANDLE)
	{
		g_hCvarExcludeCurSrv = CreateConVar("sm_hop_exclude_current_server", "0", "This excludes the current server from the listing. (lazy people)");
		OnCvarsChanged(g_hCvarExcludeCurSrv, "", "");
		HookConVarChange(g_hCvarExcludeCurSrv, OnCvarsChanged);
		
		LongToIP(GetConVarInt(hostip), g_sHostIP, sizeof(g_sHostIP));
		g_iHostPort = GetConVarInt(hostport);
		
		CloseHandle(hostip);
		CloseHandle(hostport);
	}

	AutoExecConfig(true, "plugin.serverhop");

	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");
	
	decl String:path[MAX_STR_LEN];
	BuildPath(Path_SM, path, sizeof(path), "configs/serverhop.cfg");
	
	new Handle:kv = CreateKeyValues("Servers");

	if (!FileToKeyValues(kv, path))
		LogToGame("Error loading server list");

	new i;
	KvRewind(kv);
	KvGotoFirstSubKey(kv);
	do {
		KvGetSectionName(kv, g_sServerDefaultName[i], MAX_STR_LEN);
		KvGetString(kv, "address", g_sServerAddress[i], MAX_STR_LEN);
		g_iServerPort[i] = KvGetNum(kv, "port", 27015);
		
		if (!(g_bExcludeCurServer && strcmp(g_sHostIP, g_sServerAddress[i]) == 0 && g_iHostPort == g_iServerPort[i]))
		{
			i++;
		}
	} while (KvGotoNextKey(kv));
	CloseHandle(kv);
	
	g_iServerCount = i;

	new Handle:timer = CreateTimer(REFRESH_TIME, RefreshServerInfo, _, TIMER_REPEAT);
	TriggerTimer(timer);
}

public OnCvarsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_hCvarAltTrigger)
	{
		GetConVarString(g_hCvarAltTrigger, g_sAltTrigger, sizeof(g_sAltTrigger));
	}
	else if (convar == g_hCvarServerFormat)
	{
		GetConVarString(g_hCvarServerFormat, g_sServerFormat, sizeof(g_sServerFormat));
	}
	else if (convar == g_hCvarBroadcastHops)
	{
		g_bBroadcastHops = GetConVarBool(g_hCvarBroadcastHops);
	}
	else if (convar == g_hCvarBroadcastPrefix)
	{
		GetConVarString(g_hCvarBroadcastPrefix, g_sBroadcastPrefix, sizeof(g_sBroadcastPrefix));
		for (new i = 0; i < sizeof(CTag); i++)
		{
			ReplaceString(g_sBroadcastPrefix, sizeof(g_sBroadcastPrefix), CTag[i], CTagCode[i]);
		}
	}
	else if (convar == g_hCvarAdvert)
	{
		g_iAdvert = GetConVarInt(g_hCvarAdvert);
	}
	else if (convar == g_hCvarAdvertPrefix)
	{
		GetConVarString(g_hCvarAdvertPrefix, g_sAdvertPrefix, sizeof(g_sAdvertPrefix));
		for (new i = 0; i < sizeof(CTag); i++)
		{
			ReplaceString(g_sAdvertPrefix, sizeof(g_sAdvertPrefix), CTag[i], CTagCode[i]);
		}
	}
	else if (convar == g_hCvarAdvertInterval)
	{
		g_fAdvertInterval = GetConVarFloat(g_hCvarAdvertInterval);
	}
	else if (convar == g_hCvarExcludeCurSrv)
	{
		g_bExcludeCurServer = GetConVarBool(g_hCvarExcludeCurSrv);
	}
	else if (convar == g_hCvarRegEx)
	{
		decl String:tmpString[MAX_STR_LEN];
		GetConVarString(g_hCvarRegEx, tmpString, sizeof(tmpString));
		
		if (g_hRegEx != INVALID_HANDLE)
		{
			CloseHandle(g_hRegEx);
			g_hRegEx = INVALID_HANDLE;
		}
		
		if (strlen(tmpString) > 0)
		{
			g_hRegEx = CompileRegex(tmpString);
		}
	}
}

public Action:Command_Say(client, const String:command[], args)
{
	decl String:text[MAX_STR_LEN];
	new startidx;

	if (!GetCmdArgString(text, sizeof(text)))
	{
		return Plugin_Continue;
	}

	if (text[strlen(text) - 1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (strcmp(text[startidx], g_sAltTrigger, false) == 0 || strcmp(text[startidx], "!hop", false) == 0)
	{
		ServerMenu(client);
	}

	return Plugin_Continue;
}

public Action:ServerMenu(client)
{
	new Handle:menu = CreateMenu(MenuHandler);
	decl String:serverNumStr[MAX_STR_LEN];
	decl String:menuTitle[MAX_STR_LEN];
	FormatEx(menuTitle, sizeof(menuTitle), "%T", "SelectServer", client);
	SetMenuTitle(menu, menuTitle);

	for (new i = 0; i < g_iServerCount; i++)
	{
		if (strlen(g_sServerInfo[i]) > 0)
		{
			IntToString(i, serverNumStr, sizeof(serverNumStr));
			AddMenuItem(menu, serverNumStr, g_sServerInfo[i]);
		}
	} 
	DisplayMenu(menu, client, 20);
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		case MenuAction_Select:
		{
			decl String:infobuf[MAX_STR_LEN];
			decl String:address[MAX_STR_LEN];

			GetMenuItem(menu, param2, infobuf, sizeof(infobuf));
			new serverNum = StringToInt(infobuf);

			// header
			new Handle:kvheader = CreateKeyValues("header");
			decl String:menuTitle[MAX_STR_LEN];
			FormatEx(menuTitle, sizeof(menuTitle), "%T", "AboutToJoinServer", param1);
			KvSetString(kvheader, "title", menuTitle);
			KvSetNum(kvheader, "level", 1);
			KvSetString(kvheader, "time", "10");
			CreateDialog(param1, kvheader, DialogType_Msg);
			CloseHandle(kvheader);
			
			// join confirmation dialog
			new Handle:kv = CreateKeyValues("menu");
			KvSetString(kv, "time", "10");
			FormatEx(address, MAX_STR_LEN, "%s:%i", g_sServerAddress[serverNum], g_iServerPort[serverNum]);
			KvSetString(kv, "title", address);
			CreateDialog(param1, kv, DialogType_AskConnect);
			CloseHandle(kv);
			
			decl String:mensaje[192];
			GetConVarString(msg_join, mensaje, sizeof(mensaje));
			// added
			PrintToChat(param1, "%s %s", mensaje,address);
			PrintToChat(param1, "%s %s", mensaje,address);
			PrintToChat(param1, "%s %s", mensaje,address);
			PrintHintText(param1, "%s %s", mensaje,address);
			//

			// broadcast to all
			if (g_bBroadcastHops)
			{
				decl String:sClientName[MAX_NAME_LENGTH];
				GetClientName(param1, sClientName, sizeof(sClientName));
				PrintToChatAll("%s%t", g_sBroadcastPrefix, "HopNotification", sClientName, g_sServerInfo[serverNum]);
			}
		}
	}
}

public Action:RefreshServerInfo(Handle:timer)
{
	for (new i = 0; i < g_iServerCount; i++)
	{
		g_sServerInfo[i] = "";
		g_bSocketError[i] = false;
		g_hSocket[i] = SocketCreate(SOCKET_UDP, OnSocketError);
		SocketSetArg(g_hSocket[i], i);
		SocketConnect(g_hSocket[i], OnSocketConnected, OnSocketReceive, OnSocketDisconnected, g_sServerAddress[i], g_iServerPort[i]);
	}

	CreateTimer(SERVER_TIMEOUT, CleanUp);
}

public Action:CleanUp(Handle:timer)
{
	for (new i = 0; i < g_iServerCount; i++)
	{
		if (strlen(g_sServerInfo[i]) == 0 && !g_bSocketError[i])
		{
			CloseHandle(g_hSocket[i]);
		}
	}

	// all server info is up to date: advertise
	static iAdvertInterval = 1;
	if (g_iAdvert)
	{
		if (iAdvertInterval == g_fAdvertInterval)
		{
			Advertise();
		}
		if (iAdvertInterval++ > g_fAdvertInterval)
		{
			iAdvertInterval = 1;
		}
	}
}

Advertise()
{
	static iAdvertCount = 0;

	// skip servers being marked as down
	while (strlen(g_sServerInfo[iAdvertCount]) == 0)
	{
		if (iAdvertCount++ >= g_iServerCount)
		{
			iAdvertCount = 0;
			break;
		}
	}

	if (strlen(g_sServerInfo[iAdvertCount]) > 0)
	{
		PrintToChatAll("%s%t", g_sAdvertPrefix, "Advert", g_sServerInfo[iAdvertCount], g_sAltTrigger);

		if (iAdvertCount++ >= g_iServerCount)
		{
			iAdvertCount = 0;
		}
	}
}

public OnSocketConnected(Handle:sock, any:i)
{
	SocketSend(sock, g_sEngineQuery, sizeof(g_sEngineQuery));
}

GetByte(String:data[], offset)
{
	return data[offset];
}

String:GetString(String:data[], size, offset)
{
	new String:sBuffer[MAX_STR_LEN] = "";
	new j;
	for (new i = offset; i < size; i++) {
		sBuffer[j] = data[i];
		j++;
		if (data[i] == '\x0') {
			break;
		}
	}
	return sBuffer;
}

public OnSocketReceive(Handle:sock, String:data[], const size, any:i)
{
	decl String:srvName[MAX_STR_LEN];
	decl String:mapName[MAX_STR_LEN];
	decl String:gameDir[MAX_STR_LEN];
	decl String:gameDesc[MAX_STR_LEN];
	decl String:numPlayers[MAX_STR_LEN];
	decl String:maxPlayers[MAX_STR_LEN];
	new offset = 6;
	
	srvName = GetString(data, size, offset);
	offset += strlen(srvName) + 1;
	
	new bRegExSuccess = false;
	if (g_hRegEx != INVALID_HANDLE)
	{
		if (MatchRegex(g_hRegEx, srvName) == 1)
		{
			if (GetRegexSubString(g_hRegEx, 0, srvName, sizeof(srvName)))
			{
				bRegExSuccess = true;
			}
		}
	}

	if (!bRegExSuccess)
	{
		strcopy(srvName, sizeof(srvName), g_sServerDefaultName[i]);
	}
	
	mapName = GetString(data, size, offset);
	offset += strlen(mapName) + 1;
	
	gameDir = GetString(data, size, offset);
	offset += strlen(gameDir) + 1;

	gameDesc = GetString(data, size, offset);
	offset += strlen(gameDesc) + 3; // 1 + 2
	
	new iNumPlayers = GetByte(data, offset);

	if (g_iAdvert == 2 && !iNumPlayers)
	{
		g_sServerInfo[i] = "";
		g_bSocketError[i] = true;
		CloseHandle(sock);
		return;
	}
	
	IntToString(iNumPlayers, numPlayers, sizeof(numPlayers));
	offset++;
	
	IntToString(GetByte(data, offset), maxPlayers, sizeof(maxPlayers));

	decl String:format[MAX_STR_LEN];
	strcopy(format, sizeof(format), g_sServerFormat);
	ReplaceString(format, strlen(format), "%name", srvName, false);
	ReplaceString(format, strlen(format), "%map", mapName, false);
	ReplaceString(format, strlen(format), "%numplayers", numPlayers, false);
	ReplaceString(format, strlen(format), "%maxplayers", maxPlayers, false);

	g_sServerInfo[i] = format;

	CloseHandle(sock);
}

public OnSocketDisconnected(Handle:sock, any:i)
{
	CloseHandle(sock);
}

public OnSocketError(Handle:sock, const errorType, const errorNum, any:i)
{
	g_bSocketError[i] = true;
	CloseHandle(sock);
}

stock LongToIP(ip, String:buffer[], size)
{
	FormatEx(buffer, size, "%d.%d.%d.%d", (ip >> 24) & 0xFF, (ip >> 16) & 0xFF, (ip >> 8) & 0xFF, ip & 0xFF);
}