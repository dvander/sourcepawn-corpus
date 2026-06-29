#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <clientprefs>

new bool:g_bIsCoin[MAXPLAYERS+1];
new iRank[MAXPLAYERS+1] = {0,...};
new iCoin[MAXPLAYERS+1] = {0,...};
new Handle:g_cookieRank = INVALID_HANDLE;
new Handle:g_cookieCoin = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[CS:GO] Fake Competitive Rank and coins",
	author = "Laam4",
	description = "Show competitive rank and coins on scoreboard",
	version = "1.1b-wm",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_elorank", Command_SetElo,  ADMFLAG_GENERIC, "sm_elorank <#userid|name> <0-18>");
	RegAdminCmd("sm_emblem", Command_SetCoin, ADMFLAG_GENERIC, "sm_emblem <#userid|name> <874-6011>");
//	RegConsoleCmd("sm_coin", Command_CoinMenu);
//	RegConsoleCmd("sm_mm", Command_EloMenu);
	HookEvent("announce_phase_end", Event_AnnouncePhaseEnd);
	HookEvent("player_disconnect", Event_Disconnect, EventHookMode_Pre);
	g_cookieRank = RegClientCookie("iRank", "", CookieAccess_Private);
	g_cookieCoin = RegClientCookie("iCoin", "", CookieAccess_Private);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public OnMapStart()
{
	new iIndex = FindEntityByClassname(MaxClients+1, "cs_player_manager");
	if (iIndex == -1) {
		SetFailState("Unable to find cs_player_manager entity");
	}
	SDKHook(iIndex, SDKHook_ThinkPost, Hook_OnThinkPost);
}

public OnClientCookiesCached(client)
{
	new String:valueRank[16];
	new String:valueCoin[16];
	GetClientCookie(client, g_cookieRank, valueRank, sizeof(valueRank));
	if(strlen(valueRank) > 0) iRank[client] = StringToInt(valueRank);
	GetClientCookie(client, g_cookieCoin, valueCoin, sizeof(valueCoin));
	if(strlen(valueCoin) > 0) {
		iCoin[client] = StringToInt(valueCoin);
		g_bIsCoin[client] = true;
	}
}
	
public Action:Event_Disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client)
	{
		iCoin[client] = 0;
		iRank[client] = 0;
		g_bIsCoin[client] = false;
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_SCORE) == IN_SCORE) {
		new Handle:hBuffer = StartMessageOne("ServerRankRevealAll", client);
		if (hBuffer == INVALID_HANDLE) {
			PrintToChat(client, "INVALID_HANDLE");
		}
		else {
			EndMessage();
		}
	}
	return Plugin_Continue;
}

public Action:Event_AnnouncePhaseEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Handle:hBuffer = StartMessageAll("ServerRankRevealAll");
	if (hBuffer == INVALID_HANDLE) {
		PrintToServer("ServerRankRevealAll = INVALID_HANDLE");
	}
	else {
		EndMessage();
	}
	return Plugin_Continue;
}

public Hook_OnThinkPost(iEnt) {
	static iRankOffset = -1;
	static iCoinOffset = -1;
	if (iRankOffset == -1) {
		iRankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
	}
	if (iCoinOffset == -1) {
		iCoinOffset = FindSendPropInfo("CCSPlayerResource", "m_nActiveCoinRank");
	}
	SetEntDataArray(iEnt, iRankOffset, iRank, MAXPLAYERS+1, _, true);
	static tempCoin[MAXPLAYERS+1];
	GetEntDataArray(iEnt, iCoinOffset, tempCoin, MAXPLAYERS+1);
	for (new i = 1; i <= MaxClients; i++) {
		if (g_bIsCoin[i]) {
			tempCoin[i] = iCoin[i];
		}
	}
	SetEntDataArray(iEnt, iCoinOffset, tempCoin, MAXPLAYERS+1, _, true);
}

public Action:Command_EloMenu(client, args)
{
	if ( IsClientInGame(client) )
	{
		new Handle:MenuHandle = CreateMenu(EloHandler);
		SetMenuTitle(MenuHandle, "Your competitive rank?");
		AddMenuItem(MenuHandle, "0", "No Rank");
		AddMenuItem(MenuHandle, "1", "Silver I");
		AddMenuItem(MenuHandle, "2", "Silver II");
		AddMenuItem(MenuHandle, "3", "Silver III");
		AddMenuItem(MenuHandle, "4", "Silver IV");
		AddMenuItem(MenuHandle, "5", "Silver Elite");
		AddMenuItem(MenuHandle, "6", "Silver Elite Master");
		AddMenuItem(MenuHandle, "7", "Gold Nova I");
		AddMenuItem(MenuHandle, "8", "Gold Nova II");
		AddMenuItem(MenuHandle, "9", "Gold Nova III");
		AddMenuItem(MenuHandle, "10", "Gold Nova Master");
		AddMenuItem(MenuHandle, "11", "Master Guardian I");
		AddMenuItem(MenuHandle, "12", "Master Guardian II");
		AddMenuItem(MenuHandle, "13", "Master Guardian Elite");
		AddMenuItem(MenuHandle, "14", "Distinguished Master Guardian");
		AddMenuItem(MenuHandle, "15", "Legendary Eagle");
		AddMenuItem(MenuHandle, "16", "Legandary Eagle Master");
		AddMenuItem(MenuHandle, "17", "Supreme Master First Class");
		AddMenuItem(MenuHandle, "18", "The Global Elite");

		SetMenuPagination(MenuHandle, 8);
		DisplayMenu(MenuHandle, client, 30);
	}
	return Plugin_Handled;
}

public EloHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			new String:info[4];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			iRank[client] = StringToInt(info);
			SetClientCookie(client, g_cookieRank, info);
			new String:text[20];
			Format(text, sizeof(text), "Your rank is now ");
			switch(iRank[client])
			{
			case 0:PrintToChat(client, "%s\x08No Rank", text);
			case 1:PrintToChat(client, "%s\x0ASilver I", text);
			case 2:PrintToChat(client, "%s\x0ASilver II", text);
			case 3:PrintToChat(client, "%s\x0ASilver III", text);
			case 4:PrintToChat(client, "%s\x0ASilver IV", text);
			case 5:PrintToChat(client, "%s\x0ASilver Elite", text);
			case 6:PrintToChat(client, "%s\x0ASilver Elite Master", text);
			case 7:PrintToChat(client, "%s\x0BGold Nova I", text);
			case 8:PrintToChat(client, "%s\x0BGold Nova II", text);
			case 9:PrintToChat(client, "%s\x0BGold Nova III", text);
			case 10:PrintToChat(client, "%s\x0BGold Nova Master", text);
			case 11:PrintToChat(client, "%s\x0CMaster Guardian I", text);
			case 12:PrintToChat(client, "%s\x0CMaster Guardian II", text);
			case 13:PrintToChat(client, "%s\x0CMaster Guardian Elite", text);
			case 14:PrintToChat(client, "%s\x0CDistinguished Master Guardian", text);
			case 15:PrintToChat(client, "%s\x0ELegendary Eagle", text);
			case 16:PrintToChat(client, "%s\x0ELegandary Eagle Master", text);
			case 17:PrintToChat(client, "%s\x0ESupreme Master First Class", text);
			case 18:PrintToChat(client, "%s\x0FThe Global Elite", text);
			default: PrintToChat(client, "Dunno lol");
			}
		}
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:Command_CoinMenu(client, args)
{
	if ( IsClientInGame(client) )
	{
		new Handle:MenuHandle = CreateMenu(CoinHandler);
		SetMenuTitle(MenuHandle, "Set your coin");
		AddMenuItem(MenuHandle, "0", "No Coin");
		AddMenuItem(MenuHandle, "874", "Five Year Service Coin");
		AddMenuItem(MenuHandle, "875", "DreamHack SteelSeries 2013 CS:GO Champion");
		AddMenuItem(MenuHandle, "876", "DreamHack SteelSeries 2013 CS:GO Finalist");
		AddMenuItem(MenuHandle, "877", "DreamHack SteelSeries 2013 CS:GO Semifinalist");
		AddMenuItem(MenuHandle, "878", "DreamHack SteelSeries 2013 CS:GO Quarterfinalist");
		AddMenuItem(MenuHandle, "879", "EMS One Katowice 2014 CS:GO Champion");
		AddMenuItem(MenuHandle, "880", "EMS One Katowice 2014 CS:GO Finalist");
		AddMenuItem(MenuHandle, "881", "EMS One Katowice 2014 CS:GO Semifinalist");
		AddMenuItem(MenuHandle, "882", "EMS One Katowice 2014 CS:GO Quarterfinalist");
		AddMenuItem(MenuHandle, "883", "ESL One Cologne 2014 CS:GO Champion");
		AddMenuItem(MenuHandle, "884", "ESL One Cologne 2014 CS:GO Finalist");
		AddMenuItem(MenuHandle, "885", "ESL One Cologne 2014 CS:GO Semifinalist");
		AddMenuItem(MenuHandle, "886", "ESL One Cologne 2014 CS:GO Quarterfinalist");
		AddMenuItem(MenuHandle, "887", "ESL One Cologne 2014 Pick 'Em Challenge Bronze");
		AddMenuItem(MenuHandle, "888", "ESL One Cologne 2014 Pick 'Em Challenge Silver");
		AddMenuItem(MenuHandle, "889", "ESL One Cologne 2014 Pick 'Em Challenge Gold");
		AddMenuItem(MenuHandle, "890", "DreamHack Winter 2014 CS:GO Champion");
		AddMenuItem(MenuHandle, "891", "DreamHack Winter 2014 CS:GO Finalist");
		AddMenuItem(MenuHandle, "892", "DreamHack Winter 2014 CS:GO Semifinalist");
		AddMenuItem(MenuHandle, "893", "DreamHack Winter 2014 CS:GO Quarterfinalist");
		AddMenuItem(MenuHandle, "894", "DreamHack Winter 2014 Pick 'Em Challenge Bronze");
		AddMenuItem(MenuHandle, "895", "DreamHack Winter 2014 Pick 'Em Challenge Silver");
		AddMenuItem(MenuHandle, "896", "DreamHack Winter 2014 Pick 'Em Challenge Gold");
		AddMenuItem(MenuHandle, "897", "ESL One Katowice 2015 CS:GO Champion");
		AddMenuItem(MenuHandle, "898", "ESL One Katowice 2015 CS:GO Finalist");
		AddMenuItem(MenuHandle, "899", "ESL One Katowice 2015 CS:GO Semifinalist");
		AddMenuItem(MenuHandle, "900", "ESL One Katowice 2015 CS:GO Quarterfinalist");
		AddMenuItem(MenuHandle, "901", "ESL One Katowice 2015 Pick 'Em Challenge Bronze");
		AddMenuItem(MenuHandle, "902", "ESL One Katowice 2015 Pick 'Em Challenge Silver");
		AddMenuItem(MenuHandle, "903", "ESL One Katowice 2015 Pick 'Em Challenge Gold");
		AddMenuItem(MenuHandle, "1001", "Community Season One Spring 2013 Coin 1");
		AddMenuItem(MenuHandle, "1002", "Community Season One Spring 2013 Coin 2");
		AddMenuItem(MenuHandle, "1003", "Community Season One Spring 2013 Coin 3");
		AddMenuItem(MenuHandle, "1013", "Community Season Two Autumn 2013 Coin 1");
		AddMenuItem(MenuHandle, "1014", "Community Season Two Autumn 2013 Coin 2");
		AddMenuItem(MenuHandle, "1015", "Community Season Two Autumn 2013 Coin 3");
		AddMenuItem(MenuHandle, "1024", "Community Season Three Spring 2014 Coin 1");
		AddMenuItem(MenuHandle, "1025", "Community Season Three Spring 2014 Coin 2");
		AddMenuItem(MenuHandle, "1026", "Community Season Three Spring 2014 Coin 3");
		AddMenuItem(MenuHandle, "1028", "Community Season Four Summer 2014 Coin 1");
		AddMenuItem(MenuHandle, "1029", "Community Season Four Summer 2014 Coin 2");
		AddMenuItem(MenuHandle, "1030", "Community Season Four Summer 2014 Coin 3");
		AddMenuItem(MenuHandle, "1316", "Community Season Five Summer 2014 Coin 1");
		AddMenuItem(MenuHandle, "1317", "Community Season Five Summer 2014 Coin 2");
		AddMenuItem(MenuHandle, "1318", "Community Season Five Summer 2014 Coin 3");
		AddMenuItem(MenuHandle, "6001", "Collectible Pin - Dust II");
		AddMenuItem(MenuHandle, "6002", "Collectible Pin - Guardian Elite");
		AddMenuItem(MenuHandle, "6003", "Collectible Pin - Mirage");
		AddMenuItem(MenuHandle, "6004", "Collectible Pin - Inferno");
		AddMenuItem(MenuHandle, "6005", "Collectible Pin - Italy");
		AddMenuItem(MenuHandle, "6006", "Collectible Pin - Victory");
		AddMenuItem(MenuHandle, "6007", "Collectible Pin - Militia");
		AddMenuItem(MenuHandle, "6008", "Collectible Pin - Nuke");
		AddMenuItem(MenuHandle, "6009", "Collectible Pin - Train");
		AddMenuItem(MenuHandle, "6010", "Collectible Pin - Guardian");
		AddMenuItem(MenuHandle, "6011", "Collectible Pin - Tactics");

		SetMenuPagination(MenuHandle, 8);
		DisplayMenu(MenuHandle, client, 30);
	}
	return Plugin_Handled;
}

public CoinHandler(Handle:menu, MenuAction:action, client, itemNum)
{
	switch(action)
	{
	case MenuAction_Select:
		{
			new String:info[6];
			GetMenuItem(menu, itemNum, info, sizeof(info));
			iCoin[client] = StringToInt(info);
			SetClientCookie(client, g_cookieCoin, info);
			g_bIsCoin[client] = true;
			PrintToChat(client, "New coin selected");
		}
	case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:Command_SetElo(client, args) {
	if (args < 2) {
		ReplyToCommand(client, "[SM] Usage: sm_elorank <#userid|name> <0-18>");
		return Plugin_Handled;
	}
	
	decl String:szTarget[65];
	GetCmdArg(1, szTarget, sizeof(szTarget));

	decl String:szTargetName[MAX_TARGET_LENGTH+1];
	decl iTargetList[MAXPLAYERS+1], iTargetCount, bool:bTnIsMl;

	if ((iTargetCount = ProcessTargetString(
					szTarget,
					client,
					iTargetList,
					MAXPLAYERS,
					COMMAND_FILTER_CONNECTED,
					szTargetName,
					sizeof(szTargetName),
					bTnIsMl)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}
	
	decl String:szRank[6];
	GetCmdArg(2, szRank, sizeof(szRank));

	new iRanks = StringToInt(szRank);
	
	for (new i = 0; i < iTargetCount; i++)
	{
		iRank[iTargetList[i]] = iRanks;
		SetClientCookie(i, g_cookieRank, szRank);
	}
	
	return Plugin_Handled;
}

public Action:Command_SetCoin(client, args) {
	if (args < 2) {
		ReplyToCommand(client, "[SM] Usage: sm_emblem <#userid|name> <coin>");
		return Plugin_Handled;
	}
	
	decl String:szTarget[65];
	GetCmdArg(1, szTarget, sizeof(szTarget));

	decl String:szTargetName[MAX_TARGET_LENGTH+1];
	decl iTargetList[MAXPLAYERS+1], iTargetCount, bool:bTnIsMl;

	if ((iTargetCount = ProcessTargetString(
					szTarget,
					client,
					iTargetList,
					MAXPLAYERS,
					COMMAND_FILTER_CONNECTED,
					szTargetName,
					sizeof(szTargetName),
					bTnIsMl)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}
	
	decl String:szCoin[6];
	GetCmdArg(2, szCoin, sizeof(szCoin));

	new iCoins = StringToInt(szCoin);
	
	for (new i = 0; i < iTargetCount; i++)
	{
		iCoin[iTargetList[i]] = iCoins;
		g_bIsCoin[iTargetList[i]] = true;
		SetClientCookie(i, g_cookieCoin, szCoin);
	}
	return Plugin_Handled;
}