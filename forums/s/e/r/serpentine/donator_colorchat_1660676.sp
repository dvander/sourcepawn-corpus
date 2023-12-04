#include <sourcemod>
#include <colors>
#include <clientprefs>
#include <loghelper>
#include <donator>

#pragma semicolon 1

//Uncomment for custom color (yellow in TF2 most of the time) in an orange box game.
#define ORANGEBOX

enum
{
 	cNone = 0,
	cTeamColor,
	cGreen,
	cOlive,
	#if defined ORANGEBOX
	cYellow,
	#endif
	cRandom,
	cMax
};

new String:szColorCodes[][] = {
	"\x01", "\x03", "\x04", "\x05"
	#if defined ORANGEBOX
	, "\x06"
	#endif
};

new const String:szColorNames[cMax][] = {
	"None",
	"Team Color",
	"Green",
	"Olive",
	#if defined ORANGEBOX
	"Yellow",
	#endif
	"Random"
};

new g_iColor[MAXPLAYERS + 1];
new bool:g_bIsDonator[MAXPLAYERS + 1];
new Handle:g_hColorCookie = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Donator: Colored Chat",
	author = "Nut",
	description = "Donators get colored chat!",
	version = "0.4",
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
		FormatEx(szChatMsg, 255, "\x03%N\x01 :  %c%s", iClient, szColorCodes[iColor], szArg);
		CPrintToChatAllEx(iClient, szChatMsg);
	}
	else
	{
		LogPlayerEvent(iClient, "say", szArg);
		FormatEx(szChatMsg, 255, "(TEAM) \x03%N\x01 :  %c%s", iClient, szColorCodes[iColor], szArg);
		
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
				CPrintToChatEx(param1, param1, "[SM]: %cThis is your new chat color.", szColorCodes[param2]);
		}
	}
}