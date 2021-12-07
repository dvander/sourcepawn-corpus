#define PLUGIN_AUTHOR ".#Zipcore"
#define PLUGIN_NAME "MyBB - Playtime/Credits"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_DESCRIPTION "privet plugin #mufin"
#define PLUGIN_URL "zipcore.net"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>

#undef REQUIRE_PLUGIN

#include <zcore/zcore_mysql>
bool g_pZcoreMysql;

#include <store>
bool g_pStore;

#define CHARSET "utf8mb4"

#define LoopClients(%1) for(int %1 = 1; %1 <= MaxClients; %1++)
#define LoopIngameClients(%1) for(int %1=1;%1<=MaxClients;++%1)\
	if(IsClientInGame(%1))

/* Cvars */

ConVar g_cvCreditsReg;
int g_iCreditsReg;

ConVar g_cvPlaytimeTrigger;
int g_iPlaytimeTrigger;

/* Database */

bool g_bConnected;

/* Player */

char g_sAuth[MAXPLAYERS + 1][32];
bool g_bAuthed[MAXPLAYERS + 1];
bool g_bLoadedSQL[MAXPLAYERS + 1];
bool g_bGiveCredits[MAXPLAYERS + 1];
int g_iPlaytimeTemp[MAXPLAYERS + 1];
int g_iForumUserID[MAXPLAYERS + 1];
bool bHasClanID[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("mybb-playtime");
	
	MarkNativeAsOptional("Store_IsClientLoaded");
	MarkNativeAsOptional("Store_GetClientCredits");
	MarkNativeAsOptional("Store_SetClientCredits");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_pZcoreMysql = LibraryExists("zcore-mysql");
	g_pStore = LibraryExists("store_zephyrus");
	
	g_cvCreditsReg = CreateConVar("mybb_credits", "100", "Give this amount of credits players for registering to the forums.");
	g_iCreditsReg = GetConVarInt(g_cvCreditsReg);
	HookConVarChange(g_cvCreditsReg, OnSettingChanged);
	
	g_cvPlaytimeTrigger = CreateConVar("mybb_playtimer_trigger", "5", "How long to wait before upadting playtime on the database (seconds).");
	g_iPlaytimeTrigger = GetConVarInt(g_cvPlaytimeTrigger);
	HookConVarChange(g_cvPlaytimeTrigger, OnSettingChanged);

	AutoExecConfig(true, "mybb-playtime");
	
	RegConsoleCmd("profile", Cmd_Profile);
	
	StartPlaytimeTimer();
	
	CreateTimer(1.0, Timer_CheckClanIDs, _, TIMER_REPEAT);
}

public int OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_cvCreditsReg)
	g_iCreditsReg = StringToInt(newValue);
	else if (convar == g_cvPlaytimeTrigger)
	g_iPlaytimeTrigger = StringToInt(newValue);
}

public void OnMapEnd()
{
	ResetAuthTimers();
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "zcore-mysql"))
	g_pZcoreMysql = true;
	else if (StrEqual(name, "store_zephyrus"))
	g_pStore = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "zcore-mysql"))
	g_pZcoreMysql = false;
	else if (StrEqual(name, "store_zephyrus"))
	g_pStore = false;
}

public void ZCore_Mysql_OnDatabaseError (int index, char[] config, char[] error )
{
	if(!StrEqual(config, "mybb"))
	return;
	
	DatabaseError("ZCore_Mysql_OnDatabaseError", error);
	
	ResetPlayers();
}

void DatabaseError(const char[] sFunction, const char[] error)
{
	LogError("SQL Error on %s: %s", sFunction, error);
	
	g_iSQL = -1;
	g_hSQL = null;
	g_bConnected = false;
}

public void ZCore_Mysql_OnDatabaseConnected(int index, char[] config, Database connection_handle)
{
	if(!StrEqual(config, "mybb"))
	return;
	
	g_iSQL = index;
	g_hSQL = connection_handle;
	
	g_bConnected = true;
	LoadPlayers()
}

void ConnectDB()
{
	if(!g_pZcoreMysql)
	return;
	
	if(g_hSQL != null)
	return;
	
	ZCore_Mysql_Connect("mybb");
	
	if(g_hSQL != null)
	{
		g_bConnected = true;
		
		LoadPlayers()
	}
}

void ResetPlayers()
{
	LoopIngameClients(i)
	ResetPlayer(i);
}

void ResetPlayer(int client)
{
	g_bAuthed[client] = false;
	g_bLoadedSQL[client] = false;
	g_bGiveCredits[client] = false;
	g_iPlaytimeTemp[client] = 0;
	g_iForumUserID[client] = -1;
	bHasClanID[client] = false;
	
	RemoveUserFlags(client, Admin_Custom1);
	RemoveUserFlags(client, Admin_Custom2);
}

/* Auth */

int g_iLastConnect;

Handle g_hAuthTimer[MAXPLAYERS+1] = {null, ...};

void ResetAuthTimers()
{
	LoopClients(i)
	g_hAuthTimer[i] = null;
}

void CreateAuthTimer(int client)
{
	if(g_hAuthTimer[client] != null)
	CloseHandle(g_hAuthTimer[client]);
	
	DataPack pack;
	
	g_hAuthTimer[client] = CreateDataTimer(1.5, Timer_Auth, pack, TIMER_FLAG_NO_MAPCHANGE);
	
	pack.WriteCell(client);
	pack.WriteCell(GetClientUserId(client));
}

public Action Timer_Auth(Handle timer, Handle pack)
{
	ResetPack(pack);
	
	int client = ReadPackCell(pack);
	
	g_hAuthTimer[client] = null;
	
	if(IsClientInGame(client))
	{
		AuthPlayer(client);
		
		if(client != GetClientOfUserId(ReadPackCell(pack)))
		LogMessage("%N is not the same player anymore. UserID changed during the authentication.", client);
	}
	
	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	AuthPlayer(client);
}

void AuthPlayer(client)
{
	if(IsFakeClient(client))
	{
		ResetPlayer(client)
		return;
	}
	
	g_bAuthed[client] = false;
	g_bLoadedSQL[client] = false;
	g_bGiveCredits[client] = false;
	
	if(!g_bConnected || !g_pZcoreMysql)
	{
		// Don'T spam this if manny players connect at the same time
		if(GetTime() - g_iLastConnect > 1.0)
		{
			g_iLastConnect = GetTime();
			ConnectDB();
		}
		
		CreateAuthTimer(client);
		return;
	}
	
	g_bAuthed[client] = GetClientAuthId(client, AuthId_SteamID64, g_sAuth[client], 32);
	
	if(g_bAuthed[client] && g_bConnected)
	LoadPlayer(client);
	else CreateAuthTimer(client);
}

/* Load player */

void LoadPlayers()
{
	LoopIngameClients(i)
	LoadPlayer(i);
}

void LoadPlayer(int client)
{
	if(!g_bAuthed[client] || !g_bConnected)
	{
		CreateAuthTimer(client);
		return;
	}
	
	char sQuery[2048];
	FormatEx(sQuery, sizeof(sQuery), "SELECT `user_id`,`credits`,`time` FROM `users` WHERE `loginname` = %s", g_sAuth[client]);
	SQL_TQuery(g_hSQL, CallBack_Load, sQuery, GetClientUserId(client));
}

/* Check if player is registered etc. */

public void CallBack_Load(Handle owner, Handle hndl, const char[] error, any userid)
{
	// Player disconnected
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
	return;
	
	if (owner == null || hndl == null)
	{
		DatabaseError("CallBack_Load", error);
		return;
	}
	
	if(SQL_GetRowCount(hndl) && SQL_FetchRow(hndl))
	{
		g_iForumUserID[client] = SQL_FetchInt(hndl, 0);
		
		g_bLoadedSQL[client] = true;
		
		if(SQL_IsFieldNull(hndl, 1))
		{
			g_bGiveCredits[client] = true;
		}
		// else player got already credits for registering
		
		if(SQL_IsFieldNull(hndl, 2))
		{
			// playtime field is null, lets init it
			char sQuery[256];
			FormatEx(sQuery, sizeof(sQuery), "UPDATE `users` SET `time` = 1 WHERE `loginname` = %s", g_sAuth[client]);
			SQL_TQuery(g_hSQL, CallBack_Empty, sQuery);
		}
	}
	// else player is not registered to the forums
	
	if (g_iForumUserID[client] > 0)
	{
		AddUserFlags(client, Admin_Custom1);
		
		char sFile[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sFile, sizeof(sFile), "logs/mybb_playtime.log");
		LogToFile(sFile, "Player '%N' has connected with the ForumID '%i', giving custom1 flag.", client, g_iForumUserID[client]);
	}
	
	char sClanID[32];
	GetClientInfo(client, "cl_clanid", sClanID, sizeof(sClanID));
	
	if (StrEqual(sClanID, "9354872"))
	{
		AddUserFlags(client, Admin_Custom2);
		bHasClanID[client] = true;
	}
	else
	{
		bHasClanID[client] = false;
	}
}

public Action Timer_CheckClanIDs(Handle timer)
{
	char sClanID[32];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		continue;
		
		GetClientInfo(i, "cl_clanid", sClanID, sizeof(sClanID));
		
		if (!StrEqual(sClanID, "9354872") && bHasClanID[i])
		{
			CreateTimer(5.0, Timer_RemoveFlag, GetClientUserId(i), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action Timer_RemoveFlag(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client < 1)
	{
		return Plugin_Continue;
	}
	
	char sClanID[32];
	GetClientInfo(client, "cl_clanid", sClanID, sizeof(sClanID));
	
	if (!StrEqual(sClanID, "9354872") && bHasClanID[client])
	{
		RemoveUserFlags(client, Admin_Custom2);
		bHasClanID[client] = false;
	}
	
	return Plugin_Continue;
}

public void CallBack_Empty(Handle owner, Handle hndl, const char[] error, any data)
{
	if (owner == null || hndl == null)
	{
		DatabaseError("CallBack_Empty", error);
		return;
	}
}

/* Playtime */

void StartPlaytimeTimer()
{
	CreateTimer(1.0, Timer_Playtime, _, TIMER_REPEAT);
}

public Action Timer_Playtime(Handle timer, any data)
{
	LoopIngameClients(client)
	{
		if(GetClientTeam(client) <= CS_TEAM_SPECTATOR)
		continue;
		
		g_iPlaytimeTemp[client]++;
		
		if (g_iPlaytimeTemp[client] >= g_iPlaytimeTrigger)
		Stats_UpdatePlaytime(client);
	}
	
	return Plugin_Continue;
}

void Stats_UpdatePlaytime(int client)
{
	if(!g_bConnected || !g_pZcoreMysql || !client || !IsClientInGame(client) || IsFakeClient(client) || !g_bLoadedSQL[client])
	return;
	
	if(g_pStore && g_bGiveCredits[client] && Store_IsClientLoaded(client))
	{
		int credits = Store_GetClientCredits(client);
		Store_SetClientCredits(client, credits + g_iCreditsReg);
		
		char sQuery[256];
		FormatEx(sQuery, sizeof(sQuery), "UPDATE `users` SET `credits` = 1 WHERE `loginname` = %s", g_sAuth[client]);
		SQL_TQuery(g_hSQL, CallBack_Empty, sQuery);
		
		CPrintToChatAll("{darkred}%N {orange}got {green}%d {orange}credits for registering on our forums, register now on www.{darkred}The{default}EdgeClan.com {orange}to get your credits!", client, g_iCreditsReg);
		
		g_bGiveCredits[client] = false;
	}
	
	/* Check Admin Status */
	CheckAdmin(client);
	
	/* Update playtime */
	char sQuery[512];
	FormatEx(sQuery, sizeof(sQuery), "UPDATE `users` SET `time` = `time`+%d WHERE `loginname` = %s", g_iPlaytimeTemp[client], g_sAuth[client]);
	SQL_TQuery(g_hSQL, CallBack_Empty, sQuery);
	
	g_iPlaytimeTemp[client] = 0;
}

/* Commands */

public Action Cmd_Profile(int client, int args)
{
	if(!g_bConnected)
	{
		CPrintToChat(client, "The database is unavailable currently.");
		return Plugin_Handled;
	}
	
	if(g_iForumUserID[client] <= 0)
	{
		CPrintToChat(client, "{darkred}You are not registered on the forums, visit www.TheEdgeClan.com and register yourself to get {green}%d {darkred}credits.", g_iCreditsReg);
		return Plugin_Handled;
	}
	
	char sUrl[512];
	Format(sUrl, sizeof(sUrl), "http://cola-team.com/franug/webshortcuts2.php?web=Your forum profile;franug_is_pro;http://www.theedgeclan.com/member.php?action=profile&uid=%d", g_iForumUserID[client]);
	MOTD_OpenWindow(client, sUrl);
	
	return Plugin_Handled;
}

/* Admin */

public void CheckAdmin(int client)
{
	if(g_iForumUserID[client] <= 0)
	return;
	
	AdminId admid = GetUserAdmin(client);
	
	if (admid == INVALID_ADMIN_ID)
	{
		char sAuth[32];
		GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));
		admid = CreateAdmin(sAuth);
		SetUserAdmin(client, admid, true);
		
		GroupId iGroup = FindAdmGroup("mybb");
		if (iGroup == INVALID_GROUP_ID)
		{
			iGroup = CreateAdmGroup("mybb");
			SetAdmGroupAddFlagString(iGroup, "o");
		}
		
		AdminInheritGroup(admid, iGroup);
	}
}

SetAdmGroupAddFlagString(GroupId iGroup, const char[] sFlags)
{
	for (int i = 0;; i++)
	{
		if (sFlags[i] == '\0')
		return;
		
		AdminFlag flag;
		if (FindFlagByChar(sFlags[i], flag))
		SetAdmGroupAddFlag(iGroup, flag, true);
	}
}

/* Stocks */

stock void MOTD_OpenWindow(int iClient, char[] sUrl)
{
	Handle kv = CreateKeyValues("data");
	KvSetString(kv, "title", "Web");
	KvSetString(kv, "type", "2");
	KvSetString(kv, "msg", sUrl);
	ShowVGUIPanel(iClient, "info", kv, false);
	CloseHandle(kv);
}