#include <sourcemod>
#include <morecolors>
#include <clientprefs>
#include <loghelper>
#include <donator>

#pragma semicolon 1

enum
{
 	cNone = 0,
	cRed,
	cGreen,
	cBlue,
	cMagenta,
	cCyan,
	cYellow,
	cBlack,
	cGrey,
	cHotPink,
	cRandom,
	cMax
};


new String:szColorCodes[][] = {
	"\x01", // Default
	"\x07FF0000" ,	//Red
	"\x0700FF00" ,	//Green
	"\x070000FF" ,	//Blue
	"\x07FF00FF" ,	//Magenta
	"\x0700FFFF" ,	//Cyan
	"\x07FFFF00" ,	//Yellow
	"\x07000000" ,	//Black
	"\x07CCCCCC" ,	//Grey
	"\x07FF69B4"	//Hot Pink
	
};

new const String:szColorNames[cMax][] = {
	"None",
	"Red",
	"Green",
	"Blue",
	"Magenta",
	"Cyan",
	"Yellow",
	"Black",
	"Grey",
	"Hot Pink",
	"Random"
};

new g_iColor[MAXPLAYERS + 1];
new bool:g_bIsDonator[MAXPLAYERS + 1];
new Handle:g_hColorCookie = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Donator: Colored Chat",
	author = "Nut, CoolJosh3k",
	description = "Donators get colored chat!",
	version = "0.4.1",
	url = ""
}

public OnPluginStart()
{
	AddCommandListener(SayCallback, "say");
	AddCommandListener(SayCallback, "say_team");
	
	g_hColorCookie = RegClientCookie("donator_colorcookie", "Chat color for donators.", CookieAccess_Private);
}

public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) SetFailState("Unabled to find plugin: Basic Donator Interface");
	Donator_RegisterMenuItem("Set Chat Color", ChatColorCallback);
}

public OnPostDonatorCheck(iClient)
{
	if (!IsClientInGame(iClient)) return;
	if (!(g_bIsDonator[iClient] = IsPlayerDonator(iClient))) return;
	g_iColor[iClient] = cNone;

	if (AreClientCookiesCached(iClient))
	{
		new String:szBuffer[2];
		GetClientCookie(iClient, g_hColorCookie, szBuffer, sizeof(szBuffer));

		if (strlen(szBuffer) > 0)
			g_iColor[iClient] = StringToInt(szBuffer);
	}
}

public OnClientDisconnect(iClient)
{
	g_iColor[iClient] = cNone;
	g_bIsDonator[iClient] = false;
}

public OnDonatorsChanged()
{
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerDonator(i))
		{
			g_bIsDonator[i] = true;
			new String:szBuffer[2];
			GetClientCookie(i, g_hColorCookie, szBuffer, sizeof(szBuffer));

			if (strlen(szBuffer) > 0)
				g_iColor[i] = StringToInt(szBuffer);
		}
	}
}

public Action:SayCallback(iClient, const String:szCommand[], iArgc)
{
	if (!iClient) return Plugin_Continue;
	if (!g_bIsDonator[iClient]) return Plugin_Continue;
	if(!IsClientInGame(iClient)) return Plugin_Continue;
	
	decl String:szArg[255], String:szChatMsg[255];
	GetCmdArgString(szArg, sizeof(szArg));

	StripQuotes(szArg);
	TrimString(szArg);

	if(szArg[0] == '/' || szArg[0] == '!' || szArg[0] == '@')	return Plugin_Continue;

	new iColor = g_iColor[iClient];
	if (!iColor) return Plugin_Continue;
	
	if (iColor == cRandom)
		iColor = GetRandomInt(cNone+1, cRandom-1);
	
	PrintToServer("%N: %s", iClient, szArg);
	
	if (StrEqual(szCommand, "say", true))
	{
		LogPlayerEvent(iClient, "say_team", szArg);
		FormatEx(szChatMsg, 255, "\x03%N\x01 :  %s%s", iClient, szColorCodes[iColor], szArg);
		CPrintToChatAllEx(iClient, szChatMsg);
	}
	else
	{
		LogPlayerEvent(iClient, "say", szArg);
		FormatEx(szChatMsg, 255, "(TEAM) \x03%N\x01 :  %s%s", iClient, szColorCodes[iColor], szArg);
		
		new iTeam = GetClientTeam(iClient);
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i)) continue;
			if(iTeam == GetClientTeam(i))
			CPrintToChatEx(i, iClient, szChatMsg);
		}
	}
	return Plugin_Handled;
}

public DonatorMenu:ChatColorCallback(iClient) Panel_SetColor(iClient);

public Panel_SetColor(iClient)
{
	new Handle:hMenu = CreateMenu(SetColorHandler);
	SetMenuTitle(hMenu,"Donator: Set Chat Color:");

	decl String:szItem[4];
	for (new i = 0; i < cMax; i++)
	{
		FormatEx(szItem, sizeof(szItem), "%i", i);
		if (g_iColor[iClient] == i)
			AddMenuItem(hMenu, szItem, szColorNames[i], ITEMDRAW_DISABLED);
		else
			AddMenuItem(hMenu, szItem, szColorNames[i], ITEMDRAW_DEFAULT);
	}
	DisplayMenu(hMenu, iClient, 20);
}

public SetColorHandler(Handle:menu, MenuAction:action, param1, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new iColor = param2;
			
			g_iColor[param1] = iColor;
			
			decl String:szColor[5];
			FormatEx(szColor, sizeof(szColor), "%i", iColor);
			SetClientCookie(param1, g_hColorCookie, szColor);
			if (iColor == cRandom)
				CPrintToChat(param1, "[SM]: Your new chat color is {olive}random{default}.");
			else
				CPrintToChatEx(param1, param1, "[SM]: %sThis is your new chat color.", szColorCodes[param2]);
		}
	}
}