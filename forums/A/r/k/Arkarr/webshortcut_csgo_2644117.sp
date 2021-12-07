/*  Web Shortcuts CS:GO version
 *
 *  Copyright (C) 2017-2018 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <ASteambot>

#define MODULE_NAME		"[ASteambot - Web Shortcuts]"

#pragma semicolon 1

#pragma newdecls required

#define PLUGIN_VERSION				"3.0"

public Plugin myinfo = 
{
	name = "Web Shortcuts CS:GO version",
	author = "Franc1sco franug",
	description = "Provides chat-triggered web shortcuts",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/franug/"
};

Handle g_Shortcuts;
Handle g_Titles;
Handle g_Links;

char g_ServerIp [32];
char g_ServerPort [16];

ConVar gc_sURL;

bool steambot = false;

public void OnPluginStart()
{
	CreateConVar("sm_webshortcutscsgo_version", PLUGIN_VERSION, "", FCVAR_NOTIFY|FCVAR_REPLICATED);
	
	gc_sURL = CreateConVar("sm_webshortcutscsgo_url", "http://cola-team.com/franug/redirect.php", "URL to your webspace with webshortcuts webpart (not needed if you use ASteambot)");
	
	RegConsoleCmd("say", OnSay);
	RegConsoleCmd("say_team", OnSay);
	
	RegAdminCmd("sm_web", Command_Web, ADMFLAG_GENERIC,"Open URL for target");
	
	
	g_Shortcuts = CreateArray(32);
	g_Titles = CreateArray(64);
	g_Links = CreateArray(512);
	
	Handle cvar = FindConVar("hostip");
	int hostip = GetConVarInt(cvar);
	FormatEx(g_ServerIp, sizeof(g_ServerIp), "%u.%u.%u.%u",
		(hostip >> 24) & 0x000000FF, (hostip >> 16) & 0x000000FF, (hostip >> 8) & 0x000000FF, hostip & 0x000000FF);
	
	cvar = FindConVar("hostport");
	GetConVarString(cvar, g_ServerPort, sizeof(g_ServerPort));
	
	LoadWebshortcuts();
}

public void OnPluginEnd()
{
	if(steambot)
		ASteambot_RemoveModule();
}
 
public void OnAllPluginsLoaded()
{
	steambot = LibraryExists("ASteambot");
	
	if(steambot)
		ASteambot_RegisterModule("ASteambot_WebShortcuts");
}
 
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "ASteambot"))
	{
		steambot = false;
	}
}
 
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "ASteambot"))
	{
		steambot = true;
	}
}
 
public void OnMapStart()
{
	LoadWebshortcuts();
}
 
public Action OnSay(int client, int args)
{
	if(!client) return Plugin_Continue;
	
	char text [512], shortcut[512];
	GetCmdArgString(text, sizeof(text));
	
	StripQuotes(text);
	TrimString(text);
	
	int size = GetArraySize(g_Shortcuts);
	for (int i; i != size; ++i)
	{
		GetArrayString(g_Shortcuts, i, shortcut, sizeof(shortcut));
		
		if (StrEqual(text, shortcut, false))
		{
			if(!steambot)
				QueryClientConVar(client, "cl_disablehtmlmotd", view_as<ConVarQueryFinished>(ClientConVar), client);
			
			char title [256];
			char steamId [64];
			char userId [16];
			char name [64];
			char clientIp [32];
			
			GetArrayString(g_Titles, i, title, sizeof(title));
			GetArrayString(g_Links, i, text, sizeof(text));
			
			//GetClientAuthString(client, steamId, sizeof(steamId));
			GetClientAuthId(client, AuthId_Steam2,  steamId, sizeof(steamId));
			FormatEx(userId, sizeof(userId), "%u", GetClientUserId(client));
			GetClientName(client, name, sizeof(name));
			GetClientIP(client, clientIp, sizeof(clientIp));
			
/* 			ReplaceString(title, sizeof(title), "{SERVER_IP}", g_ServerIp);
			ReplaceString(title, sizeof(title), "{SERVER_PORT}", g_ServerPort);
			ReplaceString(title, sizeof(title), "{STEAM_ID}", steamId);
			ReplaceString(title, sizeof(title), "{USER_ID}", userId);
			ReplaceString(title, sizeof(title), "{NAME}", name);
			ReplaceString(title, sizeof(title), "{IP}", clientIp); */
			
			ReplaceString(text, sizeof(text), "{SERVER_IP}", g_ServerIp);
			ReplaceString(text, sizeof(text), "{SERVER_PORT}", g_ServerPort);
			ReplaceString(text, sizeof(text), "{STEAM_ID}", steamId);
			ReplaceString(text, sizeof(text), "{USER_ID}", userId);
			ReplaceString(text, sizeof(text), "{NAME}", name);
			ReplaceString(text, sizeof(text), "{IP}", clientIp);
			
			if(steambot)
			{
				SendURLtoSteamBot(text, client);
			}
			else if(StrEqual(title, "none", false))
			{
				StreamPanel("Webshortcuts", text, client);
			}
			else if(StrEqual(title, "full", false))
			{
				FixMotdCSGO_fullsize(text);
				ShowMOTDPanel(client, "Script by Franc1sco franug", text, MOTDPANEL_TYPE_URL);
			}
			else
			{
				FixMotdCSGO(text, title);
				ShowMOTDPanel(client, "Script by Franc1sco franug", text, MOTDPANEL_TYPE_URL);
			}
		}
	}
	
	return Plugin_Continue;	
}
 
void LoadWebshortcuts()
{
	char buffer [1024];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/webshortcuts.txt");
	
	if (!FileExists(buffer))
	{
		return;
	}
	
	Handle f = OpenFile(buffer, "r");
	if (f == INVALID_HANDLE)
	{
		LogError("[SM] Could not open file: %s", buffer);
		return;
	}
	
	ClearArray(g_Shortcuts);
	ClearArray(g_Titles);
	ClearArray(g_Links);
	
	char shortcut [32];
	char title [256];
	char link [512];
	while (!IsEndOfFile(f) && ReadFileLine(f, buffer, sizeof(buffer)))
	{
		TrimString(buffer);
		if (buffer[0] == '\0' || buffer[0] == ';' || (buffer[0] == '/' && buffer[1] == '/'))
		{
			continue;
		}
		
		int pos = BreakString(buffer, shortcut, sizeof(shortcut));
		if (pos == -1)
		{
			continue;
		}
		
		int linkPos = BreakString(buffer[pos], title, sizeof(title));
		if (linkPos == -1)
		{
			continue;
		}
		
		strcopy(link, sizeof(link), buffer[linkPos+pos]);
		TrimString(link);
		
		PushArrayString(g_Shortcuts, shortcut);
		PushArrayString(g_Titles, title);
		PushArrayString(g_Links, link);
	}
	
	CloseHandle(f);
}

public Action Command_Web(int client, int args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_web <target> <url>");
		return Plugin_Handled;
	}
	char pattern[96], buffer[64], url[512];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, url, sizeof(url));
	int targets[129];
	bool ml = false;

	int count = ProcessTargetString(pattern, client, targets, sizeof(targets), 0, buffer, sizeof(buffer), ml);

	if(StrContains(url, "http://", false) != 0) Format(url, sizeof(url), "http://%s", url);
	
	if(!steambot)
		FixMotdCSGO(url,"height=720,width=1280");
	
	if (count <= 0) ReplyToCommand(client, "Bad target");
	else for (int i = 0; i < count; i++)
	{
		if(!steambot)
			ShowMOTDPanel(targets[i], "Web Shortcuts", url, MOTDPANEL_TYPE_URL);
		else
			SendURLtoSteamBot(url, targets[i]);
	}
	return Plugin_Handled;
}

public void SendURLtoSteamBot(char [] url, int client)
{
	char steamId[30];
    
	if(GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
	{
	    char buffer[4096];
	
	    Format(buffer, sizeof(buffer), "%s/%s", steamId, url);
	    
	    PrintToServer(buffer);
	    ASteambot_SendMesssage(AS_SIMPLE, buffer);
	}
}

public void StreamPanel(char [] title, char [] url, int client)
{
	Handle Radio = CreateKeyValues("data");
	KvSetString(Radio, "title", title);
	KvSetString(Radio, "type", "2");
	KvSetString(Radio, "msg", url);
	ShowVGUIPanel(client, "info", Radio, false);
	CloseHandle(Radio);
}

stock void FixMotdCSGO(char [] web, char [] title) 
{ 
	char url[64]; 
	gc_sURL.GetString(url, sizeof(url)); 
	Format(web, 512, "%s?web=%s&%s", url, web, title); 
} 

stock void FixMotdCSGO_fullsize(char [] web) 
{ 
	char url[64]; 
	gc_sURL.GetString(url, sizeof(url)); 
	Format(web, 512, "%s?web=%s&fullsize=1", url, web); 
} 

public void ClientConVar(QueryCookie cookie, int client, ConVarQueryResult result, char [] cvarName, char [] cvarValue)
{
	if (StringToInt(cvarValue) > 0)
	{
		PrintToChat(client, "---------------------------------------------------------------");
		PrintToChat(client, "You have cl_disablehtmlmotd to 1 and for that reason webshortcuts plugin dont work for you");
		PrintToChat(client, "Please, put this in your console: cl_disablehtmlmotd 0");
		PrintToChat(client, "---------------------------------------------------------------");
	}
}

public int ASteambot_Message(AS_MessageType MessageType, char[] msg, const int msgSize)
{
	if(MessageType == AS_NOT_FRIENDS)
	{
		int client = ASteambot_FindClientBySteam64(msg);
		if(client != -1)
		{
			ASteambot_SendMesssage(AS_FRIEND_INVITE, msg);
			PrintToChat(client, " \x04%s\x01 You are not friend with me and I can't send you steam messages. I sent you a friend invite.", MODULE_NAME);
		}
	}
}

stock bool IsValidClient(int client)
{
	if (client <= 0)return false;
	if (client > MaxClients)return false;
	if (!IsClientConnected(client))return false;
	return IsClientInGame(client);
}