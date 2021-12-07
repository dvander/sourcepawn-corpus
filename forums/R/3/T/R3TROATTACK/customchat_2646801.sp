#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Retro"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <scp>

#pragma newdecls required

#define MAX_MESSAGE_LENGTH 250

Database g_hDatabase;

Menu g_mColorsMenu, g_mNameMenu;

public Plugin myinfo = 
{
	name = "Custom Chat", 
	author = PLUGIN_AUTHOR, 
	description = "Allows you to customize your chat color, name color, and set a custom tag.", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/R3TROATTACK/"
};

char g_sColorNames[][] =  {
	"default", 
	"darkred", 
	"green", 
	"team", 
	"olive", 
	"lime", 
	"red", 
	"grey", 
	"yellow", 
	"gold", 
	"silver", 
	"blue", 
	"darkblue", 
	"bluegrey", 
	"magenta", 
	"lightred"
};
char g_sColorCodes[][] =  {
	"\x01", 
	"\x02", 
	"\x04", 
	"\x03", 
	"\x05", 
	"\x06", 
	"\x07", 
	"\x08", 
	"\x09", 
	"\x10", 
	"\x0A", 
	"\x0B", 
	"\x0C", 
	"\x0D", 
	"\x0E", 
	"\x0F"
};

enum ChatData {
	Chat, 
	Name,
	String:ChatHex[16],
	String:NameHex[128],
	String:Tag[128]
};

int g_iPlayerInfo[MAXPLAYERS + 1][ChatData];
bool g_bLate = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] err, int len)
{
	g_bLate = late;
}

public void OnPluginStart()
{	
	DB_Load();
	RegAdminCmd("sm_colors", Command_Colors, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_namecolors", Command_NameColors, ADMFLAG_CUSTOM1);
	RegAdminCmd("sm_settag", Command_SetTag, ADMFLAG_CUSTOM1);
	
	if (g_bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPostAdminCheck(i);
	}
}

public Action Command_Colors(int client, int args)
{
	if (0 >= client > MaxClients)
		return Plugin_Handled;
	
	if (!IsClientInGame(client))
		return Plugin_Handled;
	
	g_mColorsMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_NameColors(int client, int args)
{
	if (0 >= client > MaxClients)
		return Plugin_Handled;
	
	if (!IsClientInGame(client))
		return Plugin_Handled;
	
	g_mNameMenu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public Action Command_SetTag(int client, int args)
{
	if (0 >= client > MaxClients)
		return Plugin_Handled;
	
	if (!IsClientInGame(client))
		return Plugin_Handled;
	
	if (args == 0)
	{
		char colorlist[MAX_MESSAGE_LENGTH];
		for (int i = 0; i < sizeof(g_sColorNames); i++)
		{
			if (i == 0)
				Format(colorlist, sizeof(colorlist), " %s%s", g_sColorCodes[i], g_sColorNames[i]);
			else
				Format(colorlist, sizeof(colorlist), "%s, %s%s", colorlist, g_sColorCodes[i], g_sColorNames[i]);
		}
		PrintToChat(client, colorlist);
		return Plugin_Handled;
	}
	if(args == 1)
	{
		char arg[MAX_TARGET_LENGTH];
		GetCmdArg(1, arg, sizeof(arg));
		if(StrEqual("off", arg, false))
		{
			Format(g_iPlayerInfo[client][Tag], 32, "");
			PrintToChat(client, " \x06[CustomChat] \x01You have cleared you custom tag.");
			DB_UpdateColors(client);
			return Plugin_Handled;
		}
	}
	char arg_string[MAX_MESSAGE_LENGTH];
	GetCmdArgString(arg_string, sizeof(arg_string));
	Format(g_iPlayerInfo[client][Tag], 32, "%s", arg_string);
	char msg[MAX_MESSAGE_LENGTH];
	Format(msg, sizeof(msg), " \x06[CustomChat] \x01You have set your chat tag to %s", arg_string);
	ProcessColors(msg, sizeof(msg));
	PrintToChat(client, "%s", msg);
	DB_UpdateColors(client);
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	g_iPlayerInfo[client][Chat] = 0;
	g_iPlayerInfo[client][Name] = 3;
	Format(g_iPlayerInfo[client][Tag], 32, "");
	CreateTimer(1.5, Timer_LoadDelay, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_LoadDelay(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if (0 > client > MaxClients && !IsClientInGame(client))
		return Plugin_Handled;
	
	bool n = CheckCommandAccess(client, "sm_namecolors", ADMFLAG_CUSTOM1);
	bool chat = CheckCommandAccess(client, "sm_colors", ADMFLAG_CUSTOM1);
	bool tag = CheckCommandAccess(client, "sm_settag", ADMFLAG_CUSTOM1);
	if (!n && !chat && !tag)
		return Plugin_Handled;
	char sQuery[256], steamid[64];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
		return Plugin_Handled;
	int count = 0;
	if (n) { count++; }
	if (chat) { count++; }
	if (tag) { count++; }
	if (count > 1)
		Format(sQuery, sizeof(sQuery), "SELECT %s%s%s FROM customchat WHERE steamid='%s';", n ? "namecolor, " : "", chat ? "chatcolor, " : "", tag ? "tag" : "", steamid);
	else
		Format(sQuery, sizeof(sQuery), "SELECT %s%s%s FROM customchat WHERE steamid='%s';", n ? "namecolor" : "", chat ? "chatcolor" : "", tag ? "tag" : "", steamid);
	g_hDatabase.Query(DB_LoadColors, sQuery, userid);
	return Plugin_Handled;
}

public void DB_LoadColors(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null)
	{
		LogError("DB_LoadColors returned error: %s", error);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if (0 > client > MaxClients && !IsClientInGame(client))
		return;
	if(results.RowCount <= 0)
		return;
	int chatcol, namecol, tagcol;
	bool chat = results.FieldNameToNum("chatcolor", chatcol);
	bool name = results.FieldNameToNum("namecolor", namecol);
	bool tag = results.FieldNameToNum("tag", tagcol);
	results.FetchRow();
	
	if(chat)
		g_iPlayerInfo[client][Chat] = results.FetchInt(chatcol);
	if(name)
		g_iPlayerInfo[client][Name] = results.FetchInt(namecol);
	if(tag)
		results.FetchString(tagcol, g_iPlayerInfo[client][Tag], 32);
}

void DB_Load()
{
	Database.Connect(DB_Connect, "chatcolors");
}

public void DB_Connect(Database db, const char[] error, any data)
{
	if (db == null)
	{
		LogError("DB_Connect returned invalid Database Handle");
		return;
	}
	
	g_hDatabase = db;
	db.Query(DB_Generic, "CREATE TABLE customchat (steamid varchar(64) NOT NULL, chatcolor INT DEFAULT 0, namecolor INT DEFAULT 4, tag varchar(64) DEFAULT NULL, PRIMARY KEY(steamid));");
}

public void DB_UpdateColors(int client)
{
	if (g_hDatabase == null)
		return;
	
	char sQuery[256], steamid[64];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
		return;
	Format(sQuery, sizeof(sQuery), "INSERT INTO customchat (steamid, chatcolor, namecolor, tag) VALUES ('%s', %d, %d, '%s') ON DUPLICATE KEY UPDATE chatcolor=VALUES(chatcolor), namecolor=VALUES(namecolor), tag=VALUES(tag);", steamid, g_iPlayerInfo[client][Chat], g_iPlayerInfo[client][Name], g_iPlayerInfo[client][Tag]);
	g_hDatabase.Query(DB_Generic, sQuery);
}

public void DB_Generic(Database db, DBResultSet results, const char[] error, any data)
{
	if (db == null || results == null)
	{
		LogError("DB_Generic returned error: %s", error);
		return;
	}
}

public void OnMapStart()
{
	Menu menu = new Menu(MenuHandler_ChatColor);
	menu.SetTitle("Select your chat color!");
	for (int i = 0; i < sizeof(g_sColorNames); i++)
	{
		char info[16];
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, g_sColorNames[i]);
	}
	menu.ExitButton = true;
	g_mColorsMenu = menu;
	
	Menu menu2 = new Menu(MenuHandler_NameColor);
	menu2.SetTitle("Select your name color!");
	for (int i = 0; i < sizeof(g_sColorNames); i++)
	{
		char info[16];
		IntToString(i, info, sizeof(info));
		menu2.AddItem(info, g_sColorNames[i]);
	}
	menu2.ExitButton = true;
	g_mNameMenu = menu2;
}

public void OnMapEnd()
{
	CloseMenu(g_mColorsMenu);
	CloseMenu(g_mNameMenu);
}

stock void CloseMenu(Menu& menu)
{
	if(menu != null)
	{
		CloseHandle(menu);
	}
	menu = null;
}

public int MenuHandler_ChatColor(Menu menu, MenuAction action, int client, int choice)
{
	if (action != MenuAction_Select)
		return;
	PrintToChat(client, " \x06[CustomChat] \x01You have set your chat color to %s%s\x01.", g_sColorCodes[choice], g_sColorNames[choice]);
	g_iPlayerInfo[client][Chat] = choice;
	DB_UpdateColors(client);
}

public int MenuHandler_NameColor(Menu menu, MenuAction action, int client, int choice)
{
	if (action != MenuAction_Select)
		return;
	PrintToChat(client, " \x06[CustomChat] \x01You have set your name color to %s%s\x01.", g_sColorCodes[choice], g_sColorNames[choice]);
	g_iPlayerInfo[client][Name] = choice;
	DB_UpdateColors(client);
}

public Action OnChatMessage(int & author, Handle recipients, char[] name, char[] message)
{
	bool n = CheckCommandAccess(author, "sm_namecolors", ADMFLAG_CUSTOM1);
	bool chat = CheckCommandAccess(author, "sm_colors", ADMFLAG_CUSTOM1);
	bool tag = CheckCommandAccess(author, "sm_settag", ADMFLAG_CUSTOM1);
	if (!n && !chat && !tag)
		return Plugin_Continue;
	
	char ctag[32];
	bool changed;
	bool needspace = false;
	if (chat)
	{
		if (g_iPlayerInfo[author][Chat] != 0)
		{
			Format(message, MAX_MESSAGE_LENGTH, "%s%s", g_sColorCodes[g_iPlayerInfo[author][Chat]], message);
			changed = true;
		}
		if (CheckCommandAccess(author, "sm_colors_parse", ADMFLAG_CUSTOM1))
			ProcessColors(message, MAX_MESSAGE_LENGTH);
	}

	if (tag)
	{
		if (!StrEqual("", g_iPlayerInfo[author][Tag]))
		{
			Format(ctag, sizeof(ctag), "%s", g_iPlayerInfo[author][Tag]);
			ProcessColors(ctag, sizeof(ctag));
			Format(ctag, MAX_NAME_LENGTH, "%s\x03", ctag);
			changed = true;
			needspace = true;
		}
	}
	
	if (n)
	{
		if (g_iPlayerInfo[author][Name] != 3)
		{
			Format(name, MAX_NAME_LENGTH, " %s%s", g_sColorCodes[g_iPlayerInfo[author][Name]], name);
			changed = true;
			needspace = true;
		}
	}


	Format(name, MAX_NAME_LENGTH, "%s%s%s", needspace ? " " : "", ctag, name);
	
	if (changed)
		return Plugin_Changed;
	return Plugin_Continue;
}

void ProcessColors(char[] buffer, int maxlen)
{
	for (int i = 1; i < sizeof(g_sColorNames); i++)
	{
		char tmp[32];
		Format(tmp, sizeof(tmp), "{%s}", g_sColorNames[i]);
		ReplaceString(buffer, maxlen, tmp, g_sColorCodes[i]);
	}
} 