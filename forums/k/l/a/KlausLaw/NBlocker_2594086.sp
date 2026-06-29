
#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Klaus"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#define PREFIX " \x04[NBlocker]\x01"  

Database g_DB;
enum nameData
{
	Id, 
	banTime, 
	bool:isBan, 
	String:sName[256], 
	String:sReason[256]
};

int g_isEditing[MAXPLAYERS + 1], g_editTime[MAXPLAYERS + 1], g_editId[MAXPLAYERS + 1];
char g_editName[MAXPLAYERS + 1][256], g_editReason[MAXPLAYERS + 1][256];
bool g_editBan[MAXPLAYERS + 1];
char g_isSearching[MAXPLAYERS + 1][32];
int lastAdded;
new namesList[256][nameData];

ConVar g_cvPAdmins;

public Plugin myinfo = 
{
	name = "Vgames Blocker", 
	author = PLUGIN_AUTHOR, 
	description = "Allow ban/kick people who write blocked names", 
	version = PLUGIN_VERSION, 
	url = "http://steamcommunity.com/id/KlausLaw"
};

public void OnPluginStart()
{
	DB_Connect();
	RegAdminCmd("sm_blocker", SM_Blocker, ADMFLAG_RCON);
	g_cvPAdmins = CreateConVar("nblocker_punish_admins", "1", "Sets whether admins will be punished");
	AutoExecConfig(true, "nblocker");
	
}

public OnMapStart()
{
	loadNamesDb();
}

public OnClientPostAdminCheck(int client)
{
	resetFields(client);
	char cName[MAX_NAME_LENGTH];
	GetClientName(client, cName, sizeof(cName));
	checkInput(client, cName);
	
}

public Action SM_Blocker(int client, int args)
{
	openBlocker(client);
	return Plugin_Handled;
}

void openBlocker(int client)
{
	Menu menu = new Menu(Menu_MainMenu);
	menu.SetTitle("[NBlocker] - Main Menu\n \n");
	menu.AddItem("0", "Add a name");
	menu.AddItem("1", "Edit names\n \n");
	menu.AddItem("2", "Bans menu");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_MainMenu(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		if (Position == 0)
		{
			openAddMenu(client);
		}
		else if (Position == 1)
		{
			openNamesList(client);
		}
		else
		{
			openBansMenu(client);
		}
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void openAddMenu(int client)
{
	char sItem[256];
	Menu menu = new Menu(Menu_AddMenu);
	menu.SetTitle("[NBlocker] - Adding Menu\n \n");
	Format(sItem, sizeof(sItem), "Name: %s\n \n", strlen(g_editName[client]) <= 0 ? "(Click to edit)" : g_editName[client]);
	menu.AddItem("0", sItem);
	Format(sItem, sizeof(sItem), "Punishment: %s", g_editBan[client] ? "Banning":"Kicking");
	menu.AddItem("1", sItem);
	Format(sItem, sizeof(sItem), "Reason: %s%s", strlen(g_editReason[client]) <= 0 ? "(Click to edit)" : g_editReason[client], g_editBan[client] ? "" : "\n \n");
	menu.AddItem("2", sItem);
	if (g_editBan[client])
	{
		Format(sItem, sizeof(sItem), "Ban time: %d Minutes\n \n", g_editTime[client]);
		menu.AddItem("3", sItem);
	}
	menu.AddItem("4", "Add name");
	menu.Display(client, MENU_TIME_FOREVER);
	
}
public int Menu_AddMenu(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char item[12];
		menu.GetItem(Position, item, sizeof(item));
		int addName = StringToInt(item);
		if (Position != 1 && addName != 4)
		{
			g_isEditing[client] = Position;
			PrintToChat(client, "%s Write in chat the new value, write \x04-1\x01 to cancel.", PREFIX);
		}
		else if (Position == 1)
		{
			g_editBan[client] = !g_editBan[client];
			openAddMenu(client);
		}
		else
		{
			if (strlen(g_editName[client]) <= 0 || strlen(g_editReason[client]) <= 0)
			{
				PrintToChat(client, "%s You have to fill out all the fields.", PREFIX);
				openAddMenu(client);
				return;
			}
			char sTime[35];
			if (!g_editBan[client])
				sTime = "";
			else
				Format(sTime, sizeof(sTime), ", Time: \x04%d Minutes\x01", g_editTime[client]);
			
			PrintToChat(client, "%s You \x04successfully\x01 added \x07%s\x01 (Punishment: \x04%s\x01, Reason: \x04%s\x01%s).", PREFIX, g_editName[client], g_editBan[client] ? "Ban" : "Kick", g_editReason[client], sTime);
			insertNameDb(g_editName[client], g_editReason[client], g_editBan[client], g_editTime[client]);
			resetFields(client);
		}
	}
	if (action == MenuAction_Cancel)
	{
		resetFields(client);
		openBlocker(client);
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void openNamesList(int client)
{
	char sItem[256];
	char sInfo[24];
	Menu menu = new Menu(Menu_NamesList);
	menu.SetTitle("[NBlocker] - Names List\n \n");
	for (int i = 1; i < 256; i++)
	{
		if (strlen(namesList[i][sName]) <= 0)continue;
		IntToString(namesList[i][Id], sInfo, 24);
		Format(sItem, sizeof(sItem), "%s", namesList[i][sName]);
		menu.AddItem(sInfo, sItem);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	
}
public int Menu_NamesList(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char item[12];
		menu.GetItem(Position, item, sizeof(item));
		int nameId = StringToInt(item);
		int index = getIndexFromId(nameId);
		g_editTime[client] = namesList[index][banTime];
		Format(g_editName[client], 256, namesList[index][sName]);
		Format(g_editReason[client], 256, namesList[index][sReason]);
		g_editBan[client] = namesList[index][isBan];
		g_editId[client] = nameId;
		openEditMenu(client);
	}
	if (action == MenuAction_Cancel)
	{
		openBlocker(client);
		
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void openEditMenu(int client)
{
	char sItem[256];
	Menu menu = new Menu(Menu_EditMenu);
	menu.SetTitle("[NBlocker] - Editing Menu\n \n");
	Format(sItem, sizeof(sItem), "Name: %s\n \n", g_editName[client]);
	menu.AddItem("0", sItem);
	Format(sItem, sizeof(sItem), "Punishment: %s", g_editBan[client] ? "Banning" : "Kicking");
	menu.AddItem("1", sItem);
	Format(sItem, sizeof(sItem), "Reason: %s%s", g_editReason[client], g_editBan[client] ? "" : "\n \n");
	menu.AddItem("2", sItem);
	if (g_editBan[client])
	{
		Format(sItem, sizeof(sItem), "Ban time: %d Minutes\n \n", g_editTime[client]);
		menu.AddItem("3", sItem);
	}
	menu.AddItem("4", "Edit name");
	menu.AddItem("5", "Delete name");
	menu.Display(client, MENU_TIME_FOREVER);
	
	
}

public int Menu_EditMenu(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char item[12];
		menu.GetItem(Position, item, sizeof(item));
		int Pos = StringToInt(item);
		if (Pos != 1 && Pos != 4 && Pos != 5)
		{
			g_isEditing[client] = Position;
			PrintToChat(client, "%s Write in chat the new value, write \x04-1\x01 to cancel", PREFIX);
		}
		else if (Pos == 1)
		{
			g_editBan[client] = !g_editBan[client];
			openEditMenu(client);
		}
		else if (Pos == 4)
		{
			if (strlen(g_editName[client]) <= 0 || strlen(g_editReason[client]) <= 0)
			{
				PrintToChat(client, "%s You have to fill out all the fields", PREFIX);
				openEditMenu(client);
				return;
			}
			char sTime[35];
			if (!g_editBan[client])
				sTime = "";
			else
				Format(sTime, sizeof(sTime), ", Time: \x04%d Minutes\x01", g_editTime[client]);
			
			PrintToChat(client, "%s You \x04successfully\x01 edited \x07%s\x01 (Punishment: \x04%s\x01, Reason: \x04%s\x01%s).", PREFIX, g_editName[client], g_editBan[client] ? "Ban" : "Kick", g_editReason[client], sTime);
			editNameDb(g_editId[client], g_editName[client], g_editReason[client], g_editBan[client], g_editTime[client]);
			resetFields(client);
		}
		else
		{
			PrintToChat(client, "%s You have \x04successfully\x01 deleted \x07%s\x01.", PREFIX, g_editName[client]);
			deleteNameDb(g_editId[client]);
			resetFields(client);
		}
	}
	if (action == MenuAction_Cancel)
	{
		resetFields(client);
		openNamesList(client);
		
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public void openBansMenu(int client)
{
	Menu menu = new Menu(Menu_BansMenu);
	menu.SetTitle("[NBlocker] - Bans menu\n \n");
	menu.AddItem("1", "Search by SteamID\n \n");
	menu.AddItem("2", "Bans list");
	menu.Display(client, MENU_TIME_FOREVER);
	
}
public int Menu_BansMenu(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		if (Position == 0)
		{
			g_isSearching[client] = "";
			PrintToChat(client, "%s Write the \x04SteamID\x01 you would like to search, \x04-1\x01 to cancel.", PREFIX);
		}
		else
		{
			g_isSearching[client] = "-1";
			openBansList(client);
		}
	}
	if (action == MenuAction_Cancel)
	{
		openBlocker(client);
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}
void openBansList(int client)
{
	char sTemp[124];
	Format(sTemp, sizeof(sTemp), " WHERE auth='%s'", SQLSecure(g_isSearching[client]));
	char sQuery[320];
	Format(sQuery, sizeof(sQuery), "SELECT auth,name,server,date FROM bans%s ORDER BY date DESC", StringToInt(g_isSearching[client]) != -1 ? sTemp : "");
	g_isSearching[client] = "-1";
	SQL_TQuery(g_DB, Db_loadBans, sQuery, client);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs) {
	if (checkInput(client, sArgs))
		return Plugin_Handled;
	
	if (g_isEditing[client] == -1 && StringToInt(g_isSearching[client]) == -1)
		return Plugin_Continue;
	
	if (StringToInt(sArgs) == -1)
	{
		if (StringToInt(g_isSearching[client]) != -1)
		{
			g_isSearching[client] = "-1";
			openBansMenu(client);
			return Plugin_Handled;
		}
		
		g_isEditing[client] = -1;
		if (g_editId[client] > 0)
			openEditMenu(client);
		else
			openAddMenu(client);
		return Plugin_Handled;
	}
	if (StringToInt(g_isSearching[client]) != -1)
	{
		Format(g_isSearching[client], 32, "%s", sArgs);
		openBansList(client);
		return Plugin_Handled;
	}
	
	if (g_isEditing[client] == 0)
	{
		Format(g_editName[client], 256, sArgs);
	}
	else if (g_isEditing[client] == 2)
	{
		Format(g_editReason[client], 256, sArgs);
	}
	else
	{
		g_editTime[client] = StringToInt(sArgs);
	}
	if (g_editId[client] > 0)
		openEditMenu(client);
	else
		openAddMenu(client);
	g_isEditing[client] = -1;
	return Plugin_Handled;
	
}

public bool checkInput(int client, const char[] sArgs)
{
	
	for (int i = 1; i < 256; i++)
	{
		if (strlen(namesList[i][sName]) <= 0)continue;
		if (StrContains(sArgs, namesList[i][sName], false) != -1)
		{
			punishClient(client, i, sArgs);
			return true;
		}
	}
	return false;
}

public void punishClient(int client, int index, const char[] sbMessage)
{
	if (GetUserAdmin(client) != INVALID_ADMIN_ID && g_cvPAdmins.IntValue == 1)
	{
		PrintToChat(client, "%s \x02Since you are an admin you are not punished, Do not write this name again!", PREFIX);
		PrintToChat(client, "%s Reason for punishing: \x04%s\x01.", PREFIX, namesList[index][sReason]);
		return;
	}
	if (!namesList[index][isBan])
	{
		KickClient(client, namesList[index][sReason]);
	}
	else
	{
		
		char sAuth[35], sQuery[1024], sbName[128], sServer[128], sMessage[512];
		GetClientName(client, sbName, sizeof(sbName));
		GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth), true);
		ServerCommand("sm_ban #%d %d %s", GetClientUserId(client), namesList[index][banTime], namesList[index][sReason]);
		GetHostName(sServer, 128);
		Format(sMessage, sizeof(sMessage), sbMessage);
		Format(sQuery, sizeof(sQuery), "INSERT INTO bans(name,auth,reason,message,server,date,bantime) VALUES ('%s','%s','%s','%s','%s','%d','%d')", SQLSecure(sbName), sAuth, SQLSecure(namesList[index][sReason]), SQLSecure(sMessage), SQLSecure(sServer), GetTime(), namesList[index][banTime]);
		SQL_TQuery(g_DB, DB_SaveBan, sQuery);
	}
}

public void insertNameDb(char[] name, char[] reason, bool ban, int time)
{
	lastAdded++;
	
	namesList[lastAdded][Id] = lastAdded;
	namesList[lastAdded][banTime] = time;
	namesList[lastAdded][isBan] = ban;
	Format(namesList[lastAdded][sName], 256, "%s", name);
	Format(namesList[lastAdded][sReason], 256, "%s", reason);
	
	char sQuery[320];
	Format(sQuery, sizeof(sQuery), "INSERT INTO names(id,name,ban,reason,bantime) VALUES ('%d','%s','%d','%s','%d')", lastAdded, SQLSecure(name), ban, SQLSecure(reason), time);
	SQL_TQuery(g_DB, Db_insertName, sQuery);
}
public Db_insertName(Handle owner, Handle hndl, char[] error, any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
		return;
	}
	
}
public void editNameDb(int nameId, char[] name, char[] reason, bool ban, int time)
{
	int index = getIndexFromId(nameId);
	namesList[index][banTime] = time;
	namesList[index][isBan] = ban;
	Format(namesList[index][sName], 256, "%s", name);
	Format(namesList[index][sReason], 256, "%s", reason);
	
	char sQuery[320];
	Format(sQuery, sizeof(sQuery), "UPDATE names SET name='%s',ban='%d',reason='%s',bantime='%d' WHERE id='%d'", SQLSecure(name), ban, SQLSecure(reason), time, nameId);
	SQL_TQuery(g_DB, Db_updateName, sQuery);
}

public Db_updateName(Handle owner, Handle hndl, char[] error, any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
		return;
	}
	
}
public void deleteNameDb(int nameId)
{
	int index = getIndexFromId(nameId);
	namesList[index][banTime] = 30;
	namesList[index][isBan] = false;
	Format(namesList[index][sName], 256, "");
	Format(namesList[index][sReason], 256, "");
	
	char sQuery[320];
	Format(sQuery, sizeof(sQuery), "DELETE FROM names WHERE id='%d'", nameId);
	SQL_TQuery(g_DB, Db_deleteName, sQuery);
}

public Db_deleteName(Handle owner, Handle hndl, char[] error, any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
		return;
	}
	
}
public void loadNamesDb()
{
	for (int i = 1; i < 256; i++)
	{
		namesList[i][Id] = 0;
		namesList[i][banTime] = 0;
		namesList[i][isBan] = false;
		Format(namesList[lastAdded][sName], 256, "");
		Format(namesList[lastAdded][sReason], 256, "");
	}
	char sQuery[320];
	Format(sQuery, sizeof(sQuery), "SELECT id,name,ban,reason,bantime FROM names");
	SQL_TQuery(g_DB, Db_loadNames, sQuery);
}

public Db_loadNames(Handle owner, Handle hndl, char[] error, any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
		return;
	}
	int count = 1;
	while (SQL_FetchRow(hndl))
	{
		namesList[count][Id] = SQL_FetchInt(hndl, 0);
		lastAdded = namesList[count][Id];
		SQL_FetchString(hndl, 1, namesList[count][sName], 256);
		namesList[count][isBan] = view_as<bool>(SQL_FetchInt(hndl, 2));
		SQL_FetchString(hndl, 3, namesList[count][sReason], 256);
		namesList[count][banTime] = SQL_FetchInt(hndl, 4);
		count++;
	}
}

public Db_loadBans(Handle owner, Handle hndl, char[] error, any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
		return;
	}
	char sItem[124], sItemInfo[124];
	char sAuth[32];
	char sServer[128];
	char sTime[3][5];
	int iDate, count = 0;
	Menu menu = new Menu(Menu_BansList);
	menu.SetTitle("[NBlocker] - Bans list\n \n");
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, sAuth, sizeof(sAuth));
		SQL_FetchString(hndl, 1, sItem, sizeof(sItem));
		SQL_FetchString(hndl, 2, sServer, sizeof(sServer));
		iDate = SQL_FetchInt(hndl, 3);
		FormatTime(sTime[0], 5, "%d", iDate);
		FormatTime(sTime[1], 5, "%m", iDate);
		FormatTime(sTime[2], 5, "%Y", iDate);
		Format(sItem, sizeof(sItem), "%s(%s) [%s/%s/%s]", sItem, sAuth, sTime[0], sTime[1], sTime[2]);
		Format(sItemInfo, sizeof(sItemInfo), "%s-%d", sAuth, iDate);
		count++;
		menu.AddItem(sItemInfo, sItem);
	}
	if (count == 0)
		menu.AddItem("", "No results were found", ITEMDRAW_DISABLED);
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_BansList(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char sQuery[256], sItem[94];
		char infoExploded[2][128];
		menu.GetItem(Position, sItem, sizeof(sItem));
		ExplodeString(sItem, "-", infoExploded, sizeof(infoExploded), sizeof(infoExploded[]));
		int iDate = StringToInt(infoExploded[1]);
		Format(sQuery, sizeof(sQuery), "SELECT name,reason,message,server,date,bantime FROM bans WHERE auth='%s' AND date='%d'", infoExploded[0], iDate);
		Handle dataPack = CreateDataPack();
		WritePackString(dataPack, infoExploded[0]);
		WritePackCell(dataPack, client);
		WritePackCell(dataPack, iDate);
		SQL_TQuery(g_DB, Db_loadBanInfo, sQuery, dataPack);
		
	}
	if (action == MenuAction_Cancel)
	{
		openBlocker(client);
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}

public Db_loadBanInfo(Handle owner, Handle hndl, char[] error, any:dataPack)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
		return;
	}
	
	if (!SQL_FetchRow(hndl))
		return;
	char sbAuth[32], sbName[128], sbServer[64], sbReason[128], sbMessage[1024];
	int ibanTime;
	
	ResetPack(dataPack);
	ReadPackString(dataPack, sbAuth, sizeof(sbAuth));
	int client = ReadPackCell(dataPack);
	int iDate = ReadPackCell(dataPack);
	CloseHandle(dataPack);
	SQL_FetchString(hndl, 0, sbName, sizeof(sbName));
	SQL_FetchString(hndl, 1, sbReason, sizeof(sbReason));
	SQL_FetchString(hndl, 2, sbMessage, sizeof(sbMessage));
	SQL_FetchString(hndl, 3, sbServer, sizeof(sbServer));
	ibanTime = SQL_FetchInt(hndl, 5);
	openBanInfo(client, sbAuth, sbName, sbServer, sbReason, sbMessage, ibanTime, iDate);
}

public void openBanInfo(int client, char[] sbAuth, char[] sbName, char[] sbServer, char[] sbReason, char[] sbMessage, int ibanTime, int iDate)
{
	char sItem[1024];
	char sTime[3][5];
	FormatTime(sTime[0], 5, "%d", iDate);
	FormatTime(sTime[1], 5, "%m", iDate);
	FormatTime(sTime[2], 5, "%Y", iDate);
	Menu menu = new Menu(Menu_BanInfo);
	Format(sItem, sizeof(sItem), "[NBlocker] - Ban info\n \nName: %s\nSteamID: %s\n \nServer: %s\nReason: %s\nBanning Time: %d Minutes\nDate: %s/%s/%s\n \n", sbName, sbAuth, sbServer, sbReason, ibanTime, sTime[0], sTime[1], sTime[2]);
	menu.SetTitle(sItem);
	Format(sItem, sizeof(sItem), "Message:\n%s\n \n", sbMessage);
	menu.AddItem(sbMessage, sItem);
	Format(sItem, sizeof(sItem), "%s-%s-%d", sbAuth, sbName, iDate);
	menu.AddItem(sItem, "Delete ban record");
	menu.Display(client, MENU_TIME_FOREVER);
}

public int Menu_BanInfo(Menu menu, MenuAction action, int client, int Position)
{
	if (action == MenuAction_Select)
	{
		char sItem[512];
		menu.GetItem(Position, sItem, sizeof(sItem));
		if (Position == 0)
		{
			PrintToChat(client, "%s %s", PREFIX, sItem);
			openBansList(client);
		}
		else
		{
			char infoExploded[3][128], sQuery[256];
			ExplodeString(sItem, "-", infoExploded, sizeof(infoExploded), sizeof(infoExploded[]));
			char sTime[3][5];
			int iDate = StringToInt(infoExploded[2]);
			FormatTime(sTime[0], 5, "%d", iDate);
			FormatTime(sTime[1], 5, "%m", iDate);
			FormatTime(sTime[2], 5, "%Y", iDate);
			Format(sQuery, sizeof(sQuery), "DELETE FROM bans WHERE auth='%s' AND date='%d'", infoExploded[0], iDate);
			PrintToChat(client, "%s You have deleted \x04%s\x01's ban record [\04%s/%s/%s\x01].", PREFIX, infoExploded[1], sTime[0], sTime[1], sTime[2]);
			SQL_TQuery(g_DB, Db_deleteBan, sQuery);
		}
	}
	if (action == MenuAction_Cancel)
	{
		openBansList(client);
	}
	if (action == MenuAction_End)
	{
		delete menu;
	}
}


public void resetFields(int client)
{
	g_isEditing[client] = -1;
	g_editTime[client] = 30;
	g_editName[client] = "";
	g_editReason[client] = "";
	g_editId[client] = -1;
	g_editBan[client] = false;
	g_isSearching[client] = "-1";
}

public int getIndexFromId(int id)
{
	for (int i = 1; i < 256; i++)
	{
		if (namesList[i][Id] != id)continue;
		return i;
		
	}
	return -1;
}


DB_Connect()
{
	if (g_DB != INVALID_HANDLE)
		CloseHandle(g_DB);
	
	char error[255];
	g_DB = SQL_Connect("nblocker", true, error, sizeof(error));
	
	if (g_DB == INVALID_HANDLE)
	{
		LogError(error);
		CloseHandle(g_DB);
	}
	else
	{
		char query[512];
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS names(id INTEGER NOT NULL,name TEXT,ban INTEGER NOT NULL,reason TEXT,bantime INTEGER NOT NULL)");
		SQL_TQuery(g_DB, DB_Connect_Callback, query);
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS bans(name TEXT,auth TEXT,reason TEXT,message TEXT,server TEXT,date INTEGER NOT NULL,bantime INTEGER NOT NULL)");
		SQL_TQuery(g_DB, DB_Connect_Callback, query);
	}
}
public DB_Connect_Callback(Handle owner, Handle hndl, char[] error, any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
	}
}
public DB_SaveBan(Handle owner, Handle hndl, char[] error, any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
	}
}
public Db_deleteBan(Handle owner, Handle hndl, char[] error, any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError(error);
	}
}



stock char SQLSecure(char[] string)
{
	char secured[255];
	
	SQL_EscapeString(g_DB, string, secured, sizeof(secured));
	return secured;
}
stock GetHostName(char[] str, size)
{
	static Handle hHostName;
	
	if (hHostName == INVALID_HANDLE)
	{
		if ((hHostName = FindConVar("hostname")) == INVALID_HANDLE)
		{
			return;
		}
	}
	
	GetConVarString(hHostName, str, size);
}
