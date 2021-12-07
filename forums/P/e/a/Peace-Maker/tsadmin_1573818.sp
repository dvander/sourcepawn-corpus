#pragma semicolon 1
#include <sourcemod>
#include <socket>

#define PLUGIN_VERSION "1.0"

new Handle:g_hCVSecret;
new Handle:g_hCVURL;
new Handle:g_hCVPath;

new String:g_sServerIP[20];
new g_iServerPort;

public Plugin:myinfo = 
{
	name = "TSAdmin",
	author = "Jannik \"Peace-Maker\" Hartung / Freigeist",
	description = "Call admins on a teamspeak3.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_tsadmin_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	LoadTranslations("tsadmin.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	
	g_hCVSecret = CreateConVar("sm_tsadmin_secret", "93rzfoqenfh98qz3", "TSAdmin php script secret.", FCVAR_PLUGIN);
	g_hCVURL = CreateConVar("sm_tsadmin_domain", "DOMAIN.TLD", "The domain the php script is hosted on.", FCVAR_PLUGIN);
	g_hCVPath = CreateConVar("sm_tsadmin_path", "ts/", "The folder path the script is located in.", FCVAR_PLUGIN);
	
	RegConsoleCmd("sm_tsadmin", Cmd_TSAdmin, "Call an admin on TS3.");
	
	g_iServerPort = GetConVarInt(FindConVar("hostport"));
	new iIP = GetConVarInt(FindConVar("hostip"));
	FormatEx(g_sServerIP, sizeof(g_sServerIP), "%d.%d.%d.%d", (iIP >> 24) & 0x000000FF, (iIP >> 16) & 0x000000FF, (iIP >> 8) & 0x000000FF, iIP & 0x000000FF);
	
	AutoExecConfig(true);
}

public Action:Cmd_TSAdmin(client, args)
{
	if(!client)
	{
		ReplyToCommand(client, "TSAdmin: This command is ingame only.");
		return Plugin_Handled;
	}
	
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "TS Admin Call");
	
	DrawPanelText(hPanel, "============");
	decl String:sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "%T", "abuse", client);
	DrawPanelText(hPanel, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "really_call", client);
	DrawPanelText(hPanel, sBuffer);
	DrawPanelText(hPanel, "\n============");
	SetPanelCurrentKey(hPanel, 0);
	Format(sBuffer, sizeof(sBuffer), "%T", "Yes", client);
	DrawPanelItem(hPanel, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "No", client);
	DrawPanelItem(hPanel, sBuffer);
	
	SendPanelToClient(hPanel, client, Panel_TSAdmin, MENU_TIME_FOREVER);
	CloseHandle(hPanel);
	
	return Plugin_Handled;
}

ShowReasonMenu(client)
{
	new Handle:hPanel = CreatePanel();
	SetPanelTitle(hPanel, "TS Admin Call");
	
	DrawPanelText(hPanel, "============");
	decl String:sBuffer[256];
	Format(sBuffer, sizeof(sBuffer), "%T", "reason", client);
	DrawPanelText(hPanel, sBuffer);
	DrawPanelText(hPanel, "\n============");
	SetPanelCurrentKey(hPanel, 0);
	Format(sBuffer, sizeof(sBuffer), "%T", "reason_swearing", client);
	DrawPanelItem(hPanel, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "reason_cheating_player", client);
	DrawPanelItem(hPanel, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "reason_camping_player", client);
	DrawPanelItem(hPanel, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "reason_teamkilling_player", client);
	DrawPanelItem(hPanel, sBuffer);
	Format(sBuffer, sizeof(sBuffer), "%T", "reason_other", client);
	DrawPanelItem(hPanel, sBuffer);
	DrawPanelText(hPanel, "");
	SetPanelCurrentKey(hPanel, 10);
	Format(sBuffer, sizeof(sBuffer), "%T", "Exit", client);
	DrawPanelItem(hPanel, sBuffer);
	
	SendPanelToClient(hPanel, client, Panel_SelectReason, MENU_TIME_FOREVER);
	CloseHandle(hPanel);
}

public Panel_TSAdmin(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			ShowReasonMenu(param1);
		}
	}
}

public Panel_SelectReason(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 != 10)
		{
			decl String:sURL[64];
			GetConVarString(g_hCVURL, sURL, sizeof(sURL));
			
			new Handle:hPack = CreateDataPack();
			WritePackCell(hPack, GetClientUserId(param1));
			WritePackCell(hPack, param2); // reason
			ResetPack(hPack);
			
			new Handle:hSocket = SocketCreate(SOCKET_TCP, Socket_OnError);
			SocketSetArg(hSocket, hPack);
			SocketConnect(hSocket, Socket_OnConnected, Socket_OnReceive, Socket_OnDisconnected, sURL, 80);
			
			LogMessage("[TSAdmin] %L has called an admin!", param1);
		}
	}
}

public Socket_OnConnected(Handle:socket, any:pack)
{
	new userid = ReadPackCell(pack);
	new reason = ReadPackCell(pack);
	ResetPack(pack);
	
	new client = GetClientOfUserId(userid);
	// Player left already?
	if(!client)
	{
		CloseHandle(pack);
		CloseHandle(socket);
		return;
	}
	
	decl String:sRequestStr[512], String:sURL[64], String:sPath[256], String:sSecret[64], String:sAuth[64], String:sName[MAX_NAME_LENGTH*4+1];
	GetConVarString(g_hCVURL, sURL, sizeof(sURL));
	GetConVarString(g_hCVPath, sPath, sizeof(sPath));
	GetConVarString(g_hCVSecret, sSecret, sizeof(sSecret));
	
	GetClientName(client, sName, sizeof(sName));
	GetClientAuthString(client, sAuth, sizeof(sAuth));
	
	URLEncode(sSecret, sizeof(sSecret));
	URLEncode(sName, sizeof(sName));
	URLEncode(sAuth, sizeof(sAuth));
	
	Format(sRequestStr, sizeof(sRequestStr), "GET /%sindex.php?secret=%s&name=%s&id=%s&serverip=%s&serverport=%d&rid=%d HTTP/1.1\r\nHost: %s\r\nConnection: close\r\n\r\n", sPath, sSecret, sName, sAuth, g_sServerIP, g_iServerPort, reason, sURL);
	SocketSend(socket, sRequestStr);
}

public Socket_OnReceive(Handle:socket, String:receiveData[], const dataSize, any:pack)
{
}

public Socket_OnDisconnected(Handle:socket, any:pack)
{
	new userid = ReadPackCell(pack);
	CloseHandle(pack);
	CloseHandle(socket);
	new client = GetClientOfUserId(userid);
	if(client)
	{
		PrintToChat(client, "\x04[TSAdmin] %t", "sent");
	}
}

public Socket_OnError(Handle:socket, const errorType, const errorNum, any:pack)
{
	LogError("[TSAdmin] Socket error %d (errno %d)", errorType, errorNum);
	
	new userid = ReadPackCell(pack);
	CloseHandle(pack);
	CloseHandle(socket);
	
	new client = GetClientOfUserId(userid);
	if(client)
	{
		PrintToChat(client, "\x04[TSAdmin] %t", "error");
	}
}

// RFC 2396 conform
stock URLEncode(String:sString[], maxlen, String:safe[] = "/", bool:bFormat = false)
{
	decl String:sAlwaysSafe[256];
	Format(sAlwaysSafe, sizeof(sAlwaysSafe), "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_.-%s", safe);
	
	// Need 2 '%' since sp's Format parses one as a parameter to replace
	// http://wiki.alliedmods.net/Format_Class_Functions_%28SourceMod_Scripting%29
	if(bFormat)
		ReplaceString(sString, maxlen, "%", "%%25");
	else
		ReplaceString(sString, maxlen, "%", "%25");
	new String:sChar[8], String:sReplaceChar[8];
	for(new i=1;i<256;i++)
	{
		// Skip the '%' double replace ftw..
		if(i==37)
			continue;
		
		Format(sChar, sizeof(sChar), "%c", i);
		if(StrContains(sAlwaysSafe, sChar) == -1 && StrContains(sString, sChar) != -1)
		{
			if(bFormat)
				Format(sReplaceChar, sizeof(sReplaceChar), "%%%%%02X", i);
			else
				Format(sReplaceChar, sizeof(sReplaceChar), "%%%02X", i);
			ReplaceString(sString, maxlen, sChar, sReplaceChar);
		}
	}
}