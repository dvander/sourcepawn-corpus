#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.3"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <voiceannounce_ex>

#define MAX_TALKERS 64

Database g_hDatabase;

ConVar g_Debug;
ConVar g_OnlyAdmins;
ConVar g_Warmup;
ConVar g_TopList;
ConVar g_DbConfig;

int g_iTalkerId;

char g_szTopTalker[MAX_TALKERS][MAX_NAME_LENGTH];

float g_fTopTalker[MAX_TALKERS];
float g_fSpeaking[MAXPLAYERS + 1];

enum struct g_eTalkTime
{
	float Alive;
	float Dead;
	float T;
	float Ct;
	float Spec;
	float Total;
}

g_eTalkTime g_fTalkTime[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "MINFAS Talk Time",
	author = "MINFAS",
	description = "Saves how much players are speaking",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/minfas"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("talktime.phrases");
	g_Debug = CreateConVar("sm_talktime_debug", "0", "Show debug messages in client console?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_OnlyAdmins = CreateConVar("sm_talktime_onlyadmins", "0", "Only admins can see stats of others?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_Warmup = CreateConVar("sm_talktime_warmup", "1", "Enable logging while warmup is active?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	g_TopList = CreateConVar("sm_talktime_toplistsize", "30", "How many people will fit into toplist menu?", FCVAR_NOTIFY, true, 1.0, true, 64.0);
	g_DbConfig = CreateConVar("sm_talktime_database", "default", "Which database (from databases.cfg) should be used?", FCVAR_PROTECTED);

	RegConsoleCmd("sm_talktime", Command_TalkTime, "Show information in menu");
	RegConsoleCmd("sm_toptalkers", Command_TopTalkers, "Show list of players that spoke the most");
	
	HookEvent("player_death", Event_Cut, EventHookMode_Pre);
	HookEvent("player_spawn", Event_Cut, EventHookMode_Pre);
	HookEvent("player_team", Event_Cut, EventHookMode_Pre);
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			SendValues(i);
		}
	}
}

public void OnConfigsExecuted()
{
	char db[32];
	g_DbConfig.GetString(db, sizeof(db));
	if(!SQL_CheckConfig(db))
	{
		SetFailState("Database '%s' not found in databases.cfg", db);
		return;
	}
	else
	{
		Database.Connect(SQL_Connection, db);
	}
}

public void SQL_Connection(Database hDatabase, const char[] szError, int iData)
{
	if(hDatabase == null)
	{
		ThrowError(szError);
	}
	else
	{
		g_hDatabase = hDatabase;	
		g_hDatabase.Query(SQL_Error, "CREATE TABLE IF NOT EXISTS `sm_talktime` ( `id` INT NOT NULL AUTO_INCREMENT , `name` VARCHAR(128) NOT NULL , `steamid` VARCHAR(32) NOT NULL , `total` FLOAT NOT NULL DEFAULT '0' , `alive` FLOAT NOT NULL DEFAULT '0' , `dead` FLOAT NOT NULL DEFAULT '0' , `t` FLOAT NOT NULL DEFAULT '0' , `ct` FLOAT NOT NULL DEFAULT '0' , `spec` FLOAT NOT NULL DEFAULT '0' , PRIMARY KEY (`id`))");
		g_hDatabase.SetCharset("utf8mb4");
   	}
   	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			ClientCheck(i);
		}
	}
	
	g_hDatabase.Query(SQL_CheckTopTalkers, "SELECT `name`, `total` FROM `sm_talktime` WHERE `total`>=1 ORDER BY `total` DESC");
	
	if(g_Debug.BoolValue)
	{
		PrintToServer("[TalkTime debug] SQL Connected.");
	}
}

public void SQL_Error(Database hDatabase, DBResultSet hResults, const char[] szError, int iData)
{
    if(hResults == null)
    {
        ThrowError(szError);
    }
}

public void OnClientPostAdminCheck(int client)
{
	if(IsValidClient(client))
	{
		ClientCheck(client);
	}
}

void ClientCheck(int client)
{
	char szSteamId[18];
	char szQuery[256];
	
	GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));
	g_hDatabase.Format(szQuery, sizeof(szQuery), "SELECT * FROM `sm_talktime` WHERE `steamid`='%s'", szSteamId);
	
	DataPack pack = new DataPack();
	
	pack.WriteString(szSteamId);
	pack.WriteCell(GetClientUserId(client));

	g_hDatabase.Query(SQL_ClientCheck, szQuery, pack);
}

public void SQL_ClientCheck(Database hDatabase, DBResultSet hResults, const char[] szError, DataPack pack)
{
	if(hResults == null)
	{
		ThrowError(szError);
	}
	
	char szQuery[256];
	char szSteamId[18];
	char szName[MAX_NAME_LENGTH];
	char szDbName[MAX_NAME_LENGTH];
	
	pack.Reset();
	pack.ReadString(szSteamId, sizeof(szSteamId));
	int client = GetClientOfUserId(pack.ReadCell());
	
	delete pack;
	
	GetClientName(client, szName, sizeof(szName));
	
	if(hResults.RowCount != 0)
	{
		hResults.FetchRow();
		hResults.FetchString(1, szDbName, sizeof(szDbName));
		
		if(!StrEqual(szDbName, szName, true))
		{
			g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `sm_talktime` SET `name`='%s' WHERE `steamid`='%s'", szName, szSteamId);
			g_hDatabase.Query(SQL_Error, szQuery);
		}
		
		g_fTalkTime[client].Alive = hResults.FetchFloat(4);
		g_fTalkTime[client].Dead = hResults.FetchFloat(5);
		g_fTalkTime[client].T = hResults.FetchFloat(6);
		g_fTalkTime[client].Ct = hResults.FetchFloat(7);
		g_fTalkTime[client].Spec = hResults.FetchFloat(8);
		g_fTalkTime[client].Total = hResults.FetchFloat(3);
	}
	else
	{
		ClearValues(client);

		g_hDatabase.Format(szQuery, sizeof(szQuery), "INSERT INTO `sm_talktime` (name, steamid) VALUES ('%s', '%s')", szName, szSteamId);
		g_hDatabase.Query(SQL_Error, szQuery);
	}
}

public void SQL_CheckTopTalkers(Database hDatabase, DBResultSet hResults, const char[] szError, any iData)
{
	if(hResults == null)
	{
		ThrowError(szError);
	}
	
	while(hResults.FetchRow() && g_iTalkerId <= g_TopList.IntValue)
	{
		hResults.FetchString(0, g_szTopTalker[g_iTalkerId], sizeof(g_szTopTalker));
		g_fTopTalker[g_iTalkerId] = hResults.FetchFloat(1);
		g_iTalkerId++;
	}
}

public void OnClientDisconnect(int client)
{
	SendValues(client);
}

void SendValues(int client)
{
	char szSteamId[18];
	char szQuery[256];

	GetClientAuthId(client, AuthId_SteamID64, szSteamId, sizeof(szSteamId));

	g_hDatabase.Format(szQuery, sizeof(szQuery), "UPDATE `sm_talktime` SET `name`='%N', `total`='%f', `alive`='%f', `dead`='%f', `t`='%f', `ct`='%f', `spec`='%f' WHERE `steamid`='%s'", client, g_fTalkTime[client].Total, g_fTalkTime[client].Alive, g_fTalkTime[client].Dead, g_fTalkTime[client].T, g_fTalkTime[client].Ct, g_fTalkTime[client].Spec, szSteamId);
	g_hDatabase.Query(SQL_Error, szQuery);

	// probably not necessary but make sure everything is cleared.
	ClearValues(client);
}

void ClearValues(int client)
{
	g_fTalkTime[client].Alive = 0.0;
	g_fTalkTime[client].Dead = 0.0;
	g_fTalkTime[client].T = 0.0;
	g_fTalkTime[client].Ct = 0.0;
	g_fTalkTime[client].Spec = 0.0;
	g_fTalkTime[client].Total = 0.0;
	g_fSpeaking[client] = 0.0;
}

public Action Command_TalkTime(int client, int args)
{
	if (args < 1 || (g_OnlyAdmins.BoolValue && !CheckCommandAccess(client, "", ADMFLAG_GENERIC, true)))
	{
		TalkTimeMenu(client, client);
		return Plugin_Handled;
	}
	else if((g_OnlyAdmins.BoolValue && CheckCommandAccess(client, "", ADMFLAG_GENERIC, true)) || !g_OnlyAdmins.BoolValue)
	{
		char arg1[32];
		GetCmdArg(1, arg1, 32);
	   
		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS]; 
		int target_count; 
		bool tn_is_ml;
	   
		target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
	   
		if (target_count < 1)
		{
			ReplyToCommand(client, "%t", "No matching clients");
			return Plugin_Handled;
		}
	   
		if (target_count == 1)
		{
			TalkTimeMenu(client, target_list[0]);
			return Plugin_Handled;
		}
		
		Menu menu = new Menu(hListMenu, MENU_ACTIONS_ALL);
		menu.SetTitle("%t", "More than one client matched");
		for (int i = 0; i < target_count; i++)
		{
			if(IsValidClient(target_list[i]))
			{
				char buffer[128], timer[32], targetid[3];
				
				ShowTimer(g_fTalkTime[target_list[i]].Total, "", timer, sizeof(timer));
				Format(buffer, sizeof(buffer), "%N (%s)", target_list[i], timer); //pst..
				IntToString(target_list[i], targetid, sizeof(targetid));
				
				menu.AddItem(targetid, buffer);
			}
		}
		menu.Display(client, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

public int hListMenu(Menu menu, MenuAction action, int client, int index)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if(IsValidClient(client))
			{
				char szItem[64];
				menu.GetItem(index, szItem, sizeof(szItem));
				TalkTimeMenu(client, StringToInt(szItem));
			}
		}
		case MenuAction_End: delete menu;
	}
}

void TalkTimeMenu(int client, int talker)
{
	char buffer[128], info[32];
	Panel menu = CreatePanel();
	Format(buffer, sizeof(buffer), "%t", "My talk time", LANG_SERVER, talker);
	Format(info, sizeof(info), "%t", "Talk time", LANG_SERVER, talker);
	menu.SetTitle((talker == client)?buffer:info);
	
	Format(info, sizeof(info), "%t", "Total Talk Time", LANG_SERVER);
	ShowTimer(g_fTalkTime[talker].Total, info, buffer, sizeof(buffer));
	menu.DrawText(buffer);

	Format(info, sizeof(info), "%t", "Alive", LANG_SERVER);
	ShowTimer(g_fTalkTime[talker].Alive, info, buffer, sizeof(buffer));
	menu.DrawText(buffer);
	
	Format(info, sizeof(info), "%t", "Dead", LANG_SERVER);
	ShowTimer(g_fTalkTime[talker].Dead, info, buffer, sizeof(buffer));
	menu.DrawText(buffer);
	
	Format(info, sizeof(info), "%t", "Ct", LANG_SERVER);
	ShowTimer(g_fTalkTime[talker].Ct, info, buffer, sizeof(buffer));
	menu.DrawText(buffer);
	
	Format(info, sizeof(info), "%t", "T", LANG_SERVER);
	ShowTimer(g_fTalkTime[talker].T, info, buffer, sizeof(buffer));
	menu.DrawText(buffer);
	
	Format(info, sizeof(info), "%t", "Spec", LANG_SERVER);
	ShowTimer(g_fTalkTime[talker].Spec, info, buffer, sizeof(buffer));
	menu.DrawText(buffer);

	Format(info, sizeof(info), "%t", "Close menu", LANG_SERVER);
	menu.DrawItem(info, ITEMDRAW_DEFAULT);
	menu.Send(client, hTalkTimeMenu, MENU_TIME_FOREVER);
}

public int hTalkTimeMenu(Menu menu, MenuAction action, int client, int index)
{
	delete menu;
}

public Action Command_TopTalkers(int client, int args)
{
	Menu menu = new Menu(hTopListMenu, MENU_ACTIONS_ALL);
	menu.SetTitle("%t", "Top Talkers");
	
	for (int i; i < g_iTalkerId; i++)
	{
		char timer[128], buffer[128], info[3];
		ShowTimer(g_fTopTalker[i], "", timer, sizeof(timer));
		Format(buffer, sizeof(buffer), "%s (%s)", g_szTopTalker[i], timer);
		IntToString(i, info, sizeof(info));
		menu.AddItem(info, buffer, ITEMDRAW_DISABLED);
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int hTopListMenu(Menu menu, MenuAction action, int client, int index)
{
	switch(action)
	{
		case MenuAction_End: delete menu;
		case MenuAction_DrawItem: return ITEMDRAW_DISABLED;
	}
	return 0;
}

public void OnClientSpeakingEx(int client)
{
	if(g_fSpeaking[client] <= 0.0)
	{
		g_fSpeaking[client] = GetGameTime();
		if(g_Debug.BoolValue)
		{
			PrintToConsole(client, "[TalkTime debug] You started speaking.");
		}
	}
}

public void OnClientSpeakingEnd(int client)
{
	WriteValues(client, IsPlayerAlive(client));
}

public Action Event_Cut(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsValidClient(client))
	{
		if(IsClientSpeaking(client))
		{
			WriteValues(client, false);
		}
	}
}

void WriteValues(int client, bool alive)
{
	if(g_fSpeaking[client] > 0.01)
	{
		g_fSpeaking[client] = GetGameTime() - g_fSpeaking[client];
		
		if(g_Debug.BoolValue)
		{
			PrintToConsole(client, "[TalkTime debug] You spoke %.2f seconds. (Total: %.2f)", g_fSpeaking[client], g_fTalkTime[client].Total);
		}
		
		if(g_Warmup.BoolValue || (!g_Warmup.BoolValue && GameRules_GetProp("m_bWarmupPeriod") == 0))
		{
			if(alive == true)
			{
				g_fTalkTime[client].Alive += g_fSpeaking[client];
			}
			else
			{
				g_fTalkTime[client].Dead += g_fSpeaking[client];
			}
			
			if(GetClientTeam(client) == CS_TEAM_T)
			{
				g_fTalkTime[client].T += g_fSpeaking[client];
			}
			else if(GetClientTeam(client) == CS_TEAM_CT)
			{
				g_fTalkTime[client].Ct += g_fSpeaking[client];
			}
			else if(GetClientTeam(client) == CS_TEAM_SPECTATOR)
			{
				g_fTalkTime[client].Spec += g_fSpeaking[client];
			}
		}
		
		g_fTalkTime[client].Total += g_fSpeaking[client];
	}
	
	g_fSpeaking[client] = 0.0;	
}

int ShowTimer(float Time, char[] add, char[] buffer, int sizef)
{
	int g_iMinutes = 0;
	int g_iHours = 0;
	float g_fSeconds = Time;
	
	char hours[16];
	char minutes[16];
	char seconds[16];
	
	Format(hours, sizeof(hours), "%t", "Hours");
	Format(minutes, sizeof(minutes), "%t", "Minutes");
	Format(seconds, sizeof(seconds), "%t", "Seconds");

	while(g_fSeconds > 3600.0)
	{
		g_iHours++;
		g_fSeconds -= 3600.0;
	}
	while(g_fSeconds > 60.0)
	{
		g_iMinutes++;
		g_fSeconds -= 60.0;
	}
	if(g_iHours >= 1)
	{
		Format(buffer, sizef, "%d %s %d %s %.0f %s", g_iHours, hours, g_iMinutes, minutes, g_fSeconds, seconds);
	}
	else if(g_iMinutes >= 1)
	{
		Format(buffer, sizef, "%d %s %.0f %s", g_iMinutes, minutes, g_fSeconds, seconds);
	}
	else
	{
		Format(buffer, sizef, "%.0f %s", g_fSeconds, seconds);
	}
	Format(buffer, sizef, "%s%s", add, buffer);
}

stock bool IsValidClient(int client)
{
	if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}