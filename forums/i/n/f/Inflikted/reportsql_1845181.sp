#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <adminmenu>
#define PLUGIN_VERSION  "1.1"

public Plugin:myinfo = {
	name = "SQL Player Report",
	author = "MasterOfTheXP",
	description = "Report players to admins with SQL.",
	version = PLUGIN_VERSION,
	url = "http://mstr.ca/"
};

new Target[MAXPLAYERS + 1];
new Float:LastUsedReport[MAXPLAYERS + 1];
new Handle:g_hDatabase = INVALID_HANDLE;
new Handle:cvarDelay;
new String:configLines[256][192];
new lines;
new Handle:ServerNumber;


public OnPluginStart()
{
	RegAdminCmd("sm_report", Command_report,  ADMFLAG_CUSTOM1, "Report bad players on the server");
	cvarDelay = CreateConVar("sm_playerreport_delay","900.0","Time, in seconds, to delay the target of sm_rocket's death.", FCVAR_NONE, true, 0.0);
	ServerNumber 	=	CreateConVar("sm_report_serverid","1","Server Number", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	SQL_TConnect(sql_Connected);
}

public OnClientPutInServer(client)
{
	Target[client] = 0;
	LastUsedReport[client] = GetGameTime();
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (Target[z] == client) Target[z] = 0;
	}
}

public Action:Command_report(client, args)
{

	if (LastUsedReport[client] + GetConVarFloat(cvarDelay) > GetGameTime())
	{
		ReplyToCommand(client, "[PR] You must wait %i seconds before submitting another report.", RoundFloat((LastUsedReport[client] + RoundFloat(GetConVarFloat(cvarDelay))) - RoundFloat(GetGameTime())));
		return Plugin_Handled;
	}
	if (args == 0) ChooseTargetMenu(client);
	else if (args == 1)
	{
		new String:arg1[128];
		GetCmdArg(1, arg1, 128);
		Target[client] = FindTarget(client, arg1, true, true);
		if (!IsValidClient(Target[client]))
		{
			ReplyToCommand(client, "[PR] %t", "No matching client");
			return Plugin_Handled;
		}
		ReasonMenu(client);
	}
	else if (args > 1)
	{
		new String:arg1[128], String:arg2[256];
		GetCmdArg(1, arg1, 128);
		GetCmdArgString(arg2, 256);
		ReplaceStringEx(arg2, 256, arg1, "");
		new target = FindTarget(client, arg1, true, true);
		if (!IsValidClient(target))
		{
			ReplyToCommand(client, "[PR] %t", "No matching client");
			return Plugin_Handled;
		}
		ReportPlayer(client, target, arg2);
	}
	return Plugin_Handled;
}

stock ReportPlayer(client, target, String:reason[])
{
	if (!IsValidClient(target))
	{
		PrintToChat(client, "[PR] The player you were going to report is no longer in-game.");
		return;
	}
	new String:configFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, configFile, sizeof(configFile), "configs/playerreport_logs.txt");
	new Handle:file = OpenFile(configFile, "at+");
	new String:ID1[50], String:ID2[50], String:date[50], String:time[50];
	GetClientAuthString(client, ID1, 50);
	GetClientAuthString(target, ID2, 50);
	FormatTime(date, 50, "%m/%d/%Y");
	FormatTime(time, 50, "%H:%M:%S");
	WriteFileLine(file, "User: %N [%s]\nReported: %N [%s]\nDate: %s\nTime: %s\nReason: \"%s\"\n-------\n\n", client, ID1, target, ID2, date, time, reason);
	CloseHandle(file);
	decl String:sQuery[512];
	new ServerNo = GetConVarInt(ServerNumber);				// Check the server number
	Format(sQuery, sizeof(sQuery), "INSERT INTO report (server, client, csteamid, target, tsteamid, reason) VALUES ('%i', '%N', '%s', '%N', '%s', '%s')", ServerNo, client, ID1, target, ID2, reason);
	new Handle:hQuery = CreateDataPack();
	WritePackString(hQuery, sQuery);
	SendQuery(sQuery);
	PrintToChat(client, "[PR] Report submitted.");
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (!IsValidClient(z)) continue;
		if (CheckCommandAccess(z, "sm_admin", ADMFLAG_GENERIC))
			PrintToChat(z, "[PR] %N reported %N (Reason: \"%s\")", client, target, reason);
	}
	PrintToServer("[PR] %N reported %N (Reason: \"%s\")", client, target, reason);
	LastUsedReport[client] = GetGameTime();
}

ChooseTargetMenu(client)
{
	new Handle:smMenu = CreateMenu(ChooseTargetMenuHandler);
	SetGlobalTransTarget(client);
	new String:text[128];
	Format(text, 128, "Report player:", client);
	SetMenuTitle(smMenu, text);
	SetMenuExitBackButton(smMenu, true);
	
	AddTargetsToMenu2(smMenu, client, COMMAND_FILTER_NO_BOTS);
	
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
}

public ChooseTargetMenuHandler(Handle:menu, MenuAction:action, client, param2)
{
	if (action == MenuAction_Select)
	{
		new String:info[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0) PrintToChat(client, "[PR] %t", "Player no longer available");
		else
		{
			if (client == target) ReplyToCommand(client, "[PR] Why would you report yourself?");
			else
			{
				Target[client] = target;
				ReasonMenu(client);
			}
		}
	}
}

ReasonMenu(client)
{
	new Handle:smMenu = CreateMenu(ReasonMenuHandler);
	SetGlobalTransTarget(client);
	new String:text[128];
	Format(text, 128, "Select reason:");
	SetMenuTitle(smMenu, text);
	lines = ReadConfig("playerreport_reasons");
	for (new z = 0; z <= lines - 1; z++)
	{
		AddMenuItem(smMenu, configLines[z], configLines[z]);
	}
	DisplayMenu(smMenu, client, MENU_TIME_FOREVER);
	return;
}

public ReasonMenuHandler(Handle:menu, MenuAction:action, client, item)
{
	if (action == MenuAction_Cancel && item == MenuCancel_ExitBack) CloseHandle(menu);
	if (action == MenuAction_Select)
	{
		new String:selection[128];
		GetMenuItem(menu, item, selection, 128);
		ReportPlayer(client, Target[client], selection);
	}
}

stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	if (!IsClientInGame(client)) return false;
	if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock ReadConfig(String:configName[])
{
	new String:configFile[PLATFORM_MAX_PATH];
	new String:line[192];
	new i = 0;
	new totalLines = 0;
	
	BuildPath(Path_SM, configFile, sizeof(configFile), "configs/%s.txt", configName);
	
	new Handle:file = OpenFile(configFile, "rt");
	
	if(file != INVALID_HANDLE)
	{
		while (!IsEndOfFile(file))
		{
			if (!ReadFileLine(file, line, sizeof(line)))
				break;
			
			TrimString(line);
			if(strlen(line) > 0)
			{
				FormatEx(configLines[i], 192, "%s", line);
				totalLines++;
			}
			
			i++;
			
			if(i >= sizeof(configLines))
			{
				LogError("%s config contains too many entries!", configName);
				break;
			}
		}
				
		CloseHandle(file);
	}
	else LogError("[SM] ERROR: Config sourcemod/configs/%s.txt does not exist.", configName);
	
	return totalLines;
}

public sql_Connected(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		SetFailState("Database failure: %s", error);
	}
	else
	{
		g_hDatabase = hndl;
	}

	CreateTables();
	SendQuery("SET NAMES 'utf8'");
}

public sql_Query(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		ResetPack(data);

		decl String:query[512];
		ReadPackString(data, query, sizeof(query));


		LogError("Query Failed! %s", error);
		LogError("Query: %s", query);
	}

	CloseHandle(data);
}

SendQuery(String:query[])
{
	new Handle:dp = CreateDataPack();
	WritePackString(dp, query);
	SQL_TQuery(g_hDatabase, sql_Query, query, dp);
}

CreateTables()
{
	static String:sQuery[] = "\
		CREATE TABLE IF NOT EXISTS `report` ( \
		  `id` int(11) NOT NULL AUTO_INCREMENT, \
		  `server` varchar(255) NOT NULL, \
		  `client` varchar(255) NOT NULL, \
		  `csteamid` varchar(255) NOT NULL, \
		  `target` varchar(255) NOT NULL, \
		  `tsteamid` varchar(255) NOT NULL, \
		  `reason` varchar(255) NOT NULL, \
		  `date` timestamp NOT NULL default CURRENT_TIMESTAMP, \
		  PRIMARY KEY (`id`) \
		) ENGINE=MyISAM DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;";

	SendQuery(sQuery);
}