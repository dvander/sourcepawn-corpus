#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <chat-processor>

#pragma newdecls required

#define PREFIX " \x04[VIP]\x01"
#define PREFIX_MENU "[VIP]"
#define CTARMS "models/weapons/ct_arms.mdl" 
#define TARMS "models/weapons/t_arms.mdl" 
#define MAX_SKINS 64

enum SkinSettings
{
	Skin_Name = 0, 
	Skin_Model, 
	Skin_Arms, 
	Skin_Team
}

enum SkinTeam
{
	Skin_Team_T = 0, 
	Skin_Team_CT
}

enum ColorType
{
	Color_Tag = 0, 
	Color_Name, 
	Color_Chat
}

enum TagType
{
	Tag_Chat = 0, 
	Tag_Clan
}

enum
{
	TagEdit_None = 0, 
	TagEdit_Chat, 
	TagEdit_Clan
}

Database g_dDatabase = null;

ConVar g_cHealthBonus;
ConVar g_cArmorBonus;
ConVar g_cPistolBonus;
ConVar g_cPlayerSkins;
ConVar g_cTablePrefix;
ConVar g_cVipFlags;

ArrayList g_aBlockedTags;

char g_szSkins[MAX_SKINS][SkinSettings][512];
char g_szAuth[MAXPLAYERS + 1][32];
char g_szColors[MAXPLAYERS + 1][ColorType][16];
char g_szPlayerTags[MAXPLAYERS + 1][TagType][256];
char g_szPlayerSkins[MAXPLAYERS + 1][SkinTeam][512];

bool g_bVIP[MAXPLAYERS + 1];
bool g_bHealth[MAXPLAYERS + 1];
bool g_bArmor[MAXPLAYERS + 1];

int g_iRoundsPassed = 0;
int g_iSkins = 0;
int g_iTagEditing[MAXPLAYERS + 1];
int g_iDaysLeft[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[CS:GO] VIPCore", 
	author = "S4muRaY'", 
	description = "", 
	version = "1.0", 
	url = "http://steamcommunity.com/id/s4muray"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	g_cHealthBonus = CreateConVar("sm_vip_health", "10", "Health bonus amount, 0 = Disable", 0, true, 0.0);
	g_cArmorBonus = CreateConVar("sm_vip_armor", "1", "Enable the armor bonus? 0 = Disable, 1 = Enable", 0, true, 0.0, true, 1.0);
	g_cPistolBonus = CreateConVar("sm_vip_pistol", "1", "Enable the pistol bonus? 0 = Disable, 1 = Enable", 0, true, 0.0, true, 1.0);
	g_cPlayerSkins = CreateConVar("sm_vip_skins", "1", "Enable the player skins? 0 = Disable, 1 = Enable", 0, true, 0.0, true, 1.0);
	g_cTablePrefix = CreateConVar("sm_vip_table_prefix", "vip", "Prefix for the database table (Default: vip)");
	g_cVipFlags = CreateConVar("sm_vip_flags", "", "Flags to give the vip users, empty for nothing");
	
	AutoExecConfig();
	
	SQL_MakeConnection(); //The table cvar required in here
	
	g_aBlockedTags = new ArrayList(64);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart);
	
	RegAdminCmd("sm_addvip", Command_AddVIP, ADMFLAG_ROOT, "Gives a vip access");
	RegAdminCmd("sm_removevip", Command_RemoveVIP, ADMFLAG_ROOT, "Removes a vip access");
	RegConsoleCmd("sm_vip", Command_VIPMenu, "Opens the vip menu");
}

/* Natives */

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("VIP_IsVIP", Native_IsVip);
	
	RegPluginLibrary("VIPCore");
	return APLRes_Success;
}

public int Native_IsVip(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if (client < 1 || client > MaxClients)
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%i)", client);
	}
	if (!IsClientConnected(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %i is not connected", client);
	}
	return g_bVIP[client];
}

/* Hooks, Events */

public void OnMapStart()
{
	g_iRoundsPassed = 0;
	g_iSkins = 0;
	LoadSkins();
	LoadBlockedTags();
}

public void OnClientPostAdminCheck(int client)
{
	if (!GetClientAuthId(client, AuthId_Steam2, g_szAuth[client], sizeof(g_szAuth)))
	{
		KickClient(client, "Verification problem, Please reconnect");
		return;
	}
	
	SQL_FetchUser(client);
}

public void OnClientDisconnect(int client)
{
	if (g_bVIP[client])
	{
		SetHudTextParams(-1.0, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				ShowHudText(i, 0, "VIP %N has disconnected", client);
			}
		}
	}
	
	//Resetting the variables to prevent users to recieve another players' settings(Ex: as tag. clantag, tag color)
	g_bVIP[client] = false;
	g_bHealth[client] = false;
	g_bArmor[client] = false;
	g_szPlayerTags[client][Tag_Chat][0] = 0;
	g_szPlayerTags[client][Tag_Clan][0] = 0;
	g_szColors[client][Color_Tag][0] = 0;
	g_szColors[client][Color_Name][0] = 0;
	g_szColors[client][Color_Chat][0] = 0;
	g_iDaysLeft[client] = 0;
	g_iTagEditing[client] = TagEdit_None;
}

public Action Event_RoundStart(Event event, char[] name, bool dontBroadcast)
{
	g_iRoundsPassed++;
}

public Action Event_PlayerSpawn(Event event, char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (g_bVIP[iClient] && IsPlayerAlive(iClient))
	{
		CS_SetClientClanTag(iClient, g_szPlayerTags[iClient][Tag_Clan]);
		
		if (g_bHealth[iClient] && g_cHealthBonus.IntValue)
		{
			PrintToChat(iClient, "%s You spawned with \x07%i HP Bonus\x01.", PREFIX, g_cHealthBonus.IntValue);
			SetEntityHealth(iClient, GetClientHealth(iClient) + g_cHealthBonus.IntValue);
		}
		
		if (g_bArmor[iClient] && g_cArmorBonus.BoolValue)
		{
			PrintToChat(iClient, "%s You spawned with \x07Full Armor\x01.", PREFIX);
			SetEntProp(iClient, Prop_Send, "m_ArmorValue", 100, 1);
			SetEntProp(iClient, Prop_Send, "m_bHasHelmet", 1);
		}
		
		if (g_cPistolBonus.BoolValue)
			Menus_ShowPistols(iClient);
		
		if (g_cPlayerSkins.BoolValue)
		{
			SkinTeam stTeam = GetClientTeam(iClient) == CS_TEAM_T ? Skin_Team_T:Skin_Team_CT;
			if (!StrEqual(g_szPlayerSkins[iClient][stTeam], ""))
			{
				SetEntityModel(iClient, g_szPlayerSkins[iClient][stTeam]);
				if(!StrEqual(GetSkinArms(g_szPlayerSkins[iClient][stTeam]), ""))
					SetEntPropString(iClient, Prop_Send, "m_szArmsModel", GetSkinArms(g_szPlayerSkins[iClient][stTeam]));
			}
		}
		
	}
}

public Action OnClientSayCommand(int client, const char[] command, const char[] szArgs)
{
	if (g_iTagEditing[client] != TagEdit_None)
	{
		if (StrEqual(szArgs, "-1"))
		{
			PrintToChat(client, "%s Operation aborted.", PREFIX);
			g_iTagEditing[client] = TagEdit_None;
			Menus_ShowGeneric(client);
			return Plugin_Handled;
		}
		
		if (!IsTagAllowed(szArgs))
		{
			PrintToChat(client, "%s This tag contains forbidden words.", PREFIX);
			g_iTagEditing[client] = TagEdit_None;
			Menus_ShowGeneric(client);
			return Plugin_Handled;
		}
		
		if (g_iTagEditing[client] == TagEdit_Chat)
		{
			strcopy(g_szPlayerTags[client][Tag_Chat], sizeof(g_szPlayerTags), szArgs);
		}
		else
		{
			strcopy(g_szPlayerTags[client][Tag_Clan], sizeof(g_szPlayerTags), szArgs);
			CS_SetClientClanTag(client, g_szPlayerTags[client][Tag_Clan]);
		}
		
		SQL_UpdatePerk(client, g_iTagEditing[client] == TagEdit_Chat ? "chatTag":"clanTag", g_iTagEditing[client] == TagEdit_Chat ? g_szPlayerTags[client][Tag_Chat]:g_szPlayerTags[client][Tag_Clan]);
		
		g_iTagEditing[client] = TagEdit_None;
		PrintToChat(client, "%s Successfully changed your %s tag to \x02%s\x01.", PREFIX, g_iTagEditing[client] == TagEdit_Chat ? "chat":"clan", szArgs);
		return Plugin_Handled
	}
	return Plugin_Continue;
}

public Action CP_OnChatMessage(int & author, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool & processcolors, bool & removecolors)
{
	if (g_bVIP[author])
	{
		Format(name, MAX_NAME_LENGTH, " \x01%s[%s] \x03%s%s\x01", g_szColors[author][Color_Tag], (StrEqual(g_szPlayerTags[author][Tag_Chat], "") || StrEqual(g_szPlayerTags[author][Tag_Chat], "none")) ? "V.I.P":g_szPlayerTags[author][Tag_Chat], g_szColors[author][Color_Name], name);
		Format(message, MAXLENGTH_MESSAGE, "%s %s", g_szColors[author][Color_Chat], message);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

/* Commands */

public Action Command_AddVIP(int client, int args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "%s Usage: sm_addvip <#userid|name> <days>", PREFIX);
		return Plugin_Handled;
	}
	
	char szArg[32], szArg2[10];
	GetCmdArg(1, szArg, sizeof(szArg));
	int iTarget = FindTarget(client, szArg, true, true);
	if (iTarget == -1)
		return Plugin_Handled;
	
	GetCmdArg(2, szArg2, sizeof(szArg2));
	int iDays = StringToInt(szArg2);
	
	if (iDays <= 0)
	{
		ReplyToCommand(client, "%s The time must be greater than zero.", PREFIX);
		return Plugin_Handled;
	}
	
	char szStamp[32];
	Format(szStamp, sizeof(szStamp), "%i", GetTime() + (iDays * 86400));
	
	PrintToChat(client, "%s Trying to give \x02%N \x01a vip access...", PREFIX, iTarget);
	
	char szQuery[512];
	if (g_bVIP[iTarget])
		FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sUsers` SET `expireStamp`= '%s' WHERE `authId` = '%s'", GetTablePrefix(), szStamp, g_szAuth[iTarget]);
	else
		FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `%sUsers` (`authId`, `expireStamp`) VALUES ('%s', '%s')", GetTablePrefix(), g_szAuth[iTarget], szStamp);
	g_dDatabase.Query(SQL_CheckForErrors, szQuery, GetClientSerial(iTarget));
	
	SQL_FetchUser(iTarget);
	PrintToChat(client, "%s Successfully gave \x02%N \x01a vip access...", PREFIX, iTarget);
	return Plugin_Handled;
}

public Action Command_RemoveVIP(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "%s Usage: sm_removevip <#userid|name>", PREFIX);
		return Plugin_Handled;
	}
	
	char szArg[32];
	GetCmdArg(1, szArg, sizeof(szArg));
	int iTarget = FindTarget(client, szArg, true, true);
	if (iTarget == -1)
		return Plugin_Handled;
	
	if (!g_bVIP[iTarget])
	{
		ReplyToCommand(client, "%s Target does not have a vip access.", PREFIX);
		return Plugin_Handled;
	}
	
	PrintToChat(client, "%s Trying to remove \x02%N\x01's vip access.", PREFIX, iTarget);
	
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "DELETE FROM `%sUsers` WHERE `authId` = '%s'", GetTablePrefix(), g_szAuth[iTarget]);
	g_dDatabase.Query(SQL_CheckForErrors, szQuery, GetClientSerial(iTarget));
	FormatEx(szQuery, sizeof(szQuery), "DELETE FROM `%sPerks` WHERE `authId` = '%s'", GetTablePrefix(), g_szAuth[iTarget]);
	g_dDatabase.Query(SQL_CheckForErrors, szQuery, GetClientSerial(iTarget));
	
	PrintToChat(client, "%s Successfully removed \x02%N\x01's vip access.", PREFIX, iTarget);
	return Plugin_Handled;
}

public Action Command_VIPMenu(int client, int args)
{
	if (!g_bVIP[client])
	{
		ReplyToCommand(client, "%s This command is for \x02VIP \x01users only.", PREFIX);
		return Plugin_Handled;
	}
	
	Menus_ShowMain(client);
	return Plugin_Handled;
}

/* Menus */

void Menus_ShowMain(int client)
{
	Menu menu = new Menu(Handler_MainMenu);
	menu.SetTitle("%s Main Menu [%i Days Left]\n ", PREFIX_MENU, g_iDaysLeft[client]);
	
	menu.AddItem("generic", "Generic Perks");
	menu.AddItem("special", "Special Perks");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_MainMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		switch (itemNum)
		{
			case 0:Menus_ShowGeneric(client);
			case 1:Menus_ShowSpecial(client);
		}
	}
}

void Menus_ShowGeneric(int client)
{
	Menu menu = new Menu(Handler_GenericMenu);
	menu.SetTitle("%s Generic Menu\n ", PREFIX_MENU);
	
	menu.AddItem("tag", "Manage Chat Tag");
	menu.AddItem("ctag", "Manage Clan Tag");
	menu.AddItem("tagcolor", "Manage Tag Color");
	menu.AddItem("namecolor", "Manage Name Color");
	menu.AddItem("chatcolor", "Manage Chat Color");
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_GenericMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		Menus_ShowMain(client);
	} else if (action == MenuAction_Select) {
		switch (itemNum)
		{
			case 0:
			{
				PrintToChat(client, "%s Type whatever you want in the chat or type \x02-1 \x01to abort.", PREFIX);
				g_iTagEditing[client] = TagEdit_Chat;
			}
			case 1:
			{
				PrintToChat(client, "%s Type whatever you want in the chat or type \x02-1 \x01to abort.", PREFIX);
				g_iTagEditing[client] = TagEdit_Clan;
			}
			case 2:
			{
				Menus_ShowColors(client, Color_Tag);
			}
			case 3:
			{
				Menus_ShowColors(client, Color_Name);
			}
			case 4:
			{
				Menus_ShowColors(client, Color_Chat);
			}
		}
	}
}

void Menus_ShowColors(int client, ColorType color)
{
	Menu menu = new Menu(Handler_ColorsMenu);
	menu.SetTitle("%s Select a Color\n ", PREFIX_MENU);
	
	char szBuffer[10];
	IntToString(view_as<int>(color), szBuffer, sizeof(szBuffer));
	menu.AddItem(szBuffer, "Default");
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
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_ColorsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		Menus_ShowGeneric(client);
	} else if (action == MenuAction_Select) {
		char szColor[10], szColumn[32];
		menu.GetItem(0, szColor, sizeof(szColor));
		
		ColorType iColor = view_as<ColorType>(StringToInt(szColor));
		switch (iColor)
		{
			case Color_Tag:Format(szColumn, sizeof(szColumn), "tagColor");
			case Color_Name:Format(szColumn, sizeof(szColumn), "nameColor");
			case Color_Chat:Format(szColumn, sizeof(szColumn), "chatColor");
		}
		
		char szInfo[32], szColorName[64];
		menu.GetItem(itemNum, szInfo, sizeof(szInfo), _, szColorName, sizeof(szColorName));
		
		strcopy(g_szColors[client][iColor], sizeof(g_szColors), szInfo);
		SQL_UpdatePerk(client, szColumn, szInfo);
		
		PrintToChat(client, "%s You changed your color to: %s%s\x01.", PREFIX, szInfo, szColorName);
	}
}

void Menus_ShowSpecial(int client)
{
	Menu menu = new Menu(Handler_SpecialMenu);
	menu.SetTitle("%s Special Perks\n ", PREFIX_MENU);
	
	char szBuffer[128];
	Format(szBuffer, sizeof(szBuffer), "[%s] HP Bonus", g_bHealth[client] ? "✔️" : "❌");
	menu.AddItem("hpbonus", szBuffer, g_cHealthBonus.BoolValue ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	Format(szBuffer, sizeof(szBuffer), "[%s] Armor Bonus", g_bArmor[client] ? "✔️" : "❌");
	menu.AddItem("armorbonus", szBuffer, g_cArmorBonus.BoolValue ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	menu.AddItem("skins", "Skins Menu", g_cPlayerSkins.BoolValue ? ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED);
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
	
}

public int Handler_SpecialMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		Menus_ShowMain(client);
	} else if (action == MenuAction_Select) {
		switch (itemNum)
		{
			case 0:
			{
				g_bHealth[client] = !g_bHealth[client];
				Menus_ShowSpecial(client);
				PrintToChat(client, "%s Health bonus is now: %s\x01.", PREFIX, g_bHealth[client] ? "\x04Enabled":"\x02Disabled");
			}
			case 1:
			{
				g_bArmor[client] = !g_bArmor[client];
				Menus_ShowSpecial(client);
				PrintToChat(client, "%s Armor bonus is now: %s\x01.", PREFIX, g_bArmor[client] ? "\x04Enabled":"\x02Disabled");
			}
			case 2:
			{
				Menus_SkinsMain(client);
			}
		}
	}
}

void Menus_SkinsMain(int client)
{
	Menu menu = new Menu(Handler_SkinsMenu);
	menu.SetTitle("%s Choose a Team\n ", PREFIX_MENU);
	menu.AddItem("ct", "Terrorist");
	menu.AddItem("t", "Counter-Terrorist");
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_SkinsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		Menus_ShowSpecial(client);
	} else if (action == MenuAction_Select) {
		Menus_SkinsSelection(client, itemNum);
	}
}

void Menus_SkinsSelection(int client, int team)
{
	SkinTeam iTeam = view_as<SkinTeam>(team);
	Menu menu = new Menu(Handler_SkinsSelection);
	menu.SetTitle("%s Choose a Skin\n ", PREFIX_MENU);
	
	char szBuffer[64], szType[10];
	Format(szBuffer, sizeof(szBuffer), "No Skin%s", g_szPlayerSkins[client][iTeam][0] == 0 ? " [Equipped]":"");
	IntToString(view_as<int>(iTeam), szType, sizeof(szType));
	menu.AddItem(szType, szBuffer, g_szPlayerSkins[client][iTeam][0] == 0 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	
	for (int i = 0; i < g_iSkins; i++)
	{
		if (view_as<SkinTeam>(StringToInt(g_szSkins[i][Skin_Team])) == iTeam)
		{
			Format(szBuffer, sizeof(szBuffer), "%s%s", g_szSkins[i][Skin_Name], StrEqual(g_szPlayerSkins[client][iTeam], g_szSkins[i][Skin_Model]) ? " [Equipped]":"");
			menu.AddItem(g_szSkins[i][Skin_Model], szBuffer, StrEqual(g_szPlayerSkins[client][iTeam], g_szSkins[i][Skin_Model]) ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		}
	}
	
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_SkinsSelection(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		Menus_SkinsMain(client);
	} else if (action == MenuAction_Select) {
		char szTeam[10];
		menu.GetItem(0, szTeam, sizeof(szTeam));
		SkinTeam iTeam = view_as<SkinTeam>(StringToInt(szTeam));
		
		char szInfo[512], szName[64];
		menu.GetItem(itemNum, szInfo, sizeof(szInfo), _, szName, sizeof(szName));
		
		if (itemNum)
			strcopy(g_szPlayerSkins[client][iTeam], sizeof(g_szPlayerSkins), szInfo);
		else
			g_szPlayerSkins[client][iTeam][0] = 0;
		
		SQL_UpdatePerk(client, iTeam == Skin_Team_T ? "tSkin":"ctSkin", szInfo);
		
		Menus_SkinsSelection(client, view_as<int>(iTeam));
		PrintToChat(client, "%s You changed your skin to: \x02%s\x01.", PREFIX, szName);
	}
}

void Menus_ShowPistols(int client)
{
	Menu menu = new Menu(Handler_PistolsMenu);
	menu.SetTitle("%s Select a Pistol\n ", PREFIX_MENU);
	
	menu.AddItem("weapon_usp_silencer", "USP-S");
	menu.AddItem("weapon_glock", "Glock");
	menu.AddItem("weapon_p250", "P250");
	menu.AddItem("weapon_deagle", "Desert Eagle");
	menu.AddItem("weapon_cz75a", "CZ75");
	menu.AddItem("weapon_fiveseven", "Five-Seven");
	menu.AddItem("weapon_revolver", "Revolver");
	menu.AddItem("weapon_elite", "Dual Berettas");
	menu.AddItem("weapon_hkp2000", "P200");
	menu.AddItem("weapon_tec9", "Tec-9");
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Handler_PistolsMenu(Menu menu, MenuAction action, int client, int itemNum)
{
	if (action == MenuAction_Select)
	{
		char szInfo[32], szName[32];
		menu.GetItem(itemNum, szInfo, sizeof(szInfo), _, szName, sizeof(szName));
		
		int iWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if (iWeapon != -1)
			AcceptEntityInput(iWeapon, "kill");
		
		GivePlayerItem(client, szInfo);
		PrintToChat(client, "%s You chose to play with: \x07%s\x01.", PREFIX, szName);
	}
}

/* Database */

void SQL_MakeConnection()
{
	if (g_dDatabase != null)
		delete g_dDatabase;
	
	char szError[512];
	g_dDatabase = SQL_Connect("vip", true, szError, sizeof(szError));
	if (g_dDatabase == null)
	{
		SetFailState("Cannot connect to datbase error: %s", szError);
	}
	
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "CREATE TABLE IF NOT EXISTS `%sUsers` (`authId` VARCHAR(32) NOT NULL, `expireStamp` INT NOT NULL, UNIQUE (`authId`));", GetTablePrefix());
	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
	FormatEx(szQuery, sizeof(szQuery), "CREATE TABLE IF NOT EXISTS `%sPerks`(`authId` VARCHAR(32) NOT NULL PRIMARY KEY, `chatTag` VARCHAR(512) NOT NULL DEFAULT '', `clanTag` VARCHAR(512) NOT NULL DEFAULT '', `tagColor` VARCHAR(16) NOT NULL DEFAULT '', `nameColor` VARCHAR(16) NOT NULL DEFAULT '', `chatColor` VARCHAR(16) NOT NULL DEFAULT '', `hpBonus` INT(10) NOT NULL DEFAULT 0, `armorBonus` INT(10) NOT NULL DEFAULT 0, `tSkin` VARCHAR(512) NOT NULL DEFAULT '', `ctSkin` VARCHAR(512) NOT NULL DEFAULT '',UNIQUE (`authId`))", GetTablePrefix());
	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
}

void SQL_FetchUser(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "SELECT `expireStamp` FROM `%sUsers` WHERE `authId` = '%s'", GetTablePrefix(), g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchUser_CB, szQuery, GetClientSerial(client));
}

public void SQL_FetchUser_CB(Database db, DBResultSet results, const char[] error, any data)
{
	int iClient = GetClientFromSerial(data);
	if (results == null)
	{
		if (iClient == 0)
		{
			LogError("Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("Cant use client data on insert. Reason: %s", error);
		}
		return;
	}
	
	if (results.FetchRow())
	{
		int iStamp = results.FetchInt(0);
		int iDaysLeft = (iStamp - GetTime()) / 86400;
		if (iDaysLeft > 0)
		{
			g_bVIP[iClient] = true;
			g_iDaysLeft[iClient] = iDaysLeft;
			
			SetHudTextParams(-1.0, 0.1, 7.0, 0, 255, 150, 255, 2, 6.0, 0.1, 0.2);
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					ShowHudText(i, 0, "VIP %N has connected", iClient);
				}
			}
			
			/* Give Flags */
			char szFlags[32];
			g_cVipFlags.GetString(szFlags, sizeof(szFlags));
			if (!StrEqual(szFlags, ""))
			{
				int iFlags = ReadFlagString(szFlags);
				int iPlayerFlags = GetUserFlagBits(iClient);
				
				bool bFlags[AdminFlags_TOTAL];
				bool bPlayerFlags[AdminFlags_TOTAL];
				bool bNewFlags[AdminFlags_TOTAL];
				
				FlagBitsToBitArray(iFlags, bFlags, AdminFlags_TOTAL);
				FlagBitsToBitArray(iPlayerFlags, bPlayerFlags, AdminFlags_TOTAL);
				
				for (int i = 0; i < AdminFlags_TOTAL; i++)
				{
					if (bPlayerFlags[i] || bFlags[i])
						bNewFlags[i] = true;
				}
				
				int iNewFlags = FlagBitArrayToBits(bNewFlags, AdminFlags_TOTAL)
				SetUserFlagBits(iClient, iNewFlags);
			}
			/* */
			
			SQL_FetchPerks(iClient);
		}
	} else if (GetMaxHumanPlayers() < GetOnlineUsers() && g_iRoundsPassed > 1) {
		KickClient(iClient, "Server is full");
	}
}

void SQL_FetchPerks(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "SELECT * FROM `%sPerks` WHERE `authId` = '%s'", GetTablePrefix(), g_szAuth[client]);
	g_dDatabase.Query(SQL_FetchPerks_CB, szQuery, GetClientSerial(client));
}

public void SQL_FetchPerks_CB(Database db, DBResultSet results, const char[] error, any data)
{
	int iClient = GetClientFromSerial(data);
	if (results == null)
	{
		if (iClient == 0)
		{
			LogError("Client is not valid. Reason: %s", error);
		}
		else
		{
			LogError("Cant use client data on insert. Reason: %s", error);
		}
		return;
	}
	if (results.FetchRow())
	{
		results.FetchString(1, g_szPlayerTags[iClient][Tag_Chat], sizeof(g_szPlayerTags));
		results.FetchString(2, g_szPlayerTags[iClient][Tag_Clan], sizeof(g_szPlayerTags));
		results.FetchString(3, g_szColors[iClient][Color_Tag], sizeof(g_szColors));
		results.FetchString(4, g_szColors[iClient][Color_Name], sizeof(g_szColors));
		results.FetchString(5, g_szColors[iClient][Color_Chat], sizeof(g_szColors));
		g_bHealth[iClient] = view_as<bool>(results.FetchInt(6));
		g_bArmor[iClient] = view_as<bool>(results.FetchInt(7));
		results.FetchString(8, g_szPlayerSkins[iClient][Skin_Team_T], sizeof(g_szPlayerSkins));
		results.FetchString(9, g_szPlayerSkins[iClient][Skin_Team_CT], sizeof(g_szPlayerSkins));
		
		CS_SetClientClanTag(iClient, g_szPlayerTags[iClient][Tag_Clan]);
	} else {
		SQL_RegisterPerks(iClient);
	}
}

void SQL_RegisterPerks(int client)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "INSERT INTO `%sPerks` (`authId`) VALUES ('%s')", GetTablePrefix(), g_szAuth[client]);
	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
}

void SQL_UpdatePerk(int client, char[] perk, char[] value)
{
	char szQuery[512];
	FormatEx(szQuery, sizeof(szQuery), "UPDATE `%sPerks` SET `%s` = '%s' WHERE `authId` = '%s'", GetTablePrefix(), perk, value, g_szAuth[client]);
	g_dDatabase.Query(SQL_CheckForErrors, szQuery);
}

public void SQL_CheckForErrors(Database db, DBResultSet results, const char[] error, any data)
{
	if (!StrEqual(error, ""))
	{
		LogError("Databse error, %s", error);
		return;
	}
}

/* Stocks, Functions */

void LoadSkins()
{
	char szPath[512];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/vip/skins.txt");
	if (!FileExists(szPath))
		SetFailState("Couldn't find file: %s", szPath);
	
	KeyValues kConfig = new KeyValues("");
	kConfig.ImportFromFile(szPath);
	kConfig.JumpToKey("Skins");
	kConfig.GotoFirstSubKey();
	
	do {
		kConfig.GetString("name", g_szSkins[g_iSkins][Skin_Name], sizeof(g_szSkins));
		kConfig.GetString("model", g_szSkins[g_iSkins][Skin_Model], sizeof(g_szSkins));
		kConfig.GetString("arms", g_szSkins[g_iSkins][Skin_Arms], sizeof(g_szSkins));
		kConfig.GetString("team", g_szSkins[g_iSkins][Skin_Team], sizeof(g_szSkins));
		PrecacheModel(g_szSkins[g_iSkins][Skin_Model]);
		g_iSkins++;
	} while (kConfig.GotoNextKey())
}

void LoadBlockedTags()
{
	char szPath[512];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/vip/blockedtags.txt");
	if (!FileExists(szPath))
		SetFailState("Couldn't find file: %s", szPath);
	
	Handle hFile = OpenFile(szPath, "r");
	char szLine[64];
	do {
		if (IsValidString(szLine))
			g_aBlockedTags.PushString(szLine);
	} while (!IsEndOfFile(hFile) && ReadFileLine(hFile, szLine, sizeof(szLine)))
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

stock bool IsTagAllowed(const char[] tag)
{
	for (int i = 0; i < g_aBlockedTags.Length; i++)
	{
		char szBuffer[64];
		g_aBlockedTags.GetString(i, szBuffer, sizeof(szBuffer));
		if (StrContains(tag, szBuffer, false) != -1)
			return false;
	}
	return true;
}

stock bool IsValidString(char[] string)
{
	int iCount;
	for (int i = 0; i <= strlen(string); i++)
	{
		if (IsCharAlpha(string[i]) || IsCharNumeric(string[i]))
			iCount++;
	}
	
	return iCount ? true:false;
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	return IsClientInGame(client);
}

stock char GetTablePrefix()
{
	char szPrefix[512];
	g_cTablePrefix.GetString(szPrefix, sizeof(szPrefix));
	return szPrefix;
} 

stock char GetSkinArms(char[] skinModel)
{
	char szArms[512];
	for (int i = 0; i < g_iSkins; i++)
	{
		if(StrEqual(g_szSkins[i][Skin_Model], skinModel))
			strcopy(szArms, sizeof(szArms), g_szSkins[i][Skin_Arms]);
	}
	
	return szArms;
}