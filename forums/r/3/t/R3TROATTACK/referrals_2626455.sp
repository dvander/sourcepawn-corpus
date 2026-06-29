#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Retro"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

int g_iClientCode[MAXPLAYERS + 1];
int g_iReferralCount[MAXPLAYERS + 1];
bool g_bWasReferred[MAXPLAYERS + 1];

bool g_bLoading[MAXPLAYERS + 1];

StringMap g_smReferralCommands;

Database g_hDatabase;

Menu g_hRewardsMenu;

float g_fPlayTime[MAXPLAYERS + 1];
float g_fLastTeamJoin[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Referrals",
	author = PLUGIN_AUTHOR,
	description = "A referral system with rewards",
	version = PLUGIN_VERSION,
	url = "www.memerland.com"
};

ConVar g_cPlayTimeConVar;

public void OnPluginStart()
{
	g_smReferralCommands = new StringMap();
	RegConsoleCmd("sm_getcode", Command_GetCode);
	RegConsoleCmd("sm_redeem", Command_Redeem);
	RegConsoleCmd("sm_referrals", Command_Referrals);
	AddCommandListener(Listener_JoinTeam, "jointeam");
	
	g_cPlayTimeConVar = CreateConVar("referrals_playtime", "30", "The amount of playtime needed for the referral to count", FCVAR_NONE, true, 0.0);
	AutoExecConfig(true, "referrals");
	SQL_LoadDatabase();
}

public Action Listener_JoinTeam(int client, const char[] command, int argc)
{
	char sTeam[32];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	int team = StringToInt(sTeam);
	int curTeam = GetClientTeam(client);
	if(curTeam < 2)
	{
		if(team >= 2)
			g_fLastTeamJoin[client] = GetGameTime();
		return Plugin_Continue;
	}
	
	g_fPlayTime[client] += GetGameTime() - g_fLastTeamJoin[client];
	g_fLastTeamJoin[client] = GetGameTime();
	return Plugin_Continue;
}

public Action Listener_Rewards(int client, const char[] command, int argc)
{
	int count = 0;
	if(!g_smReferralCommands.GetValue(command, count))
		return Plugin_Continue;
	if(g_iReferralCount[client] >= count)
		return Plugin_Continue;
	
	PrintToChat(client, " \x06[Referrals] \x01You must refer at least \x02%d \x01more people to use this command.", count - g_iReferralCount[client]);
	return Plugin_Stop;
}

public void OnMapStart()
{
	g_smReferralCommands.Clear();
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/referrals.cfg");
	if(!FileExists(path))
	{
		SetFailState("Referrals config file doesnt exist at path \"%s\"", path);
	}
	
	KeyValues kv = new KeyValues("Referrals");
	kv.ImportFromFile(path);
	if(!kv.GotoFirstSubKey())
		SetFailState("No first subkey");
	
	do 
	{
		char section[64];
		kv.GetSectionName(section, sizeof(section));
		AddCommandListener(Listener_Rewards, section);
		g_smReferralCommands.SetValue(section, kv.GetNum("amount"));
	} while (kv.GotoNextKey());
	kv.Rewind();
	CloseHandle(kv);
	
	CreateRewardsMenu();
}

public void CreateRewardsMenu()
{
	if(g_hRewardsMenu != null)
		CloseHandle(g_hRewardsMenu);
	StringMapSnapshot snap = g_smReferralCommands.Snapshot();
	Menu menu = new Menu(MenuHandler_ReferralRewards);
	menu.SetTitle("Referral Rewards");
	for (int i = 0; i < snap.Length; i++)
	{
		char command[64];
		snap.GetKey(i, command, sizeof(command));
		
		int count = 0;
		g_smReferralCommands.GetValue(command, count);

		if(count == 0)
			continue;
		
		char display[128];
		Format(display, sizeof(display), "To unlock %s you must refer %d player%s", command, count, count > 1 ? "s" : "");
		menu.AddItem("", display, ITEMDRAW_DISABLED);
	}
	menu.ExitBackButton = true;
	menu.ExitButton = true;
	g_hRewardsMenu = menu;
}

public void OnMapEnd()
{
	StringMapSnapshot snap = g_smReferralCommands.Snapshot();
	for (int i = 0; i < snap.Length; i++)
	{
		char command[64];
		snap.GetKey(i, command, sizeof(command));
		
		RemoveCommandListener(Listener_Rewards, command);
	}
}

public int MenuHandler_ReferralRewards(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_Cancel:
		{
			if(choice == MenuCancel_ExitBack)
				CreateReferralsMainMenu(client).Display(client, MENU_TIME_FOREVER);
		}
	}
}

public Action Command_Referrals(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;
		
	if(g_bLoading[client])
	{
		PrintToChat(client, " \x06[Referrals] \x01Please wait till your client settings have been loaded to get a referral code.");
		return Plugin_Handled;
	}
	
	Menu menu = CreateReferralsMainMenu(client);
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

Menu CreateReferralsMainMenu(int client)
{
	Menu menu = new Menu(MenuHandler_ReferralsMain);
	menu.SetTitle("Referrals Main Menu\n\n    Your referal code is: %d\n    You have refered %d player%s!", g_iClientCode[client], g_iReferralCount[client], g_iReferralCount[client] != 1 ? "s": "");
	menu.AddItem("help", "Referrals Information");
	menu.AddItem("rewards", "Referral Rewards");
	
	menu.ExitBackButton = false;
	menu.ExitButton = true;
	return menu;
}

public int MenuHandler_ReferralsMain(Menu m, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(choice == 0)
			{
				Panel panel = new Panel();
				panel.SetTitle("Referrals Info\n");
				panel.DrawText("To refer players you must first get your referal code\nThis can be found at the main menu or !getcode");
				char display[128];
				Format(display, sizeof(display), "The person who refers your code via !redeem code\nThey must play on the server for at least %d minutes", g_cPlayTimeConVar.IntValue);
				panel.DrawText(display);
				panel.DrawItem("", ITEMDRAW_SPACER);
				Format(display, sizeof(display), "To redeem someone else's code\nYou must do !redeem code and play for at least %dmins", g_cPlayTimeConVar.IntValue);
				panel.DrawText(display);
				panel.DrawItem("", ITEMDRAW_SPACER);
				panel.CurrentKey = 7;
				panel.DrawItem("Back", ITEMDRAW_DEFAULT);
				panel.DrawItem("", ITEMDRAW_SPACER);
				panel.DrawItem("Exit", ITEMDRAW_DEFAULT);
				panel.Send(client, MenuHandler_ReferralsInfo, MENU_TIME_FOREVER);
			}
			else if(choice == 1)
			{
				g_hRewardsMenu.Display(client, MENU_TIME_FOREVER);
			}
		}
		case MenuAction_End:
		{
			delete m;
		}
	}
}

public int MenuHandler_ReferralsInfo(Menu menu, MenuAction action, int client, int choice)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(choice == 7)
				CreateReferralsMainMenu(client).Display(client, MENU_TIME_FOREVER);
		}
		case MenuAction_End:
		{
			delete menu;
		}
	}
}

public Action Command_GetCode(int client, int args)
{
	if(g_bLoading[client])
	{
		PrintToChat(client, " \x06[Referrals] \x01Please wait till your client settings have been loaded to get a referral code.");
		return Plugin_Handled;
	}
	
	PrintToChat(client, " \x06[Referrals] \x01Your referral code is \x04%d", g_iClientCode[client]);
	return Plugin_Handled;
}

public Action Command_Redeem(int client, int args)
{
	if(g_bLoading[client])
	{
		PrintToChat(client, " \x06[Referrals] \x01Please wait till your client settings have been loaded to redeem a referral code.");
		return Plugin_Handled;
	}
	
	char arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	int code = StringToInt(arg);
	if(code < 1)
	{
		PrintToChat(client, " \x06[Referrals] \x01The code you tried to use is not a valid code!");
		return Plugin_Handled;
	}
	
	if(code == g_iClientCode[client])
	{
		PrintToChat(client, " \x06[Referrals] \x01You cannot refer yourself silly.");
		return Plugin_Handled;
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
			continue;
		
		if(g_iClientCode[i] == code)
		{
			if(g_fPlayTime[client] >= g_cPlayTimeConVar.FloatValue * 60.0)
				g_iReferralCount[i]++;
			else
				PrintToChat(i, " \x06[Referrals] \x0B%N's \x01referral will be valid when they have played for \x04%d \x01minutes.", client, g_cPlayTimeConVar.FloatValue);
			break;
		}
	}
	char sQuery[256];
	Format(sQuery, sizeof(sQuery), "SELECT userid, name, reffered FROM referrals WHERE userid=%d LIMIT 1;", code);
	DataPack pack = new DataPack();
	pack.WriteCell(GetClientUserId(client));
	pack.WriteCell(code);
	g_hDatabase.Query(SQLCallback_ReferralCheck, sQuery, pack);
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	g_bLoading[client] = true;
	if(!IsValidClient(client))
		return;
		
	g_iClientCode[client] = 0;
	g_iReferralCount[client] = 0;
	g_fPlayTime[client] = 0.0;
	g_bWasReferred[client] = false;
	g_bLoading[client] = true;
	
	CreateTimer(1.0, Timer_LoadData, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientDisconnect(int client)
{
	if(!g_bLoading[client])
	{
		SQL_UpdatePlaytime(client, g_fPlayTime[client] + GetClientTeam(client) >= 2 ? GetGameTime() - g_fLastTeamJoin[client] : 0.0);
	}
	
	g_iClientCode[client] = 0;
	g_iReferralCount[client] = 0;
	g_fPlayTime[client] = 0.0;
	g_bWasReferred[client] = false;
	g_bLoading[client] = true;
}

public void SQL_LoadDatabase()
{
	if (!SQL_CheckConfig("referrals"))
		SetFailState("Database file incorrectly setup please insert \"referrals\" into the config file");
	Database.Connect(SQLCallback_Connect, "referrals");
}

public void SQLCallback_Connect(Database db, const char[] error, any data)
{
	if(db == null)
	{
		LogError("Failed to connect to database: %s", error);
		CreateTimer(60.0, Timer_RetryConnect, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	g_hDatabase = db;
	char sQuery[256+128];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS referrals (userid INT AUTO_INCREMENT NOT NULL, steamid varchar(64) NOT NULL, name varchar(64) NULL, reffered INT DEFAULT 0, refferedby INT DEFAULT 0, playtime FLOAT(10,3) DEFAULT 0.0, PRIMARY KEY (userid), UNIQUE KEY referrals_unique (steamid));");
	db.Query(SQLCallback_CreateTable, sQuery);
}

public void SQLCallback_CreateTable(Database db, DBResultSet results, const char[] error, any data)
{
	if(db == null || results == null)
	{
		SetFailState("Failed to create tables: %s", error);
		return;
	}
	
	for (int i = 1; i <= MaxClients; i++)
		if(IsValidClient(i))
			OnClientPostAdminCheck(i);
}

public Action Timer_RetryConnect(Handle timer)
{
	if(g_hDatabase == null)
		SQL_LoadDatabase();
}

public Action Timer_LoadData(Handle timer, any userid)
{
	int client = GetClientOfUserId(userid);
	if(!IsValidClient(client))
		return Plugin_Handled;
	
	char sQuery[256], steamid[64];
	if(!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		PrintToChat(client, " \x06[Referrals] \x01Your steamid was not able to successfully valid please reconnect to use the referrals features.");
		return Plugin_Handled;
	}
	float time = g_cPlayTimeConVar.FloatValue * 60.0;
	Format(sQuery, sizeof(sQuery), "SELECT userid, (SELECT COUNT(*) FROM referrals WHERE refferedby=(SELECT userid FROM referrals WHERE steamid='%s' LIMIT 1) AND playtime > %f) AS referred, refferedby FROM referrals WHERE steamid='%s' LIMIT 1;", steamid, time, steamid);
	g_hDatabase.Query(SQLCallback_LoadData, sQuery, userid);
	return Plugin_Handled;
}

public void SQLCallback_LoadData(Database db, DBResultSet results, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if(db == null || results == null)
	{
		if(!IsValidClient(client))
			LogError("Failed to load player data: %s", error);
		else
			LogError("Failed to load player data for %L: %s", client, error);
	}
	
	if(results.RowCount == 0)
	{
		SQL_InsertNewPlayer(client);
		return;
	}
	
	char sQuery[256], steamid[64], name[MAX_NAME_LENGTH * 2 + 1];
	if (GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		GetClientName(client, name, sizeof(name));
		g_hDatabase.Escape(name, name, sizeof(name));
		Format(sQuery, sizeof(sQuery), "UPDATE referrals SET name='%s' WHERE steamid='%s';", name, steamid);
		g_hDatabase.Query(SQLCallback_Generic, sQuery);
	}
	
	results.FetchRow();
	g_iClientCode[client] = results.FetchInt(0);
	g_iReferralCount[client] = results.FetchInt(1);
	g_bWasReferred[client] = 0 != results.FetchInt(2);
	g_bLoading[client] = false;
}

public void SQL_InsertNewPlayer(int client)
{
	char sQuery[256], steamid[64], name[MAX_NAME_LENGTH * 2 + 1];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
	{
		PrintToChat(client, " \x06[Referrals] \x01Your steamid was not able to successfully valid please reconnect to use the referrals features.");
		return;
	}
	
	GetClientName(client, name, sizeof(name));
	g_hDatabase.Escape(name, name, sizeof(name));
	Format(sQuery, sizeof(sQuery), "INSERT INTO referrals (steamid, name) VALUES ('%s', '%s');", steamid, name);
	g_hDatabase.Query(SQLCallback_InsertNewPlayer, sQuery, GetClientUserId(client));
}

public void SQL_UpdatePlaytime(int client, float time)
{
	char sQuery[256], steamid[64];
	if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
		return;
		
	Format(sQuery, sizeof(sQuery), "UPDATE referrals SET playtime=playtime+%f WHERE steamid='%s';", time, steamid);
	PrintToServer(sQuery);
	g_hDatabase.Query(SQLCallback_Generic, sQuery);
}

public void SQLCallback_ReferralCheck(Database db, DBResultSet results, const char[] error, DataPack data)
{
	data.Reset();
	int client = GetClientOfUserId(data.ReadCell());
	int code = data.ReadCell();
	delete data;
	if(results == null || db == null)
	{
		LogError("Failed to check for referral: %s", error);
		if(IsValidClient(client))
			PrintToChat(client, " \x06[Referrals] \x01For some reason the database lost connection please try again later.");
		return;
	}
	
	if(results.RowCount == 0)
	{
		PrintToChat(client, " \x06[Referrals] \x01The code \x04$d \x01is not a valid code. :(", code);
		return;
	}
	
	results.FetchRow();
	char name[MAX_NAME_LENGTH];
	results.FetchString(1, name, sizeof(name));
	PrintToChatAll(" \x06[Referrals] \x0B%s \x01has just referred \x04%N \x01bring their total up to \x0E%d\x01.", name, client, results.FetchInt(2) + 1);
	char sQuery[128];
	Format(sQuery, sizeof(sQuery), "UPDATE referrals SET reffered=reffered+1 WHERE userid=%d;", code);
	g_hDatabase.Query(SQLCallback_Generic, sQuery);
	Format(sQuery, sizeof(sQuery), "UPDATE referrals SET refferedby=%d WHERE userid=%d;", code, g_iClientCode[client]);
	g_hDatabase.Query(SQLCallback_Generic, sQuery);
}

public void SQLCallback_InsertNewPlayer(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null || db == null)
	{
		LogError("Failed to insert new player: %s", error);
		return;
	}
	Timer_LoadData(null, data);
}

public void SQLCallback_Generic(Database db, DBResultSet results, const char[] error, any data)
{
	if(results == null || db == null)
	{
		LogError("Generic sql error statement: %s", error);
	}
}

bool IsValidClient(int client)
{
	return (0 < client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}