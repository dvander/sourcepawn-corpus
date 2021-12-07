#include <sourcemod>
#include <sdktools>
#include <morecolors>
#include <basecomm>

#pragma semicolon 1

#define MAXCOLORS 150
#define FEATURECAP_COMMANDLISTENER  "command listener"

//DBI Saving

//Global Strings
new String:g_szChatColor[MAXPLAYERS + 1][64];
new String:g_szNameColor[MAXPLAYERS + 1][64];
new String:g_szColorName[MAXCOLORS][64];

//Global Handles
new Handle:g_hNameColorEnabled = INVALID_HANDLE;

//Global Integers
new g_iColorCount = 0;





public Plugin:myinfo = 
{
	name = "[HL2DM] Simple Chat Colors",
	author = "EasSidezZ",
	description = "A simple and easy to use processor for colors.",
	version = "1.0",
	url = "http://www.redspeedservers.com"
};


public OnPluginStart()
{
	RegConsoleCmd("sm_colors", Build_ColorsMenu, "-Set the color of your chat messages");
	RegConsoleCmd("sm_resetcolors", Command_ResetColors, "-Reset the colors of your name/chat to default");
	RegConsoleCmd("sm_previewcolors", PrintColors, "");
	RegAdminCmd("sm_resetcolorsall", Command_ResetColorsAll, ADMFLAG_ROOT, "Globally Reset Colors (All Players");
	AddCommandListener(Listener_HandleSay, "say");		
	g_hNameColorEnabled = CreateConVar("sm_colorname_enabled", "1", "Enable the changing of Name Colors (1 = Enabled, 0 = Disabled)", FCVAR_PLUGIN|FCVAR_NOTIFY);
	LoadColors();
}

public OnClientPutInServer(Client)
{
	Format(g_szChatColor[Client], sizeof(g_szChatColor[]), "default");
	Format(g_szNameColor[Client], sizeof(g_szNameColor[]), "default");
}


public Action:PrintColors(Client, Args)
{
	for(new i = 1; i < g_iColorCount; i++)
	{
		CPrintToChat(Client, "{%s}%s", g_szColorName[i], g_szColorName[i]);
	}
	return Plugin_Handled;
}

public Action:Listener_HandleSay(iClient, const String:Command[], argc)
{
	decl String:Buffer[10246];
	new ClientTeam = GetClientTeam(iClient);
	GetCmdArgString(Buffer, sizeof(Buffer));
	StripQuotes(Buffer);
	TrimString(Buffer);
	if(Buffer[0] == '/') return Plugin_Handled;
	if(Buffer[0] == '@') return Plugin_Handled;
	
	if(!BaseComm_IsClientGagged(iClient))
	{
		if(GetConVarInt(FindConVar("mp_teamplay")) == 1)
		{
			if(ClientTeam == 1 && StrEqual(g_szNameColor[iClient], "default"))
			{
				CPrintToChatAll("*SPEC* {grey}%N {default}:  {%s}%s", iClient, g_szChatColor[iClient], Buffer);
				return Plugin_Handled;
			}
			
			if(ClientTeam == 2 && StrEqual(g_szNameColor[iClient], "default"))
			{
				CPrintToChatAll("{blue}%N {default}:  {%s}%s", iClient, g_szChatColor[iClient], Buffer);
				return Plugin_Handled;
			}
			
			if(ClientTeam == 3 && StrEqual(g_szNameColor[iClient], "default"))
			{
				CPrintToChatAll("{red}%N {default}:  {%s}%s", iClient, g_szNameColor[iClient], Buffer);
				return Plugin_Handled;
			}
		}	
		
		CPrintToChatAll("{%s}%N {default}:  {%s}%s", g_szNameColor[iClient], iClient, g_szChatColor[iClient], Buffer);
	}
	else
	{
		return Plugin_Handled;
	}
	return Plugin_Handled;
}
public Action:Command_ResetColors(iClient, iArgs)
{
	if(iArgs > 0)
	{
		PrintToChat(iClient, "[SM] Invalid Usage: sm_resetcolors <NO ARGS>");
		PrintToConsole(iClient, "[SM] Invalid Usage: sm_resetcolors <NO ARGS>");
		return Plugin_Handled;
	}
	
	PrintToChat(iClient, "Your chat colors have been reset to default");
	
	return Plugin_Handled;
}
public Action:Build_ColorsMenu(iClient, iArgs)
{
	new Handle:hMenu = CreateMenu(Menu_Colors);
	SetMenuTitle(hMenu, "SimpleColors Menu");
	
	AddMenuItem(hMenu, "1", "Chat Colors");
	if(GetConVarInt(g_hNameColorEnabled) == 1)
	{
		AddMenuItem(hMenu, "2", "Name Colors");
	}

	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, 120);
	
	return Plugin_Handled;
}

public Menu_Colors(Handle:Menu, MenuAction:action, iClient, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(Menu);
	}
	
	if(action == MenuAction_Select)
	{
		new String:Select[32];
		GetMenuItem(Menu, param2, Select, sizeof(Select));
		
		if(StringToInt(Select) == 1)
		{
			ChatColorsMenu(iClient);
		}
		else if(StringToInt(Select) == 2)
		{
			NameColorsMenu(iClient);
		}
	}
}

public Menu_ChatColorsMenu(Handle:ColorsMenu, MenuAction:action, iClient, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(ColorsMenu);
	}
	
	
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(ColorsMenu, param2, info, sizeof(info));
		for(new i = 0; i < g_iColorCount; i++)
		{
			if(StrEqual(info, g_szColorName[i]))
			{
				g_szChatColor[iClient] = g_szColorName[i];
				
				CPrintToChat(iClient, "Your chat color is now: {%s}%s", g_szColorName[i], g_szColorName[i]);
				Format(g_szChatColor[iClient], sizeof(g_szChatColor[]), "%s", g_szColorName[i]);
			}
		}
	}
}

public Action:ChatColorsMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_ChatColorsMenu);
	SetMenuTitle(hMenu, "Chat Colors Menu");
	
	for(new i = 0; i < g_iColorCount; i++)
	{
		AddMenuItem(hMenu, g_szColorName[i], g_szColorName[i]);
	}
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	
	PrintToChat(iClient, "Press [ESC] to access the menu");
	
	return Plugin_Handled;
}

public Action:CheckColors(Client, Args)
{
	PrintToChat(Client, "%d", g_iColorCount);
	return Plugin_Handled;
}

public Menu_NameColorsMenu(Handle:ColorsMenu, MenuAction:action, iClient, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(ColorsMenu);
	}
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(ColorsMenu, param2, info, sizeof(info));
		for(new i = 0; i < g_iColorCount; i++)
		{
			if(StrEqual(info, g_szColorName[i]))
			{
				Format(g_szNameColor[iClient], sizeof(g_szNameColor[]), "%s", g_szColorName[i]);
				g_szNameColor[iClient] = g_szColorName[i];
						
				CPrintToChat(iClient, "Your name color is now: {%s}%s", g_szColorName[i], g_szColorName[i]);
			}
		}
	}
}

public Action:NameColorsMenu(iClient)
{
	new Handle:hMenu = CreateMenu(Menu_NameColorsMenu);
	SetMenuTitle(hMenu, "Name Colors Menu");
	
	for(new i = 0; i < g_iColorCount; i++)
	{
		AddMenuItem(hMenu, g_szColorName[i], g_szColorName[i]);
	}
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	
	PrintToChat(iClient, "Press [ESC] to access the menu");
	
	return Plugin_Handled;
}

public Action:Command_ResetColorsAll(iClient, Args)
{
	for(new X = 1; X < MaxClients; X++)
	{
		Format(g_szChatColor[X], sizeof(g_szChatColor[]), "default");
		Format(g_szNameColor[X], sizeof(g_szNameColor[]), "default");
	}
	return Plugin_Handled;
}	

LoadColors() //Credits to Panda && Marcus, I'd be lost without those two
{
	decl String:szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, PLATFORM_MAX_PATH, "configs/colorsmenu.ini");

	new Handle:_hColors = CreateKeyValues("Colors");
	if(FileToKeyValues(_hColors, szPath))
	{
		KvGotoFirstSubKey(_hColors);
		do
		{		
			KvGetString(_hColors, "color_name", g_szColorName[g_iColorCount], sizeof(g_szColorName[]));
			g_iColorCount++;
		}
		while (KvGotoNextKey(_hColors));
		CloseHandle(_hColors);
		
		PrintToServer("SimpleChatColors: Loaded %d colors!", g_iColorCount);
	} else
	{
		CloseHandle(_hColors);
		SetFailState("SimpleChatColors: Couldn't find: \"configs/colorsmenu.ini\"");
	}
}
	