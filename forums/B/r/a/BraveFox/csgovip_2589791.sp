/*
	* CSGO VIP System Plugin
	* Required: Mysql\SQL Database, Simple Chat Proccesor, SourceMod.
	* Version: 3.4
	* Author: S4muRaY'(BraveFox)
	* Remake of my old system https://forums.alliedmods.net/showthread.php?p=2541503
*/
//Includes
#include <sourcemod>
#include <cstrike>
#include <clientprefs>
#include <sdktools>
#include <scp>
#include <csgovip>
#define prefix " \x07[VIP]\x03 "
//Database
Database DB = null;
//Handles
Handle g_hVIPTag = INVALID_HANDLE, g_hVIPClanTag = INVALID_HANDLE, g_hVIPTagColor = INVALID_HANDLE, g_hVIPNameColor = INVALID_HANDLE, g_hVIPChatColor = INVALID_HANDLE, g_hEnabled = INVALID_HANDLE, g_hSkins = INVALID_HANDLE, g_hHealth = INVALID_HANDLE, g_hDefuse = INVALID_HANDLE, g_hArmor = INVALID_HANDLE;
//Chars
char sModel[512][512], sName[512][512];
//Bools
bool g_bEnabled = true;
bool g_bSkins = true;
bool g_bHP = true;
bool g_bDefuse = true;
bool g_bFullArmor = true;
//Client's Chars
char g_sClanTag[MAXPLAYERS + 1][512];
char g_sChatColor[MAXPLAYERS + 1][512];
char g_sNameColor[MAXPLAYERS + 1][512];
char g_sTagColor[MAXPLAYERS + 1][512];
char g_sTag[MAXPLAYERS + 1][512];
char g_sClientSkin[MAXPLAYERS + 1][512];
//Client's Bools
bool g_bIsClientVIP[MAXPLAYERS + 1] = false;
bool g_bArmor[MAXPLAYERS + 1] = false;
bool g_bIsTypingTag[MAXPLAYERS + 1] = false;
bool g_bIsTypingClanTag[MAXPLAYERS + 1] = false;
bool g_bHealth[MAXPLAYERS + 1] = false;
bool g_bDefusekit[MAXPLAYERS + 1] = false;
//Client's Integers
int g_iTimeLeft[MAXPLAYERS + 1] = 0;
//Integer
int g_iSkins;
int g_iRounds = 0;
public Plugin myinfo = 
{
	name = "[CSGO]VIP System", 
	author = "S4muRaY'(BraveFox)", 
	description = "Advanced VIP system", 
	version = "3.4", 
	url = "http://steamcommunity.com/id/s4muray"
};

public void OnPluginStart()
{
	SQL_StartConnection();
	//Translations
	LoadTranslations("common.phrases");
	//Cvars
	g_hEnabled = CreateConVar("sm_vipsystem_enabled", "1", "Enable the vip system?", 0, true, 0.0, true, 1.0);
	g_hSkins = CreateConVar("sm_vipsystem_skins", "1", "Allow vip players to use player skins?", 0, true, 0.0, true, 1.0);
	g_hHealth = CreateConVar("sm_vipsystem_health", "1", "Allow vip players to use hp bonus?", 0, true, 0.0, true, 1.0);
	g_hDefuse = CreateConVar("sm_vipsystem_defuse", "1", "Allow vip players to use defuse kit bonus?", 0, true, 0.0, true, 1.0);
	g_hArmor = CreateConVar("sm_vipsystem_armor", "1", "Allow vip players to use full armor bonus?", 0, true, 0.0, true, 1.0);
	//Hook Cvars Change
	HookConVarChange(g_hEnabled, OnCvarChange_Enabled);
	HookConVarChange(g_hSkins, OnCvarChange_Skins);
	HookConVarChange(g_hHealth, OnCvarChange_Health);
	HookConVarChange(g_hDefuse, OnCvarChange_Defuse);
	HookConVarChange(g_hArmor, OnCvarChange_Armor);
	//Auto exec config
	AutoExecConfig(true, "s4muray_vipsystem");
	//Cookies
	g_hVIPTag = RegClientCookie("VIPSystemTags", "Saving the VIP's chat tags here", CookieAccess_Protected);
	g_hVIPClanTag = RegClientCookie("VIPSystemCTags", "Saving the VIP's clan tags here", CookieAccess_Protected);
	g_hVIPTagColor = RegClientCookie("VIPSystemTagColor", "Saving the VIP's tag colors here", CookieAccess_Protected);
	g_hVIPNameColor = RegClientCookie("VIPSystemNameColor", "Saving the VIP's name colors here", CookieAccess_Protected);
	g_hVIPChatColor = RegClientCookie("VIPSystemChatColor", "Saving the VIP's chat colors here", CookieAccess_Protected);
	//Custom Tags From Menu
	AddCommandListener(OnSay, "say");
	AddCommandListener(OnSay, "say_team");
	//Hooks
	HookEvent("player_spawn", player_spawn);
	HookEvent("round_start", rounds);
	HookEvent("round_end", rounds);
	//Commands
	RegAdminCmd("sm_addvip", Command_AddVIP, ADMFLAG_ROOT);
	RegAdminCmd("sm_removevip", Command_RemoveVIP, ADMFLAG_ROOT);
	RegConsoleCmd("sm_vip", Command_VIPMenu);
	RegConsoleCmd("sm_vips", Command_VIPMenu);
	RegConsoleCmd("sm_tag", Command_Tag);
	RegConsoleCmd("sm_tagcolor", Command_TagColor);
	RegConsoleCmd("sm_namecolor", Command_NameColor);
	RegConsoleCmd("sm_chatcolor", Command_ChatColor);
	RegConsoleCmd("sm_clantag", Command_ClanTag);
	RegConsoleCmd("sm_skins", Command_Skins);
	//For expire and time left
	CreateTimer(1.0, Timer_CheckPlayersTime, _, TIMER_REPEAT);
}
//Natives
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CSGOVIP_SetVIP", Native_SetVIP);
	CreateNative("CSGOVIP_IsClientVIP", Native_IsClientVIP);
	return APLRes_Success;
}
public int Native_SetVIP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	bool test = GetNativeCell(2);
	g_bIsClientVIP[client] = test;
	return true;
}
public int Native_IsClientVIP(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	}
	return g_bIsClientVIP[client];
}
//Convars
public void OnCvarChange_Enabled(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	if (StrEqual(newvalue, "1"))
		g_bEnabled = true;
	else if (StrEqual(newvalue, "0"))
		g_bEnabled = false;
}
public void OnCvarChange_Skins(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	if (StrEqual(newvalue, "1"))
		g_bSkins = true;
	else if (StrEqual(newvalue, "0"))
		g_bSkins = false;
}
public void OnCvarChange_Health(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	if (StrEqual(newvalue, "1"))
		g_bHP = true;
	else if (StrEqual(newvalue, "0"))
		g_bHP = false;
}
public void OnCvarChange_Defuse(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	if (StrEqual(newvalue, "1"))
		g_bDefuse = true;
	else if (StrEqual(newvalue, "0"))
		g_bDefuse = false;
}
public void OnCvarChange_Armor(ConVar cvar, char[] oldvalue, char[] newvalue)
{
	if (StrEqual(newvalue, "1"))
		g_bFullArmor = true;
	else if (StrEqual(newvalue, "0"))
		g_bFullArmor = false;
}
//Voids
public void OnMapStart()
{
	//Player Skins
	g_iSkins = 0;
	GetSkins();
}
//Check Players
public Action Timer_CheckPlayersTime(Handle timer)
{
	for (int i = 0; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}
public void OnClientPutInServer(int client)
{
	if (!IsValidClient(client) || IsFakeClient(client))
	{
		return;
	}
	if (DB == null)
	{
		return;
	}
	char playername[MAX_NAME_LENGTH], steamid[32];
	GetClientName(client, playername, MAX_NAME_LENGTH);
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, 32))
	{
		KickClient(client, "Verification problem please reconnect.");
		return;
	}
	
	int iLength = ((strlen(playername) * 2) + 1);
	char[] escapedname = new char[iLength];
	DB.Escape(playername, escapedname, iLength);
	
	char gB_ClientIP[64];
	GetClientIP(client, gB_ClientIP, 64);
	
	char gB_Query[512];
	FormatEx(gB_Query, sizeof(gB_Query), "SELECT COUNT(*) FROM `users` WHERE expiredate > NOW() AND `steamid` = '%s'", steamid);
	DB.Query(SQL_SelectPlayer_Callback, gB_Query, GetClientSerial(client), DBPrio_Normal);
	//Other
	Format(g_sTag[client], sizeof(g_sTag), "");
	Format(g_sClanTag[client], sizeof(g_sTag), "");
	char test[512];
	GetClientCookie(client, g_hVIPTag, test, sizeof(test));
	if (!StrEqual(test, "") && !StrEqual(test, "none"))
		Format(g_sTag[client], sizeof(test), test);
	GetClientCookie(client, g_hVIPClanTag, g_sClanTag[client], 512);
	GetClientCookie(client, g_hVIPTagColor, test, sizeof(test));
	if (!StrEqual(test, ""))
		Format(g_sTagColor[client], sizeof(test), test);
	
	GetClientCookie(client, g_hVIPNameColor, test, sizeof(test));
	if (!StrEqual(test, ""))
		Format(g_sNameColor[client], sizeof(test), test);
	
	GetClientCookie(client, g_hVIPChatColor, test, sizeof(test));
	if (!StrEqual(test, ""))
		Format(g_sChatColor[client], sizeof(test), test);
}
public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	char steamid[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, 32))
	{
		return;
	}
	if (!g_bIsClientVIP[client])
	{
		SQL_RemoveVIP(steamid);
	}
	if (g_bIsClientVIP[client])
	{
		SetHudTextParams(0.05, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				ShowHudText(i, -1, "VIP %N has disconnected from the server!", client);
			}
		}
		g_bIsClientVIP[client] = false;
	}
	Format(g_sTag[client], sizeof(g_sTag), "");
	Format(g_sClanTag[client], sizeof(g_sTag), "");
}
//Staff
public Action OnSay(int client, const char[] command, int args)
{
	char text[4096];
	GetCmdArgString(text, sizeof(text));
	StripQuotes(text);
	if (g_bIsTypingTag[client])
	{
		if (StrEqual(text, "!cancel") || StrEqual(text, "/cancel"))
		{
			PrintToChat(client, "%sTag Type Aborted", prefix);
			g_bIsTypingTag[client] = false;
		}
		else {
			Format(g_sTag[client], sizeof(g_sTag), text);
			g_bIsTypingTag[client] = false;
			if (StrEqual(text, "none"))
				PrintToChat(client, "%sYou just reset your tag!", prefix);
			else
				PrintToChat(client, "%sYou changed your tag to '%s'", prefix, text);
			
			SetClientCookie(client, g_hVIPTag, g_sTag[client]);
		}
		return Plugin_Handled;
	}
	if (g_bIsTypingClanTag[client])
	{
		if (StrEqual(text, "!cancel") || StrEqual(text, "/cancel"))
		{
			PrintToChat(client, "%sClan Tag Type Aborted", prefix);
			g_bIsTypingClanTag[client] = false;
		}
		else {
			Format(g_sClanTag[client], sizeof(g_sTag), text);
			g_bIsTypingClanTag[client] = false;
			if (StrEqual(text, "none"))
				PrintToChat(client, "%sYou just reset your clan tag!", prefix);
			else
			{
				PrintToChat(client, "%sYou changed your clan tag to '%s'", prefix, text);
				CS_SetClientClanTag(client, g_sClanTag[client]);
			}
			SetClientCookie(client, g_hVIPClanTag, g_sClanTag[client]);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action rounds(Event event, char[] name, bool dontBroadcast)
{
	if (StrEqual(name, "round_start"))
		g_iRounds++;
}
public Action player_spawn(Event event, char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (g_bIsClientVIP[client])
	{
		if (g_bArmor[client] && g_bFullArmor)
		{
			SetEntProp(client, Prop_Send, "m_ArmorValue", 100, 1);
			SetEntProp(client, Prop_Send, "m_bHasHelmet", 1);
			PrintToChat(client, "%sYou spawned with \x04Full Armor\x01!", prefix);
		}
		if (g_bHealth[client] && g_bHP)
		{
			int hp = GetClientHealth(client);
			SetEntityHealth(client, hp + 10);
			PrintToChat(client, "%sYou recived a\x04 10 HP Bonus\x01!", prefix);
		}
		if (GetClientTeam(client) == CS_TEAM_CT && g_bDefusekit[client] && g_bDefuse)
		{
			PrintToChat(client, "%sYou recived a \x04defuse kit!", prefix);
			SetEntProp(client, Prop_Send, "m_bHasDefuser", 1);
		}
		if (!StrEqual(g_sClanTag[client], "") && !StrEqual(g_sClanTag[client], "none"))
		{
			CS_SetClientClanTag(client, g_sClanTag[client]);
		}
		if (!StrEqual(g_sClientSkin[client], "") && g_bSkins)
			CreateTimer(1.1, Timer_ApplySkin, client);
	}
}
//Commands
public Action Command_Skins(int client, int args)
{
	if (!g_bEnabled)
	{
		PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bSkins)
	{
		PrintToChat(client, "%sThe \x07Player Skins \x03option is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bIsClientVIP[client])
	{
		PrintToChat(client, "%sThis command is for \x05VIP \x01only!", prefix);
		return Plugin_Handled;
	}
	Menu menu = CreateMenu(SkinsMenu);
	menu.SetTitle("VIP Skins - Choose A Skin");
	char sTest[512];
	Format(sTest, sizeof(sTest), "%s", g_sClientSkin[client]);
	if (StrEqual(sTest, ""))
		menu.AddItem("", "Default Skin[Equipped]");
	else
		menu.AddItem("", "Default Skin");
	for (int i = 1; i <= g_iSkins; i++)
	{
		if (StrEqual(sModel[i], sTest) && !StrEqual(sTest, ""))
		{
			char sNoName[512];
			Format(sNoName, sizeof(sNoName), "%s[Equipped]", sName[i]);
			menu.AddItem(sModel[i], sNoName);
		}
		else
			menu.AddItem(sModel[i], sName[i]);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}
public int SkinsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		if (!g_bEnabled)
		{
			PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
			return;
		}
		if (!g_bSkins)
		{
			PrintToChat(client, "%sThe \x07Player Skins \x03option is disabled right now!", prefix);
			return;
		}
		char sTest[512];
		menu.GetItem(itemNum, sTest, sizeof(sTest));
		menu.GetItem(itemNum, g_sClientSkin[client], 512);
		if (itemNum == 0)
			PrintToChat(client, "%sSuccessfuly Changed Your Player Skin To Default Skin!", prefix);
		else
			PrintToChat(client, "%sSuccessfuly Changed Your Player Skin To \"%s\"!", prefix, sName[itemNum]);
		
		menu.Display(client, MENU_TIME_FOREVER);
	}
}
public Action Command_Tag(int client, int args)
{
	if (!g_bEnabled)
	{
		PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bIsClientVIP[client])
	{
		PrintToChat(client, "%sThis command is for \x07VIP \x03members only!", prefix);
		return Plugin_Handled;
	}
	if (args == 0)
	{
		PrintToChat(client, "%sWrong usage: sm_tag <Text | None = reset tag>", prefix);
		return Plugin_Handled;
	}
	char arg[512];
	GetCmdArgString(arg, sizeof(arg));
	Format(g_sTag[client], sizeof(arg), arg);
	SetClientCookie(client, g_hVIPTag, g_sTag[client]);
	if (StrEqual(arg, "none"))
		PrintToChat(client, "%sYou just reset your tag!", prefix);
	else
		PrintToChat(client, "%sYou changed your tag to '%s'", prefix, arg);
	return Plugin_Handled;
}
public Action Command_TagColor(int client, int args)
{
	if (!g_bEnabled)
	{
		PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bIsClientVIP[client])
	{
		PrintToChat(client, "%sThis command is for \x07VIP \x03members only!", prefix);
		return Plugin_Handled;
	}
	Menu menu = CreateMenu(TagMenu);
	menu.SetTitle("Choose Your Color");
	menu.AddItem("\x03", "Default");
	menu.AddItem("\x02", "Strong Red");
	menu.AddItem("\x03", "Team Color");
	menu.AddItem("\x04", "Green");
	menu.AddItem("\x05", "Turquoise");
	menu.AddItem("\x06", "Yellow-Green");
	menu.AddItem("\x07", "Light Red");
	menu.AddItem("\x08", "Gray");
	menu.AddItem("\x09", "Light Yellow");
	menu.AddItem("\x0A", "Light Blue");
	menu.AddItem("\x0C", "Purple");
	menu.AddItem("\x0E", "Pink");
	menu.AddItem("\x10", "Orange");
	menu.Display(client, 30);
	return Plugin_Handled;
}
public int TagMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		if (!g_bEnabled)
		{
			PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
			return;
		}
		char info[64], sItemName[64];
		GetMenuItem(menu, itemNum, info, sizeof(info), _, sItemName, sizeof(sItemName));
		Format(g_sTagColor[client], sizeof(g_sTagColor), info);
		PrintToChat(client, "%sYou changed your tag color to %s%s", prefix, info, sItemName);
		SetClientCookie(client, g_hVIPTagColor, g_sTagColor[client]);
		menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
}
public Action Command_NameColor(int client, int args)
{
	if (!g_bEnabled)
	{
		PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bIsClientVIP[client])
	{
		PrintToChat(client, "%sThis command is for \x07VIP \x03members only!", prefix);
		return Plugin_Handled;
	}
	Menu menu = CreateMenu(NameMenu);
	menu.SetTitle("Choose Your Color");
	menu.AddItem("\x03", "Default");
	menu.AddItem("\x02", "Strong Red");
	menu.AddItem("\x03", "Team Color");
	menu.AddItem("\x04", "Green");
	menu.AddItem("\x05", "Turquoise");
	menu.AddItem("\x06", "Yellow-Green");
	menu.AddItem("\x07", "Light Red");
	menu.AddItem("\x08", "Gray");
	menu.AddItem("\x09", "Light Yellow");
	menu.AddItem("\x0A", "Light Blue");
	menu.AddItem("\x0C", "Purple");
	menu.AddItem("\x0E", "Pink");
	menu.AddItem("\x10", "Orange");
	menu.Display(client, 30);
	return Plugin_Handled;
}
public int NameMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		if (!g_bEnabled)
		{
			PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
			return;
		}
		char info[64], sItemName[64];
		GetMenuItem(menu, itemNum, info, sizeof(info), _, sItemName, sizeof(sItemName));
		Format(g_sNameColor[client], sizeof(g_sNameColor), info);
		PrintToChat(client, "%sYou changed your name color to %s%s", prefix, info, sItemName);
		SetClientCookie(client, g_hVIPNameColor, g_sNameColor[client]);
		menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
}
public Action Command_ChatColor(int client, int args)
{
	if (!g_bEnabled)
	{
		PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bIsClientVIP[client])
	{
		PrintToChat(client, "%sThis command is for \x07VIP \x03members only!", prefix);
		return Plugin_Handled;
	}
	Menu menu = CreateMenu(ChatMenu);
	menu.SetTitle("Choose Your Color");
	menu.AddItem("\x01", "Default");
	menu.AddItem("\x02", "Strong Red");
	menu.AddItem("\x03", "Team Color");
	menu.AddItem("\x04", "Green");
	menu.AddItem("\x05", "Turquoise");
	menu.AddItem("\x06", "Yellow-Green");
	menu.AddItem("\x07", "Light Red");
	menu.AddItem("\x08", "Gray");
	menu.AddItem("\x09", "Light Yellow");
	menu.AddItem("\x0A", "Light Blue");
	menu.AddItem("\x0C", "Purple");
	menu.AddItem("\x0E", "Pink");
	menu.AddItem("\x10", "Orange");
	menu.Display(client, 30);
	return Plugin_Handled;
}
public int ChatMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		if (!g_bEnabled)
		{
			PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
			return;
		}
		char info[64], sItemName[64];
		GetMenuItem(menu, itemNum, info, sizeof(info), _, sItemName, sizeof(sItemName));
		Format(g_sChatColor[client], sizeof(g_sChatColor), info);
		PrintToChat(client, "%sYou changed your chat color to %s%s", prefix, info, sItemName);
		SetClientCookie(client, g_hVIPChatColor, g_sChatColor[client]);
		menu.DisplayAt(client, GetMenuSelectionPosition(), MENU_TIME_FOREVER);
	}
}
public Action Command_ClanTag(int client, int args)
{
	if (!g_bEnabled)
	{
		PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bIsClientVIP[client])
	{
		PrintToChat(client, "%sThis command is for \x07VIP \x03members only!", prefix);
		return Plugin_Handled;
	}
	if (args == 0)
	{
		PrintToChat(client, "%sWrong usage: sm_clantag <Text | None=reset>", prefix);
		return Plugin_Handled;
	}
	char arg[512];
	GetCmdArgString(arg, sizeof(arg));
	Format(g_sClanTag[client], sizeof(arg), arg);
	CS_SetClientClanTag(client, g_sClanTag[client]);
	SetClientCookie(client, g_hVIPClanTag, g_sClanTag[client]);
	if (StrEqual(arg, "none"))
		PrintToChat(client, "%sYou just reset your tag!", prefix);
	else
		PrintToChat(client, "%sYou changed your tag to '%s'", prefix, arg);
	return Plugin_Handled;
}
public Action Command_VIPMenu(int client, int args)
{
	if (!g_bEnabled)
	{
		PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
		return Plugin_Handled;
	}
	if (!g_bIsClientVIP[client])
	{
		PrintToChat(client, "%sThis command is for \x07VIP \x03members only!", prefix);
		return Plugin_Handled;
	}
	ShowVIPMenu(client, 0);
	return Plugin_Handled;
}
public int VIPMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		if (!g_bEnabled)
		{
			PrintToChat(client, "%sThe \x07VIP System \x03is disabled right now!", prefix);
			return;
		}
		char info[64];
		GetMenuItem(menu, itemNum, info, sizeof(info));
		if (StrEqual(info, "skins"))
		{
			FakeClientCommand(client, "say /skins");
		}
		if (StrEqual(info, "clantag"))
		{
			PrintToChat(client, "%sType your clan tag in the chat or type !cancel to abort(Tip: type 'none' to reset your clan tag)", prefix);
			g_bIsTypingClanTag[client] = true;
			ShowVIPMenu(client, itemNum);
		}
		if (StrEqual(info, "tag"))
		{
			PrintToChat(client, "%sType your tag in the chat or type !cancel to abort(Tip: type 'none' to reset your tag)", prefix);
			g_bIsTypingTag[client] = true;
			ShowVIPMenu(client, itemNum);
		}
		if (StrEqual(info, "tagcolor"))
		{
			FakeClientCommand(client, "say /tagcolor");
		}
		if (StrEqual(info, "namecolor"))
		{
			FakeClientCommand(client, "say /namecolor");
		}
		if (StrEqual(info, "chatcolor"))
		{
			FakeClientCommand(client, "say /chatcolor");
		}
		if (StrEqual(info, "armor"))
		{
			if (g_bArmor[client])g_bArmor[client] = false;
			else g_bArmor[client] = true;
			PrintToChat(client, "%sYou just %s \x01the Full Armor bonus!", prefix, g_bArmor[client] ? "\x04Enabled" : "\x02Disabled");
			ShowVIPMenu(client, itemNum);
		}
		if (StrEqual(info, "health"))
		{
			if (g_bHealth[client])g_bHealth[client] = false;
			else g_bHealth[client] = true;
			PrintToChat(client, "%sYou just %s \x01the 10 HP bonus!", prefix, g_bHealth[client] ? "\x04Enabled" : "\x02Disabled");
			ShowVIPMenu(client, itemNum);
		}
		if (StrEqual(info, "defuse"))
		{
			if (g_bDefusekit[client])g_bDefusekit[client] = false;
			else g_bDefusekit[client] = true;
			PrintToChat(client, "%sYou just %s \x01the Defuse Kit bonus!", prefix, g_bDefusekit[client] ? "\x04Enabled" : "\x02Disabled");
			ShowVIPMenu(client, itemNum);
		}
	}
}
stock void ShowVIPMenu(int client, int itemNum)
{
	Menu menu = CreateMenu(VIPMenu);
	menu.SetTitle("VIP Menu [%d Days Left]\n ", g_iTimeLeft[client]);
	menu.AddItem("skins", "VIP Player Skins", g_bSkins ? 0 : 1);
	menu.AddItem("clantag", "Manage Clan Tag");
	menu.AddItem("tag", "Manage Chat Tag");
	menu.AddItem("tagcolor", "Manage Tag Color");
	menu.AddItem("namecolor", "Manage Name Color");
	menu.AddItem("chatcolor", "Manage Chat Color");
	if (g_bArmor[client])
		menu.AddItem("armor", "Disable Full Armor", g_bFullArmor ? 0 : 1);
	else
		menu.AddItem("armor", "Enable Full Armor", g_bFullArmor ? 0 : 1);
	if (g_bHealth[client])
		menu.AddItem("health", "Disable 10 HP Bonus", g_bHP ? 0 : 1);
	else
		menu.AddItem("health", "Enable 10 HP Bonus", g_bHP ? 0 : 1);
	if (g_bDefusekit[client])
		menu.AddItem("defuse", "Disable Defuse Kit Bonus", g_bDefuse ? 0 : 1);
	else
		menu.AddItem("defuse", "Enable Defuse Kit Bonus", g_bDefuse ? 0 : 1);
	menu.AddItem("", "Automatic Perks:", ITEMDRAW_DISABLED);
	menu.AddItem("", "Connect & Disconnect Messages", ITEMDRAW_DISABLED);
	menu.AddItem("", "Reserved Slots", ITEMDRAW_DISABLED);
	menu.AddItem("", "V.I.P Tag In Chat", ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
}
public Action Command_AddVIP(int client, int args)
{
	if (args != 2)
		PrintToChat(client, "%sWrong usage: sm_addvip <name | steamid> <days>", prefix);
	else {
		char arg1[64], arg2[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		if (StrContains(arg1, "STEAM_", false) != -1)
		{
			int time = StringToInt(arg2);
			int time2 = time * 1440;
			PrintToChat(client, "%sSteamID '%s' was added to a VIP for %d days!", prefix, arg1, time);
			SQL_AddVIP_Steamid(arg1, time2);
		}
		else
		{
			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			
			if ((target_count = ProcessTargetString(
						arg1, 
						client, 
						target_list, 
						MAXPLAYERS, 
						0, 
						target_name, 
						sizeof(target_name), 
						tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for (int i = 0; i < target_count; i++)
			{
				int time = StringToInt(arg2);
				g_bIsClientVIP[target_list[i]] = true;
				//Info
				char playername[MAX_NAME_LENGTH], steamid[32];
				GetClientName(target_list[i], playername, MAX_NAME_LENGTH);
				if (!GetClientAuthId(target_list[i], AuthId_Steam2, steamid, 32))
				{
					PrintToChat(client, "%sError execued while getting target's info", prefix);
					return Plugin_Handled;
				}
				
				int iLength = ((strlen(playername) * 2) + 1);
				char[] escapedname = new char[iLength];
				DB.Escape(playername, escapedname, iLength);
				
				char gB_ClientIP[64];
				GetClientIP(target_list[i], gB_ClientIP, 64);
				//End of info
				UpdatePlayer(target_list[i], time);
				//Message
				SetHudTextParams(0.05, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
				for (int targets = 1; targets <= MaxClients; targets++)
				{
					if (IsValidClient(targets))
					{
						ShowHudText(targets, -1, "%N is now a VIP!", target_list[i]);
					}
				}
				//Confirm MSG
				PrintToChat(client, "%s%N has been added to a VIP for %d days!", prefix, target_list[i], time);
			}
		}
	}
	return Plugin_Handled;
}
public Action Command_RemoveVIP(int client, int args)
{
	if (args != 1)
		PrintToChat(client, "%sWrong usage: sm_removevip <name | steamid> ", prefix);
	else {
		char arg1[64];
		GetCmdArg(1, arg1, sizeof(arg1));
		if (StrContains(arg1, "STEAM_", false) != -1)
		{
			SQL_RemoveVIP(arg1);
			PrintToChat(client, "%sSteamID '%s' has been removed from a VIP", prefix, arg1);
		}
		else
		{
			char target_name[MAX_TARGET_LENGTH];
			int target_list[MAXPLAYERS], target_count;
			bool tn_is_ml;
			
			if ((target_count = ProcessTargetString(
						arg1, 
						client, 
						target_list, 
						MAXPLAYERS, 
						0, 
						target_name, 
						sizeof(target_name), 
						tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				return Plugin_Handled;
			}
			
			for (int i = 0; i < target_count; i++)
			{
				char steamid[64];
				if (!GetClientAuthId(target_list[i], AuthId_Steam2, steamid, 32))
				{
					PrintToChat(client, "%sError execued while getting target's info", prefix);
					return Plugin_Handled;
				}
				SQL_RemoveVIP(steamid);
				g_bIsClientVIP[target_list[i]] = false;
				PrintToChat(client, "%s%N has been removed from a VIP", prefix, target_list[i]);
			}
		}
	}
	return Plugin_Handled;
}
//Database
void UpdatePlayer(int client, int days)
{
	if (DB == null)
	{
		return;
	}
	char gB_Query[512], steamid[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, 32))
	{
		return;
	}
	FormatEx(gB_Query, sizeof(gB_Query), "INSERT INTO `users` (`expiredate`, `steamid`) VALUES (NOW() + INTERVAL %d DAY, '%s') ON DUPLICATE KEY UPDATE `expiredate` = NOW() + INTERVAL %d DAY;", days, steamid, days);
	DB.Query(SQL_UpdatePlayer_Callback, gB_Query, GetClientSerial(client), DBPrio_Normal);
}
void SQL_AddVIP_Steamid(const char[] steamid, int minutes)
{
	if (DB == null)
	{
		return;
	}
	char gB_Query[512];
	char test[512];
	Format(test, sizeof(test), "NOW() + INTERVAL %d MINUTE", minutes);
	FormatEx(gB_Query, sizeof(gB_Query), "INSERT INTO `users` (`expiredate`, `steamid`) VALUES (%s, '%s') ON DUPLICATE KEY UPDATE `expiredate` = %s;", test, steamid, test);
	DB.Query(SQL_UpdatePlayer_Callback2, gB_Query, _, DBPrio_Normal);
}
public void SQL_UpdatePlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientFromSerial(data);
	if (results == null)
	{
		if (client == 0)
		{
			LogError("[Line 873] Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("[Line 877] Cant use client data. Reason: %s", error);
		}
		return;
	}
}
public void SQL_UpdatePlayer_Callback2(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[Line 886] Cant use client data. Reason: %s", error);
		return;
	}
}
void SQL_StartConnection()
{
	if (DB != null)
	{
		delete DB;
	}
	
	char gB_Error[255];
	if (SQL_CheckConfig("vipsystem"))
	{
		DB = SQL_Connect("vipsystem", true, gB_Error, 255);
		
		if (DB == null)
		{
			SetFailState("[CSGOVIP] Error on start. Reason: %s", gB_Error);
		}
	}
	else
	{
		SetFailState("[CSGOVIP] Cant find `vipsystem` on database.cfg");
	}
	
	DB.SetCharset("utf8");
	
	char gB_Query[512];
	FormatEx(gB_Query, sizeof(gB_Query), "CREATE TABLE IF NOT EXISTS `users`( `steamid` VARCHAR(32) NOT NULL PRIMARY KEY, `expiredate` DATETIME NOT NULL, UNIQUE (`steamid`));");
	if (!SQL_FastQuery(DB, gB_Query))
	{
		SQL_GetError(DB, gB_Error, 255);
		LogError("[CSGOVIP] Cant create table. Error : %s", gB_Error);
	}
}
void SQL_RemoveVIP(const char[] steamid)
{
	char gB_Query[512];
	FormatEx(gB_Query, sizeof(gB_Query), "DELETE FROM `users` WHERE `steamid` = '%s'", steamid);
	DB.Query(SQL_RemovePlayer_Callback, gB_Query, DBPrio_Normal);
}
public void SQL_RemovePlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("Error: %s", error);
		return;
	}
}
/*public void SQL_InsertPlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[CSGOVIP] DB Error: Reason: %s", error);
		return;
	}
	int client = GetClientFromSerial(data);
	if (client == 0)
	{
		LogError("[CSGOVIP] Client is not valid. Reason: %s", error);
		return;
	}
	while (results.FetchRow()) {
		g_bIsClientVIP[client] = true;
		g_iClientTime[client] = -1;
		SetHudTextParams(0.05, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				ShowHudText(i, -1, "VIP %N has connected to the server!", client);
			}
		}
		if (GetMaxHumanPlayers() < GetOnlineUsers())
		{
			int iRandom = GetRandomPlayer();
			KickClient(iRandom, "You were kicked to make a space for a V.I.P user!");
		}
	}
	if (SQL_GetRowCount(results) == 0)
	{
		char steamid[64];
		if (!GetClientAuthId(client, AuthId_Steam2, steamid, 32))
		{
			return;
		}
		SQL_RemoveVIP(steamid);
	}
	if (!g_bIsClientVIP[client] && GetMaxHumanPlayers() < GetOnlineUsers() && g_iRounds > 1)
	{
		KickClient(client, "Server is full, buy a V.I.P to join the server while full.");
		return;
	}
}*/
public void SQL_SelectPlayer_Callback(Database db, DBResultSet results, const char[] error, any data)
{
	if (results == null)
	{
		LogError("[CSGOVIP] Selecting player error. Reason: %s", error);
		return;
	}
	
	int client = GetClientFromSerial(data);
	if (client == 0)
	{
		LogError("[Line 992] Client is not valid. Reason: %s", error);
		return;
	}
	char steamid[32];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, 32))
	{
		return;
	}
	while (results.FetchRow())
	{
		int iCount = results.FetchInt(0);
		if (!g_bIsClientVIP[client]) {  //Client connected now
			if (iCount != 0)
			{
				g_bIsClientVIP[client] = true;
				SetHudTextParams(0.05, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i))
					{
						ShowHudText(i, -1, "VIP %N has connected to the server!", client);
					}
				}
			}
			if (iCount == 0 && GetMaxHumanPlayers() < GetOnlineUsers() && g_iRounds > 1)
			{
				KickClient(client, "Server is full, buy a V.I.P to join the server while full.");
				return;
			}
			if (iCount != 0 && GetMaxHumanPlayers() < GetOnlineUsers())
			{
				int iRandom = GetRandomPlayer();
				KickClient(iRandom, "You were kicked to make a space for a V.I.P user!");
			}
			CheckTimeLeft(client);
		}
		else {
			if (g_bIsClientVIP[client] && iCount == 0)
			{
				PrintToChat(client, "%sYour \x07VIP \x03has expired!", prefix);
				g_bIsClientVIP[client] = false;
				return;
			}
			CheckTimeLeft(client);
		}
	}
}
stock void CheckTimeLeft(int client)
{
	if (!IsValidClient(client))return;
	char authid[64];
	if (!GetClientAuthId(client, AuthId_Steam2, authid, 32))
	{
		return;
	}
	char gB_Query[512];
	FormatEx(gB_Query, sizeof(gB_Query), "SELECT TIMESTAMPDIFF(DAY, NOW(), expiredate) FROM `users` WHERE `steamid` = '%s';", authid);
	DB.Query(SQL_VIPTime, gB_Query, GetClientSerial(client), DBPrio_Normal);
}
public void SQL_VIPTime(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientFromSerial(data);
	if (results == null)
	{
		if (client == 0)
		{
			LogError("[Line 1058] Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("[CSGOVIP] Cant use client data on insert. Reason: %s", error);
		}
		return;
	}
	while (results.FetchRow())
	{
		g_iTimeLeft[client] = results.FetchInt(0);
	}
}
//Timers
//Apply Skin
public Action Timer_ApplySkin(Handle timer, any client)
{
	char sTest[512];
	Format(sTest, sizeof(sTest), "%s", g_sClientSkin[client]) // Should fix crashes
	if (StrEqual(sTest, ""))return;
	PrecacheModel(sTest);
	SetEntityModel(client, sTest);
}
//Chat
public Action OnChatMessage(&author, Handle recipients, char[] name, char[] message)
{
	if (g_bIsClientVIP[author])
	{
		if (StrEqual(g_sTag[author], "") || StrEqual(g_sTag[author], "none"))
			Format(name, MAX_NAME_LENGTH, " %s[V.I.P] \x03%s%s", g_sTagColor[author], g_sNameColor[author], name);
		else
			Format(name, MAX_NAME_LENGTH, " %s[%s] \x03%s%s", g_sTagColor[author], g_sTag[author], g_sNameColor[author], name);
		Format(message, MAXLENGTH_MESSAGE, "%s%s", g_sChatColor[author], message);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
//Stocks
stock void GetSkins()
{
	char sPath[512];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/vipskins.txt");
	if (!FileExists(sPath))SetFailState("[CSGOVIP] - Couldn't Find configs/vipskins.txt");
	KeyValues kConfig = new KeyValues("");
	kConfig.ImportFromFile(sPath);
	
	kConfig.JumpToKey("Skins");
	kConfig.GotoFirstSubKey();
	do {
		g_iSkins++;
		kConfig.GetString("name", sName[g_iSkins], 512);
		kConfig.GetString("location", sModel[g_iSkins], 512);
		AddFileToDownloadsTable(sModel[g_iSkins]);
	} while (kConfig.GotoNextKey());
}
stock int GetRandomPlayer()
{
	new clients[MaxClients + 1], clientCount;
	for (int i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsValidClient(i) && !CheckCommandAccess(i, "", ADMFLAG_GENERIC) && !g_bIsClientVIP[i])
		clients[clientCount++] = i;
	return (clientCount == 0) ? -1 : clients[GetRandomInt(0, clientCount - 1)];
}
stock int GetOnlineUsers()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			iCount++;
	}
	return iCount;
}
stock bool IsValidClient(int client, bool alive = false, bool bots = false)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)) && (bots == false && !IsFakeClient(client)))
	{
		return true;
	}
	return false;
} 