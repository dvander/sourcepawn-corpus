#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required
#pragma tabsize 0
#define QUERY_DEFAULT_SIZE 256
#define PREFIX " \x04[Ban-Lister]\x01"
Database g_dbDataBase;
ArrayList g_aBanAdminsNames;
ArrayList g_aUnbanAdminsNames;
int g_iAdminImmunity[MAXPLAYERS + 1];
int g_iAdminIds[MAXPLAYERS + 1];
int g_iLastBansAmount[MAXPLAYERS + 1];
bool g_bAdminOwnsBan[MAXPLAYERS + 1] = {false};
char g_sAdminFlags[MAXPLAYERS + 1][20];
char g_sViewsId[MAXPLAYERS + 1][32];
ConVar g_cvAdminFlagsDelete;
ConVar g_cvAdminFlagsIp;
ConVar g_cvLastBansMaxAmount;
char g_sDeleteFlags[20];
char g_sIpFlags[20];
int g_iMaxBansAmount;
public Plugin myinfo = 
{
	name = "Ban lister for Sourcebans 2.0.0-dev",
	author = "SheriF",
	description = "Manage your bans in game.",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	g_cvAdminFlagsDelete = CreateConVar("sm_flag_show_delete", "z", "The flag required to use the delete ban option alongside admin's immunity (leave empty to disable).");
	g_cvAdminFlagsIp = CreateConVar("sm_flag_show_ip", "z", "The flag required to see the IP of banned clients (leave empty to disable).");
	g_cvLastBansMaxAmount = CreateConVar("sm_last_bans_amount", "10", "The defualt amount of bans to show when sm_lastbans issued without specific number.");
	g_aBanAdminsNames = new ArrayList(MAX_NAME_LENGTH, 0);
	g_aUnbanAdminsNames = new ArrayList(MAX_NAME_LENGTH, 0);
	RegAdminCmd("sm_banlist", Command_BanList, ADMFLAG_GENERIC, "Opens the ban list menu using name or steamid.");
	RegAdminCmd("sm_bl", Command_BanList, ADMFLAG_GENERIC, "Opens the ban list menu using name or steamid.");
	RegAdminCmd("sm_lastbans", Command_LastBans, ADMFLAG_GENERIC, "Opens the last bans menu.");
	char szError[QUERY_DEFAULT_SIZE];
	g_dbDataBase = SQL_Connect("sourcebans", true, szError, sizeof(szError));
	if(g_dbDataBase == null)
	{
		SetFailState("Faild to connect to the database. Error(%s)", szError);
		return;
	}
	else
		SQL_SetCharset(g_dbDataBase, "utf8");
	AutoExecConfig(true, "BanLister");
}
public void OnConfigsExecuted()
{
	GetConVarString(g_cvAdminFlagsDelete, g_sDeleteFlags, 20);
	GetConVarString(g_cvAdminFlagsIp, g_sIpFlags, 20);
	g_iMaxBansAmount = g_cvLastBansMaxAmount.IntValue;
}

public void OnClientPostAdminCheck(int client)
{
	if(CheckCommandAccess(client,"",ADMFLAG_GENERIC,true))
	{
		char szQuery[QUERY_DEFAULT_SIZE];
		char sId[32];
		GetClientAuthId(client, AuthId_Steam2, sId, 32);
		FormatEx(szQuery, sizeof(szQuery), "SELECT `id` FROM sb_admins WHERE identity LIKE 'STEAM__:%s';", sId[8]);
		SQL_TQuery(g_dbDataBase, PostAdminCheckCallback, szQuery, client, DBPrio_High);
	}
}
public Action Command_LastBans(int client,int args)
{
	DataPack dp = new DataPack();
	if(args==1)
	{
		char sAmount[6];
		GetCmdArg(1, sAmount, 6);
		int iAmount = StringToInt(sAmount);
		if(!IsNumeric(sAmount))
		{
			PrintToChat(client, "%s Usage: sm_lastbans <number>", PREFIX);
			return Plugin_Handled;
		}
		else
		{
			g_iLastBansAmount[client] = iAmount;
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `admin_id`, `unban_admin_id`, `id`, REVERSE(name), `steam`, `ip` FROM sb_bans ORDER BY create_time DESC LIMIT %d;", iAmount);
			dp.WriteCell(client);
			dp.WriteCell(iAmount);
			SQL_TQuery(g_dbDataBase, Command_LastBans_Callback, szQuery, dp, DBPrio_High);
		}		
	}
	else if (args==0)
	{
		g_iLastBansAmount[client] = g_iMaxBansAmount;
		char szQuery[QUERY_DEFAULT_SIZE];
		FormatEx(szQuery, sizeof(szQuery), "SELECT `admin_id`, `unban_admin_id`, `id`, REVERSE(name), `steam`, `ip` FROM sb_bans ORDER BY create_time DESC LIMIT %d;", g_iMaxBansAmount);
		dp.WriteCell(client);
		dp.WriteCell(g_iMaxBansAmount);
		SQL_TQuery(g_dbDataBase, Command_LastBans_Callback, szQuery, dp, DBPrio_High);
	}
	return Plugin_Continue;
}
public Action Command_BanList(int client,int args)
{
	DataPack dp = new DataPack();
	if(args==1)
	{
		char sName[MAX_NAME_LENGTH];
		GetCmdArg(1, sName, MAX_NAME_LENGTH);
		if(FindTarget(client, sName, true, false)==-1)
		{
			PrintToChat(client, "%s Target Not Found!", PREFIX);
			return Plugin_Handled;
		}
		else
		{
			int iClient = FindTarget(client, sName, true, false);
			char sId[32];
			GetClientAuthId(iClient, AuthId_Steam2, sId, 32);
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `create_time`, `admin_id`, `unban_admin_id`, `id` FROM sb_bans WHERE steam LIKE 'STEAM__:%s' ORDER BY `id` DESC LIMIT 1000", sId[8]);
        	dp.WriteString(sId);
        	dp.WriteCell(client);
			SQL_TQuery(g_dbDataBase, Command_BanList_Callback, szQuery, dp, DBPrio_High);
		}
	}
	else if(args==5)
	{
		char sId[32];
		GetCmdArgString(sId, 32);
		char szQuery[QUERY_DEFAULT_SIZE];
		FormatEx(szQuery, sizeof(szQuery), "SELECT `create_time`, `admin_id`, `unban_admin_id`, `id` FROM sb_bans WHERE steam LIKE 'STEAM__:%s' ORDER BY `id` DESC LIMIT 1000", sId[8]);
        dp.WriteString(sId);
        dp.WriteCell(client);
		SQL_TQuery(g_dbDataBase, Command_BanList_Callback, szQuery, dp, DBPrio_High);
	}
	else
	{
		PrintToChat(client, "%s Usage: sm_banlist <name|steamid>", PREFIX);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public void Command_LastBans_Callback(Handle owner, Handle hndl, const char[] error, DataPack data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	data.Reset();
	int client = data.ReadCell();
	int iAmount = data.ReadCell();
	delete data;
	if(row_count > 0)
	{
		Menu LastBansMenu = CreateMenu(Command_LastBans_MenuHandler);
		int counter = 0;
		while(SQL_FetchRow(hndl))
		{
			counter++;
			char menuline[64];
			char sBanId[6];
			char sName[MAX_NAME_LENGTH];
			char sId[32];
			char sIp[32];
			IntToString(SQL_FetchInt(hndl, 2), sBanId, 6);
			SQL_FetchString(hndl, 3, sName, MAX_NAME_LENGTH);
			SQL_FetchString(hndl, 4, sId, 32);
			SQL_FetchString(hndl, 5, sIp, 32);
			if(!StrEqual(sName,""))
			{
				char NameArgs[16][64];
				char FixedName[64];
				ExplodeString(sName, " ", NameArgs, 16, 64);
				for (int i = 0; i < 16;i++ )
				{
					if(IsArgAlpha(NameArgs[i]) && !StrEqual(NameArgs[i],""))
						ReplaceString(NameArgs[i], 16, NameArgs[i], ReverseString(NameArgs[i]));
				}
				for (int i = 0; i < 16;i++ )
				{
					if(!StrEqual(NameArgs[i],""))
					{
						StrCat(FixedName, 64, " ");
						StrCat(FixedName, 64, NameArgs[i]);
					}
				}
				if(!IsArgAlpha(FixedName))
				{
					FormatEx(menuline, sizeof(menuline), "Ban#%d:%s", counter, ReverseStringOrder(FixedName));
					LastBansMenu.AddItem(sBanId, menuline);
				}
				else
				{
					FormatEx(menuline, sizeof(menuline), "Ban#%d:%s", counter, FixedName);
					LastBansMenu.AddItem(sBanId, menuline);
				}
			}
			else if(!StrEqual(sId,""))
			{
				FormatEx(menuline, sizeof(menuline), "Ban#%d: %s", counter,sId);
				LastBansMenu.AddItem(sBanId, menuline);
			}
			else if(!StrEqual(sIp,""))
			{
				FormatEx(menuline, sizeof(menuline), "Ban#%d: %s", counter,sIp);
				LastBansMenu.AddItem(sBanId, menuline);
			}
			else
			{
				FormatEx(menuline, sizeof(menuline), "Ban#%d: Not set", counter);
				LastBansMenu.AddItem(sBanId, menuline);
			}
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `name`, `id` FROM sb_admins WHERE id = %d", SQL_FetchInt(hndl, 0));
			SQL_TQuery(g_dbDataBase, Command_BanList_CallbackAdmin, szQuery,client, DBPrio_High);
			char szQuery2[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery2, sizeof(szQuery2), "SELECT `name`, `id` FROM sb_admins WHERE id = %d", SQL_FetchInt(hndl, 1));
			SQL_TQuery(g_dbDataBase, Command_BanList_CallbackUnbanAdmin, szQuery2,client, DBPrio_High);
		}
		LastBansMenu.SetTitle("The last %d bans", iAmount);
		LastBansMenu.ExitBackButton = true;		
		LastBansMenu.Display(client, MENU_TIME_FOREVER);
	}
}
public void Command_BanList_Callback(Handle owner, Handle hndl, const char[] error, DataPack data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	char sId[32];
	data.Reset();
	data.ReadString(sId, 32);
	int client = data.ReadCell();
	delete data;
	if(row_count > 0)
	{
		Menu BansMenu = CreateMenu(Command_BanList_MenuHandler);
		int counter = 0;
		while(SQL_FetchRow(hndl))
		{
			counter++;
			char menuline[64];
			char date[128];
			char sBanId[6];
			IntToString(SQL_FetchInt(hndl, 3), sBanId, 6);
			FormatTime(date, 128, NULL_STRING, SQL_FetchInt(hndl, 0));
			FormatEx(menuline, sizeof(menuline), "Ban: Issued on %s",date);
			BansMenu.AddItem(sBanId, menuline);
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `name`, `id` FROM sb_admins WHERE id = %d", SQL_FetchInt(hndl, 1));
			SQL_TQuery(g_dbDataBase, Command_BanList_CallbackAdmin, szQuery,client, DBPrio_High);
			char szQuery2[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery2, sizeof(szQuery2), "SELECT `name`, `id` FROM sb_admins WHERE id = %d", SQL_FetchInt(hndl, 2));
			SQL_TQuery(g_dbDataBase, Command_BanList_CallbackUnbanAdmin, szQuery2,client, DBPrio_High);
		}
		BansMenu.SetTitle("Ban list of %s\nTotal bans: %d", sId, counter);
		BansMenu.Display(client, MENU_TIME_FOREVER);
	}
	else
	PrintToChat(client, "%s No bans were found matching the name|steamid you entered.", PREFIX);
}
public void Command_BanList_CallbackUnbanAdmin(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		if(SQL_FetchRow(hndl))
		{
			char name[MAX_NAME_LENGTH];
			char UnbanAdminID[5];
			SQL_FetchString(hndl, 0, name, sizeof(name));
			g_aUnbanAdminsNames.PushString(name);
			IntToString(SQL_FetchInt(hndl, 1), UnbanAdminID, 5);
			g_aUnbanAdminsNames.PushString(UnbanAdminID);
		}
	}
}
public void Command_BanList_CallbackAdmin(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		if(SQL_FetchRow(hndl))
		{
			char name[MAX_NAME_LENGTH];
			char AdminID[5];
			SQL_FetchString(hndl, 0, name, sizeof(name));
			g_aBanAdminsNames.PushString(name);
			IntToString(SQL_FetchInt(hndl, 1), AdminID, 5);
			g_aBanAdminsNames.PushString(AdminID);
		}
	}
}

public void Command_BanList_Callback2(Handle owner, Handle hndl, const char[] error, DataPack data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		char date[128];
		data.Reset();
		int iBanId = data.ReadCell();
		int client = data.ReadCell();
		delete data;
		Menu BanMenu = CreateMenu(Command_BanList_MenuHandler2);
		while(SQL_FetchRow(hndl))
		{
			int CreateTime = SQL_FetchInt(hndl, 0);
			FormatTime(date, 128, NULL_STRING, CreateTime);
			BanMenu.SetTitle("The ban Issued on %s",date);
			if(iBanId==SQL_FetchInt(hndl, 7))
			{
				char name[MAX_NAME_LENGTH];
				char AdminName[MAX_NAME_LENGTH];
				char UnbanAdminName[MAX_NAME_LENGTH];
				char reason[512];
				char menuline[128];
				char menuline2[128];
				char menuline3[128];
				char menuline4[128];
				char menuline5[128];
				char menuline7[128];
				char menuline8[128];
				char ExpireDate[128];
				char sId[32];
				SQL_FetchString(hndl, 1, name, sizeof(name));
				SQL_FetchString(hndl, 2, reason, sizeof(reason));
				SQL_FetchString(hndl, 9, sId, sizeof(sId));
				strcopy(g_sViewsId[client], 32, sId);
				int length = SQL_FetchInt(hndl, 3);
				int iUnbanStamp = SQL_FetchInt(hndl, 4);
				if(!StrEqual(name,""))
				{
					char NameArgs[16][64];
					char FixedName[64];
					ExplodeString(name, " ", NameArgs, 16, 64);
					for (int i = 0; i < 16;i++ )
					{
						if(IsArgAlpha(NameArgs[i]) && !StrEqual(NameArgs[i],""))
							ReplaceString(NameArgs[i], 16, NameArgs[i], ReverseString(NameArgs[i]));
					}
					for (int i = 0; i < 16;i++ )
					{
						if(!StrEqual(NameArgs[i],""))
						{
							StrCat(FixedName, 64, " ");
							StrCat(FixedName, 64, NameArgs[i]);
						}
					}
					if(!IsArgAlpha(FixedName))
					{
						FormatEx(menuline, sizeof(menuline), "Name:%s",ReverseStringOrder(FixedName));
						BanMenu.AddItem(FixedName, menuline, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(menuline, sizeof(menuline), "Name:%s",FixedName);
						BanMenu.AddItem(FixedName, menuline, ITEMDRAW_DISABLED);
					}
				}
				else
				{
					FormatEx(menuline, sizeof(menuline), "Name: Not set");
					BanMenu.AddItem(name, menuline, ITEMDRAW_DISABLED);
				}
				if(!StrEqual(sId,""))
				{
					FormatEx(menuline8, sizeof(menuline8), "SteamID: %s",sId);
					BanMenu.AddItem(sId, menuline8, ITEMDRAW_DISABLED);
				}
				else
				{
					FormatEx(menuline8, sizeof(menuline8), "SteamID: Not set");
					BanMenu.AddItem(sId, menuline8, ITEMDRAW_DISABLED);
				}
				if((StrEqual(g_sAdminFlags[client],"z",false) && !StrEqual(g_sIpFlags,"")) || StrContains(g_sAdminFlags[client],g_sIpFlags,false)!=-1)
				{
					char sIp[64];
					SQL_FetchString(hndl, 8, sIp, sizeof(sIp));
					if(!StrEqual(sIp,""))
					{					
						FormatEx(menuline7, sizeof(menuline7), "IP: %s",sIp);
						BanMenu.AddItem(sIp, menuline7, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(menuline7, sizeof(menuline7), "IP: Not set");
						BanMenu.AddItem(sIp, menuline7, ITEMDRAW_DISABLED);
					}
				}
				char ReasonArgs[32][64];
				char menulinereason[512];
				char FixedReason[512];
				ExplodeString(reason, " ", ReasonArgs, 32, 64);
				for (int i = 0; i < 32;i++ )
				{
					if(IsArgAlpha(ReasonArgs[i]) && !StrEqual(ReasonArgs[i],""))
						ReplaceString(ReasonArgs[i], 64, ReasonArgs[i], ReverseString(ReasonArgs[i]));
				}
				for (int i = 0; i < 32;i++ )
				{
					if(!StrEqual(ReasonArgs[i],""))
					{
						StrCat(FixedReason, 512, " ");
						StrCat(FixedReason, 512, ReasonArgs[i]);
					}
				}
				if(!IsArgAlpha(FixedReason))
				{
					FormatEx(menulinereason, sizeof(menulinereason), "Reason:%s",ReverseStringOrder(FixedReason));
					BanMenu.AddItem(FixedReason, menulinereason, ITEMDRAW_DISABLED);
				}
				else
				{
					FormatEx(menulinereason, sizeof(menulinereason), "Reason:%s",FixedReason);
					BanMenu.AddItem(FixedReason, menulinereason, ITEMDRAW_DISABLED);
				}
				if(length>0)
				{
					char sLength[128];
					ShowTime((length * 60), sLength, 128);
					FormatEx(menuline2, sizeof(menuline2), "Length: %s",sLength);
					BanMenu.AddItem(menuline2, menuline2, ITEMDRAW_DISABLED);
					int iEndStamp = length * 60 + CreateTime;
					if(iEndStamp<=GetTime())
					{
						FormatTime(ExpireDate, 128, NULL_STRING, iEndStamp);
						FormatEx(menuline5, sizeof(menuline5), "Expired on: %s",ExpireDate);
						BanMenu.AddItem(menuline5, menuline5, ITEMDRAW_DISABLED);
					}
					else if(iUnbanStamp>0)
					{
						FormatTime(ExpireDate, 128, NULL_STRING, iUnbanStamp);
						FormatEx(menuline5, sizeof(menuline5), "Expired on: %s",ExpireDate);
						BanMenu.AddItem(menuline5, menuline5, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatTime(ExpireDate, 128, NULL_STRING, iEndStamp);
						FormatEx(menuline5, sizeof(menuline5), "Will expire on: %s",ExpireDate);
						BanMenu.AddItem(menuline5, menuline5, ITEMDRAW_DISABLED);
					}					
				}
				else
				{
					FormatEx(menuline2, sizeof(menuline2), "Length: Permanent");
					BanMenu.AddItem(menuline2, menuline2, ITEMDRAW_DISABLED);
				}
				char AdminID[5];
				IntToString(SQL_FetchInt(hndl, 5), AdminID, 5);
				int index = g_aBanAdminsNames.FindString(AdminID);
				if(index!=-1)
				{
					g_aBanAdminsNames.GetString(index - 1, AdminName, MAX_NAME_LENGTH);
					FormatEx(menuline3, sizeof(menuline3), "Banned by: %s",AdminName);
					BanMenu.AddItem(menuline3, menuline3, ITEMDRAW_DISABLED);
					g_aBanAdminsNames.Clear();
				}
				else
				{
					FormatEx(menuline3, sizeof(menuline3), "Banned by: CONSOLE");
					BanMenu.AddItem(menuline3, menuline3, ITEMDRAW_DISABLED);
				}
				if(SQL_FetchInt(hndl, 6)!=0)
				{
					char UnbanAdminID[5];
					IntToString(SQL_FetchInt(hndl, 6), UnbanAdminID, 5);
					int unbanindex = g_aUnbanAdminsNames.FindString(UnbanAdminID);
					if(index!=-1)
					{
						g_aUnbanAdminsNames.GetString(unbanindex - 1, UnbanAdminName, MAX_NAME_LENGTH);
						FormatEx(menuline4, sizeof(menuline4), "UnBanned by: %s",UnbanAdminName);
						BanMenu.AddItem(menuline4, menuline4, ITEMDRAW_DISABLED);
						g_aUnbanAdminsNames.Clear();
					}
					else
					{
						FormatEx(menuline4, sizeof(menuline4), "UnBanned by: CONSOLE");
						BanMenu.AddItem(menuline4, menuline4, ITEMDRAW_DISABLED);
					}
				}
				for (int i = 1; i <= MaxClients;i++)
				{
					if(g_iAdminIds[client]==SQL_FetchInt(hndl, 5))
						g_bAdminOwnsBan[i] = true;
				}
				DataPack dp = new DataPack();
				dp.WriteCell(client);
				dp.WriteCell(BanMenu);
				dp.WriteCell(SQL_FetchInt(hndl, 7));
				dp.WriteCell(length);
				dp.WriteCell(CreateTime);
				dp.WriteCell(iUnbanStamp);
				dp.WriteCell(SQL_FetchInt(hndl, 5));
				char szQuery2[QUERY_DEFAULT_SIZE];
				FormatEx(szQuery2, sizeof(szQuery2), "SELECT `group_id` FROM sb_admins_server_groups WHERE admin_id = %d", SQL_FetchInt(hndl, 5));
				SQL_TQuery(g_dbDataBase, GetGroupIdCallback, szQuery2,dp, DBPrio_High);	
			}
		}
		BanMenu.ExitBackButton = true;		
		BanMenu.Display(client, MENU_TIME_FOREVER);
	}
}
public void Command_LastBans_Callback2(Handle owner, Handle hndl, const char[] error, DataPack data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		char date[128];
		data.Reset();
		int iBanId = data.ReadCell();
		int client = data.ReadCell();
		delete data;
		Menu BanMenu = CreateMenu(Command_LastBans_MenuHandler2);
		while(SQL_FetchRow(hndl))
		{
			int CreateTime = SQL_FetchInt(hndl, 0);
			FormatTime(date, 128, NULL_STRING, CreateTime);
			BanMenu.SetTitle("The ban Issued on %s",date);
			if(iBanId==SQL_FetchInt(hndl, 7))
			{
				char name[MAX_NAME_LENGTH];
				char AdminName[MAX_NAME_LENGTH];
				char UnbanAdminName[MAX_NAME_LENGTH];
				char reason[512];
				char menuline[128];
				char menuline2[128];
				char menuline3[128];
				char menuline4[128];
				char menuline5[128];
				char menuline7[128];
				char menuline8[128];
				char ExpireDate[128];
				char sId[32];
				SQL_FetchString(hndl, 1, name, sizeof(name));
				SQL_FetchString(hndl, 2, reason, sizeof(reason));
				SQL_FetchString(hndl, 9, sId, sizeof(sId));
				strcopy(g_sViewsId[client], 32, sId);
				int length = SQL_FetchInt(hndl, 3);
				int iUnbanStamp = SQL_FetchInt(hndl, 4);
				if(!StrEqual(name,""))
				{
					char NameArgs[16][64];
					char FixedName[64];
					ExplodeString(name, " ", NameArgs, 16, 64);
					for (int i = 0; i < 16;i++ )
					{
						if(IsArgAlpha(NameArgs[i]) && !StrEqual(NameArgs[i],""))
							ReplaceString(NameArgs[i], 16, NameArgs[i], ReverseString(NameArgs[i]));
					}
					for (int i = 0; i < 16;i++ )
					{
						if(!StrEqual(NameArgs[i],""))
						{
							StrCat(FixedName, 64, " ");
							StrCat(FixedName, 64, NameArgs[i]);
						}
					}
					if(!IsArgAlpha(FixedName))
					{
						FormatEx(menuline, sizeof(menuline), "Name:%s",ReverseStringOrder(FixedName));
						BanMenu.AddItem(FixedName, menuline, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(menuline, sizeof(menuline), "Name:%s",FixedName);
						BanMenu.AddItem(FixedName, menuline, ITEMDRAW_DISABLED);
					}
				}
				else
				{
					FormatEx(menuline, sizeof(menuline), "Name: Not set");
					BanMenu.AddItem(name, menuline, ITEMDRAW_DISABLED);
				}
				if(!StrEqual(sId,""))
				{
					FormatEx(menuline8, sizeof(menuline8), "SteamID: %s",sId);
					BanMenu.AddItem(sId, menuline8, ITEMDRAW_DISABLED);
				}
				else
				{
					FormatEx(menuline8, sizeof(menuline8), "SteamID: Not set");
					BanMenu.AddItem(sId, menuline8, ITEMDRAW_DISABLED);
				}
				if((StrEqual(g_sAdminFlags[client],"z",false) && !StrEqual(g_sIpFlags,"")) || StrContains(g_sAdminFlags[client],g_sIpFlags,false)!=-1)
				{
					char sIp[64];
					SQL_FetchString(hndl, 8, sIp, sizeof(sIp));
					if(!StrEqual(sIp,""))
					{					
						FormatEx(menuline7, sizeof(menuline7), "IP: %s",sIp);
						BanMenu.AddItem(sIp, menuline7, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatEx(menuline7, sizeof(menuline7), "IP: Not set");
						BanMenu.AddItem(sIp, menuline7, ITEMDRAW_DISABLED);
					}
				}
				char ReasonArgs[32][64];
				char menulinereason[512];
				char FixedReason[512];
				ExplodeString(reason, " ", ReasonArgs, 32, 64);
				for (int i = 0; i < 32;i++ )
				{
					if(IsArgAlpha(ReasonArgs[i]) && !StrEqual(ReasonArgs[i],""))
						ReplaceString(ReasonArgs[i], 64, ReasonArgs[i], ReverseString(ReasonArgs[i]));
				}
				for (int i = 0; i < 32;i++ )
				{
					if(!StrEqual(ReasonArgs[i],""))
					{
						StrCat(FixedReason, 512, " ");
						StrCat(FixedReason, 512, ReasonArgs[i]);
					}
				}
				if(!IsArgAlpha(FixedReason))
				{
					FormatEx(menulinereason, sizeof(menulinereason), "Reason:%s",ReverseStringOrder(FixedReason));
					BanMenu.AddItem(FixedReason, menulinereason, ITEMDRAW_DISABLED);
				}
				else
				{
					FormatEx(menulinereason, sizeof(menulinereason), "Reason:%s",FixedReason);
					BanMenu.AddItem(FixedReason, menulinereason, ITEMDRAW_DISABLED);
				}
				if(length>0)
				{
					char sLength[128];
					ShowTime((length * 60), sLength, 128);
					FormatEx(menuline2, sizeof(menuline2), "Length: %s",sLength);
					BanMenu.AddItem(menuline2, menuline2, ITEMDRAW_DISABLED);
					int iEndStamp = length * 60 + CreateTime;
					if(iEndStamp<=GetTime())
					{
						FormatTime(ExpireDate, 128, NULL_STRING, iEndStamp);
						FormatEx(menuline5, sizeof(menuline5), "Expired on: %s",ExpireDate);
						BanMenu.AddItem(menuline5, menuline5, ITEMDRAW_DISABLED);
					}
					else if(iUnbanStamp>0)
					{
						FormatTime(ExpireDate, 128, NULL_STRING, iUnbanStamp);
						FormatEx(menuline5, sizeof(menuline5), "Expired on: %s",ExpireDate);
						BanMenu.AddItem(menuline5, menuline5, ITEMDRAW_DISABLED);
					}
					else
					{
						FormatTime(ExpireDate, 128, NULL_STRING, iEndStamp);
						FormatEx(menuline5, sizeof(menuline5), "Will expire on: %s",ExpireDate);
						BanMenu.AddItem(menuline5, menuline5, ITEMDRAW_DISABLED);
					}					
				}
				else
				{
					FormatEx(menuline2, sizeof(menuline2), "Length: Permanent");
					BanMenu.AddItem(menuline2, menuline2, ITEMDRAW_DISABLED);
				}
				char AdminID[5];
				IntToString(SQL_FetchInt(hndl, 5), AdminID, 5);
				int index = g_aBanAdminsNames.FindString(AdminID);
				if(index!=-1)
				{
					g_aBanAdminsNames.GetString(index - 1, AdminName, MAX_NAME_LENGTH);
					FormatEx(menuline3, sizeof(menuline3), "Banned by: %s",AdminName);
					BanMenu.AddItem(menuline3, menuline3, ITEMDRAW_DISABLED);
					g_aBanAdminsNames.Clear();
				}
				else
				{
					FormatEx(menuline3, sizeof(menuline3), "Banned by: CONSOLE");
					BanMenu.AddItem(menuline3, menuline3, ITEMDRAW_DISABLED);
				}
				if(SQL_FetchInt(hndl, 6)!=0)
				{
					char UnbanAdminID[5];
					IntToString(SQL_FetchInt(hndl, 6), UnbanAdminID, 5);
					int unbanindex = g_aUnbanAdminsNames.FindString(UnbanAdminID);
					if(index!=-1)
					{
						g_aUnbanAdminsNames.GetString(unbanindex - 1, UnbanAdminName, MAX_NAME_LENGTH);
						FormatEx(menuline4, sizeof(menuline4), "UnBanned by: %s",UnbanAdminName);
						BanMenu.AddItem(menuline4, menuline4, ITEMDRAW_DISABLED);
						g_aUnbanAdminsNames.Clear();
					}
					else
					{
						FormatEx(menuline4, sizeof(menuline4), "UnBanned by: CONSOLE");
						BanMenu.AddItem(menuline4, menuline4, ITEMDRAW_DISABLED);
					}
				}
				for (int i = 1; i <= MaxClients;i++)
				{
					if(g_iAdminIds[client]==SQL_FetchInt(hndl, 5))
						g_bAdminOwnsBan[i] = true;
				}
				DataPack dp = new DataPack();
				dp.WriteCell(client);
				dp.WriteCell(BanMenu);
				dp.WriteCell(SQL_FetchInt(hndl, 7));
				dp.WriteCell(length);
				dp.WriteCell(CreateTime);
				dp.WriteCell(iUnbanStamp);
				dp.WriteCell(SQL_FetchInt(hndl, 5));
				char szQuery2[QUERY_DEFAULT_SIZE];
				FormatEx(szQuery2, sizeof(szQuery2), "SELECT `group_id` FROM sb_admins_server_groups WHERE admin_id = %d", SQL_FetchInt(hndl, 5));
				SQL_TQuery(g_dbDataBase, GetGroupIdCallback, szQuery2,dp, DBPrio_High);	
			}
		}
		BanMenu.AddItem(g_sViewsId[client], "Previous Bans");
		BanMenu.ExitBackButton = true;		
		BanMenu.Display(client, MENU_TIME_FOREVER);
	}
}

public int Command_BanList_MenuHandler(Menu menu, MenuAction action, int client, int ItemNum)
{
	if(action == MenuAction_Select)
	{
		char sBanId[6];
		menu.GetItem(ItemNum, sBanId, 6);
		int iBanId = StringToInt(sBanId);
		char szQuery[QUERY_DEFAULT_SIZE];
		FormatEx(szQuery, sizeof(szQuery), "SELECT `create_time`, REVERSE(name), REVERSE(reason), `length`, `unban_time`, `admin_id`, `unban_admin_id`, `id`, `ip`, `steam` FROM sb_bans WHERE id=%d", iBanId);
		DataPack dp = new DataPack();
        dp.WriteCell(iBanId);
        dp.WriteCell(client);
		SQL_TQuery(g_dbDataBase, Command_BanList_Callback2, szQuery, dp, DBPrio_High);
	}
}
public int Command_LastBans_MenuHandler(Menu menu, MenuAction action, int client, int ItemNum)
{
	if(action == MenuAction_Select)
	{
		char sBanId[6];
		menu.GetItem(ItemNum, sBanId, 6);
		int iBanId = StringToInt(sBanId);
		char szQuery[QUERY_DEFAULT_SIZE];
		FormatEx(szQuery, sizeof(szQuery), "SELECT `create_time`, REVERSE(name), REVERSE(reason), `length`, `unban_time`, `admin_id`, `unban_admin_id`, `id`, `ip`, `steam` FROM sb_bans WHERE id=%d", iBanId);
		DataPack dp = new DataPack();
        dp.WriteCell(iBanId);
        dp.WriteCell(client);
		SQL_TQuery(g_dbDataBase, Command_LastBans_Callback2, szQuery, dp, DBPrio_High);
	}
}

public int Command_LastBans_MenuHandler2(Menu menu, MenuAction action, int client, int ItemNum)
{
	switch (action)
	{
    	case MenuAction_Cancel:
    	{
    		if(ItemNum == MenuCancel_ExitBack)
    		{
				FakeClientCommandEx(client, "sm_lastbans %d", g_iLastBansAmount[client]);
        	}
        }
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(ItemNum, sItem, 32);
			if(StrEqual(sItem,g_sViewsId[client]))
			{
				DataPack dp = new DataPack();
				char szQuery[QUERY_DEFAULT_SIZE];
				FormatEx(szQuery, sizeof(szQuery), "SELECT `create_time`, `admin_id`, `unban_admin_id`, `id` FROM sb_bans WHERE steam LIKE 'STEAM__:%s' ORDER BY `id` DESC LIMIT 1000", g_sViewsId[client][8]);
       			dp.WriteString(g_sViewsId[client]);
       			dp.WriteCell(client);
				SQL_TQuery(g_dbDataBase, Command_BanList_Callback, szQuery, dp, DBPrio_High);
			}
			else
			{
				char strings[3][16];
				ExplodeString(sItem, " ", strings, 3, 16);
				if(StrEqual(strings[0],"Delete"))
					ShowDeleteBanMenu(client,strings[1]);
				else if(StrEqual(strings[0],"Unban"))
					ShowUnbanMenu(client,strings[1],strings[2]);
			}
		}
	}
}
public int Command_BanList_MenuHandler2(Menu menu, MenuAction action, int client, int ItemNum)
{
	switch (action)
	{
    	case MenuAction_Cancel:
    	{
    		if(ItemNum == MenuCancel_ExitBack)
    		{
        		DataPack dp = new DataPack();
				char szQuery[QUERY_DEFAULT_SIZE];
				FormatEx(szQuery, sizeof(szQuery), "SELECT `create_time`, `admin_id`, `unban_admin_id`, `id` FROM sb_bans WHERE steam LIKE 'STEAM__:%s' ORDER BY `id` DESC LIMIT 1000", g_sViewsId[client][8]);
       			dp.WriteString(g_sViewsId[client]);
       			dp.WriteCell(client);
				SQL_TQuery(g_dbDataBase, Command_BanList_Callback, szQuery, dp, DBPrio_High);
        	}
        }
		case MenuAction_Select:
		{
			char sItem[32];
			menu.GetItem(ItemNum, sItem, 32);
			char strings[3][16];
			ExplodeString(sItem, " ", strings, 3, 16);
			if(StrEqual(strings[0],"Delete"))
				ShowDeleteBanMenu(client,strings[1]);
			else if(StrEqual(strings[0],"Unban"))
				ShowUnbanMenu(client,strings[1],strings[2]);
		}
	}
}
int ShowTime(int Time, char[] buffer,int sizef)
{
	int iDays = 0;
	int iHours = 0;
	int iMinutes = 0;
	int iSeconds = Time;
	while(iSeconds >= 86400)
	{
		iDays++;
		iSeconds -= 86400;
	}
	while(iSeconds >= 3600)
	{
		iHours++;
		iSeconds -= 3600;
	}
	while(iSeconds >= 60)
	{
		iMinutes++;
		iSeconds -= 60;
	}
	if(iDays >= 1)
	{
		Format(buffer, sizef, "%d days %d hours %d minutes %d seconds", iDays, iHours, iMinutes, iSeconds);
	}
	else if(iHours >= 1)
	{
		Format(buffer, sizef, "%d hours %d minutes %d seconds", iHours, iMinutes, iSeconds );
	}
	else if(iMinutes >= 1)
	{
		Format(buffer, sizef, "%d minutes %d seconds", iMinutes, iSeconds );
	}
	else
	{
		Format(buffer, sizef, "%d seconds", iSeconds );
	}
}
void ShowUnbanMenu(int client,char []banId,char []sAdminId)
{
	Menu menu = CreateMenu(Command_BanList_UnbanMenu);
	menu.SetTitle("Do you want to Unban this ban?");
	FormatEx(banId, 32, " %s", sAdminId);
	menu.AddItem(banId, "Yes");
	menu.AddItem("No", "No");
	menu.Display(client, MENU_TIME_FOREVER);
}
public int Command_BanList_UnbanMenu(Menu menu, MenuAction action, int client, int ItemNum)
{
	char szQuery[QUERY_DEFAULT_SIZE];
	FormatEx(szQuery, sizeof(szQuery), "SET FOREIGN_KEY_CHECKS=0;");
	SQL_TQuery(g_dbDataBase, Command_BanList_CallbackError, szQuery, DBPrio_High);	
	if(action == MenuAction_Select)
	{
		char sItem[32];
		menu.GetItem(ItemNum, sItem, 32);
		if(!StrEqual(sItem,"No"))
		{
			char strings[2][16];
			ExplodeString(sItem, " ", strings, 2, 16);
			FormatEx(szQuery, sizeof(szQuery), "UPDATE sb_bans SET unban_time = %d, unban_admin_id = %d WHERE id = %d", GetTime(), StringToInt(strings[1]),StringToInt(strings[0]));
			SQL_TQuery(g_dbDataBase, Command_BanList_CallbackErrorU, szQuery,client, DBPrio_High);	
		}
		else
			delete menu;
	}
	FormatEx(szQuery, sizeof(szQuery), "SET FOREIGN_KEY_CHECKS=1;");
	SQL_TQuery(g_dbDataBase, Command_BanList_CallbackError, szQuery, DBPrio_High);		
}
void ShowDeleteBanMenu(int client,char []banId)
{
	Menu menu = CreateMenu(Command_BanList_DeleteMenu);
	menu.SetTitle("Do you want to delete this ban?");
	menu.AddItem(banId, "Yes");
	menu.AddItem("No", "No");
	menu.Display(client, MENU_TIME_FOREVER);
}
public int Command_BanList_DeleteMenu(Menu menu, MenuAction action, int client, int ItemNum)
{
	if(action == MenuAction_Select)
	{
		char sItem[32];
		menu.GetItem(ItemNum, sItem, 32);
		if(!StrEqual(sItem,"No"))
		{
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "DELETE FROM sb_bans WHERE id = %d", StringToInt(sItem));
			SQL_TQuery(g_dbDataBase, Command_BanList_CallbackErrorD, szQuery,client, DBPrio_High);	
		}
		else
			delete menu;
	}	
}

public void Command_BanList_CallbackErrorD(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	else
	PrintToChat(client, "%s You \x07deleted\x01 the ban successfully!", PREFIX);
}
public void Command_BanList_CallbackErrorU(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	else
	PrintToChat(client, "%s You \x07Unbanned\x01 the ban successfully!", PREFIX);
}
public void Command_BanList_CallbackError(Handle owner, Handle hndl, const char[] error,any data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
}
public void PostAdminCheckCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		while(SQL_FetchRow(hndl))
		{
			g_iAdminIds[client] = SQL_FetchInt(hndl, 0);
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `group_id` FROM sb_admins_server_groups WHERE admin_id = %d",g_iAdminIds[client]);
			SQL_TQuery(g_dbDataBase, GetClientGroupIdCallback, szQuery,client, DBPrio_High);	
		}
	}
}

public void GetClientGroupIdCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		while(SQL_FetchRow(hndl))
		{
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `immunity`, `flags` FROM sb_server_groups WHERE id = %d", SQL_FetchInt(hndl,0));
			SQL_TQuery(g_dbDataBase, InsertClientGroupIdCallback, szQuery,client, DBPrio_High);	
		}
	}
}
public void GetGroupIdCallback(Handle owner, Handle hndl, const char[] error, DataPack data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		while(SQL_FetchRow(hndl))
		{
			char szQuery[QUERY_DEFAULT_SIZE];
			FormatEx(szQuery, sizeof(szQuery), "SELECT `immunity` FROM sb_server_groups WHERE id = %d", SQL_FetchInt(hndl,0));
			SQL_TQuery(g_dbDataBase, CheckGroupIdCallback, szQuery,data, DBPrio_High);	
		}
	}
}
public void InsertClientGroupIdCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		while(SQL_FetchRow(hndl))
		{
			g_iAdminImmunity[client] = SQL_FetchInt(hndl, 0);
			SQL_FetchString(hndl, 1, g_sAdminFlags[client], 20);
		}
	}
}
public void CheckGroupIdCallback(Handle owner, Handle hndl, const char[] error, DataPack Pack)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Faild to connect to the database. Error(%s)", error);
	}
	int row_count = SQL_GetRowCount(hndl);
	if(row_count > 0)
	{
		Pack.Reset();
		int client = Pack.ReadCell();
		Menu MenuAdd = Pack.ReadCell();
		int iBanId = Pack.ReadCell();
		int length = Pack.ReadCell();
		int CreateTime = Pack.ReadCell();
		int UnbanTime = Pack.ReadCell();
		int iAdminId = Pack.ReadCell();
		delete Pack;
		while(SQL_FetchRow(hndl))
		{
			if((SQL_FetchInt(hndl, 0)<g_iAdminImmunity[client]) || g_bAdminOwnsBan[client])
			{
				g_bAdminOwnsBan[client] = false;
				char UBanId[32];
				char sUBanId[32];
				int iEndStamp2 = (length * 60) + CreateTime;
				if(UnbanTime==0 && (length==0 || iEndStamp2>GetTime()))
				{
					IntToString(iBanId, sUBanId, 16);
					FormatEx(UBanId, sizeof(UBanId), "Unban %s %d", sUBanId, iAdminId);
					MenuAdd.AddItem(UBanId, "Unban this ban");
				}
				if((StrEqual(g_sAdminFlags[client],"z",false) && !StrEqual(g_sDeleteFlags,"")) || StrContains(g_sAdminFlags[client],g_sDeleteFlags,false)!=-1)
				{
					char DBanId[16];
					char sDBanId[16];
					IntToString(iBanId, sDBanId, 16);
					FormatEx(DBanId, sizeof(DBanId), "Delete %s",sDBanId);
					MenuAdd.AddItem(DBanId, "Delete this ban");
				}
				MenuAdd.Display(client, MENU_TIME_FOREVER);
			}
		}		
	}
}

stock bool IsArgAlpha(char []str)
{
	for (int i = 0; i < strlen(str); i++)
	{
		if(!StrEqual(str[i],"") && !IsCharAlpha(str[i]) && !(str[i] >=33 && str[i] <= 64) && !(str[i] >= 91 && str[i] <= 96))
			return false;
	}
	return true;
}
stock char ReverseString(char []str)
{
	char str2[512];
	for(int i = 0, j = strlen(str) - 1; i < strlen(str); i++, j--)
  			str2[i] = str[j];
  	return str2;
}
stock bool IsNumeric(const char[] buffer)
{
	int iLen = strlen(buffer);
	for (int i = 0; i < iLen; i++)
	{
		if (!IsCharNumeric(buffer[i]))
			return false;
	}
	return true;
}
stock char ReverseStringOrder(char []str)
{
	char str2[512];
	char strArgs[32][64];
	ArrayList Args;
	Args = new ArrayList(64, 0);
	ExplodeString(str, " ", strArgs, 32, 64);
	for (int i = 0; i < 32; i++)
	{
		if(!StrEqual(strArgs[i],""))
			Args.PushString(strArgs[i]);
	}
	for (int i = Args.Length-1; i >= 0; i--)
	{
		char temp[64];
		Args.GetString(i, temp, 64);
		if(IsArgAlpha(temp))
		{
			StrCat(str2, 512, " ");
			StrCat(str2, 512, temp);
		}
		else
		{
			char temp2[64];
			StrCat(str2, 512, " ");
			Args.GetString(Args.Length-i-1, temp2, 64);
			StrCat(str2, 512, temp2);
		}
	}
	Args.Clear();
  	return str2;
}