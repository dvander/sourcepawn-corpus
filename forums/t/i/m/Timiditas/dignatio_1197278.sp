//DO NOT OPEN DB CONNECTION BEFORE LOADING CONFIGURATION!
/*
dignatio -onis f. [esteem; dignity , reputation, honor].




There is an sql syntax error hidden somewhere. I added some debug logging (which might consume a bit of cpu and memory).
If you find any error messages in dignatio.log, post them to:
https://forums.alliedmods.net/showthread.php?p=1197278

*/

new debug_version = 1;

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "0.6.1a"
#define DBVERSION 9
#define MAX_LINE_WIDTH 66

#define WEAPON_COUNT 26
#define WP_PLAYERS 64
#define SQLSIZE_MAX 8192

new Handle:CV_recordheat = INVALID_HANDLE;
new bool:Recordheat = false;
new DeathCount;
new hTimestamps[65];
new hX[65];
new hY[65];
new Handle:CV_heatbots = INVALID_HANDLE;
new Handle:CV_cleanheat_count = INVALID_HANDLE;
new Handle:CV_cleanheat_date = INVALID_HANDLE;


new hitbox_stats[WP_PLAYERS + 1][8]; //temporary array that will be emptied on flush to DB

new session_stats[WP_PLAYERS + 1][WEAPON_COUNT][2];	//0 = shots fired, 1 = hits - temporary array that holds session stats
new String:weapon_ID[WP_PLAYERS + 1][64];
new weapon_stats[WP_PLAYERS + 1][WEAPON_COUNT][2];	//0 = shots fired, 1 = hits - temporary array that will be emptied on flush to DB
new String: weaponlist[][] = { "ak47", "m4a1", "awp", "deagle", "mp5navy", "aug",
																"p90", "famas", "galil", "scout", "g3sg1", "hegrenade",
																"usp", "glock", "m249", "m3", "elite", "fiveseven",
																"mac10", "p228", "sg550", "sg552", "tmp", "ump45",
																"xm1014", "knife" };
new String: limblist[][] = { "head", "chest", "stomach", "left arm", "right arm", "left leg", "right leg" };

//0.4.2 --> 0.4.2.9, plugin taken over by Timiditas with permission from alliedmods user "r5053", original author of the TF2 port
//0.5.2.3 --> 0.6  changed plugin name and version cvar

new Handle:hTopMenu = INVALID_HANDLE;
new Handle:hGGimport = INVALID_HANDLE;
new bool:import_running = false;
new import_client;

new Handle:CV_m4a1 = INVALID_HANDLE;
new Handle:CV_ak47 = INVALID_HANDLE;
new Handle:CV_scout = INVALID_HANDLE;
new Handle:CV_hegrenade = INVALID_HANDLE;
new Handle:CV_deagle = INVALID_HANDLE;
new Handle:CV_knife = INVALID_HANDLE;
new Handle:CV_sg552 = INVALID_HANDLE;
new Handle:CV_p90 = INVALID_HANDLE;
new Handle:CV_aug = INVALID_HANDLE;
new Handle:CV_usp = INVALID_HANDLE;
new Handle:CV_famas = INVALID_HANDLE;
new Handle:CV_mp5navy = INVALID_HANDLE;
new Handle:CV_galil = INVALID_HANDLE;
new Handle:CV_m249 = INVALID_HANDLE;
new Handle:CV_m3 = INVALID_HANDLE;
new Handle:CV_glock = INVALID_HANDLE;
new Handle:CV_p228 = INVALID_HANDLE;
new Handle:CV_elite = INVALID_HANDLE;
new Handle:CV_xm1014 = INVALID_HANDLE;
new Handle:CV_fiveseven = INVALID_HANDLE;
new Handle:CV_tmp = INVALID_HANDLE;
new Handle:CV_ump45 = INVALID_HANDLE;
new Handle:CV_mac10 = INVALID_HANDLE;
new Handle:CV_sg550 = INVALID_HANDLE;
new Handle:CV_awp = INVALID_HANDLE;
new Handle:CV_g3sg1 = INVALID_HANDLE;

new Handle:CV_conrankpaneltime = INVALID_HANDLE;
new Handle:CV_infopaneltime = INVALID_HANDLE;
new Handle:CV_toppaneltime = INVALID_HANDLE;
new Handle:CV_sessionrankpaneltime = INVALID_HANDLE;

new Handle:CV_bomb_planted = INVALID_HANDLE;
new Handle:CV_bomb_defused = INVALID_HANDLE;
new Handle:CV_bomb_exploded = INVALID_HANDLE;
new Handle:CV_hostage_follows = INVALID_HANDLE;
new Handle:CV_hostage_rescued = INVALID_HANDLE;
new Handle:CV_hostage_killed_CT = INVALID_HANDLE;
new Handle:CV_hostage_killed_T = INVALID_HANDLE;

new Handle:CV_pointmsg = INVALID_HANDLE;
new Handle:CV_chattag = INVALID_HANDLE;

new Handle:CV_diepoints = INVALID_HANDLE;

new Handle:CV_suicidepoints = INVALID_HANDLE;
new Handle:CV_worldkillpoints = INVALID_HANDLE;
new Handle:CV_teamkillpoints = INVALID_HANDLE;
new Handle:CV_botteamkillpoints = INVALID_HANDLE;
new Handle:CV_botteamkillrecord = INVALID_HANDLE;

new Handle:CV_removeoldplayers = INVALID_HANDLE;
new Handle:CV_removeoldplayersdays = INVALID_HANDLE;
new Handle:CV_removevoyeurhours = INVALID_HANDLE;
new Handle:CV_removeoldmaps = INVALID_HANDLE;
new Handle:CV_removeoldmapssdays = INVALID_HANDLE;
new Handle:CV_deductpoints = INVALID_HANDLE;

new Handle:CV_teamwinpoints = INVALID_HANDLE;
new Handle:CV_teamlosepoints = INVALID_HANDLE;

new Handle:CV_showrankonconnect = INVALID_HANDLE;
new Handle:CV_webrank = INVALID_HANDLE;
new Handle:CV_webrankurl = INVALID_HANDLE;
new Handle:CV_disableafterroundwin = INVALID_HANDLE;
new Handle:CV_neededplayercount = INVALID_HANDLE;
new Handle:CV_showrankonroundend = INVALID_HANDLE;

new Handle:CV_botpoints = INVALID_HANDLE;
new Handle:CV_botfactor = INVALID_HANDLE;

new Handle:CV_enable = INVALID_HANDLE;
new Handle:CV_announcements = INVALID_HANDLE;
new Handle:CV_chatannounce = INVALID_HANDLE;
new Handle:WerbeTimer = INVALID_HANDLE;

new Handle:CV_tableprefix = INVALID_HANDLE;
new Handle:CV_bottopmessage = INVALID_HANDLE;
new Handle:CV_noGG = INVALID_HANDLE;

new ME_Enable = 1;
new dblocked = 0;
new FirstRun = 1;

new mapisset;

new Handle:db = INVALID_HANDLE;			/** Database connection */

new RandomApproval;

new sqllite = 0;
new bool:rankingactive = false;

new HostageCanGetPoints[MAXPLAYERS + 1][16];
//Here we store what player already has gotten points for letting follow a specific hostage, so he can't exploit this

new onconrank[MAXPLAYERS + 1];
new onconpoints[MAXPLAYERS + 1];
new rankedclients = 0;
new playerpoints[MAXPLAYERS + 1];
new playerrank[MAXPLAYERS + 1];

new wprankmode[MAXPLAYERS + 1];

new playerGGwins[MAXPLAYERS + 1];
new playerGGrank[MAXPLAYERS + 1];

new String:ranksteamidreq[MAXPLAYERS + 1][25];
new String:ranknamereq[MAXPLAYERS + 1][32];
new reqplayerrankpoints[MAXPLAYERS + 1];
new reqplayerrank[MAXPLAYERS + 1];
new String:ranknametop[10][32];
new String:ranksteamidtop[10][32];

new sessionpoints[MAXPLAYERS + 1];
new sessionkills[MAXPLAYERS + 1];
new sessiondeath[MAXPLAYERS + 1];
new sessionheadshotkills[MAXPLAYERS + 1];

new bool:roundactive = false;

new String:CHATTAG[MAX_LINE_WIDTH];
new String:Logfile[PLATFORM_MAX_PATH];

new String:tableaccuracy[255], String:tableplayer[255], String:tabledata[255], String:tablemap[255], String:tablecountrylist[255];
new String:tableheat[255];

public Plugin:myinfo = 
{
	name = "Dignatio Stats",
	author = "R-Hehl, Timiditas",
	description = "CS:S Player Stats",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=128477"
};

public OnPluginStart()
{
	BuildPath(Path_SM, Logfile, PLATFORM_MAX_PATH, "logs/dignatio.log");
	LoadTranslations("dignatio.phrases");
	convarcreating();
	openDatabaseConnection();
	FirstRun = 0;
	starteventhooking();
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	CreateTimer(60.0,sec60evnt,INVALID_HANDLE,TIMER_REPEAT);
	Lateload();
	RegAdminCmd("rank_dumpDB", cmd_dump, ADMFLAG_BAN, "Dump player table to a file");
	RegAdminCmd("rank_resetcolumn", cmd_resetcolumn, ADMFLAG_BAN, "Reset a single field on all Players");
	RegAdminCmd("rank_importGG", cmd_importgg, ADMFLAG_BAN, "Import GG:SM winner points");
	RegAdminCmd("rank_reload", cmd_reload, ADMFLAG_BAN, "Reload plugin");
	RegAdminCmd("rank_reset_db", cmd_reset_db, ADMFLAG_BAN, "Reset database");
	RegAdminCmd("rank_reset_session", cmd_reset_session, ADMFLAG_BAN, "Reset session");
	RegAdminCmd("rank_modpoints", cmd_modpoints, ADMFLAG_BAN, "Modify player points");
	//RegAdminCmd("rank_checkstructure", cmd_check, ADMFLAG_BAN, "log db structure to error log");
	RegAdminCmd("rank_fake_old_db", cmd_fake, ADMFLAG_BAN, "re-fire dbupdate function");
	RegAdminCmd("rank_debugheat", cmd_debugheat, ADMFLAG_BAN, "show debug data");
	RegAdminCmd("rank_punish", cmd_punish, ADMFLAG_BAN, "punish a player - lower all stats by X");
	RegAdminCmd("rank_showdebug", cmd_showdebug, ADMFLAG_BAN, "show table fields and mysql version");
}
public t_fake(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new String:myFile[255];
	GetPluginFilename(INVALID_HANDLE, myFile, sizeof(myFile));
	ServerCommand("sm plugins reload %s", myFile);
}
/*public Action:cmd_check(client, args)
{
	new String:Query[255], String:Buffer[255];
	ME_Enable = 0;
	dblocked = 1;
	SQL_LockDatabase(db);
	LogToFile(Logfile, "Plugin version: %s, sqllite = %i", DB_VERSION, sqllite);
	
}*/
public Action:cmd_debugheat(client, args)
{
	new String:Buffer[255];
	Format(Buffer, sizeof(Buffer), "Recordheat = %b, Deathcount = %i, rankingactive = %b", Recordheat, DeathCount, rankingactive);
	ReplyToCommand(client, Buffer);
}
public Action:cmd_fake(client, args)
{
	new String:query[255];
	ME_Enable = 0;
	dblocked = 1;
	Format(query, sizeof(query), "UPDATE %s SET dataint = 6 where name = 'dbversion';", tabledata);
	SQL_TQuery(db,t_fake, query);
}

public OnConfigsExecuted()
{
	new String:Buffer[255];
	GetConVarString(CV_tableprefix, Buffer, sizeof(Buffer));
	Format(tableaccuracy, sizeof(tableaccuracy), "%sAccuracy", Buffer);
	Format(tableplayer, sizeof(tableplayer), "%sPlayer", Buffer);
	Format(tabledata, sizeof(tabledata), "%sdata", Buffer);
	Format(tablemap, sizeof(tablemap), "%sMap", Buffer);
	Format(tablecountrylist, sizeof(tablecountrylist), "%scountrylist", Buffer);
	Format(tableheat, sizeof(tableheat), "%sheat", Buffer);
	
	if(db == INVALID_HANDLE)
	{
		if(FirstRun == 1)
			FirstRun = 0;
		else
		{
			FirstRun = 1;
			LogError(Logfile, "Warning! Database connection lost! Retrying...");
		}
		openDatabaseConnection();
	}
	createdbtables();
	MapInit();

	GetConVarString(CV_chattag,CHATTAG, sizeof(CHATTAG));
	new Float:Werbung = GetConVarFloat(CV_announcements);
	if (Werbung >= 30.0 && WerbeTimer == INVALID_HANDLE)
		WerbeTimer = CreateTimer(Werbung, Werbeevent, INVALID_HANDLE,TIMER_REPEAT);
}

public Action:cmd_showdebug(client, args)
{
	new String:TableShow[255], String:prefix[255], String:TArg[255];
	GetConVarString(CV_tableprefix, prefix, sizeof(prefix));
	
	if(args > 0)
		GetCmdArg(1, TArg, sizeof(TArg));
	else
		strcopy(TArg, sizeof(TArg), "Player");
	Format(TableShow, sizeof(TableShow), "%s%s",prefix,TArg);
	new String:query[1024];
	Format(query, sizeof(query), "select version()");
	ReplyToCommand(client, "Querying database...");
	new userid;
	if(client != 0)
		userid = GetClientUserId(client);
	new Handle:hQuery = CreateDataPack();
	WritePackCell(hQuery, userid);
	WritePackString(hQuery, TableShow);
	SQL_TQuery(db,T_showdebug, query, hQuery);
	return Plugin_Continue;
}

public T_showdebug(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data, false);
	new userid = ReadPackCell(data);
	new client = GetClientOfUserId(userid);
	
	if(!StrEqual("", error))
	{
		ReplyCust(client, "Query failed! %s", error);
	}
	else
	{
		new String:sVersion[255];
		SQL_FetchRow(hndl);
		SQL_FetchString(hndl, 0, sVersion, sizeof(sVersion));
		ReplyCust(client, "[rank_showdebug] mysql version string: %s", sVersion);
	}
	new String:query[1024];
	Format(query, sizeof(query), "SHOW FIELDS FROM player");
	SQL_TQuery(db,T_showdebug2, query, data);
}
ReplyCust(client, String:Reply[], any:...)
{
	decl String:bReply[SQLSIZE_MAX];
	if(client == 0)
		SetGlobalTransTarget(LANG_SERVER);
	else
		SetGlobalTransTarget(client);
	VFormat(bReply, sizeof(bReply), Reply, 3);
	if(client == 0)
		PrintToServer(bReply);
	else
	{
		PrintToConsole(client, bReply);
		PrintToChat(client, bReply);
	}
}

public T_showdebug2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data, false);
	new userid = ReadPackCell(data);
	new client = GetClientOfUserId(userid);
	
	if(!StrEqual("", error))
	{
		ReplyCust(client, "Query failed! %s", error);
	}
	else
	{
		new fcount = (SQL_GetFieldCount(hndl)-1);
		decl String:Buffer[255], String:Output[1024];
		Output[0] = 0;
		for(new i=0;i<=fcount;i++)
		{
			SQL_FieldNumToName(hndl, i, Buffer, sizeof(Buffer));
			StrCat(Output, sizeof(Output), Buffer);
			if(i < fcount)
				StrCat(Output, sizeof(Output), "|");
		}
		ReplyCust(client, Output);
		new Headerlen = strlen(Output);
		for(new i=0;i<Headerlen;i++)
		{
			Output[i] = 45;
		}
		ReplyCust(client, Output);
		while(SQL_FetchRow(hndl))
		{
			Output[0] = 0;
			for(new i=0;i<=fcount;i++)
			{
				new DBResult:Result;
				SQL_FetchString(hndl, i, Buffer, sizeof(Buffer), Result);
				switch(Result)
				{
					case DBVal_Null:
						StrCat(Output, sizeof(Output), "*NULL*");
					case DBVal_Data:
						StrCat(Output, sizeof(Output), Buffer);
					case DBVal_Error:
						StrCat(Output, sizeof(Output), "*INVALID IDX*");
					case DBVal_TypeMismatch:
						StrCat(Output, sizeof(Output), "*TYPE MISMATCH*");
				}
				if(i < fcount)
					StrCat(Output, sizeof(Output), "|");
			}
			ReplyCust(client, Output);
		}
	}
}
	
public Action:cmd_reset_db(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[rank] Type <rank_reset_db yes> to reset DB");
		return Plugin_Handled;
	}
	decl String:buffer[10];
	GetCmdArg(1, buffer, sizeof(buffer));
	if(!StrEqual(buffer, "yes", false))
	{
		ReplyToCommand(client, "[rank] Type <rank_reset_db yes> to reset DB");
		return Plugin_Handled;
	}
	if(client > 0)
	{
		new String:sClient[2][96];
		GetClientAuthString(client, sClient[0], 96); 
		GetClientName(client, sClient[1], 96);
		LogToFile(Logfile, "Client %s, SteamID: %s has deleted the rankings!", sClient[1], sClient[0]);
	}
	else
		LogToFile(Logfile, "The rankings have been deleted through the console!");
	
	resetdb();
	ReplyToCommand(client,"DB has been reset!");
	return Plugin_Continue;
}

public Action:cmd_reset_session(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[rank] Type <rank_reset_session yes> to reset session stats");
		return Plugin_Handled;
	}
	decl String:buffer[10];
	GetCmdArg(1, buffer, sizeof(buffer));
	if(!StrEqual(buffer, "yes", false))
	{
		ReplyToCommand(client, "[rank] Type <rank_reset_session yes> to reset session stats");
		return Plugin_Handled;
	}
	ResetSession();
	ReplyToCommand(client,"Session stats have been reset!");
	return Plugin_Continue;
}

public Action:cmd_reload(client, args)
{
	new String:myFile[255];
	GetPluginFilename(INVALID_HANDLE, myFile, sizeof(myFile));
	ServerCommand("sm plugins reload %s", myFile);
}

public Action:cmd_resetcolumn(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[rank] Usage: rank_resetcolumn <FIELDNAME>");
		return Plugin_Handled;
	}
	decl String:buffer[255];
	GetCmdArg(1, buffer, sizeof(buffer));
	if((strcmp(buffer, "STEAMID", false) == 0) || (strcmp(buffer, "NAME", false) == 0))
	{
		ReplyToCommand(client, "[rank_resetcolumn] Only Integer fields supported! STEAMID and NAME are forbidden");
		return Plugin_Handled;
	}
	
	new String:query[512];
	Format(query, sizeof(query), "UPDATE %s SET %s = 0;", tableplayer, buffer);
	//if(debug_version == 1){LogToFile(Logfile, "Line 276: %s",query);}
	SQL_TQuery(db,T_resetcolumn, query, client);
	return Plugin_Continue;
}

public T_resetcolumn(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		if(data == 0)
			PrintToServer("[rank_resetcolumn] SQL Error: %s", error);
		else
		{
			PrintToConsole(data, "[rank_resetcolumn] SQL Error: %s", error);
			PrintToChat(data, "[rank_resetcolumn] SQL Error: %s", error);
		}
	}
	else
	{
		if(data == 0)
			PrintToServer("[rank_resetcolumn] Column reset complete!");
		else
		{
			PrintToConsole(data, "[rank_resetcolumn] Column reset complete!");
			PrintToChat(data, "[rank_resetcolumn] Column reset complete!");
		}
	}
}

public Action:cmd_punish(client, args)
{
	if (args != 2)
	{
		ReplyToCommand(client, "usage: rank_punish <\"SteamID\"> <value>");
		ReplyToCommand(client, "Remember to enclose the SteamID by quotation marks!");
		return Plugin_Handled;
	}
	decl String:SteamID[96], String:Value[255], iValue;
	GetCmdArg(1, SteamID, sizeof(SteamID));
	GetCmdArg(2, Value, sizeof(Value));
	iValue = StringToInt(Value);
	if (iValue < 1)
	{
		ReplyToCommand(client, "<value> must be greater than 0");
		return Plugin_Handled;
	}
	PunishSid(SteamID, iValue);
	return Plugin_Handled;
}
PunishSid(String:SteamID[], amount, punishpoints = 1)
{
	new tlen = 0;
	decl String:query[2048];
	tlen += Format(query[tlen], sizeof(query)-tlen, "SELECT %i,POINTS,KILLS,HeadshotKill,bomb_planted,", amount);
	tlen += Format(query[tlen], sizeof(query)-tlen, "bomb_defused,hostage_rescued,KW_deagle,");
	tlen += Format(query[tlen], sizeof(query)-tlen, "KW_ak47,KW_m4a1,KW_awp,KW_elite,KW_mp5navy,KW_m3,STEAMID");
	tlen += Format(query[tlen], sizeof(query)-tlen, " FROM %s WHERE STEAMID = '%s';", tableplayer, SteamID);
	SQL_TQuery(db,T_punish, query, punishpoints);
}
public T_punish(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "PunishSid: Query failed! %s", error);
	}
	else 
	{
		if (!SQL_GetRowCount(hndl))
		{
			LogToFile(Logfile, "PunishSid: SteamID not found in database!");
		}
		else
		{
			while (SQL_FetchRow(hndl))
			{
				new iBuffer, amount = SQL_FetchInt(hndl,0), tlen = 0, punishpoints = data;
				new String:query[2048], String:FieldName[255], String:sBuffer[2048], String:SteamID[64];
				SQL_FetchString(hndl, 14, SteamID, sizeof(SteamID));
				tlen += Format(query[tlen], sizeof(query)-tlen, "UPDATE %s SET", tableaccuracy);
				for(new I=1;I<14;I++)
				{
					iBuffer = SQL_FetchInt(hndl,I);
					
					if(punishpoints == 0 && I == 1)
					{
						//iBuffer
					}
					else
					{
						if((iBuffer-amount) < 0)
							iBuffer = 0;
						else
							iBuffer -= amount;
					}
					SQL_FieldNumToName(hndl, I, FieldName, sizeof(FieldName));
					tlen += Format(query[tlen], sizeof(query)-tlen, " %s = %i,", FieldName, iBuffer);
				}
				strcopy(sBuffer, strlen(query), query);	//delete last char - full string would be strlen(sBuffer)+1
				Format(query, sizeof(query), "%s WHERE STEAMID = '%s';", sBuffer, SteamID);
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_001: %s",query);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
			}
		}
	}
}

public Action:cmd_modpoints(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "usage: rank_modpoints <\"SteamID\"> <add|subtract|set> <points>");
		ReplyToCommand(client, "Remember to enclose the SteamID by quotation marks!");
		return Plugin_Handled;
	}
	decl String:SteamID[96], String:Mode[255], String:Points[255], iPoints;
	GetCmdArg(1, SteamID, sizeof(SteamID));
	GetCmdArg(2, Mode, sizeof(Mode));
	GetCmdArg(3, Points, sizeof(Points));
	iPoints = StringToInt(Points);
	if (!StrEqual(Mode, "add", false) && !StrEqual(Mode, "subtract", false) && !StrEqual(Mode, "set", false))
	{
		ReplyToCommand(client, "Invalid mode specified. Must be add, subtract or set");
		return Plugin_Handled;
	}
	if (iPoints < 1 && !StrEqual(Mode, "set", false))
	{
		ReplyToCommand(client, "<points> must be greater than 0");
		return Plugin_Handled;
	}
	new String:query[1024];
	Format(query, sizeof(query), "SELECT POINTS FROM %s WHERE STEAMID = '%s';", tableplayer, SteamID);
	new Handle:testhandle = CreateArray(ByteCountToCells(255));
	PushArrayString(testhandle, SteamID);
	PushArrayString(testhandle, Mode);
	PushArrayCell(testhandle, iPoints);
	PushArrayCell(testhandle, client);
	//if(debug_version == 1){LogToFile(Logfile, "Line 329: %s",query);}
	SQL_TQuery(db,T_modpoints, query, testhandle);
	return Plugin_Handled;
}

public T_modpoints(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetArrayCell(data, 3), iPoints = GetArrayCell(data, 2), String:SteamID[96], String:Mode[255];
	GetArrayString(data, 0, SteamID, sizeof(SteamID));
	GetArrayString(data, 1, Mode, sizeof(Mode));
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		ReplyToCommand(client, "Query failed! %s", error);
		CloseHandle(data);
	}
	else 
	{
		if (!SQL_GetRowCount(hndl))
		{
			ReplyToCommand(client, "SteamID %s not found in database! Remember to enclose the SteamID in quotation marks", SteamID);
			CloseHandle(data);
		}
		else
		{
			//user found
			while (SQL_FetchRow(hndl))
			{
				new String:query[1024];
				if (StrEqual(Mode, "add", false))
					Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i WHERE STEAMID = '%s'", tableplayer, iPoints, SteamID);
				else if (StrEqual(Mode, "subtract", false))
					Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i WHERE STEAMID = '%s'", tableplayer, iPoints, SteamID);
				else if (StrEqual(Mode, "set", false))
					Format(query, sizeof(query), "UPDATE %s SET POINTS = %i WHERE STEAMID = '%s'", tableplayer, iPoints, SteamID);
				//if(debug_version == 1){LogToFile(Logfile, "Line 365: %s",query);}
				SQL_TQuery(db,T_modpoints2, query, data);
			}
		}
	}
}

public T_modpoints2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetArrayCell(data, 3), iPoints = GetArrayCell(data, 2), String:SteamID[96], String:Mode[255];
	GetArrayString(data, 0, SteamID, sizeof(SteamID));
	GetArrayString(data, 1, Mode, sizeof(Mode));

	if(!StrEqual("", error))
	{
		LogToFile(Logfile, "SQL Error while %s points for %s: %s", Mode, SteamID, error);
		ReplyToCommand(client, "SQL Error while %s points for %s: %s", Mode, SteamID, error);
	}
	else
	{
		ReplyToCommand(client, "%s %i points for SteamID %s", Mode, iPoints, SteamID);
	}
	CloseHandle(data);
}

public Action:cmd_dump(client, args)
{
	new String:Query[255];
	Format(Query, sizeof(Query), "SELECT * FROM `%s`", tableplayer);
	//if(debug_version == 1){LogToFile(Logfile, "Line 399: %s",Query);}
	SQL_TQuery(db, T_dump, Query, client);
}
public T_dump(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (!SQL_GetRowCount(hndl))
	{
		if(data == 0)
			PrintToServer("T_dump error! Query failed!");
		else
		{
			PrintToConsole(data, "T_dump error! Query failed!");
			PrintToChat(data, "T_dump error! Query failed!");
		}
	}
	else
	{
		new String:LogPath[4096];
		BuildPath(Path_SM, LogPath, sizeof(LogPath), "logs/n1g-css-stats_DB_dump.log");
		new Handle:fFile = OpenFile(LogPath, "w");
		
		new String:dSteamID[1024];
		new String:dName[1024];
		new dPoints;
		new dPlaytime;
		new dLastontime;
		new dKills;
		WriteFileLine(fFile, "Database dump! STEAMID - NAME - POINTS - PLAYTIME - LASTONTIME - KILLS");
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, dSteamID, sizeof(dSteamID));
			SQL_FetchString(hndl, 1, dName, sizeof(dName));
			dPoints = SQL_FetchInt(hndl,2);
			dPlaytime = SQL_FetchInt(hndl,3);
			dLastontime = SQL_FetchInt(hndl,4);
			dKills = SQL_FetchInt(hndl,5);
			WriteFileLine(fFile, "%s - %s - %i - %i - %i - %i", dSteamID, dName, dPoints, dPlaytime, dLastontime, dKills);
		}
		CloseHandle(fFile);
		if(data == 0)
			PrintToServer("Database dumped to: '%s'", LogPath);
		else
		{
			PrintToConsole(data, "Database dumped to: '%s'", LogPath);
			PrintToChat(data, "Database dumped to: '%s'", LogPath);
		}
	}
}

public Action:sec60evnt(Handle:timer, Handle:hndl)
{
	if(dblocked == 0)
	{
		playerstimeupdateondb();
		refreshmaptime();
	}
}

public Action:Werbeevent(Handle:timer, Handle:hndl)
{
	if(GetConVarInt(CV_announcements) > 29.9)
	{
		if (ME_Enable && rankingactive)
			TopMessage("Ranking Active");
		else
			TopMessage("Ranking Inactive");
	}
}

TopMessage(String:tPhrase[])
{
	new Red = 255, Green = 0, Blue = 0, Alpha = 255;
	new String:message[255];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(!IsFakeClient(i))
			{
				Format(message, sizeof(message), "%T", tPhrase, i);
				new Handle:kv = CreateKeyValues("Stuff", "title", message);
				KvSetColor(kv, "color", Red, Green, Blue, Alpha);
				KvSetNum(kv, "level", 2);
				KvSetNum(kv, "time", 10);
				CreateDialog(i, kv, DialogType_Msg);
				CloseHandle(kv);
			}
		}
	}
}

/*
TopMessage(String:text[])
{
	new Red = 255, Green = 0, Blue = 0, Alpha = 255;
	new String:message[255];
	strcopy(message, sizeof(message), text);
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", Red, Green, Blue, Alpha);
	KvSetNum(kv, "level", 2);
	KvSetNum(kv, "time", 10);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if(!IsFakeClient(i))
				CreateDialog(i, kv, DialogType_Msg);
		}
	}
	CloseHandle(kv);
}
*/

public refreshmaptime()
{
	new String:name[MAX_LINE_WIDTH];
	GetCurrentMap(name,MAX_LINE_WIDTH);
	new time = GetTime();
	new String:query[512];
	Format(query, sizeof(query), "UPDATE %s SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE NAME LIKE '%s'", tablemap, time ,name);
	//if(debug_version == 1){LogToFile(Logfile, "Line 490: %s",query);}
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_002: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}

public playerstimeupdateondb()
{
	new String:clsteamId[MAX_LINE_WIDTH];
	new time = GetTime();
	for(new i=1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientAuthString(i, clsteamId, sizeof(clsteamId));
			new String:query[512];
			Format(query, sizeof(query), "UPDATE %s SET PLAYTIME = PLAYTIME + 1, LASTONTIME = %i WHERE STEAMID = '%s'", tableplayer, time ,clsteamId);
			//if(debug_version == 1){LogToFile(Logfile, "Line 505: %s",query);}
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_003: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
			Format(query, sizeof(query), "UPDATE %s SET LASTONTIME = %i WHERE STEAMID = '%s'", tableaccuracy, time, clsteamId);
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_004: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		}
	}
}

openDatabaseConnection()
{
	if (SQL_CheckConfig("dignatio"))
	{
		new String:error[255];
		db = SQL_Connect("dignatio",true,error, sizeof(error));
		if (db == INVALID_HANDLE)
		{
			LogToFile(Logfile, "Failed to connect to 'dignatio': %s", error);
		}
		else 
		{
			//PrintToServer("DatabaseInit (CONNECTED) with db config");
			//LogToFile(Logfile, "DatabaseInit (CONNECTED) with db config");
			// Set codepage to utf8
			decl String:query[255];
			Format(query, sizeof(query), "SET NAMES 'utf8'");
			if (!SQL_FastQuery(db, query))
				LogToFile(Logfile, "Can't select character set (%s)", query);
			// End of Set codepage to utf8
		}
	} 
	else
	{
		new String:error[255];
		sqllite = 1;
		//db = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "dignatio", error, sizeof(error), true, 0);
		new Handle:h_kv = CreateKeyValues("");
		KvSetString(h_kv, "driver", "sqlite");
		KvSetString(h_kv, "database", "dignatio");
		db = SQL_ConnectCustom(h_kv, error, sizeof(error), true);
		CloseHandle(h_kv);
		if (db == INVALID_HANDLE)
			LogToFile(Logfile, "Failed to connect: %s", error);
		else 
			PrintToServer("DatabaseInit SQLLITE (CONNECTED)");
	}
}

public starteventhooking() 
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_start", Event_round_start);
	HookEvent("round_end", Event_round_end);
	HookEvent("bomb_defused", Event_bomb_defused);
	HookEvent("bomb_exploded", Event_bomb_exploded);
	HookEvent("bomb_planted", Event_bomb_planted);
	HookEvent("hostage_follows", Event_hostage_follows);
	HookEvent("hostage_killed", Event_hostage_killed);
	HookEvent("hostage_rescued", Event_hostage_rescued);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("weapon_fire", EventWeaponFire);
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	//In case someone switched to or from spectator team
	//This is a POST-hook. EnoughClientsForRanking should return the correct value
	EnoughClientsForRanking();
}

bool:blockranking()
{
	return ((GetConVarInt(CV_disableafterroundwin) == 1) && !roundactive);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (blockranking() || (ME_Enable == 0))
		return;
	
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);
	new bool:headshot = GetEventBool(event, "headshot");
	new String:weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	new team_victim = GetClientTeam(victim);
	new team_attacker;
	if(attacker != 0)
		team_attacker = GetClientTeam(attacker);
	else
		team_attacker = -1;
	new bool:teamkill = (team_victim == team_attacker);
	new teamkill_malus = GetConVarInt(CV_teamkillpoints);
	
	new bool:vbot = IsFakeClient(victim);
	new bool:abot;
	if(attacker != 0)
		abot = IsFakeClient(attacker);
	else
		abot = false;
	if ((vbot || abot) && (GetConVarInt(CV_botpoints) == 0))
		return;
	
	decl String:query[512];
	new String:steamIdattacker[MAX_LINE_WIDTH];
	new String:steamIdavictim[MAX_LINE_WIDTH];
	if(attacker != 0)
		GetClientAuthString(attacker, steamIdattacker, sizeof(steamIdattacker));
	GetClientAuthString(victim, steamIdavictim, sizeof(steamIdavictim));
	
	if(sqllite == 0 && Recordheat == true)
	{
		if(rankingactive && ((vbot && GetConVarInt(CV_heatbots) == 1) || !vbot))
		{
			hTimestamps[DeathCount] = GetTime();
			new Float:vec[3];
			GetClientAbsOrigin(victim, vec);
			hX[DeathCount] = RoundToNearest(vec[0]);
			hY[DeathCount] = RoundToNearest(vec[1]);
			DeathCount++;
			if(DeathCount >= 64)
				FlushHeat();
		}
	}
	
	//World entity kill / suicide by falling/being crushed to death
	if(attacker == 0)
	{
		new worldkill = GetConVarInt(CV_worldkillpoints);
		if(worldkill < 1)
			return;
		sessiondeath[victim]++;
		sessionpoints[victim] = sessionpoints[victim] - worldkill;
		if(vbot || !rankingactive)
			return;
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i, Death = Death + 1, suicides = suicides + 1 WHERE STEAMID = '%s'", tableplayer, worldkill ,steamIdavictim);
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_005: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		return;
	}
	
	//Suicide by nade kill
	if(attacker == victim)
	{
		new nadekill = GetConVarInt(CV_suicidepoints);
		if(nadekill < 1)
			return;
		sessiondeath[victim]++;
		sessionpoints[victim] = sessionpoints[victim] - nadekill;
		if(vbot || !rankingactive)
			return;
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i, Death = Death + 1, suicides = suicides + 1 WHERE STEAMID = '%s'", tableplayer, nadekill ,steamIdavictim);
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_007: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		return;
	}
	
	if(!teamkill)
		sessionkills[attacker]++;
	
	new i_pointvalue = 0;
	new String:sqlWeapon[128];
	new Float:f_buffer;
	new Float:pointvalue;
	
	if (vbot)
		f_buffer = GetConVarFloat(CV_botfactor);
	else
		f_buffer = 1.0;

	//this is bound to be optimized in the near future :(
	if (strcmp(weapon[0], "m4a1", false) == 0)
	{
		pointvalue = GetConVarInt(CV_m4a1) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_m4a1 = KW_m4a1");
	}
	else if (strcmp(weapon[0], "ak47", false) == 0)
	{
		pointvalue = GetConVarInt(CV_ak47) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_ak47 = KW_ak47");
	}
	else if (strcmp(weapon[0], "scout", false) == 0)
	{
		pointvalue = GetConVarInt(CV_scout) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_scout = KW_scout");
	}
	else if (strcmp(weapon[0], "hegrenade", false) == 0)
	{
		pointvalue = GetConVarInt(CV_hegrenade) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_hegrenade = KW_hegrenade");
	}
	else if (strcmp(weapon[0], "deagle", false) == 0)
	{
		pointvalue = GetConVarInt(CV_deagle) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_deagle = KW_deagle");
	}
	else if (strcmp(weapon[0], "knife", false) == 0)
	{
		pointvalue = GetConVarInt(CV_knife) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_knife = KW_knife");
	}
	else if (strcmp(weapon[0], "sg552", false) == 0)
	{
		pointvalue = GetConVarInt(CV_sg552) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_sg552 = KW_sg552");
	}
	else if (strcmp(weapon[0], "p90", false) == 0)
	{
		pointvalue = GetConVarInt(CV_p90) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_p90 = KW_p90");
	}
	else if (strcmp(weapon[0], "aug", false) == 0)
	{
		pointvalue = GetConVarInt(CV_aug) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_aug = KW_aug");
	}
	else if (strcmp(weapon[0], "usp", false) == 0)
	{
		pointvalue = GetConVarInt(CV_usp) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_usp = KW_usp");
	}
	else if (strcmp(weapon[0], "famas", false) == 0)
	{
		pointvalue = GetConVarInt(CV_famas) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_famas = KW_famas");
	}
	else if (strcmp(weapon[0], "mp5navy", false) == 0)
	{
		pointvalue = GetConVarInt(CV_mp5navy) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_mp5navy = KW_mp5navy");
	}
	else if (strcmp(weapon[0], "galil", false) == 0)
	{
		pointvalue = GetConVarInt(CV_galil) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_galil = KW_galil");
	}
	else if (strcmp(weapon[0], "m249", false) == 0)
	{
		pointvalue = GetConVarInt(CV_m249) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_m249 = KW_m249");
	}
	else if (strcmp(weapon[0], "m3", false) == 0)
	{
		pointvalue = GetConVarInt(CV_m3) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_m3 = KW_m3");
	}
	else if (strcmp(weapon[0], "glock", false) == 0)
	{
		pointvalue = GetConVarInt(CV_glock) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_glock = KW_glock");
	}
	else if (strcmp(weapon[0], "p228", false) == 0)
	{
		pointvalue = GetConVarInt(CV_p228) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_p228 = KW_p228");
	}
	else if (strcmp(weapon[0], "elite", false) == 0)
	{
		pointvalue = GetConVarInt(CV_elite) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_elite = KW_elite");
	}
	else if (strcmp(weapon[0], "xm1014", false) == 0)
	{
		pointvalue = GetConVarInt(CV_xm1014) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_xm1014 = KW_xm1014");
	}
	else if (strcmp(weapon[0], "fiveseven", false) == 0)
	{
		pointvalue = GetConVarInt(CV_fiveseven) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_fiveseven = KW_fiveseven");
	}
	else if (strcmp(weapon[0], "tmp", false) == 0)
	{
		pointvalue = GetConVarInt(CV_tmp) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_tmp = KW_tmp");
	}
	else if (strcmp(weapon[0], "ump45", false) == 0)
	{
		pointvalue = GetConVarInt(CV_ump45) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_ump45 = KW_ump45");
	}
	else if (strcmp(weapon[0], "mac10", false) == 0)
	{
		pointvalue = GetConVarInt(CV_mac10) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_mac10 = KW_mac10");
	}
	else if (strcmp(weapon[0], "awp", false) == 0)
	{
		pointvalue = GetConVarInt(CV_awp) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_awp = KW_awp");
	}
	else if (strcmp(weapon[0], "sg550", false) == 0)
	{
		pointvalue = GetConVarInt(CV_sg550) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_sg550 = KW_sg550");
	}
	else if (strcmp(weapon[0], "g3sg1", false) == 0)
	{
		pointvalue = GetConVarInt(CV_g3sg1) * f_buffer;
		strcopy(sqlWeapon, sizeof(sqlWeapon), "KW_g3sg1 = KW_g3sg1");
	}

	i_pointvalue = RoundToNearest(pointvalue);
	
	if(!abot && rankingactive)
	{
		if(!teamkill)
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, KILLS = KILLS + 1, %s + 1 WHERE steamId = '%s'", tableplayer, i_pointvalue, sqlWeapon, steamIdattacker);
		else
		{
			if(!vbot)
				Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i, teamkills = teamkills + 1 WHERE steamId = '%s'", tableplayer, teamkill_malus, steamIdattacker);
			else
			{
				new botTKpoints = GetConVarInt(CV_botteamkillpoints);
				new botTKrecord;
				if(GetConVarInt(CV_botteamkillrecord) > 0)
					botTKrecord = 1;
				else
					botTKrecord = 0;
				Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i, teamkills = teamkills + %i WHERE steamId = '%s'", tableplayer, botTKpoints, botTKrecord, steamIdattacker);
			}
		}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_009: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	}
	
	new death_pointvalue;
	if(GetConVarInt(CV_diepoints) == -1)
		death_pointvalue = i_pointvalue;
	else
	{
		if (abot)
		{
			new Float:f_diepoints = (GetConVarInt(CV_diepoints) * GetConVarFloat(CV_botfactor));
			death_pointvalue = RoundToNearest(f_diepoints);
		}
		else
			death_pointvalue = GetConVarInt(CV_diepoints);
	}

	if (!teamkill)
	{
		//If it wasn't a teamkill, update victim points
		sessiondeath[victim]++;
		sessionpoints[victim] = sessionpoints[victim] - death_pointvalue;
		if(!vbot && rankingactive)
		{
			Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i, Death = Death + 1 WHERE STEAMID = '%s'", tableplayer, death_pointvalue ,steamIdavictim);
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_010: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		}
	}
	
	
	
	
	
	if(headshot && !teamkill)
	{
		if(!abot && rankingactive)
		{
			Format(query, sizeof(query), "UPDATE %s SET HeadshotKill = HeadshotKill + 1 WHERE steamId = '%s'", tableplayer, steamIdattacker);
			
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_011: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		}
		sessionheadshotkills[attacker]++;
	}
	
	if (!teamkill)
		sessionpoints[attacker] = sessionpoints[attacker] + i_pointvalue;
	else
		sessionpoints[attacker] = sessionpoints[attacker] - teamkill_malus;
	
	
	new String:attackername[MAX_LINE_WIDTH];
	GetClientName(attacker,attackername, sizeof(attackername));
	
	new String:victimname[MAX_LINE_WIDTH];
	GetClientName(victim,victimname, sizeof(victimname));
	new pointmsgval = GetConVarInt(CV_pointmsg);
	if (pointmsgval >= 1 && rankingactive)
	{
		if (pointmsgval == 1)
		{
			if(!teamkill)
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t %s",CHATTAG,attackername, "got", i_pointvalue, "points for", "killing", victimname);
			else
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t %s", CHATTAG, attackername, "lost", teamkill_malus, "points for", "teamkilling", victimname);
		}
		else
		{
			if(!teamkill)
				PrintToChat(attacker,"\x04[\x03%s\x04]\x01 %t %i %t %t %s",CHATTAG, "you got", i_pointvalue, "points for", "killing", victimname);
			else
				PrintToChat(attacker,"\x04[\x03%s\x04]\x01 %t %i %t %t %s",CHATTAG, "you lost", teamkill_malus, "points for", "teamkilling", victimname);
		}
	}
}

public Action:Command_Say(client, args)
{
	if (client == 0)
		return Plugin_Continue;
	if(IsFakeClient(client))
		return Plugin_Continue;
	if(dblocked)
		return Plugin_Continue;
	
	new String:text[192], String:command[64];
	new startidx = 0;
	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{		
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	} 	
	if (strcmp(command, "say2", false) == 0)
		startidx += 4;
	if (strcmp(text[startidx], "!Rank", false) == 0)
		session(client);
	else if (strcmp(text[startidx], "Rank", false) == 0)
		session(client);
	else if (strcmp(text[startidx], "Top10", false) == 0)
		top10pnl(client);
	else if (strcmp(text[startidx], "Top", false) == 0)
		top10pnl(client);
	else if (strcmp(text[startidx], "ggTop", false) == 0)
		top10gg(client);
	else if (strcmp(text[startidx], "bottop", false) == 0)
		bottop(client);
	else if (strcmp(text[startidx], "rankinfo", false) == 0)
		rankinfo(client);
	else if (strcmp(text[startidx], "players", false) == 0)
		listplayers(client);
	else if (strcmp(text[startidx], "session", false) == 0)
		session(client);
	else if (strcmp(text[startidx], "webtop", false) == 0)
		webtop(client);
	else if (strcmp(text[startidx], "webrank", false) == 0)
		webranking(client);
	else if (strcmp(text[startidx], "topcountry", false) == 0)
		topcountry(client);
	else if (strcmp(text[startidx], "mycountry", false) == 0)
		mycountry(client);
	else if (strcmp(text[startidx], "topweapon", false) == 0)
		topweapon(client);
	else if (strcmp(text[startidx], "myweapon", false) == 0)
		myweapon(client);
	else if (strcmp(text[startidx], "currentmap", false) == 0)
		currentmap(client);
	else if (strcmp(text[startidx], "topmap", false) == 0)
		topmap(client);
	else if (strcmp(text[startidx], "rankcommands", false) == 0)
		commandinfo(client);
	return Plugin_Continue;
}

public commandinfohandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				session(param1);
			}
			case 1:
			{
				top10pnl(param1);
			}
			case 2:
			{
				top10gg(param1);
			}
			case 3:
			{
				bottop(param1);
			}
			case 4:
			{
				listplayers(param1);
			}
			case 5:
			{
				webtop(param1);
			}
			case 6:
			{
				webranking(param1);
			}
			case 7:
			{
				topcountry(param1);
			}
			case 8:
			{
				mycountry(param1);
			}
			case 9:
			{
				topweapon(param1);
			}
			case 10:
			{
				myweapon(param1);
			}
			case 11:
			{
				topmap(param1);
			}
			case 12:
			{
				currentmap(param1);
			}
		}
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}
public Action:commandinfo(client)
{
	new Handle:menu = CreateMenu(commandinfohandler);
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "%T", "Rank commands", client);
	SetMenuTitle(menu, buffer);
	Format(buffer, sizeof(buffer), "rank/session - %T", "rank_session", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "top/top10 - %T", "top_top10", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "ggtop - %T", "ggtop", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "bottop - %T", "bottop", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "players - %T", "players", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "webtop - %T", "webtop", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "webrank - %T", "webrank", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "topcountry - %T", "topcountry", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "mycountry - %T", "mycountry", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "topweapon - %T", "topweapon", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "myweapon - %T", "myweapon", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "topmap - %T", "topmap", client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "currentmap - %T", "currentmap", client);
	AddMenuItem(menu, "", buffer);
 	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 99);
	return Plugin_Handled;
}
public Action:rankinfo(client)
{
	new Handle:menu = CreateMenu(InfoPanelHandler);
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "%T", "About Rank", client);
	SetMenuTitle(menu, buffer);
	Format(buffer, sizeof(buffer), "%T", "commandlist",client);
	AddMenuItem(menu, "", buffer);
	Format(buffer, sizeof(buffer), "%T R-Hehl", "original plugin",client);
	AddMenuItem(menu, "", buffer,ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "maintained",client);
	AddMenuItem(menu, "", buffer,ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "Timiditas - %T", "contact",client);
	AddMenuItem(menu, "", buffer,ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T", "ftbugs",client);
	AddMenuItem(menu, "", buffer,ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "E-Mail cateyetech@t-online.de");
	AddMenuItem(menu, "", buffer,ITEMDRAW_DISABLED);
	Format(buffer, sizeof(buffer), "%T %s DB Typ %i", "rversion",client, PLUGIN_VERSION ,sqllite);
	AddMenuItem(menu, "", buffer,ITEMDRAW_DISABLED);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, GetConVarInt(CV_infopaneltime));
	return Plugin_Handled;
}
public InfoPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if(param2 == 0)
			commandinfo(param1);
	}
	else if (action == MenuAction_End)
		CloseHandle(menu);
}

public showeallrank()
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			new String:steamIdclient[MAX_LINE_WIDTH];
			GetClientAuthString(i, steamIdclient, sizeof(steamIdclient));
			rankpanel(i, steamIdclient);
		}
	}
}

public removetooldplayers()
{
	new remdays = GetConVarInt(CV_removeoldplayersdays);
	if (remdays >= 1)
	{
		new timesec = GetTime() - (remdays * 86400);
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM %s WHERE LASTONTIME < %i", tableplayer, timesec);
		//if(debug_version == 1){LogToFile(Logfile, "Line 994: %s",query);}
		//LogError("db = %i, (db==INVALID_HANDLE)=%b",db,(db==INVALID_HANDLE));
		SQL_TQuery(db,removeplayersCallback, query, timesec);
	}
}

public removeplayersCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogToFile(Logfile, "SQL Error: %s", error);
		return;
	}
	new String:query[512];
	Format(query, sizeof(query), "DELETE FROM %s WHERE LASTONTIME < %i", tableaccuracy, data);
	//if(debug_version == 1){LogToFile(Logfile, "Line 1008: %s",query);}
	SQL_TQuery(db,removevoyeurs, query);
}

public removevoyeurs(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogToFile(Logfile, "SQL Error: %s", error);
		return;
	}
	new remhours = GetConVarInt(CV_removevoyeurhours);
	if (remhours >= 1)
	{
		new timesec = GetTime() - (remhours * 3600);
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM %s WHERE LASTONTIME < %i AND KILLS = 0 AND Death = 0 AND POINTS = 0", tableplayer, timesec);
		//if(debug_version == 1){LogToFile(Logfile, "Line 1025: %s",query);}
		SQL_TQuery(db,removevoyeursCallback, query);
	}
	else
		cleancountrylist();
}
public removevoyeursCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogToFile(Logfile, "SQL Error: %s", error);
		return;
	}
	new String:query[512];
	Format(query, sizeof(query), "DELETE FROM %s WHERE NOT EXISTS (SELECT STEAMID FROM %s WHERE %s.STEAMID = %s.STEAMID);", tableaccuracy, tableplayer, tableplayer, tableaccuracy);
	//if(debug_version == 1){LogToFile(Logfile, "Line 1040: %s",query);}
	SQL_TQuery(db,ctd_callback, query);
}
public ctd_callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogToFile(Logfile, "SQL Error: %s", error);
		return;
	}
	cleancountrylist();
}
/*
one cross table delete after doing both cleanups in player table is enough. lastontime in table accuracy is unnecessary.
bound to be changed sometime in the future...
*/

cleancountrylist()
{
	new String:query[1024];
	Format(query, sizeof(query), "DELETE FROM %s where (SELECT count(country) from %s where country = %s.country) = 0;", tablecountrylist, tableplayer, tablecountrylist);
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_012: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}

public OnMapEnd()
{
	if(dblocked == 0)
	{
		AccToDB();
		mapisset = 0;
		if (GetConVarInt(CV_removeoldplayers) == 1)
			removetooldplayers();
		if (GetConVarInt(CV_removeoldmaps) == 1)
			removetooldmaps();
		if(DeathCount > 0 && sqllite == 0 && Recordheat == true)
		{
			FlushHeat();
			CleanHeat();
		}
	}
}

public MapInit()
{
	if(dblocked == 0)
	{
		if (mapisset == 0)
			InitializeMaponDB();
	}
}

public InitializeMaponDB()
{
	if (mapisset == 0)
	{
		if(sqllite == 0 && Recordheat == true)
			SetHeatmapDefaultNameOnDB();
		new String:name[MAX_LINE_WIDTH];
		GetCurrentMap(name,MAX_LINE_WIDTH);
		new String:query[512];
		if (sqllite != 1)
			Format(query, sizeof(query), "INSERT IGNORE INTO %s (`NAME`,`LASTONTIME`) VALUES ('%s','%i')", tablemap, name, GetTime());
		else
			Format(query, sizeof(query), "INSERT OR IGNORE INTO %s VALUES ('%s',0,%i,0,0)", tablemap, name, GetTime());
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_013: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		mapisset = 1;
	}
}

ResetAcc(client)
{
	for (new j = 0; j < WEAPON_COUNT; j++)
	{
		weapon_stats[client][j][0] = 0;
		weapon_stats[client][j][1] = 0;
	}
	for (new j = 1; j <= 7; j++)
	{
		hitbox_stats[client][j] = 0;
	}
}

ResetAccAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		ResetAcc(i);
	}
}
public Event_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	//on booting the gameserver, this function seems to be fired before OnConfigsExecuted - check the db handle
	if(dblocked == 1 || db == INVALID_HANDLE)
		return;
	
	Recordheat = (GetConVarInt(CV_recordheat) == 1);
	EnoughClientsForRanking();

	roundactive = true;
	for (new i=1; i <= MaxClients; i++)
	{
		for (new j=0; j<16; j++)
		{
			HostageCanGetPoints[i][j] = -1;
		}
	}

	ResetAccAll();
	
	new rempoints = GetConVarInt(CV_deductpoints);
	if (rempoints > 0)
	{
		new timesec = GetTime() - 86400;
		new String:query[512];
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i WHERE LASTDEDUCT < %i", tableplayer, rempoints ,timesec);
		//if(debug_version == 1){LogToFile(Logfile, "Line 1182: %s",query);}
		SQL_TQuery(db,T_deduct, query, timesec);
	}
	new showbottop = GetConVarInt(CV_bottopmessage);
	if(showbottop > 0)
		sbottop(showbottop);
}
get_weapon_index(const String: weapon_name[])
{
	new loop_break = 0;
	new index = 0;
	
	while ((loop_break == 0) && (index < sizeof(weaponlist)))
	{
		if (strcmp(weapon_name, weaponlist[index], true) == 0)
			loop_break++;
		index++;
	}

	if (loop_break == 0)
		return -1;
	else
		return index - 1;
}

public T_deduct(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogToFile(Logfile, "SQL Error: %s", error);
		return;
	}
	new TheTime = data + 86400;
	new String:query[512];
	Format(query, sizeof(query), "UPDATE %s SET LASTDEDUCT = %i WHERE LASTDEDUCT < %i", tableplayer, TheTime, data);
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_014: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}

FlushHeat()
{
	//on every new map starting, the column default value of "mapname" is set to the current mapname, so we can omit it here
	new String:query[2048];
	new tlen = 0;
	new tStamp, X, Y;
	if(DeathCount > 0)
	{
		tlen = 0;
		tStamp = hTimestamps[0];
		X = hX[0];
		Y = hY[0];
		tlen += Format(query[tlen], sizeof(query)-tlen, "INSERT INTO %s (`TIMESTAMP`,`x`,`y`) VALUES", tableheat);
		tlen += Format(query[tlen], sizeof(query)-tlen, "(%i,%i,%i)", tStamp,X,Y);
		if(DeathCount > 1)
		{
			for(new i = 1; i < DeathCount;i++)
			{
				tStamp = hTimestamps[i];
				X = hX[i];
				Y = hY[i];
				tlen += Format(query[tlen], sizeof(query)-tlen, ",(%i,%i,%i)", tStamp,X,Y);
			}
		}
		tlen += Format(query[tlen], sizeof(query)-tlen, ";");
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_015: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	}
	DeathCount = 0;
	/*on none-deathmatch-servers you will never notice this function consuming any cpu time
	since deathcount will never exceed 64 and thus flushheat always gets called at round_end only*/
}

CleanHeat()
{
	new cleancount = GetConVarInt(CV_cleanheat_count);
	new remdays = GetConVarInt(CV_cleanheat_date);
	if (remdays >= 1)
	{
		new timesec = GetTime() - (remdays * 86400);
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM %s WHERE TIMESTAMP < %i", tableheat, timesec);
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_016: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	}

	if (cleancount >= 1)
	{
		new String:mapname[64], String:query[255];
		GetCurrentMap(mapname, sizeof(mapname));
		Format(query, sizeof(query), "SELECT count(*) FROM %s where mapname = '%s';",tableheat,mapname);
		SQL_TQuery(db,t_cleanheat, query, cleancount);
	}
}

public t_cleanheat(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new String:mapname[64], String:query[255];
	GetCurrentMap(mapname, sizeof(mapname));
	new heatcount, cleancount = data;
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		if (!SQL_GetRowCount(hndl))
			LogToFile(Logfile, "Query failed! %s", error);
		else
		{
			while (SQL_FetchRow(hndl))
			{
				heatcount = SQL_FetchInt(hndl,0);
			}
			if (heatcount <= cleancount)
				return;
			heatcount -= cleancount;
			Format(query, sizeof(query), "DELETE FROM %s where mapname = '%s' order by TIMESTAMP ASC LIMIT %i;", tableheat, mapname, heatcount);
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_017: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		}
	}
}

public Event_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	roundactive = false;
	if(dblocked == 1 || db == INVALID_HANDLE)
		return;
	new String:query[8192];
	
	if(DeathCount > 0 && sqllite == 0 && Recordheat == true)
	{
		FlushHeat();
		CleanHeat();
	}
	
	AccToDB();
	if ((GetConVarInt(CV_showrankonroundend) == 1) && ME_Enable == 1)
		showeallrank();
	
	if (GetConVarInt(CV_removeoldplayers) == 1)
		removetooldplayers();
	
	if (GetConVarInt(CV_removeoldmaps) == 1)
		removetooldmaps();
	
	if (ME_Enable == 0 || !rankingactive)
		return;
	
	new winner = GetEventInt(event, "winner");
	new reason = GetEventInt(event, "reason");
	//Make sure that it wasn't a round draw
	if(reason == 16)
		return;
	
	if(winner != 2 && winner != 3)
		return;
	
	new String:mName[PLATFORM_MAX_PATH];
	GetCurrentMap(mName, PLATFORM_MAX_PATH);
	switch (winner)
	{
		case 2:
		{
			Format(query, sizeof(query), "UPDATE %s SET wins_t = wins_t + 1 WHERE NAME = '%s'", tablemap, mName);
		}
		case 3:
		{
			Format(query, sizeof(query), "UPDATE %s SET wins_ct = wins_ct + 1 WHERE NAME = '%s'", tablemap, mName);
		}
	}
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_018: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	
	new teamwin = GetConVarInt(CV_teamwinpoints), teamlose = GetConVarInt(CV_teamlosepoints);
	if(teamwin == 0 && teamlose == 0)
		return;
	
	new String:team_winner[65][64], team_winner_count = -1, team_winner_cid[65];
	new String:team_loser[65][64], team_loser_count = -1, team_loser_cid[65];
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i))
			continue;
		new cTeam = GetClientTeam(i);
		if((cTeam != 2 && cTeam != 3) || IsFakeClient(i))
			continue;
		switch (cTeam == winner)
		{
			case true:
			{
				team_winner_count++;
				GetClientAuthString(i, team_winner[team_winner_count], 64);
				team_winner_cid[team_winner_count] = i;
			}
			case false:
			{
				team_loser_count++;
				GetClientAuthString(i, team_loser[team_loser_count], 64);
				team_loser_cid[team_loser_count] = i;
			}
		}
	}
	new tlen = 0;
	new pointmsgval = GetConVarInt(CV_pointmsg);

	if (teamwin != 0)
	{
		if(pointmsgval == 1)
			PrintToChatAll("\x04[\x03%s\x04]\x01 %t %t %t %i %t", CHATTAG, "winnerteam", "players", "got", teamwin, "exwin");
		if(team_winner_count > -1)
		{
			tlen += Format(query[tlen], sizeof(query)-tlen, "UPDATE %s SET POINTS = POINTS + %i WHERE", tableplayer, teamwin);
			for(new i=0;i<=team_winner_count;i++)
			{
				if(i == team_winner_count)
					tlen += Format(query[tlen], sizeof(query)-tlen, " STEAMID = '%s';", team_winner[i]);
				else
					tlen += Format(query[tlen], sizeof(query)-tlen, " STEAMID = '%s' or", team_winner[i]);
				if(pointmsgval == 2)
					PrintToChat(team_winner_cid[i],"\x04[\x03%s\x04]\x01 %t %t %i %t %t",CHATTAG, "yourteam", "got", teamwin, "points for", "winning");
			}
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_019: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		}
	}
	tlen = 0;
	if (teamlose != 0)
	{
		if(pointmsgval == 1)
			PrintToChatAll("\x04[\x03%s\x04]\x01 %t %t %t %i %t",CHATTAG, "loserteam", "players", "lost", teamlose, "exlose");
		if(team_loser_count > -1)
		{
			tlen += Format(query[tlen], sizeof(query)-tlen, "UPDATE %s SET POINTS = POINTS - %i WHERE", tableplayer, teamlose);
			for(new i=0;i<=team_loser_count;i++)
			{
				if(i == team_loser_count)
					tlen += Format(query[tlen], sizeof(query)-tlen, " STEAMID = '%s';", team_loser[i]);
				else
					tlen += Format(query[tlen], sizeof(query)-tlen, " STEAMID = '%s' or", team_loser[i]);
				if(pointmsgval == 2)
					PrintToChat(team_loser_cid[i],"\x04[\x03%s\x04]\x01 %t %t %i %t %t",CHATTAG, "yourteam", "lost", teamlose, "points for", "losing");
			}
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_020: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		}
	}
}

public removetooldmaps()
{
	new remdays = GetConVarInt(CV_removeoldmapssdays);
	if (remdays >= 1)
	{
		new timesec = GetTime() - (remdays * 86400);
		new String:query[512];
		Format(query, sizeof(query), "DELETE FROM %s WHERE LASTONTIME < %i", tablemap, timesec);
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_021: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	}
}

public updateplayername(client)
{
	new String:steamId[MAX_LINE_WIDTH];
	GetClientAuthString(client, steamId, sizeof(steamId));
	new String:name[(MAX_LINE_WIDTH*3)+2];
	GetClientName( client, name, sizeof(name) );
	EscapeIT(name);
	
	new String:query[1024];
	Format(query, sizeof(query), "UPDATE %s SET NAME = '%s' WHERE STEAMID = '%s'", tableplayer, name ,steamId);
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_022: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}

public initonlineplayers()
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			updateplayername(i);
			InitializeClientonDB(i);
		}
	}
}

public resetdb()
{
	new String:query[512];
	Format(query, sizeof(query), "TRUNCATE TABLE %s", tableplayer);
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_023: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	Format(query, sizeof(query), "TRUNCATE TABLE %s", tablemap);
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_024: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	Format(query, sizeof(query), "TRUNCATE TABLE %s", tableaccuracy);
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_025: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	
	initonlineplayers();
}

public listplayers(client)
{
	Menu_playerlist(client);
}

public Action:Menu_playerlist(client)
{
	new Handle:menu = CreateMenu(MenuHandlerplayerslist);
	new String:smenutitle[512];
	Format(smenutitle, sizeof(smenutitle), "%T", "online players",client);
	SetMenuTitle(menu, smenutitle);
	for (new i=1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i))
				continue;

			new String:name[65];
			GetClientName(i, name, sizeof(name));
			new String:steamId[MAX_LINE_WIDTH];
			GetClientAuthString(i, steamId, sizeof(steamId));
			AddMenuItem(menu, steamId, name);
		}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

public MenuHandlerplayerslist(Handle:menu, MenuAction:action, param1, param2)
{
	/* Either Select or Cancel will ALWAYS be sent! */
	if (action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		rankpanel(param1, info);
	}
	/* If the menu has ended, destroy it */
	if (action == MenuAction_End)
		CloseHandle(menu);
}

ResetSession()
{
	new client;
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		client = i;
		sessionpoints[client] = 0;
		sessionkills[client] = 0;
		sessiondeath[client] = 0;
		sessionheadshotkills[client] = 0;
		for (new j = 0; j < WEAPON_COUNT; j++)
		{
			session_stats[i][j][0] = 0;
			session_stats[i][j][1] = 0;
		}
	}
}

public Action:t_Delay(Handle:timer, any:package)
{
	new client = package;
	InitializeClientonDB(client);
	sessionpoints[client] = 0;
	sessionkills[client] = 0;
	sessiondeath[client] = 0;
	sessionheadshotkills[client] = 0;
	EnoughClientsForRanking();
	ResetAcc(client);
	new String:steamId[MAX_LINE_WIDTH];
	strcopy(steamId,64,"BOT");
	if(IsClientInGame(client) && !IsFakeClient(client))
		GetClientAuthString(client, steamId, sizeof(steamId));
	
	strcopy(weapon_ID[client],64,steamId);
	for (new j = 0; j < WEAPON_COUNT; j++)
	{
		session_stats[client][j][0] = 0;
		session_stats[client][j][1] = 0;
	}
}
public OnClientPostAdminCheck(client)
{
	if(dblocked == 0)
		CreateTimer(1.0, t_Delay, client); //compatiblity fix for a specific plugin
}

EnoughClientsForRanking()
{
	new bool:en_old = rankingactive;
	
	new tCount = GetConVarInt(CV_neededplayercount);
	new h_ingame = 0;
	new b_ingame = 0;
	new clients_ingame = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			new cTeam = GetClientTeam(i);
			if ((cTeam > 1) && (cTeam < 4))
			{
				if(IsFakeClient(i))
					b_ingame++;
				else
					h_ingame++;
			}
		}
	}
	if(GetConVarInt(CV_botpoints) == 1)
		clients_ingame = h_ingame + b_ingame;
	else
		clients_ingame = h_ingame;
	
	new bool:en_new = (clients_ingame >= tCount);

	if(en_new == en_old)
		return;

	if(en_new)
		ResetAccAll();
	else
		AccToDB();

	rankingactive = en_new;
	
	if(GetConVarInt(CV_chatannounce) == 0)
		return;
	if (rankingactive)
		PrintToChatAll("\x04[\x03%s\x04]\x01 %t",CHATTAG, "Ranking Enabled");
	else
		PrintToChatAll("\x04[\x03%s\x04]\x01 %t",CHATTAG, "Ranking Disabled",GetConVarInt(CV_neededplayercount));
}

public InitializeClientonDB(client)
{
	if(!IsClientInGame(client) || db == INVALID_HANDLE)
		return;
	if(IsFakeClient(client))
		return;
	
	new String:ConUsrSteamID[MAX_LINE_WIDTH];
	new String:buffer[255];
	
	GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
	strcopy(weapon_ID[client],64,ConUsrSteamID);
	Format(buffer, sizeof(buffer), "SELECT POINTS FROM %s WHERE STEAMID = '%s'", tableplayer, ConUsrSteamID);
	new conuserid;
	conuserid = GetClientUserId(client);
	//if(debug_version == 1){LogToFile(Logfile, "Line 1538: %s",buffer);}
	SQL_TQuery(db, T_CheckConnectingUsr, buffer, conuserid);
	Format(buffer, sizeof(buffer), "SELECT * FROM %s WHERE STEAMID = '%s'", tableaccuracy, ConUsrSteamID);
	//if(debug_version == 1){LogToFile(Logfile, "Line 1543: %s",buffer);}
	SQL_TQuery(db, CheckAccUpdate, buffer, conuserid);
}

public CheckAccUpdate(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new userid = data;
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(userid)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else 
	{
		new String:ClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
		new String:buffer[2048];
		if (!SQL_GetRowCount(hndl))
		{
			new thaTime = GetTime();
			if (sqllite != 1)
			{
				Format(buffer, sizeof(buffer), "INSERT INTO %s (`STEAMID`,`LASTONTIME`) VALUES ('%s',%i)", tableaccuracy, ClientSteamID,thaTime);
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_026: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
			}
			else
			{
				new tlen = 0;
				decl String:query[2048];
				tlen += Format(query[tlen], sizeof(query)-tlen, "INSERT INTO %s VALUES('%s',%i", tableaccuracy, ClientSteamID,thaTime);
				for(new i = 0; i < WEAPON_COUNT; i++)
				{
					tlen += Format(query[tlen], sizeof(query)-tlen, ",0");
					tlen += Format(query[tlen], sizeof(query)-tlen, ",0");
				}
				for(new i = 1; i <= 7; i++)
				{
					tlen += Format(query[tlen], sizeof(query)-tlen, ",0");
					//add 7 new hitbox fields
				}
				tlen += Format(query[tlen], sizeof(query)-tlen, ");");
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_027: %s",query);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
			}
		}
	}
}

EscapeIT(String:sSource[])
{
	new String:buffer[(MAX_LINE_WIDTH*3)+2];
	strcopy(buffer,sizeof(buffer),sSource);
	//deleting html/php tags from names is unnecessary. just use
	//$playername = htmlentities($adr['NAME'], ENT_QUOTES, 'UTF-8', true);
	//instead of $adr['NAME'] in the webpanels php code
	SQL_EscapeString(db,buffer,sSource,sizeof(buffer));
}

public T_CheckConnectingUsr(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else 
	{
		new String:clientname[(MAX_LINE_WIDTH*3)+2];
		GetClientName( client, clientname, sizeof(clientname) );
		EscapeIT(clientname);
		new String:ClientSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, ClientSteamID, sizeof(ClientSteamID));
		new String:buffer[2048], String:cIP[20], String:Country[64];
		GetClientIP(client,cIP,sizeof(cIP),true);
		GeoipCountry(cIP, Country, sizeof(Country));
		if (!SQL_GetRowCount(hndl))
		{
			new thaTime = GetTime();
			/*insert user*/
			if (sqllite != 1)
			{
				Format(buffer, sizeof(buffer), "INSERT INTO %s (`NAME`,`STEAMID`,`LASTONTIME`,`LASTDEDUCT`,`country`) VALUES ('%s','%s',%i,%i,'%s')", tableplayer, clientname, ClientSteamID, thaTime, thaTime, Country);
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_028: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				Format(buffer, sizeof(buffer), "INSERT IGNORE INTO %s (`country`) VALUES ('%s')", tablecountrylist, Country);
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_029: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
			}
			else
			{
				Format(buffer, sizeof(buffer), "INSERT INTO %s VALUES('%s','%s',0,0,%i,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,%i,'%s');", tableplayer, ClientSteamID,clientname,thaTime,thaTime,Country);
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_030: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				Format(buffer, sizeof(buffer), "INSERT OR IGNORE INTO %s VALUES('%s');", tablecountrylist, Country);
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_031: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
			}
			PrintToChatAll("\x04[\x03%s\x04]\x01 %t: '%s'",CHATTAG, "Created New Profile", clientname);
		}
		else
		{
			/*update name*/
			Format(buffer, sizeof(buffer), "UPDATE %s SET NAME = '%s', country = '%s' WHERE STEAMID = '%s'", tableplayer, clientname, Country, ClientSteamID);
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_032: %s",buffer);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
			new clientpoints;
			while (SQL_FetchRow(hndl))
			{
				clientpoints = SQL_FetchInt(hndl,0);
				onconpoints[client] = clientpoints;
				Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s` WHERE `POINTS` >=%i", tableplayer, clientpoints);
				new conuserid = GetClientUserId(client);
				//if(debug_version == 1){LogToFile(Logfile, "Line 1663: %s",buffer);}
				SQL_TQuery(db, T_ShowrankConnectingUsr1, buffer, conuserid);
			}
		}
	}
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(StrEqual("", error))
	{
		if(data != INVALID_HANDLE)
			CloseHandle(data);
		return;
	}
	LogToFile(Logfile, "SQL Error: %s", error);
	if(data == INVALID_HANDLE)
		LogToFile(Logfile, "Problematic query not supplied. Please Enable Debug Logging!");
	else
	{
		new String:debugstring[1024];
		ResetPack(data, false);
		ReadPackString(data, debugstring, sizeof(debugstring));
		CloseHandle(data);
		LogToFile(Logfile, "[SQLITE=%i]Problematic query: %s", sqllite, debugstring);
	}
}

public T_ShowrankConnectingUsr1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		new rank;
		while (SQL_FetchRow(hndl))
		{
			rank = SQL_FetchInt(hndl,0);
		}
		onconrank[client] = rank;
		if (GetConVarInt(CV_showrankonconnect) != 0)
		{
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s`", tableplayer);
			new conuserid = GetClientUserId(client);
			//if(debug_version == 1){LogToFile(Logfile, "Line 1701: %s",buffer);}
			SQL_TQuery(db, T_ShowrankConnectingUsr2, buffer, conuserid);
		}
	}
}

public T_ShowrankConnectingUsr2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0);
		}
		new String:country[3];
		new String:ip[20];
		GetClientIP(client,ip,sizeof(ip),true);
		GeoipCode2(ip,country);
		if (GetConVarInt(CV_showrankonconnect) == 1)
			PrintToChat(client,"%t %t %i", "your", "conrank", onconrank[client], rankedclients);
		else if (GetConVarInt(CV_showrankonconnect) == 2)
		{
			new String:clientname[MAX_LINE_WIDTH];
			GetClientName( client, clientname, sizeof(clientname) );
			PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %s. \x04[\x03%t %i\x04]",CHATTAG, clientname, "connected from", country, "conrank", onconrank[client], rankedclients);
		}
		else if (GetConVarInt(CV_showrankonconnect) == 3)
			ConRankPanel(client);
		else if (GetConVarInt(CV_showrankonconnect) == 4)
		{
			new String:clientname[MAX_LINE_WIDTH];
			GetClientName( client, clientname, sizeof(clientname));
			PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %s. \x04[\x03%t %i\x04]",CHATTAG, clientname, "connected from", country, "conrank", onconrank[client], rankedclients);
			ConRankPanel(client);
		}
	}
}

public ConRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public Action:ConRankPanel(client)
{
	new Handle:panel = CreatePanel();
	new String:clientname[MAX_LINE_WIDTH];
	GetClientName( client, clientname, sizeof(clientname) );
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "%T %s", "Welcome back", client, clientname);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "%T %i", "conrank", client, onconrank[client], rankedclients);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "Rank panel Points", client, onconpoints[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), "%T", "close", client);
	DrawPanelItem(panel, buffer);
 
	SendPanelToClient(panel, client, ConRankPanelHandler, GetConVarInt(CV_conrankpaneltime));
 
	CloseHandle(panel);
 
	return Plugin_Handled;
}

public session(client)
{
	if(db == INVALID_HANDLE)
	{
		NotPanel(client, 1);
		return;
	}
	if(CheckFlush(client))
	{
		//Write current player accuracy data to DB first
		ClientAccToDB(client, 1); //argument 1 makes it jump into t_accpanel on callback
		ResetAcc(client);
	}
	else
	{
		//if checkflush returns false, accuracy data is not flushed to disk. so we need to call t_showsession manually at this point
		new String:buffer[255], conuserid = GetClientUserId(client);
		Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s`", tableplayer);
		//if(debug_version == 1){LogToFile(Logfile, "Line 1802: %s",buffer);}
		SQL_TQuery(db, T_ShowSession1, buffer, conuserid);
	}
}

public t_accpanel(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	//ClientAccToDB sends the userID through 'data'
	if (GetClientOfUserId(data) == 0)
		return;
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s`", tableplayer);
	//if(debug_version == 1){LogToFile(Logfile, "Line 1815: %s",buffer);}
	SQL_TQuery(db, T_ShowSession1, buffer, data);
}

public T_ShowSession1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		NotPanel(client);
	}
	else 
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0);
			new String:ConUsrSteamID[MAX_LINE_WIDTH];
			new String:buffer[255];
			GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
			Format(buffer, sizeof(buffer), "SELECT POINTS,gungamewins FROM %s WHERE STEAMID = '%s'", tableplayer, ConUsrSteamID);
			new conuserid = GetClientUserId(client);
			//if(debug_version == 1){LogToFile(Logfile, "Line 1850: %s",buffer);}
			SQL_TQuery(db, T_ShowSession2, buffer, conuserid);
		}
	}
}

public T_ShowSession2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		NotPanel(client);
	}
	else
	{
		new clientpoints,clientggwins;
		while (SQL_FetchRow(hndl))
		{
			clientpoints = SQL_FetchInt(hndl,0);
			clientggwins = SQL_FetchInt(hndl,1);
			playerpoints[client] = clientpoints;
			playerGGwins[client] = clientggwins;
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT (SELECT COUNT(*) FROM `%s` WHERE `POINTS` >=%i),(SELECT COUNT(*) FROM `%s` WHERE `gungamewins` >=%i)", tableplayer, clientpoints,tableplayer,clientggwins);
			new conuserid = GetClientUserId(client);
			//if(debug_version == 1){LogToFile(Logfile, "Line 1879: %s",buffer);}
			SQL_TQuery(db, T_ShowSession3, buffer, conuserid);
		}
	}
}

public T_ShowSession3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		NotPanel(client);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			playerrank[client] = SQL_FetchInt(hndl,0);
			playerGGrank[client] = SQL_FetchInt(hndl,1);
		}
		new String:ConUsrSteamID[MAX_LINE_WIDTH];
		new String:buffer[255];
		GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
		Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `PLAYTIME` FROM `%s` WHERE STEAMID = '%s'", tableplayer, ConUsrSteamID);
		new conuserid;
		conuserid = GetClientUserId(client);
		//if(debug_version == 1){LogToFile(Logfile, "Line 1909: %s",buffer);}
		SQL_TQuery(db, T_ShowSession4, buffer, conuserid);
	}
}

public T_ShowSession4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	// Make sure the client didn't disconnect while the thread was running
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		NotPanel(client);
	}
	else
	{
		new kills, death, playtime;
		while (SQL_FetchRow(hndl))
		{
			kills = SQL_FetchInt(hndl,0);
			death = SQL_FetchInt(hndl,1);
			playtime = SQL_FetchInt(hndl,2);
		}
		new Handle:testhandle = CreateArray();
		PushArrayCell(testhandle, data);
		PushArrayCell(testhandle, kills);
		PushArrayCell(testhandle, death);
		PushArrayCell(testhandle, playtime);
		new String:ConUsrSteamID[MAX_LINE_WIDTH];
		new String:buffer[255];
		GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
		Format(buffer, sizeof(buffer), "SELECT * FROM `%s` WHERE STEAMID = '%s'", tableaccuracy, ConUsrSteamID);
		//if(debug_version == 1){LogToFile(Logfile, "Line 1947: %s",buffer);}
		SQL_TQuery(db, T_ShowSession5, buffer, testhandle);
	}
}
public T_ShowSession5(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new userID = GetArrayCell(data, 0);
	
	new client = GetClientOfUserId(userID);
 
	// Make sure the client didn't disconnect while the thread was running
	if (client == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		NotPanel(client);
	}
	else
	{
		new kills = GetArrayCell(data, 1), death = GetArrayCell(data, 2), playtime = GetArrayCell(data, 3);
		new fields = SQL_GetFieldCount(hndl) - 7;
		new shots, hits, PreferredLimb;
		while (SQL_FetchRow(hndl))
		{
			for(new i = 2; i < fields; i++)
			{
				switch (i & 1)
				{
					case true:
					{
						hits += SQL_FetchInt(hndl,i); // i is odd
					}
					case false:
					{
						shots += SQL_FetchInt(hndl,i);	// i is even
					}
				}
			}
			new Limbhits, Limbcount;
			for(new i = fields;i <= (fields + 6);i++)
			{
				Limbcount++;
				new iBuff = SQL_FetchInt(hndl, i);
				if (iBuff > Limbhits)
				{
					Limbhits = iBuff;
					PreferredLimb = Limbcount;
				}
			}
		}
		new accuracy, Float:fAcc, sessionaccuracy;
		if (shots == 0)
			accuracy = 0;
		else
		{
			fAcc = ((float(100) / float(shots)) * float(hits));
			accuracy = RoundToNearest(fAcc);
		}
		shots = 0;
		hits = 0;
		for (new j = 0; j < WEAPON_COUNT; j++)
		{
			shots += session_stats[client][j][0];
			hits += session_stats[client][j][1];
		}
		
		if(shots == 0)
			sessionaccuracy = 0;
		else
		{
			fAcc = ((float(100) / float(shots)) * float(hits));
			sessionaccuracy = RoundToNearest(fAcc);
		}
		SessionPanel(client,kills,death,playtime,accuracy,sessionaccuracy,PreferredLimb);
	}
	CloseHandle(data);
}

NotPanel(client, cause = 0)
{
	new Float:fAcc, sessionaccuracy, shots, hits;
	for (new j = 0; j < WEAPON_COUNT; j++)
	{
		shots += session_stats[client][j][0];
		hits += session_stats[client][j][1];
	}
	
	if(shots == 0)
		sessionaccuracy = 0;
	else
	{
		fAcc = ((float(100) / float(shots)) * float(hits));
		sessionaccuracy = RoundToNearest(fAcc);
	}

	new Handle:panel = CreatePanel();
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "%T", "Session Panel", client);
	SetPanelTitle(panel, buffer);
	Format(buffer, sizeof(buffer), " - %T", "Total", client);
	DrawPanelItem(panel, buffer);
	if(cause == 1)
		Format(buffer, sizeof(buffer), "*%T*", "database error", client);
	else
		Format(buffer, sizeof(buffer), "*%T*", "sql error", client);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " - %T", "Session", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), " %T", "Rank panel Points", client, sessionpoints[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %i:%i K/D", sessionkills[client] , sessiondeath[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T", "Rank panel headshots", client, sessionheadshotkills[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T", "Rank panel Playtime", client, RoundToZero(GetClientTime(client)/60));
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T %i\%", "accuracy", client, sessionaccuracy);
	DrawPanelText(panel, buffer);
	SendPanelToClient(panel, client, SessionRankPanelHandler, GetConVarInt(CV_sessionrankpaneltime));
	
	CloseHandle(panel);
}

public Action:SessionPanel(client,kills,death,playtime,accuracy,sessionaccuracy, PreferredLimb)
{
	new String:Limb[255];
	if(PreferredLimb == 0)
		PreferredLimb = 1;
	Format(Limb, sizeof(Limb), "%T", limblist[(PreferredLimb-1)], client);

	new Handle:panel = CreatePanel();
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "%T", "Session Panel", client);
	SetPanelTitle(panel, buffer);
	Format(buffer, sizeof(buffer), " - %T", "Total", client);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), " %T %i", "conrank", client, playerrank[client], rankedclients);
	DrawPanelText(panel, buffer);
	if(GetConVarInt(CV_noGG) == 0)
	{
		Format(buffer, sizeof(buffer), "GG %T %i GG %T %i", "rank", client, playerGGrank[client], "wins", client, playerGGwins[client]);
		DrawPanelText(panel, buffer);
	}
	Format(buffer, sizeof(buffer), " %T", "Rank panel Points", client, playerpoints[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %i:%i K/D", kills , death);
	DrawPanelText(panel, buffer);
 	Format(buffer, sizeof(buffer), " %T", "Rank panel Playtime", client, playtime);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T %i\%", "accuracy", client, accuracy);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T %s", "preferred limb", client, Limb);
	DrawPanelItem(panel, buffer);
	Format(buffer, sizeof(buffer), " - %T", "Session", client);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T", "Rank panel Points", client, sessionpoints[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %i:%i K/D", sessionkills[client] , sessiondeath[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T", "Rank panel headshots", client, sessionheadshotkills[client]);
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T", "Rank panel Playtime", client, RoundToZero(GetClientTime(client)/60));
	DrawPanelText(panel, buffer);
	Format(buffer, sizeof(buffer), " %T %i\%", "accuracy", client, sessionaccuracy);
	DrawPanelText(panel, buffer);
	SendPanelToClient(panel, client, SessionRankPanelHandler, GetConVarInt(CV_sessionrankpaneltime));
	
	CloseHandle(panel);
	
	return Plugin_Handled;
}

public SessionRankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(param2 != 2)
		return;
	new String:SteamID[64], UserID, String:buffer[255];
	UserID = GetClientUserId(param1);
	GetClientAuthString(param1, SteamID, sizeof(SteamID));
	Format(buffer, sizeof(buffer), "SELECT * FROM `%s` WHERE STEAMID = '%s'", tableaccuracy, SteamID);
	//if(debug_version == 1){LogToFile(Logfile, "Line 2153: %s",buffer);}
	SQL_TQuery(db, T_HitBox, buffer, UserID);
}

public T_HitBox(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new userID = data;
	new client = GetClientOfUserId(userID);
	if (client == 0)
		return;
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
	}
	else
	{
		new fields = SQL_GetFieldCount(hndl) - 7;
		while (SQL_FetchRow(hndl))
		{
			new Handle:panel = CreatePanel();
			new String:buffer[255], String:snip[255];
			Format(buffer, sizeof(buffer), "%T", "limb stats", client);
			SetPanelTitle(panel, buffer);
			for(new i = fields;i <= (fields + 6);i++)
			{
				new Limb = SQL_FetchInt(hndl, i);
				Format(snip, sizeof(snip), "%T", limblist[(i-fields)], client);
				Format(buffer, sizeof(buffer), "%s - %i %T", snip, Limb, "hits", client);
				DrawPanelText(panel, buffer);
			}
			Format(buffer, sizeof(buffer), "%T", "close", client);
			DrawPanelItem(panel, buffer);
			SendPanelToClient(panel, client, SessionRankPanelHandler, GetConVarInt(CV_sessionrankpaneltime));
			CloseHandle(panel);
		}
	}
}

public webranking(client)
{
	if (GetConVarInt(CV_webrank) == 1)
	{
		new String:rankurl[255];
		GetConVarString(CV_webrankurl,rankurl, sizeof(rankurl));
		new String:showrankurl[255];
		new String:UsrSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));
		
		Format(showrankurl, sizeof(showrankurl), "%splayer.php?steamid=%s&time=%i",rankurl,UsrSteamID,GetTime());
		PrintToConsole(client, "RANK MOTDURL %s", showrankurl);
		Format(rankurl, sizeof(rankurl), "%T %T", "your", client, "rank", client);
		ShowMOTDPanel(client, rankurl, showrankurl, 2);
	}
}

public webtop(client)
{
	if (GetConVarInt(CV_webrank) == 1)
	{
		new String:rankurl[255];
		GetConVarString(CV_webrankurl,rankurl, sizeof(rankurl));
		new String:showrankurl[255];
		new String:UsrSteamID[MAX_LINE_WIDTH];
		GetClientAuthString(client, UsrSteamID, sizeof(UsrSteamID));
		
		Format(showrankurl, sizeof(showrankurl), "%splayer_ranking.php?time=%i",rankurl,GetTime());
		PrintToConsole(client, "RANK MOTDURL %s", showrankurl);
		Format(rankurl, sizeof(rankurl), "%T", "rank", client);
		ShowMOTDPanel(client, rankurl, showrankurl, 2);
	}
}

public rankpanel(client, const String:steamid[])
{
	new String:buffer[255];
	Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s`", tableplayer);
	Format(ranksteamidreq[client],25, "%s" ,steamid);
	//if(debug_version == 1){LogToFile(Logfile, "Line 2229: %s",buffer);}
	SQL_TQuery(db, T_ShowRank1, buffer, GetClientUserId(client));
}

public T_ShowRank1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		while (SQL_FetchRow(hndl))
		{
			rankedclients = SQL_FetchInt(hndl,0);
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT POINTS FROM %s WHERE STEAMID = '%s'", tableplayer, ranksteamidreq[client]);
			//if(debug_version == 1){LogToFile(Logfile, "Line 2251: %s",buffer);}
			SQL_TQuery(db, T_ShowRank2, buffer, data);
		}
	}
}

public T_ShowRank2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		while (SQL_FetchRow(hndl))
		{
			reqplayerrankpoints[client] = SQL_FetchInt(hndl,0);
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT COUNT(*) FROM `%s` WHERE `POINTS` >=%i", tableplayer, reqplayerrankpoints[client]);
			//if(debug_version == 1){LogToFile(Logfile, "Line 2274: %s",buffer);}
			SQL_TQuery(db, T_ShowRank3, buffer, data);
		}
	}
}

public T_ShowRank3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
 
	if ((client = GetClientOfUserId(data)) == 0)
		return;
 
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		while (SQL_FetchRow(hndl))
		{
			reqplayerrank[client] = SQL_FetchInt(hndl,0);
		}
		new String:ConUsrSteamID[MAX_LINE_WIDTH];
		new String:buffer[255];
		GetClientAuthString(client, ConUsrSteamID, sizeof(ConUsrSteamID));
		Format(buffer, sizeof(buffer), "SELECT `KILLS`, `Death`, `PLAYTIME`, `NAME` FROM `%s` WHERE STEAMID = '%s'", tableplayer, ranksteamidreq[client]);
		//if(debug_version == 1){LogToFile(Logfile, "Line 2300: %s",buffer);}
		SQL_TQuery(db, T_ShowRank4, buffer, data);
	}
}

public T_ShowRank4(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	if ((client = GetClientOfUserId(data)) == 0)
		return;
	
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		new kills,death, playtime;
		while (SQL_FetchRow(hndl))
		{
			kills = SQL_FetchInt(hndl,0);
			death = SQL_FetchInt(hndl,1);
			playtime = SQL_FetchInt(hndl,2);
			SQL_FetchString(hndl,3, ranknamereq[client] , 32);
		}
		RankPanel(client,kills,death,playtime);
	}
}

public Action:RankPanel(client,kills,death,playtime)
{
	new Handle:rnkpanel = CreatePanel();
	new String:value[MAX_LINE_WIDTH];
	new String:bb[255];
	SetPanelTitle(rnkpanel, "Rank Panel:");
	Format(value, sizeof(value), "%T", "Rank panel Name" , client, ranknamereq[client]);
	DrawPanelText(rnkpanel, value);
	Format(bb, sizeof(bb), "%T", "conrank", client, reqplayerrank[client]);
	Format(value, sizeof(value), "%s %i", bb,rankedclients);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "%T", "Rank panel Points" , client, reqplayerrankpoints[client]);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "%T", "Rank panel Playtime" , client, playtime);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "%T", "Rank panel Kills" , client, kills);
	DrawPanelText(rnkpanel, value);
	Format(value, sizeof(value), "%T", "Rank panel Deaths" , client, death);
	DrawPanelText(rnkpanel, value);
	if (GetConVarInt(CV_webrank) == 1)
	{
		Format(value, sizeof(value), "%T", "webranknotice", client);
		DrawPanelText(rnkpanel, value);
	}
	Format(value, sizeof(value), "%T", "close", client);
	DrawPanelItem(rnkpanel, value);
	SendPanelToClient(rnkpanel, client, SessionRankPanelHandler, GetConVarInt(CV_sessionrankpaneltime));

	CloseHandle(rnkpanel);
 
	return Plugin_Handled;
}

public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}

public echo_rank(client)
{
	if(client == 0)
		return;
	if(!IsClientInGame(client))
		return;
	if(!IsFakeClient(client))
	{
		new String:steamId[MAX_LINE_WIDTH];
		GetClientAuthString(client, steamId, sizeof(steamId));
		rankpanel(client, steamId);
	}
}
sbottop(mode)
{
	if(db != INVALID_HANDLE)
	{
		new String:buffer[255], shift;
		shift = (mode - 10);
		Format(buffer, sizeof(buffer), "SELECT STEAMID,(KILLS/Death) FROM `%s` ORDER BY PLAYTIME DESC LIMIT 0,20", tableplayer);
		//if(debug_version == 1){LogToFile(Logfile, "Line 2300: %s",buffer);}
		SQL_TQuery(db, T_bottop, buffer, shift);
	}
}

public bottop(client)
{
	if(db == INVALID_HANDLE)
	{
		new String:errmsg[255];
		Format(errmsg, sizeof(errmsg), "*%T*", "database error", client);
		PrintToChat(client, errmsg);
	}
	else
	{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "SELECT STEAMID,(KILLS/Death) FROM `%s` ORDER BY PLAYTIME DESC LIMIT 0,20", tableplayer);
		//if(debug_version == 1){LogToFile(Logfile, "Line 2399: %s",buffer);}
		SQL_TQuery(db, T_bottop, buffer, GetClientUserId(client));
	}
}

public T_bottop(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;

	if ((client = GetClientOfUserId(data)) == 0 && data > 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		if (data > 0)
		{
			new String:errmsg[255];
			Format(errmsg, sizeof(errmsg), "*%T*", "sql error", client);
			PrintToChat(client, errmsg);
		}
	}
	else
	{
		new Float:lowestKD = 1000.0, String:SteamID[96], Float:setKD;
		while (SQL_FetchRow(hndl))
		{
			setKD = SQL_FetchFloat(hndl,1);
			if (setKD < lowestKD)
			{
				lowestKD = setKD;
				SQL_FetchString(hndl,0, SteamID, sizeof(SteamID));
			}
		}
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "SELECT NAME,POINTS,PLAYTIME,KILLS,Death FROM `%s` WHERE STEAMID = '%s'", tableplayer, SteamID);
		//if(debug_version == 1){LogToFile(Logfile, "Line 2431: %s",buffer);}
		SQL_TQuery(db, T_bottop2, buffer, data);
	}
	return;
}
public T_bottop2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client;
	
	if ((client = GetClientOfUserId(data)) == 0 && data > 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		if (data > 0)
		{
			new String:errmsg[255];
			Format(errmsg, sizeof(errmsg), "*%T*", "sql error", client);
			PrintToChat(client, errmsg);
		}
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			new String:Name[255], Points, Playtime, Kills, Death, Float:KD, String:Buffer[255];
			SQL_FetchString(hndl,0, Name, sizeof(Name));
			Points = SQL_FetchInt(hndl,1);
			Playtime = SQL_FetchInt(hndl,2);
			Kills = SQL_FetchInt(hndl,3);
			Death = SQL_FetchInt(hndl,4);
			KD = float(Kills)/float(Death);
			if(data > 0 || data == -8)
			{
				new Handle:rnktoppanel = CreatePanel();
				Format(Buffer, sizeof(Buffer), "*%T*", "bottop", client);
				SetPanelTitle(rnktoppanel, Buffer);
				Format(Buffer, sizeof(Buffer), Name);
				DrawPanelText(rnktoppanel, Buffer);
				Format(Buffer, sizeof(Buffer), "%T", "Rank panel Points", client, Points);
				DrawPanelText(rnktoppanel, Buffer);
				Format(Buffer, sizeof(Buffer), "%T", "Rank panel Playtime", client, Playtime);
				DrawPanelText(rnktoppanel, Buffer);
				Format(Buffer, sizeof(Buffer), "%T", "kills per death", client, KD);
				DrawPanelText(rnktoppanel, Buffer);
				Format(Buffer, sizeof(Buffer), "%T", "close", client);
				DrawPanelItem(rnktoppanel, Buffer);
				if (data > 0)
					SendPanelToClient(rnktoppanel, client, bottopHandler, GetConVarInt(CV_toppaneltime));
				else
				{
					for(new i = 1;i<= MaxClients;i++)
					{
						if(IsClientInGame(i) && !IsFakeClient(i))
							SendPanelToClient(rnktoppanel, i, bottopHandler, GetConVarInt(CV_toppaneltime));
					}
				}
				CloseHandle(rnktoppanel);
			}
			else if(data == -9)
				PrintToChatAll("%t: %s, %t, %t, %t", "bottop", Name, "Rank panel Points", Points, "Rank panel Playtime", Playtime, "kills per death", KD);
		}
	}
	return;
}
public bottopHandler(Handle:menu, MenuAction:action, param1, param2)
{}
public topweapon(client)
{
	new String:Buffer[255];
	if(db == INVALID_HANDLE)
	{
		Format(Buffer, sizeof(Buffer), "*%T*", "database error", client);
		PrintToChat(client, Buffer);
		return;
	}
	new Handle:menu = CreateMenu(TopWeaponHandler);
	Format(Buffer, sizeof(Buffer), "%T", "wtop select", client);
	SetMenuTitle(menu, Buffer);
	Format(Buffer, sizeof(Buffer), "%T", "wprank by kills", client);
	AddMenuItem(menu, "0", Buffer);
	Format(Buffer, sizeof(Buffer), "%T %T", "wprank by accuracy", client, "fired vs hits", client);
	AddMenuItem(menu, "1", Buffer);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, GetConVarInt(CV_toppaneltime));
}

public TopWeaponHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[8], iInfo, String:Buffer[255];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		iInfo = StringToInt(info);
		if(found)
		{
			new Handle:tmenu = CreateMenu(SelectedWeapon);
			if(iInfo == 0)
			{
				Format(Buffer, sizeof(Buffer), "%T - %T", "wprank by kills", param1, "select weapon", param1);
				SetMenuTitle(tmenu, Buffer);
				wprankmode[param1] = 0;
			}
			else
			{
				SetMenuTitle(tmenu, "%T - %T", "wprank by accuracy", param1, "select weapon", param1);
				wprankmode[param1] = 1;
			}
			for (new j = 0; j < WEAPON_COUNT; j++)
			{
				new String:WI[4]; IntToString(j, WI, sizeof(WI));
				AddMenuItem(tmenu, WI, weaponlist[j]);
			}
			SetMenuExitButton(tmenu, true);
			DisplayMenu(tmenu, param1, GetConVarInt(CV_toppaneltime));
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public SelectedWeapon(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[8], weaponindex;
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		weaponindex = StringToInt(info);
		if(found)
		{
			weaponrank(param1, wprankmode[param1], weaponindex);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

weaponrank(client, mode, weaponindex)
{
	new String:buffer[1024], String:wp[255], String:wp_hit[255], UserID = GetClientUserId(client), String:KW[255];
	strcopy(wp, sizeof(wp), weaponlist[weaponindex]);
	Format(wp_hit, sizeof(wp_hit), "%s_hit",wp);
	Format(KW, sizeof(KW), "KW_%s",wp);
	switch (mode)
	{
		case 0:
		{
			Format(buffer, sizeof(buffer), "SELECT STEAMID,%s,NAME,%i,%i FROM %s order by %s desc limit 0,20", KW, mode, weaponindex, tableplayer, KW);
		}
		case 1:
		{
			Format(buffer, sizeof(buffer), "SELECT STEAMID,((100/%s)*%s),(select NAME from %s where STEAMID = %s.STEAMID),%i,%i FROM %s order by ((100 / %s) * %s) desc limit 0,20;", wp, wp_hit, tableplayer, tableaccuracy, mode, weaponindex, tableaccuracy, wp, wp_hit);
		}
	}
	//if(debug_version == 1){LogToFile(Logfile, "Line 2580: %s",buffer);}
	SQL_TQuery(db, T_ShowAccTop, buffer, UserID);
}
bool:FloatToCutString(Float:value, String:Target[], TargetSize, DecPlaces)
{
	if(DecPlaces < 1)
		return false;
	new Float:fBuffer = value, String:Buffer[255], String:Buffer2[255];
	new Ganz = RoundToFloor(fBuffer);	//strip integer from decimal places
	fBuffer = FloatFraction(fBuffer);	//strip decimal places from integer
	FloatToString(fBuffer, Buffer, (3+DecPlaces)); //cut decimal places to desired (2 places = 5 characters (0,xx\n)
	strcopy(Buffer2, sizeof(Buffer2), Buffer[2]); //strip decimal places string from '0,'-prefix
	Format(Buffer, sizeof(Buffer), "%i,%s",Ganz,Buffer2);
	strcopy(Target, TargetSize, Buffer);
	return true;
}
public T_ShowAccTop(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client = GetClientOfUserId(data);
	
	/* Make sure the client didn't disconnect while the thread was running */
	if (client == 0)
		return;
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		new String:errmsg[255];
		Format(errmsg, sizeof(errmsg), "*%T*", "sql error", client);
		PrintToChat(client, errmsg);
	}
	else
	{
		new String:Buffer[255];
		if(SQL_GetRowCount(hndl) == 0)
		{
			Format(Buffer, sizeof(Buffer), "%T", "nowpdata", client);
			PrintToChat(client, Buffer);
		}
		else
		{
			new String:Name[20][255], String:SteamID[20][64], Rankvalue[20], Rankmode, weaponindex, Rowcount = SQL_GetRowCount(hndl);
			new counter, Float:fBuffer, String:fRankvalue[20][20];
			
			while (SQL_FetchRow(hndl))
			{
				SQL_FetchString(hndl, 0, SteamID[counter], 64);
				SQL_FetchString(hndl, 2, Name[counter], 255);
				Rankmode = SQL_FetchInt(hndl, 3);
				weaponindex = SQL_FetchInt(hndl, 4);
				switch (Rankmode)
				{
					case 0:
					{
						Rankvalue[counter] = SQL_FetchInt(hndl, 1);
					}
					case 1:
					{
						fBuffer = SQL_FetchFloat(hndl, 1);
						FloatToCutString(fBuffer, fRankvalue[counter], 20, 2);
					}
				}
				counter++;
			}
			new Handle:menu = CreateMenu(TopWeaponDisplayHandler), Upperbound;
			if (Rowcount < 20)
				Upperbound = Rowcount;
			else
				Upperbound = 20;
			if(Rankmode == 0)
			{
				Format(Buffer, sizeof(Buffer), "%T %s :", "top kills", client, weaponlist[weaponindex]);
				SetMenuTitle(menu, Buffer);
				for(new i=0;i<Upperbound;i++)
				{
					if(i < 9)
						Format(Buffer,sizeof(Buffer), "%T 0%i: %s - %i", "place", client, (i+1), Name[i], Rankvalue[i]);
					else
						Format(Buffer,sizeof(Buffer), "%T %i: %s - %i", "place", client, (i+1), Name[i], Rankvalue[i]);
					AddMenuItem(menu, SteamID[i], Buffer);
				}
			}
			else
			{
				Format(Buffer, sizeof(Buffer), "%T %s :", "top accuracy", client, weaponlist[weaponindex]);
				SetMenuTitle(menu, Buffer);
				for(new i=0;i<Upperbound;i++)
				{
					if(i < 9)
						Format(Buffer,sizeof(Buffer), "%T 0%i: %s - %s \%", "place", client, (i+1), Name[i], fRankvalue[i]);
					else
						Format(Buffer,sizeof(Buffer), "%T %i: %s - %s \%", "place", client, (i+1), Name[i], fRankvalue[i]);
					AddMenuItem(menu, SteamID[i], Buffer);
				}
			}
			SetMenuExitButton(menu, true);
			DisplayMenu(menu, client, GetConVarInt(CV_toppaneltime));
		}
	}
}

public TopWeaponDisplayHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		new UserID = GetClientUserId(param1);
		new String:MenuTitle[255], String:exp[3][255], String:weapon[255], String:query[2048], String:SteamID[64], String:whit[255];
		GetMenuTitle(menu, String:MenuTitle, sizeof(MenuTitle));
		ExplodeString(MenuTitle, " ", exp, 3, 255);
		Format(weapon, sizeof(weapon), "KW_%s", exp[2]);
		Format(whit, sizeof(whit), "%s_hit", exp[2]);
		new bool:found = GetMenuItem(menu, param2, SteamID, sizeof(SteamID));
		if(found)
		{
			Format(query, sizeof(query), "SELECT '%s',NAME,%s,Death,HeadshotKill,(SELECT ((100/%s)*%s) FROM %s WHERE STEAMID = '%s'),(SELECT %s FROM %s WHERE STEAMID = '%s'),(SELECT %s FROM %s WHERE STEAMID = '%s') FROM %s WHERE STEAMID = '%s';", exp[2], weapon, exp[2], whit, tableaccuracy, SteamID, exp[2], tableaccuracy, SteamID, whit, tableaccuracy, SteamID, tableplayer, SteamID);
			//if(debug_version == 1){LogToFile(Logfile, "Line 2690: %s",query);}
			SQL_TQuery(db, T_Showmyweapon, query, UserID);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
myweapon(client)
{
	new String:snip[255];
	if(db == INVALID_HANDLE)
	{
		Format(snip, sizeof(snip), "*%T*", "database error", client);
		PrintToChat(client, snip);
		return;
	}

	new UserID = GetClientUserId(client);
	new String:cWeapon[255];
	GetClientWeapon(client, cWeapon, sizeof(cWeapon));
	if(strlen(cWeapon) == 0)
	{
		Format(snip, sizeof(snip), "*%T*", "nohold", client);
		PrintToChat(client, snip);
		return;
	}
	strcopy(snip, sizeof(snip), cWeapon[7]);
	if(StrEqual("c4", snip, false) || StrEqual("flashbang", snip, false) || StrEqual("smokegrenade", snip, false))
	{
		Format(snip, sizeof(snip), "%T", "witzpille", client);
		PrintToChat(client, snip);
		return;
	}
	new String:weapon[255], String:query[2048], String:SteamID[64], String:whit[255];
	Format(weapon, sizeof(weapon), "KW_%s", snip);
	Format(whit, sizeof(whit), "%s_hit", snip);
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	Format(query, sizeof(query), "SELECT '%s',NAME,%s,Death,HeadshotKill,(SELECT ((100/%s)*%s) FROM %s WHERE STEAMID = '%s'),(SELECT %s FROM %s WHERE STEAMID = '%s'),(SELECT %s FROM %s WHERE STEAMID = '%s') FROM %s WHERE STEAMID = '%s';", snip, weapon, snip, whit, tableaccuracy, SteamID, snip, tableaccuracy, SteamID, whit, tableaccuracy, SteamID, tableplayer, SteamID);
	//LogToFile(Logfile, "Line 2864: *%s*", query);
	//if(debug_version == 1){LogToFile(Logfile, "Line 2721: %s",query);}
	SQL_TQuery(db, T_Showmyweapon, query, UserID);
}
public T_Showmyweapon(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client, String:Buffer[255];
	
	if ((client = GetClientOfUserId(data)) == 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		Format(Buffer, sizeof(Buffer), "*%T*", "sql error", client);
		PrintToChat(client, Buffer);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			new String:Name[255], Kills, Death, HeadshotKill, Float:accuracy, BulletsFired, Hits, String:weapon[255];
			SQL_FetchString(hndl,0, weapon, sizeof(weapon));
			SQL_FetchString(hndl,1, Name, sizeof(Name));
			Kills = SQL_FetchInt(hndl, 2);
			Death = SQL_FetchInt(hndl, 3);
			HeadshotKill = SQL_FetchInt(hndl, 4);
			accuracy = SQL_FetchFloat(hndl, 5);
			BulletsFired = SQL_FetchInt(hndl, 6);
			Hits = SQL_FetchInt(hndl, 7);
			
			new Handle:rnktoppanel = CreatePanel();
			Format(Buffer, sizeof(Buffer), Name);
			SetPanelTitle(rnktoppanel, Buffer);
			Format(Buffer, sizeof(Buffer), "%T", "Rank panel Deaths", client, Death);
			DrawPanelText(rnktoppanel, Buffer);
			Format(Buffer, sizeof(Buffer), "%T %T", "Total", client, "Rank panel headshots", client, HeadshotKill);
			DrawPanelText(rnktoppanel, Buffer);
			Format(Buffer, sizeof(Buffer), "****%s %T****", weapon, "Rank panel player titel", client);
			DrawPanelText(rnktoppanel, Buffer);
			Format(Buffer, sizeof(Buffer), "%s %T", weapon, "Rank panel Kills", client, Kills);
			DrawPanelText(rnktoppanel, Buffer);
			if(!StrEqual("knife",weapon, false))
			{
				Format(Buffer, sizeof(Buffer), "%s %T", weapon, "vfired", client, BulletsFired);
				DrawPanelText(rnktoppanel, Buffer);
			}
			Format(Buffer, sizeof(Buffer), "%s %T", weapon, "vhits", client, Hits);
			DrawPanelText(rnktoppanel, Buffer);
			if(!StrEqual("knife",weapon, false))
			{
				new String:accstring[255];
				FloatToCutString(accuracy, accstring, sizeof(accstring), 2);
				Format(Buffer, sizeof(Buffer), "%s %T %s\%", weapon, "accuracy", client, accstring);
				DrawPanelText(rnktoppanel, Buffer);
			}
			Format(Buffer, sizeof(Buffer), "%T", "close", client);
			DrawPanelItem(rnktoppanel, Buffer);
			SendPanelToClient(rnktoppanel, client, bottopHandler, GetConVarInt(CV_toppaneltime));
			CloseHandle(rnktoppanel);
		}
	}
}

public topcountry(client)
{
	new String:buffer[255];
	if(db == INVALID_HANDLE)
	{
		Format(buffer, sizeof(buffer), "*%T*", "database error", client);
		PrintToChat(client, buffer);
	}
	else
	{
		Format(buffer, sizeof(buffer), "SELECT country FROM `%s` ORDER BY country ASC", tablecountrylist);
		//if(debug_version == 1){LogToFile(Logfile, "Line 2790: %s",buffer);}
		SQL_TQuery(db, T_ShowCountry, buffer, GetClientUserId(client));
	}
}

public T_ShowCountry(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client, String:Buffer[255];
	
	if ((client = GetClientOfUserId(data)) == 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		Format(Buffer, sizeof(Buffer), "*%T*", "sql error", client);
		PrintToChat(client, Buffer);
	}
	else
	{
		new Handle:Countrylist = CreateArray(ByteCountToCells(64)), String:sUserID[64], String:sCounter[64], String:sCountrycount[64];
		PushArrayString(Countrylist, "Reserved");
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0,Buffer,64);
			PushArrayString(Countrylist, Buffer);
		}
		new String:query[255];
		IntToString(data,sUserID,64);
		IntToString(1,sCounter,64);
		IntToString((GetArraySize(Countrylist)-1),sCountrycount,64);
		Format(Buffer,64,"%s*%s*%s",sUserID,sCounter,sCountrycount);
		SetArrayString(Countrylist, 0, Buffer);
		GetArrayString(Countrylist, 1, Buffer, 64);
		Format(query, sizeof(query), "SELECT SUM(POINTS) from %s where country = '%s'", tableplayer, Buffer);
		//if(debug_version == 1){LogToFile(Logfile, "Line 2825: %s",query);}
		SQL_TQuery(db, T_ShowCountryLoop, query, Countrylist);
	}
	return;
}

//damn how stupid that was!!
//use this: SELECT SUM(POINTS), country from sDM_Player group by country order by sum(points) desc

public T_ShowCountryLoop(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new Handle:Countrylist = data, String:Buffer[255], String:sCounter[64];
	new String:exBuffer[3][64], UserID, Counter, Countrycount, client;
	GetArrayString(Countrylist, 0, Buffer,64);
	ExplodeString(Buffer, "*", exBuffer, 3, 64);
	UserID = StringToInt(exBuffer[0]); Counter = StringToInt(exBuffer[1]); Countrycount = StringToInt(exBuffer[2]);
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(UserID)) == 0)
	{
		CloseHandle(Countrylist);
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		Format(Buffer, sizeof(Buffer), "*%T*", "sql error", client);
		PrintToChat(client, Buffer);
		CloseHandle(Countrylist);
	}
	else
	{
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0,Buffer,64);
			PushArrayString(Countrylist, Buffer);
		}
		if(Counter < Countrycount)
		{
			Counter++;
			new String:query[255];
			GetArrayString(Countrylist, Counter, Buffer, 64);
			Format(query, sizeof(query), "SELECT SUM(POINTS) from %s where country = '%s'", tableplayer, Buffer);
			IntToString(Counter,sCounter,64);
			Format(Buffer,64,"%s*%s*%s",exBuffer[0],sCounter,exBuffer[2]);
			SetArrayString(Countrylist, 0, Buffer);
			//if(debug_version == 1){LogToFile(Logfile, "Line 2865: %s",query);}
			SQL_TQuery(db, T_ShowCountryLoop, query, Countrylist);
		}
		else
			ShowCountryPostLoop(Countrylist);
	}
	return;
}

ShowCountryPostLoop(Handle:Countrylist)
{
	new String:Buffer[255];
	new String:exBuffer[3][64], UserID, Countrycount, client;
	GetArrayString(Countrylist, 0, Buffer,64);
	ExplodeString(Buffer, "*", exBuffer, 3, 64);
	UserID = StringToInt(exBuffer[0]); Countrycount = StringToInt(exBuffer[2]);
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(UserID)) == 0)
	{
		CloseHandle(Countrylist);
		return;
	}
	new String:sBuffer[128], String:pBuffer[64];
	new Handle:Countries = CreateArray(ByteCountToCells(64)), Handle:cPoints = CreateArray();
	new Sortcount = 0;
	new Searchlowest;
	new ThePoints[255], UsedIndexes[255];
	for(new i=1;i<=Countrycount;i++)
	{
		GetArrayString(Countrylist,(i+Countrycount),pBuffer,64);
		new Current = StringToInt(pBuffer);
		ThePoints[i] = Current;
		Current *= -1;
		if(Current > Searchlowest)
			Searchlowest = Current;
	}
	if(Searchlowest > 0)
	{
		Searchlowest++;
		Searchlowest *= -1;
	}
	else
		Searchlowest--;
	while(Sortcount < Countrycount)
	{
		new Highest = Searchlowest, hIndex;
		for(new i=1;i<=Countrycount;i++)
		{
			new Current = ThePoints[i];
			if(Current > Highest)
			{
				new bool:Used = false;
				if(Sortcount > 0)
				{
					for(new j=0;j<Sortcount;j++)
					{
						if(i == UsedIndexes[j])
						{
							Used = true;
							break;
						}
					}
				}
				if(!Used)
				{
					Highest = Current;
					hIndex = i;
					UsedIndexes[Sortcount] = i;
				}
			}
		}
		GetArrayString(Countrylist, hIndex, Buffer, 64);
		if(strlen(Buffer)!=0)
			PushArrayString(Countries, Buffer);
		else
			PushArrayString(Countries, "Playercountry unknown");
		PushArrayCell(cPoints, Highest);
		Sortcount++;
	}
	
	CloseHandle(Countrylist);
	
	new Handle:menu = CreateMenu(TopCountryHandler);
	Format(Buffer, sizeof(Buffer), "%T", "top countries", client);
	SetMenuTitle(menu, Buffer);
	for(new i=0;i<Countrycount;i++)
	{
		if((i+1)>Countrycount)
			break;
		GetArrayString(Countries, i, Buffer, sizeof(Buffer));
		Format(sBuffer,sizeof(sBuffer), "%s - %i", Buffer, GetArrayCell(cPoints,i));
		if(StrEqual("Playercountry unknown",Buffer))
			AddMenuItem(menu, "", sBuffer);
		else
			AddMenuItem(menu, Buffer, sBuffer);
	}
	CloseHandle(Countries);
	CloseHandle(cPoints);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, GetConVarInt(CV_toppaneltime));
}
public TopCountryHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[64];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		if(found)
		{
			new String:buffer[255], UserID = GetClientUserId(param1);
			Format(buffer, sizeof(buffer), "SELECT NAME,steamId FROM `%s` where country = '%s' ORDER BY POINTS DESC LIMIT 0,10", tableplayer, info);
			new Handle:Krempel = CreateArray(ByteCountToCells(64));
			PushArrayCell(Krempel, UserID);
			PushArrayString(Krempel, info);
			//if(debug_version == 1){LogToFile(Logfile, "Line 2980: %s",buffer);}
			SQL_TQuery(db, T_ShowTOPCountry, buffer, Krempel);
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public mycountry(client)
{
	new String:buffer[255];
	if(db == INVALID_HANDLE)
	{
		Format(buffer, sizeof(buffer), "*%T*", "database error", client);
		PrintToChat(client, buffer);
	}
	else
	{
		new String:cIP[20], String:Country[64], UserID = GetClientUserId(client);
		GetClientIP(client,cIP,sizeof(cIP),true);
		GeoipCountry(cIP, Country, sizeof(Country));
		Format(buffer, sizeof(buffer), "SELECT NAME,steamId FROM `%s` where country = '%s' ORDER BY POINTS DESC LIMIT 0,10", tableplayer, Country);
		new Handle:Krempel = CreateArray(ByteCountToCells(64));
		PushArrayCell(Krempel, UserID);
		PushArrayString(Krempel, Country);
		//if(debug_version == 1){LogToFile(Logfile, "Line 3009: %s",buffer);}
		SQL_TQuery(db, T_ShowTOPCountry, buffer, Krempel);
	}
}

public T_ShowTOPCountry(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new UserID = GetArrayCell(data,0), String:sInfo[64], String:sBuffer[96], String:buffer[255];
	GetArrayString(data, 1, sInfo, 64);
	CloseHandle(data);
	if(strlen(sInfo)!=0)
		Format(sBuffer, sizeof(sBuffer), "Top %s", sInfo);
	else
		Format(sBuffer, sizeof(sBuffer), "Top unknown countries", sInfo);
	
	new client;
	
	if ((client = GetClientOfUserId(UserID)) == 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		Format(buffer, sizeof(buffer), "*%T*", "sql error", client);
		PrintToChat(client, buffer);
	}
	else
	{
		new i  = 0;
		new Handle:rnktoppanel = CreatePanel();
		SetPanelTitle(rnktoppanel, sBuffer);
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, ranknametop[i] , 32);
			SQL_FetchString(hndl,1, ranksteamidtop[i] , 32);
			DrawPanelItem(rnktoppanel, ranknametop[i]);
			i++;
		}
		if (GetConVarInt(CV_webrank) == 1)
		{
			new String:value[255];
			Format(value, sizeof(value), "%T", "webranknotice", client);
			DrawPanelText(rnktoppanel, value);
		}
		SendPanelToClient(rnktoppanel, client, TopPanelHandler, GetConVarInt(CV_toppaneltime));
		CloseHandle(rnktoppanel);
	}
	return;
}
public top10gg(client)
{
	new String:buffer[255];
	if(db == INVALID_HANDLE)
	{
		Format(buffer, sizeof(buffer), "*%T*", "database error", client);
		PrintToChat(client, buffer);
	}
	else
	{
		Format(buffer, sizeof(buffer), "SELECT NAME,steamId,gungamewins FROM `%s` ORDER BY gungamewins DESC LIMIT 0,10", tableplayer);
		//if(debug_version == 1){LogToFile(Logfile, "Line 3070: %s",buffer);}
		new Handle:Krempel = CreateArray();
		PushArrayCell(Krempel,GetClientUserId(client));
		PushArrayCell(Krempel,1);
		SQL_TQuery(db, T_ShowTOP1, buffer, Krempel);
	}
}

public top10pnl(client)
{
	new String:buffer[255];
	if(db == INVALID_HANDLE)
	{
		Format(buffer, sizeof(buffer), "*%T*", "database error", client);
		PrintToChat(client, buffer);
	}
	else
	{
		Format(buffer, sizeof(buffer), "SELECT NAME,steamId,POINTS FROM `%s` ORDER BY POINTS DESC LIMIT 0,10", tableplayer);
		//if(debug_version == 1){LogToFile(Logfile, "Line 3070: %s",buffer);}
		new Handle:Krempel = CreateArray();
		PushArrayCell(Krempel,GetClientUserId(client));
		PushArrayCell(Krempel,0);
		SQL_TQuery(db, T_ShowTOP1, buffer, Krempel);
	}
}

public TopMapsHandler(Handle:menu, MenuAction:action, param1, param2)
{
	/* If an option was selected, tell the client about the item. */
	if (action == MenuAction_Select)
	{
		new String:info[255];
		new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		if(found)
		{
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "SELECT * FROM `%s` WHERE NAME LIKE '%s'", tablemap, info);
			SQL_TQuery(db, T_ShowSingleMap, buffer, GetClientUserId(param1));
		}
	}
	/* If the menu was cancelled, print a message to the server about it. */
	else if (action == MenuAction_Cancel)
	{
		//PrintToServer("Client %d's menu was cancelled.  Reason: %d", param1, param2);
	}
	/* If the menu has ended, destroy it */
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public currentmap(client)
{
	new String:buffer[255];
	if(db == INVALID_HANDLE)
	{
		Format(buffer, sizeof(buffer), "[%s]*%T*", CHATTAG, "database error", client);
		PrintToChat(client, buffer);
	}
	else
	{
		new String:Map[255];
		GetCurrentMap(Map, sizeof(Map));
		Format(buffer, sizeof(buffer), "SELECT * FROM `%s` WHERE NAME LIKE '%s'", tablemap, Map);
		SQL_TQuery(db, T_ShowSingleMap, buffer, GetClientUserId(client));
	}
}
public topmap(client)
{
	new String:buffer[255];
	if(db == INVALID_HANDLE)
	{
		Format(buffer, sizeof(buffer), "*%T*", "database error", client);
		PrintToChat(client, buffer);
	}
	else
	{
		Format(buffer, sizeof(buffer), "SELECT NAME,PLAYTIME FROM `%s` ORDER BY PLAYTIME DESC LIMIT 0,20", tablemap);
		SQL_TQuery(db, T_ShowTOPMap, buffer, GetClientUserId(client));
	}
}
public TopSingleMapHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
}
public T_ShowSingleMap(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client, String:Buffer[255];
	
	/* Make sure the client didn't disconnect while the thread was running */
	if ((client = GetClientOfUserId(data)) == 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		Format(Buffer, sizeof(Buffer), "*%T*", "sql error", client);
		PrintToChat(client, Buffer);
	}
	else
	{
		new pval, Minutes, Float:Hours, String:TimeString[255];
		new Handle:menu = CreateMenu(TopSingleMapHandler);
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, Buffer, sizeof(Buffer));
			SetMenuTitle(menu, "%s:", Buffer);
			Minutes = SQL_FetchInt(hndl,1);
			if(Minutes > 60)
			{
				Hours = (float(Minutes) / 60.0);
				FloatToCutString(Hours, TimeString, sizeof(TimeString), 1);
				Format(Buffer, sizeof(Buffer), "%T - %s %T", "dontgiveadamn", client, TimeString, "Hours", client);
			}
			else
			{
				IntToString(Minutes, TimeString, sizeof(TimeString));
				Format(Buffer, sizeof(Buffer), "%T - %s %T", "dontgiveadamn", client, TimeString, "Minutes", client);
			}
			AddMenuItem(menu, " ", Buffer);
			pval = SQL_FetchInt(hndl, 2);
			FormatTime(TimeString, sizeof(TimeString), "%c", pval);
			Format(Buffer, sizeof(Buffer), "%T - %s", "last played", client, TimeString);
			AddMenuItem(menu, " ", Buffer,ITEMDRAW_DISABLED);
			pval = SQL_FetchInt(hndl, 3);
			Format(Buffer, sizeof(Buffer), "CT %T %i", "wins", client, pval);
			AddMenuItem(menu, " ", Buffer,ITEMDRAW_DISABLED);
			pval = SQL_FetchInt(hndl, 4);
			Format(Buffer, sizeof(Buffer), "T %T %i", "wins", client, pval);
			AddMenuItem(menu, " ", Buffer,ITEMDRAW_DISABLED);
		}
		if (GetConVarInt(CV_webrank) == 1)
		{
			new String:value[255];
			Format(value, sizeof(value), "%T", "webranknotice", client);
			AddMenuItem(menu, " ",value,ITEMDRAW_DISABLED);
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, GetConVarInt(CV_toppaneltime));
	}
	return;
}

public T_ShowTOPMap(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client, String:Buffer[255];
	
	if ((client = GetClientOfUserId(data)) == 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		Format(Buffer, sizeof(Buffer), "*%T*", "sql error", client);
		PrintToChat(client, Buffer);
	}
	else
	{
		new String:Buffer2[255], String:TimeString[255], Minutes, Float:Hours;
		new Handle:menu = CreateMenu(TopMapsHandler);
		Format(Buffer, sizeof(Buffer), "%T", "topmap", client);
		SetMenuTitle(menu, Buffer);
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, Buffer, sizeof(Buffer));
			Minutes = SQL_FetchInt(hndl,1);
			if(Minutes > 60)
			{
				Hours = (float(Minutes) / 60.0);
				FloatToCutString(Hours, TimeString, sizeof(TimeString), 1);
				Format(Buffer2, sizeof(Buffer2), "%s - %s %T", Buffer, TimeString, "Hours", client);
			}
			else
			{
				IntToString(Minutes, TimeString, sizeof(TimeString));
				Format(Buffer2, sizeof(Buffer2), "%s - %s %T", Buffer, TimeString, "Minutes", client);
			}
			AddMenuItem(menu, Buffer, Buffer2);
		}
		if (GetConVarInt(CV_webrank) == 1)
		{
			new String:value[255];
			Format(value, sizeof(value), "%T", "webranknotice", client);
			AddMenuItem(menu, " ",value,ITEMDRAW_DISABLED);
		}
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, GetConVarInt(CV_toppaneltime));
	}
	return;
}
public T_ShowTOP1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new UserID = GetArrayCell(data, 0), String:Buffer[255];
	new mode = GetArrayCell(data, 1);
	CloseHandle(data);
	new client;
	
	if ((client = GetClientOfUserId(UserID)) == 0)
		return;
 
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(Logfile, "Query failed! %s", error);
		Format(Buffer, sizeof(Buffer), "*%T*", "sql error", client);
		PrintToChat(client, Buffer);
	}
	else
	{
		new i  = 0, pval;
		new Handle:rnktoppanel = CreatePanel();
		if(mode == 0)
			Format(Buffer, sizeof(Buffer), "%T", "top_top10", client);
		else
			Format(Buffer, sizeof(Buffer), "%T", "ggtop", client);
		SetPanelTitle(rnktoppanel, Buffer);
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl,0, ranknametop[i] , 32);
			SQL_FetchString(hndl,1, ranksteamidtop[i] , 32);
			pval = SQL_FetchInt(hndl,2);
			Format(Buffer, sizeof(Buffer), "%s - %i", ranknametop[i],pval);
			DrawPanelItem(rnktoppanel, Buffer);
			i++;
		}
		if (GetConVarInt(CV_webrank) == 1)
		{
			new String:value[255];
			Format(value, sizeof(value), "%T", "webranknotice", client);
			DrawPanelText(rnktoppanel, value);
		}
		SendPanelToClient(rnktoppanel, client, TopPanelHandler, GetConVarInt(CV_toppaneltime));
		CloseHandle(rnktoppanel);
	}
	return;
}

public TopPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
		rankpanel(param1, ranksteamidtop[param2-1]);
}

createdbtables()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tabledata);
	len += Format(query[len], sizeof(query)-len, "(`name` TEXT, `datatxt` TEXT, `dataint` INTEGER);");
	//if(debug_version == 1){LogToFile(Logfile, "Line 3124: %s",query);}
	SQL_TQuery(db, T_CheckDBUptodate1, query);
}

public T_CheckDBUptodate1(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		new String:buffer[255];
		Format(buffer, sizeof(buffer), "SELECT dataint FROM `%s` where `name` = 'dbversion'", tabledata);
		//if(debug_version == 1){LogToFile(Logfile, "Line 3136: %s",buffer);}
		SQL_TQuery(db, T_CheckDBUptodate2, buffer);
	}
}

public T_CheckDBUptodate2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	//if(debug_version == 1){LogToFile(Logfile, "T_CheckDBUptodate2");}
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		if (!SQL_GetRowCount(hndl))
		{
			createdb();
			new String:buffer[255];
			Format(buffer, sizeof(buffer), "INSERT INTO %s (`name`,`dataint`) VALUES ('dbversion',%i)", tabledata, DBVERSION);
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_033: %s",buffer);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
		}
		else
		{
			new tmpdbversion;
			while (SQL_FetchRow(hndl))
			{
				tmpdbversion = SQL_FetchInt(hndl,0);
			}
			if (tmpdbversion <= 1)
			{
				if (sqllite == 1)
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table %s add KW_awp INTEGER;", tableplayer);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_034: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add KW_sg550 INTEGER;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_035: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 2 where `name` = 'dbversion'", tabledata);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_036: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table %s add KW_awp int(11);", tableplayer);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_037: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add KW_sg550 int(11);", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_038: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 2 where `name` = 'dbversion';", tabledata);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_039: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
			}
			if (tmpdbversion <= 2)
			{
				if (sqllite == 1)
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table %s add KW_g3sg1 INTEGER;", tableplayer);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_040: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 3 where `name` = 'dbversion'", tabledata);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_041: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER table %s add KW_g3sg1 int(11);", tableplayer);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_042: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 3 where `name` = 'dbversion';", tabledata);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_043: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
			}
			if (tmpdbversion <= 3)
			{
				if (sqllite == 1)
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 4 where `name` = 'dbversion'", tabledata);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_044: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER TABLE %s DROP PRIMARY KEY;", tableplayer);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_045: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER TABLE %s ADD PRIMARY KEY (`STEAMID`);", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_046: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 4 where `name` = 'dbversion';", tabledata);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_047: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
			}
			if (tmpdbversion <= 4)
			{
				if (sqllite == 1)
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 5 where `name` = 'dbversion'", tabledata);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_048: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "ALTER TABLE %s MODIFY `NAME` varchar(255) NOT NULL;", tableplayer);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_049: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 5 where `name` = 'dbversion';", tabledata);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_050: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
			}
			if (tmpdbversion <= 5)
			{
				if (sqllite == 1)
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 6 where `name` = 'dbversion'", tabledata);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_051: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add teamkills INTEGER;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_052: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add gungamewins INTEGER;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_053: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add suicides INTEGER;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_054: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add LASTDEDUCT INTEGER;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_055: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					createACCtable();
				}
				else
				{
					new String:buffer[255];
					Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 6 where `name` = 'dbversion';", tabledata);
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_056: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add teamkills int(11) NOT NULL DEFAULT 0;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_057: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add gungamewins int(11) NOT NULL DEFAULT 0;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_058: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add suicides int(11) NOT NULL DEFAULT 0;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_059: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add LASTDEDUCT int(11) NOT NULL DEFAULT 0;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_060: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s MODIFY `KW_awp` int(11) NOT NULL DEFAULT 0;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_061: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s MODIFY `KW_sg550` int(11) NOT NULL DEFAULT 0;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_062: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s MODIFY `KW_g3sg1` int(11) NOT NULL DEFAULT 0;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_063: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER TABLE %s ADD PRIMARY KEY (`dataint`);", tabledata);
					//This is a fix for a bug in MySQL Query Browser, where it won't let you edit fields when no primary key is set for a table
					//You cannot set column 'name' as primary key, because its length is variable
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_064: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					createACCtable();
				}
			}
			if (tmpdbversion <= 6)
			{
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 7 where `name` = 'dbversion'", tabledata);
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_065: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				if (sqllite == 1)
				{
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_head INTEGER;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_066: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_chest INTEGER;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_067: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_stomach INTEGER;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_068: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_leftarm INTEGER;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_069: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_rightarm INTEGER;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_070: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_leftleg INTEGER;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_071: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_rightleg INTEGER;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_072: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
				else
				{
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_head int(11) NOT NULL DEFAULT 0;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_073: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_chest int(11) NOT NULL DEFAULT 0;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_074: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_stomach int(11) NOT NULL DEFAULT 0;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_075: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_leftarm int(11) NOT NULL DEFAULT 0;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_076: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_rightarm int(11) NOT NULL DEFAULT 0;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_077: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_leftleg int(11) NOT NULL DEFAULT 0;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_078: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add hitbox_rightleg int(11) NOT NULL DEFAULT 0;", tableaccuracy);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_079: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add wins_ct int(11) NOT NULL DEFAULT 0;", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_080: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "ALTER table %s add wins_t int(11) NOT NULL DEFAULT 0;", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_081: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
			}
			if (tmpdbversion <= 7)
			{
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 8 where `name` = 'dbversion'", tabledata);
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_082: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				createdbcountrylist();
				if (sqllite == 1)
				{
					Format(buffer, sizeof(buffer), "ALTER table %s add country TEXT;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_083: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					createdbmapsqllite();
				}
				else
				{
					Format(buffer, sizeof(buffer), "ALTER table %s add country varchar(64) NOT NULL;", tableplayer);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_084: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					//it seems dropping multiple columns in ONE query is impossible
					Format(buffer, sizeof(buffer), "Alter Table %s drop column POINTS", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_085: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KILLS", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_086: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column Death", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_087: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column HeadshotKill", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_088: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_m4a1", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_089: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_ak47", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_090: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_scout", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_091: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_hegrenade", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_092: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_deagle", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_093: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_knife", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_094: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_sg552", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_095: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_p90", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_096: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_aug", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_097: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_usp", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_098: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_famas", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_099: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_mp5navy", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_100: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_galil", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_101: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_m249", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_102: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_m3", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_103: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_glock", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_104: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_p228", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_105: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_elite", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_106: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_xm1014", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_107: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_fiveseven", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_108: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_tmp", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_109: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_ump45", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_110: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column KW_mac10", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_111: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column bomb_planted", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_112: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column bomb_defused", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_113: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column bomb_exploded", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_114: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column hostage_follows", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_115: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column hostage_killed", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_116: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
					Format(buffer, sizeof(buffer), "Alter Table %s drop column hostage_rescued", tablemap);
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_117: %s",buffer);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				}
			}
			if (tmpdbversion <= 8)
			{
				new String:buffer[255];
				Format(buffer, sizeof(buffer), "UPDATE %s SET dataint = 9 where `name` = 'dbversion'", tabledata);
				new Handle:dataPackHandle = INVALID_HANDLE;
				if(debug_version == 1)
				{
					//********DEBUG QUERY STRING PUSH************
					dataPackHandle = CreateDataPack();
					new String:DEBUGSTRING[2048];
					Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_118: %s",buffer);
					WritePackString(dataPackHandle, DEBUGSTRING);
				}
				SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
				if (sqllite != 1)
				{
					createdbheat();
				}
			}
		}
		initonlineplayers();
	}
}

bool:CheckFlush(client)
{
	if(client < 1 || !IsClientInGame(client) || ME_Enable == 0 || rankingactive == false)
		return false;
	if(IsFakeClient(client))
		return false;
	
	new String:sID[64];
	GetClientAuthString(client, sID, sizeof(sID));
	if(!StrEqual(sID, weapon_ID[client], false))
		return false;
	
	new bool:FlushApproved = false;
	for (new j = 0; j < WEAPON_COUNT; j++)
	{
		if(weapon_stats[client][j][0] > 0)
		{
			FlushApproved = true;
			break;
		}
	}
	return FlushApproved;
}

ClientAccToSession(client)
{
	if(client < 1 || !IsClientInGame(client))
		return;

	new String:sID[64];
	GetClientAuthString(client, sID, sizeof(sID));
	if(!StrEqual(sID, weapon_ID[client], false))
		return;
	for (new j = 0; j < WEAPON_COUNT; j++)
	{
		session_stats[client][j][0] += weapon_stats[client][j][0];
		session_stats[client][j][1] += weapon_stats[client][j][1];
	}
}

ClientAccToDB(client, purpose)
{
	ClientAccToSession(client);
	//purpose changes the callback, the query jumps into.
	//0 = generic, 1 = client called the ranking panel
	if(!CheckFlush(client))
		return;
	new String:sID[64];
	GetClientAuthString(client, sID, sizeof(sID));

	new len = 0, String:varS[64];
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "UPDATE %s SET", tableaccuracy);
	
	for (new j = 0; j < WEAPON_COUNT; j++)
	{
		if(weapon_stats[client][j][0] > 0)
			len += Format(query[len], sizeof(query)-len, " %s = %s + %i,", weaponlist[j], weaponlist[j], weapon_stats[client][j][0]);
		if(weapon_stats[client][j][1] > 0)
		{
			Format(varS, sizeof(varS), "%s_hit", weaponlist[j]);
			len += Format(query[len], sizeof(query)-len, " %s = %s + %i,", varS, varS, weapon_stats[client][j][1]);
		}
	}
	len += Format(query[len], sizeof(query)-len, " hitbox_head = hitbox_head + %i,", hitbox_stats[client][1]);
	len += Format(query[len], sizeof(query)-len, " hitbox_chest = hitbox_chest + %i,", hitbox_stats[client][2]);
	len += Format(query[len], sizeof(query)-len, " hitbox_stomach = hitbox_stomach + %i,", hitbox_stats[client][3]);
	len += Format(query[len], sizeof(query)-len, " hitbox_leftarm = hitbox_leftarm + %i,", hitbox_stats[client][4]);
	len += Format(query[len], sizeof(query)-len, " hitbox_rightarm = hitbox_rightarm + %i,", hitbox_stats[client][5]);
	len += Format(query[len], sizeof(query)-len, " hitbox_leftleg = hitbox_leftleg + %i,", hitbox_stats[client][6]);
	len += Format(query[len], sizeof(query)-len, " hitbox_rightleg = hitbox_rightleg + %i", hitbox_stats[client][7]);
	len += Format(query[len], sizeof(query)-len, " WHERE STEAMID = '%s'", sID);
	if(purpose == 0)
	{
		//if(debug_version == 1){LogToFile(Logfile, "Line 3469: %s",query);}
					new Handle:dataPackHandle = INVALID_HANDLE;
					if(debug_version == 1)
					{
						//********DEBUG QUERY STRING PUSH************
						dataPackHandle = CreateDataPack();
						new String:DEBUGSTRING[2048];
						Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_119: %s",query);
						WritePackString(dataPackHandle, DEBUGSTRING);
					}
					SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	}
	else if(purpose == 1)
	{
		new conuserid = GetClientUserId(client);
		//if(debug_version == 1){LogToFile(Logfile, "Line 3469: %s",query);}
		SQL_TQuery(db, t_accpanel, query, conuserid);
	}
}
AccToDB()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		ClientAccToDB(i,0);
	}
}
public OnClientDisconnect(client)
{
	ClientAccToDB(client,0);
}
public OnClientDisconnect_Post(client)
{
	EnoughClientsForRanking();
}

public Event_bomb_defused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (blockranking() || (ME_Enable == 0))
		return;
	
	new userid = GetEventInt(event, "userid");
	new usercl = GetClientOfUserId(userid);
	
	if (IsClientInGame(usercl))
	{
		new pointvalue = GetConVarInt(CV_bomb_defused);
		sessionpoints[usercl] = sessionpoints[usercl] + pointvalue;
		if(!rankingactive || IsFakeClient(usercl))
			return;

		new String:userclname[MAX_LINE_WIDTH];
		GetClientName(usercl,userclname, sizeof(userclname));
		decl String:query[512];
		new String:steamIduser[MAX_LINE_WIDTH];
		GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, bomb_defused = bomb_defused + 1 WHERE steamId = '%s'", tableplayer,pointvalue ,steamIduser);
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_120: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		new pointmsgval = GetConVarInt(CV_pointmsg);
		if (pointmsgval >= 1)
		{
			if (pointmsgval == 1)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t %t",CHATTAG,userclname, "got", pointvalue, "points for", "defusing", "bomb");
			}
			else
			{
				PrintToChat(usercl,"\x04[\x03%s\x04]\x01 %t %i %t %t %t",CHATTAG, "you got", pointvalue, "points for", "defusing", "bomb");
			}
		}
	}
}

public Event_bomb_exploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (blockranking() || (ME_Enable == 0))
		return;
	
	new userid = GetEventInt(event, "userid");
	new usercl = GetClientOfUserId(userid);
	if(usercl == 0)
		return;
	if (IsClientInGame(usercl))
	{
		new pointvalue = GetConVarInt(CV_bomb_exploded);
		sessionpoints[usercl] = sessionpoints[usercl] + pointvalue;
		if(!rankingactive || IsFakeClient(usercl))
			return;

		new String:userclname[MAX_LINE_WIDTH];
		GetClientName(usercl,userclname, sizeof(userclname));
		decl String:query[512];
		new String:steamIduser[MAX_LINE_WIDTH];
		GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, bomb_exploded = bomb_exploded + 1 WHERE steamId = '%s'", tableplayer,pointvalue ,steamIduser);
		//if(debug_version == 1){LogToFile(Logfile, "ollowing query formatted on Line 4193: %s",query);}
		//if(debug_version == 1){LogToFile(Logfile, "Line 3574: %s",query);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_121: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		new pointmsgval = GetConVarInt(CV_pointmsg);
		if (pointmsgval >= 1)
		{
			if (pointmsgval == 1)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t %t",CHATTAG,userclname, "got", pointvalue, "points for", "planting", "exploded bomb");
			}
			else
			{
				PrintToChat(usercl,"\x04[\x03%s\x04]\x01 %t %i %t %t %t",CHATTAG, "you got", pointvalue, "points for", "planting", "exploded bomb");
			}
		}
	}
}

public Event_bomb_planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (blockranking() || (ME_Enable == 0))
		return;
	
	new userid = GetEventInt(event, "userid");
	new usercl = GetClientOfUserId(userid);
	if (IsClientInGame(usercl))
	{
		new pointvalue = GetConVarInt(CV_bomb_planted);
		sessionpoints[usercl] = sessionpoints[usercl] + pointvalue;
		if(!rankingactive || IsFakeClient(usercl))
			return;

		new String:userclname[MAX_LINE_WIDTH];
		GetClientName(usercl,userclname, sizeof(userclname));
		decl String:query[512];
		new String:steamIduser[MAX_LINE_WIDTH];
		GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, bomb_planted = bomb_planted + 1 WHERE steamId = '%s'", tableplayer,pointvalue ,steamIduser);
		//if(debug_version == 1){LogToFile(Logfile, "ollowing query formatted on Line 4231: %s",query);}
		//if(debug_version == 1){LogToFile(Logfile, "Line 3611: %s",query);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_122: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		new pointmsgval = GetConVarInt(CV_pointmsg);
		if (pointmsgval >= 1)
		{
			if (pointmsgval == 1)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t %t",CHATTAG,userclname, "got", pointvalue, "points for", "planting", "bomb");
			}
			else
			{
				PrintToChat(usercl,"\x04[\x03%s\x04]\x01 %t %i %t %t %t",CHATTAG, "you got", pointvalue, "points for", "planting", "bomb");
			}
		}
	}
}

public Event_hostage_follows(Handle:event, const String:name[], bool:dontBroadcast)
{

	if (blockranking() || (ME_Enable == 0))
		return;
	
	new hostageID = GetEventInt(event, "hostage");
	new userid = GetEventInt(event, "userid");
	new usercl = GetClientOfUserId(userid);
	
	for (new j=0; j<16; j++)
	{
		if(HostageCanGetPoints[usercl][j] == hostageID)
			return;
	}
	for (new i=0; i<16; i++)
	{
		if(HostageCanGetPoints[usercl][i] == -1)
		{
			HostageCanGetPoints[usercl][i] = hostageID;
			break;
		}
	}

	
	if (IsClientInGame(usercl))
	{
		new pointvalue = GetConVarInt(CV_hostage_follows);
		sessionpoints[usercl] = sessionpoints[usercl] + pointvalue;
		if(!rankingactive || IsFakeClient(usercl))
			return;

		new String:userclname[MAX_LINE_WIDTH];
		GetClientName(usercl,userclname, sizeof(userclname));
		decl String:query[512];
		new String:steamIduser[MAX_LINE_WIDTH];
		GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, hostage_follows = hostage_follows + 1 WHERE steamId = '%s'", tableplayer,pointvalue ,steamIduser);
		//if(debug_version == 1){LogToFile(Logfile, "ollowing query formatted on Line 4287: %s",query);}
		//if(debug_version == 1){LogToFile(Logfile, "Line 3666: %s",query);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_123: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		new pointmsgval = GetConVarInt(CV_pointmsg);
		if (pointmsgval >= 1)
		{
			if (pointmsgval == 1)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t",CHATTAG,userclname, "got", pointvalue, "points for", "hostage follows");
			}
			else
			{
				PrintToChat(usercl,"\x04[\x03%s\x04]\x01 %t %i %t %t",CHATTAG, "you got", pointvalue, "points for", "hostage follows");
			}
		}
	}
}

public Event_hostage_killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (blockranking() || (ME_Enable == 0))
		return;
	
	new userid = GetEventInt(event, "userid");
	new usercl = GetClientOfUserId(userid);
	if (IsClientInGame(usercl))
	{
		new teamID = GetClientTeam(usercl), pointvalue;
		if (teamID == 3)
			pointvalue = GetConVarInt(CV_hostage_killed_CT);
		else
			pointvalue = GetConVarInt(CV_hostage_killed_T);
		
		sessionpoints[usercl] -= pointvalue;
		if(!rankingactive || IsFakeClient(usercl))
			return;
		
		new String:userclname[MAX_LINE_WIDTH];
		GetClientName(usercl,userclname, sizeof(userclname));
		new String:steamIduser[MAX_LINE_WIDTH];
		GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
		
		decl String:query[512];
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS - %i, hostage_killed = hostage_killed + 1 WHERE steamId = '%s'", tableplayer,pointvalue,steamIduser);
		//if(debug_version == 1){LogToFile(Logfile, "ollowing query formatted on Line 4333: %s",query);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_124: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		
		new pointmsgval = GetConVarInt(CV_pointmsg);
		if (pointmsgval >= 1)
		{
			if (pointmsgval == 1)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t",CHATTAG,userclname, "lost", pointvalue, "points for", "hostage killed");
			}
			else
			{
				PrintToChat(usercl,"\x04[\x03%s\x04]\x01 %t %i %t %t",CHATTAG, "you lost", pointvalue, "points for", "hostage killed");
			}
		}
	}
}

public Event_hostage_rescued(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (blockranking() || (ME_Enable == 0))
		return;
	
	new userid = GetEventInt(event, "userid");
	new usercl = GetClientOfUserId(userid);
	if (usercl == 0)
	{
		//LogToFile(Logfile, "[DEBUG MESSAGE:]CliendID was 0 on UserID %i after firing 'event_hostage_rescued'", userid);
		//WHY??? A hostage cannot run to the safe zone on its own! If the leading CT quits, the hostage stops moving!
		//(addendum: propably because the hostage still walks a few steps before stopping)
		return;
	}
	if (IsClientInGame(usercl))
	{
		new pointvalue = GetConVarInt(CV_hostage_rescued);
		sessionpoints[usercl] = sessionpoints[usercl] + pointvalue;
		if(!rankingactive || IsFakeClient(usercl))
			return;
		new String:userclname[MAX_LINE_WIDTH];
		GetClientName(usercl,userclname, sizeof(userclname));
		decl String:query[512];
		new String:steamIduser[MAX_LINE_WIDTH];
		GetClientAuthString(usercl, steamIduser, sizeof(steamIduser));
		Format(query, sizeof(query), "UPDATE %s SET POINTS = POINTS + %i, hostage_rescued = hostage_rescued + 1 WHERE steamId = '%s'", tableplayer,pointvalue ,steamIduser);
		//if(debug_version == 1){LogToFile(Logfile, "ollowing query formatted on Line 4385: %s",query);}
		//if(debug_version == 1){LogToFile(Logfile, "Line 3744: %s",query);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_126: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		new pointmsgval = GetConVarInt(CV_pointmsg);
		if (pointmsgval >= 1)
		{
			if (pointmsgval == 1)
			{
				PrintToChatAll("\x04[\x03%s\x04]\x01 %s %t %i %t %t",CHATTAG,userclname, "got", pointvalue, "points for", "hostage rescued");
			}
			else
			{
				PrintToChat(usercl,"\x04[\x03%s\x04]\x01 %t %i %t %t",CHATTAG, "you got", pointvalue, "points for", "hostage rescued");
			}
		}
	}
}

public convarcreating()
{
	CreateConVar("dignatio_version", PLUGIN_VERSION, "dignatio (n1g-css-stats)version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CV_enable = CreateConVar("rank_enable", "1", "General On/Off toggle");
	CV_tableprefix = CreateConVar("rank_dbtable_prefix", "", "Prefix for the four ranking tables in the database");
	CV_diepoints = CreateConVar("rank_diepoints","-1","Set the points a player lose on Death. If -1, the player will lose the same amount of points that the attacker gets.");
	CV_removeoldplayers = CreateConVar("rank_removeoldplayers","1","Enable Automatic Removing Player who doesn't conect a specific time on every Roundend");
	CV_removeoldplayersdays = CreateConVar("rank_removeoldplayersdays","14","The time in days after a player get removed if he doesn't connect min 1 day");
	CV_removevoyeurhours = CreateConVar("rank_removevoyeurhours","2","Same like rank_removeoldplayersdays in hours, but for players with 0 kills & 0 deaths & 0 points");
	CV_removeoldmaps = CreateConVar("rank_removeoldmaps","1","Enable Automatic Removing Maps who wasn't played a specific time on every Roundend");
	CV_removeoldmapssdays = CreateConVar("rank_removeoldmapsdays","14","The time in days after a map get removed, min 1 day");
	CV_showrankonconnect = CreateConVar("rank_show","2","Show on connect, 0=disabled, 1=clientchat, 2=allchat, 3=panel, 4=panel + all chat");
	CV_bottopmessage = CreateConVar("rank_bottop_show","0","Show bottop on round start - 0=disabled, 1=chat, 2=panel");
	
	CV_webrank = CreateConVar("rank_webrank","0","Enable/Disable Webrank");
	CV_webrankurl = CreateConVar("rank_webrankurl","","URL to root folder of webpanel. Trailing slash needed!", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CV_neededplayercount = CreateConVar("rank_neededplayers","0","How many clients are needed to start ranking");
	CV_showrankonroundend = CreateConVar("rank_showrankonroundend","0","Shows Top 10 on Roundend");
	CV_disableafterroundwin = CreateConVar("rank_disableafterroundwin","1","disable ranking between rounds");

	CV_suicidepoints = CreateConVar("rank_suicide_malus", "1", "How many points a player gets taken on suicide (nade selfkill)");
	CV_worldkillpoints = CreateConVar("rank_suicide_world_malus", "1", "How many points to take from player on suicide by world entity kill (falling off ledges, kill console command, crushed by a door etc.)");
	CV_teamkillpoints = CreateConVar("rank_teamkill_malus", "5", "How many points a player gets taken for a teamkill");
	
	CV_botteamkillpoints = CreateConVar("rank_botteamkill_malus", "0", "How many points a player gets taken for teamkilling a bot");
	CV_botteamkillrecord = CreateConVar("rank_botteamkill_record", "0", "If 0, doesn't record the teamkill to the DB, if victim was a bot");
	
	CV_teamwinpoints = CreateConVar("rank_team_bonus", "0", "All players of a team get this much points for winning a round");
	CV_teamlosepoints = CreateConVar("rank_team_malus", "0", "All players of a team lose this much points for losing a round");

	CV_announcements = CreateConVar("rank_announcements_inverval", "120.0", "Status announcement of the ranking each X seconds. Set < 30 to turn off");
	CV_chatannounce = CreateConVar("rank_chatannounce", "1", "Print to Chat when ranking is enabled/disabled");
	
	CV_conrankpaneltime = CreateConVar("rank_time_conpanel","20","autoclose rank panel on connection after x seconds");
	CV_infopaneltime = CreateConVar("rank_time_infopanel","20","autoclose info panel after x seconds");
	CV_toppaneltime = CreateConVar("rank_time_toppanel","20","autoclose top10 panel after x seconds");
	CV_sessionrankpaneltime = CreateConVar("rank_time_sessionpanel","20","autoclose session rank panel on connection after x seconds");
	CV_deductpoints = CreateConVar("rank_timebase","5","if > 0, deduct this amount of points from a player per day");
	CV_m4a1 = CreateConVar("rank_kill_m4a1","3","Set the points the attacker get");
	CV_ak47 = CreateConVar("rank_kill_ak47","3","Set the points the attacker get");
	CV_scout = CreateConVar("rank_kill_scout","3","Set the points the attacker get");
	CV_hegrenade = CreateConVar("rank_kill_hegrenade","3","Set the points the attacker get");
	CV_deagle = CreateConVar("rank_kill_deagle","3","Set the points the attacker get");
	CV_knife = CreateConVar("rank_kill_knife","3","Set the points the attacker get");
	CV_sg552 = CreateConVar("rank_kill_sg552","3","Set the points the attacker get");
	CV_p90 = CreateConVar("rank_kill_p90","3","Set the points the attacker get");
	CV_aug = CreateConVar("rank_kill_aug","3","Set the points the attacker get");
	CV_usp = CreateConVar("rank_kill_usp","3","Set the points the attacker get");
	CV_famas = CreateConVar("rank_kill_famas","3","Set the points the attacker get");
	CV_mp5navy = CreateConVar("rank_kill_mp5navy","3","Set the points the attacker get");
	CV_galil = CreateConVar("rank_kill_galil","3","Set the points the attacker get");
	CV_m249 = CreateConVar("rank_kill_m249","3","Set the points the attacker get");
	CV_m3 = CreateConVar("rank_kill_m3","3","Set the points the attacker get");
	CV_glock = CreateConVar("rank_kill_glock","3","Set the points the attacker get");
	CV_p228 = CreateConVar("rank_kill_p228","3","Set the points the attacker get");
	CV_elite = CreateConVar("rank_kill_elite","3","Set the points the attacker get");
	CV_xm1014 = CreateConVar("rank_kill_xm1014","3","Set the points the attacker get");
	CV_fiveseven = CreateConVar("rank_kill_fiveseven","3","Set the points the attacker get");
	CV_tmp = CreateConVar("rank_kill_tmp","3","Set the points the attacker get");
	CV_ump45 = CreateConVar("rank_kill_ump45","3","Set the points the attacker get");
	CV_mac10 = CreateConVar("rank_kill_mac10","3","Set the points the attacker get");
	CV_sg550 = CreateConVar("rank_kill_sg550","3","Set the points the attacker get");
	CV_awp = CreateConVar("rank_kill_awp","3","Set the points the attacker get");
	CV_g3sg1 = CreateConVar("rank_kill_g3sg1","3","Set the points the attacker get");
	
	CV_chattag = CreateConVar("rank_chattag","RANK","Set the Chattag");
	CV_pointmsg = CreateConVar("rank_pointmsg","2","on point earned message 0 = disabled, 1 = all, 2 = only who earned");
	
	
	CV_bomb_planted = CreateConVar("rank_bomb_planted","3","Set the points");
	CV_bomb_defused = CreateConVar("rank_bomb_defused","5","Set the points");
	CV_bomb_exploded = CreateConVar("rank_bomb_exploded","3","Set the points");
	CV_hostage_follows = CreateConVar("rank_hostage_follows","1","Set the points");
	CV_hostage_rescued = CreateConVar("rank_hostage_rescued","3","Set the points");
	CV_hostage_killed_CT = CreateConVar("rank_hostage_killed_ct", "4", "Points to subtract from a CT for killing a hostage");
	CV_hostage_killed_T = CreateConVar("rank_hostage_killed_t", "2", "Points to subtract from a T for killing a hostage");
	CV_botpoints = CreateConVar("rank_bots_influence_rank","0","Bots can steal or bring you points");
	CV_botfactor = CreateConVar("rank_bots_point_factor","0.3333","Factor to multiply normal points with if bot was involved");
	
	CV_heatbots = CreateConVar("rank_heatmaps_record_bots","1","Show bot deaths on heatmaps");
	CV_recordheat = CreateConVar("rank_heatmaps_record","1","Heatmap logging enabled (mysql only)");
	CV_cleanheat_count = CreateConVar("rank_heatmaps_countlimit_per_map","10000","Keep a maximum of X entries per map (0 = unlimited)");
	CV_cleanheat_date = CreateConVar("rank_heatmaps_datelimit_per_map","30","Keep entries per map up to X days (0 = unlimited)");
	CV_noGG = CreateConVar("rank_nopanelGG", "1", "Do not show gungame stats in session panel");
	
	HookConVarChange(CV_recordheat, OnConVarChangeRecordHeat);
	HookConVarChange(CV_chattag,OnConVarChangechattag);
	HookConVarChange(CV_enable, OnConVarChangeEnable);
	HookConVarChange(CV_announcements,OnConVarChangeTimer);
	
	AutoExecConfig(true, "dignatio");
}
public OnConVarChangeRecordHeat(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new tOld = StringToInt(oldValue), tNew = StringToInt(newValue);
	if (tOld == tNew)
		return;
	Recordheat = (tNew == 1);
}
public OnConVarChangeTimer(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new Float:tOld = StringToFloat(oldValue), Float:tNew = StringToFloat(newValue);
	if (tOld == tNew)
		return;
	if(WerbeTimer != INVALID_HANDLE)
		CloseHandle(WerbeTimer);

	if (tNew > 29.9)
		WerbeTimer = CreateTimer(tNew, Werbeevent, INVALID_HANDLE,TIMER_REPEAT);
}

public OnConVarChangechattag(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GetConVarString(CV_chattag,CHATTAG, sizeof(CHATTAG));
}
public OnConVarChangeEnable(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new tOld = StringToInt(oldValue), tNew = StringToInt(newValue);
	if (tOld == tNew)
		return;
	
	if(tNew == 1)
		ResetAccAll();
	else
		AccToDB();

	ME_Enable = tNew;
	if(GetConVarInt(CV_chatannounce) == 0)
		return;
	if (ME_Enable == 1)
		PrintToChatAll("%t", "Ranking Enabled Menu");
	else
		PrintToChatAll("%t", "Ranking Disabled Menu");
}

createdb()
{
	createdbcountrylist();
	if (sqllite != 1)
	{
		createdbplayer();
		createdbmap();
		createdbheat();
	}
	else
	{
		createdbplayersqllite();
		createdbmapsqllite();
	}
}

createdbcountrylist()
{
	new len = 0;
	decl String:query[2048];
	if (sqllite != 1)
	{
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tablecountrylist);
		len += Format(query[len], sizeof(query)-len, " (`country` varchar(64) NOT NULL, PRIMARY KEY (`country`));");
	}
	else
	{
		len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tablecountrylist);
		len += Format(query[len], sizeof(query)-len, " (`country` TEXT);");
	}
	//if(debug_version == 1){LogToFile(Logfile, "Line 3903: %s",query);}
	SQL_TQuery(db, T_createdbcountrylist, query);
}
public T_createdbcountrylist(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
		LogToFile(Logfile, "Query failed! %s", error);
	else
	{
		new String:buffer[255];
		if (sqllite != 1)
			Format(buffer, sizeof(buffer), "INSERT IGNORE INTO %s (`country`) VALUES ('')", tablecountrylist);
		else
			Format(buffer, sizeof(buffer), "INSERT OR IGNORE INTO %s VALUES ('')", tablecountrylist);
		//if(debug_version == 1){LogToFile(Logfile, "Line 3923: %s",buffer);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_127: %s",buffer);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
	}
}
createdbplayer()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tableplayer);
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `NAME` varchar(255) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` int(25) NOT NULL DEFAULT 0,`PLAYTIME` int(25) NOT NULL DEFAULT 0, `LASTONTIME` int(25) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` int(11) NOT NULL DEFAULT 0 , `Death` int(11) NOT NULL DEFAULT 0 , `HeadshotKill` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `KW_m4a1` int(11) NOT NULL DEFAULT 0 , `KW_ak47` int(11) NOT NULL DEFAULT 0 , `KW_scout` int(11) NOT NULL DEFAULT 0 , `KW_hegrenade` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `KW_deagle` int(11) NOT NULL DEFAULT 0 , `KW_knife` int(11) NOT NULL DEFAULT 0 , `KW_sg552` int(11) NOT NULL DEFAULT 0 , `KW_p90` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `KW_aug` int(11) NOT NULL DEFAULT 0 , `KW_usp` int(11) NOT NULL DEFAULT 0 , `KW_famas` int(11) NOT NULL DEFAULT 0 , `KW_mp5navy` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `KW_galil` int(11) NOT NULL DEFAULT 0 , `KW_m249` int(11) NOT NULL DEFAULT 0 , `KW_m3` int(11) NOT NULL DEFAULT 0 , `KW_glock` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `KW_p228` int(11) NOT NULL DEFAULT 0 , `KW_elite` int(11) NOT NULL DEFAULT 0 , `KW_xm1014` int(11) NOT NULL DEFAULT 0 , `KW_fiveseven` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `KW_tmp` int(11) NOT NULL DEFAULT 0 , `KW_ump45` int(11) NOT NULL DEFAULT 0 , `KW_mac10` int(11) NOT NULL DEFAULT 0 , `bomb_planted` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `bomb_defused` int(11) NOT NULL DEFAULT 0 , `bomb_exploded` int(11) NOT NULL DEFAULT 0 , `hostage_follows` int(11) NOT NULL DEFAULT 0 , `hostage_killed` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `hostage_rescued` int(11) NOT NULL DEFAULT 0 , `KW_awp` int(11) NOT NULL DEFAULT 0 , `KW_sg550` int(11) NOT NULL DEFAULT 0 , `KW_g3sg1` int(11) NOT NULL DEFAULT 0 ,");
	len += Format(query[len], sizeof(query)-len, " `teamkills` int(11) NOT NULL DEFAULT 0 , `gungamewins` int(11) NOT NULL DEFAULT 0 , `suicides` int(11) NOT NULL DEFAULT 0 , `LASTDEDUCT` int(11) NOT NULL DEFAULT 0 , `country` varchar(64) NOT NULL, PRIMARY KEY (`STEAMID`));");
	//if(debug_version == 1){LogToFile(Logfile, "Line 3945: %s",query);}
	SQL_TQuery(db, createAtable, query);
}
createdbheat()
{
	new String:MapName[65];
	GetCurrentMap(MapName, sizeof(MapName));
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tableheat);
	len += Format(query[len], sizeof(query)-len, "(`TIMESTAMP` int(11), `mapname` varchar(64) NOT NULL DEFAULT '%s', `x` int(11) NOT NULL DEFAULT 0", MapName);
	len += Format(query[len], sizeof(query)-len, ", `y` int(11) NOT NULL DEFAULT 0);");
	/*we could make timestamp a primary key but two deaths could occur at the same timestamp and you cannot have two identical entries
	on a key field*/
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_128: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}

SetHeatmapDefaultNameOnDB()
{
	new String:MapName[65];
	GetCurrentMap(MapName, sizeof(MapName));
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "ALTER TABLE `%s` ", tableheat);
	len += Format(query[len], sizeof(query)-len, "MODIFY COLUMN `mapname` VARCHAR(64) ");
	len += Format(query[len], sizeof(query)-len, "NOT NULL DEFAULT '%s';", MapName);
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_129: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}

createdbplayersqllite()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tableplayer);
	len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `NAME` TEXT,");
	len += Format(query[len], sizeof(query)-len, "  `POINTS` INTEGER,`PLAYTIME` INTEGER, `LASTONTIME` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KILLS` INTEGER, `Death` INTEGER, `HeadshotKill` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_m4a1` INTEGER, `KW_ak47` INTEGER, `KW_scout` INTEGER, `KW_hegrenade` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_deagle` INTEGER, `KW_knife` INTEGER, `KW_sg552` INTEGER, `KW_p90` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_aug` INTEGER, `KW_usp` INTEGER, `KW_famas` INTEGER, `KW_mp5navy` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_galil` INTEGER, `KW_m249` INTEGER, `KW_m3` INTEGER, `KW_glock` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_p228` INTEGER, `KW_elite` INTEGER, `KW_xm1014` INTEGER, `KW_fiveseven` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `KW_tmp` INTEGER, `KW_ump45` INTEGER, `KW_mac10` INTEGER, `bomb_planted` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `bomb_defused` INTEGER, `bomb_exploded` INTEGER, `hostage_follows` INTEGER, `hostage_killed` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `hostage_rescued` INTEGER, `KW_awp` INTEGER, `KW_sg550` INTEGER, `KW_g3sg1` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `teamkills` INTEGER, `gungamewins` INTEGER, `suicides` INTEGER, `LASTDEDUCT` INTEGER, `country` TEXT);");
	//if(debug_version == 1){LogToFile(Logfile, "Line 3966: %s",query);}
	SQL_TQuery(db, createAtable, query);
}

public createAtable(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogToFile(Logfile, "SQL Error: %s", error);
		return;
	}
	createACCtable();
}

createACCtable()
{
	new len = 0, String:varS[64];
	decl String:query[10000];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tableaccuracy);
	if (sqllite != 1)
	{
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` varchar(25) NOT NULL, `LASTONTIME` int(25) NOT NULL DEFAULT 0,");
		for(new i=0; i < WEAPON_COUNT; i++)
		{
			len += Format(query[len], sizeof(query)-len, " `%s` int(25) NOT NULL DEFAULT 0,", weaponlist[i]);
			Format(varS, sizeof(varS), "%s_hit", weaponlist[i]);
			len += Format(query[len], sizeof(query)-len, " `%s` int(25) NOT NULL DEFAULT 0,", varS);
		}
		len += Format(query[len], sizeof(query)-len, " `hitbox_head` int(25) NOT NULL DEFAULT 0,");
		len += Format(query[len], sizeof(query)-len, " `hitbox_chest` int(25) NOT NULL DEFAULT 0,");
		len += Format(query[len], sizeof(query)-len, " `hitbox_stomach` int(25) NOT NULL DEFAULT 0,");
		len += Format(query[len], sizeof(query)-len, " `hitbox_leftarm` int(25) NOT NULL DEFAULT 0,");
		len += Format(query[len], sizeof(query)-len, " `hitbox_rightarm` int(25) NOT NULL DEFAULT 0,");
		len += Format(query[len], sizeof(query)-len, " `hitbox_leftleg` int(25) NOT NULL DEFAULT 0,");
		len += Format(query[len], sizeof(query)-len, " `hitbox_rightleg` int(25) NOT NULL DEFAULT 0,");
		len += Format(query[len], sizeof(query)-len, " PRIMARY KEY (`STEAMID`));");
		//if(debug_version == 1){LogToFile(Logfile, "Line 4002: %s",query);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_130: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	}
	else
	{
		len += Format(query[len], sizeof(query)-len, " (`STEAMID` TEXT, `LASTONTIME` INTEGER");
		for(new i=0; i < WEAPON_COUNT; i++)
		{
			len += Format(query[len], sizeof(query)-len, ", `%s` INTEGER", weaponlist[i]);
			Format(varS, sizeof(varS), "%s_hit", weaponlist[i]);
			len += Format(query[len], sizeof(query)-len, ", `%s` INTEGER", varS);
		}
		len += Format(query[len], sizeof(query)-len, ", `hitbox_head` INTEGER");
		len += Format(query[len], sizeof(query)-len, ", `hitbox_chest` INTEGER");
		len += Format(query[len], sizeof(query)-len, ", `hitbox_stomach` INTEGER");
		len += Format(query[len], sizeof(query)-len, ", `hitbox_leftarm` INTEGER");
		len += Format(query[len], sizeof(query)-len, ", `hitbox_rightarm` INTEGER");
		len += Format(query[len], sizeof(query)-len, ", `hitbox_leftleg` INTEGER");
		len += Format(query[len], sizeof(query)-len, ", `hitbox_rightleg` INTEGER");
		len += Format(query[len], sizeof(query)-len, ");");
		//if(debug_version == 1){LogToFile(Logfile, "Line 4022: %s",query);}
		new Handle:dataPackHandle = INVALID_HANDLE;
		if(debug_version == 1)
		{
			//********DEBUG QUERY STRING PUSH************
			dataPackHandle = CreateDataPack();
			new String:DEBUGSTRING[2048];
			Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_131: %s",query);
			WritePackString(dataPackHandle, DEBUGSTRING);
		}
		SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
	}
}

createdbmap()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tablemap);
	len += Format(query[len], sizeof(query)-len, " (`NAME` varchar(30) NOT NULL,");
	len += Format(query[len], sizeof(query)-len, "  `PLAYTIME` int(25) NOT NULL DEFAULT 0, `LASTONTIME` int(25) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `wins_ct` int(11) NOT NULL DEFAULT 0,");
	len += Format(query[len], sizeof(query)-len, " `wins_t` int(11) NOT NULL DEFAULT 0, PRIMARY KEY (`NAME`));");
	//if(debug_version == 1){LogToFile(Logfile, "Line 4036: %s",query);}
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_132: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}

createdbmapsqllite()
{
	new len = 0;
	decl String:query[2048];
	len += Format(query[len], sizeof(query)-len, "CREATE TABLE IF NOT EXISTS `%s`", tablemap);
	len += Format(query[len], sizeof(query)-len, " (`NAME` TEXT, `PLAYTIME` INTEGER,");
	len += Format(query[len], sizeof(query)-len, " `LASTONTIME` INTEGER, `wins_ct` INTEGER, `wins_t` INTEGER);");
	//if(debug_version == 1){LogToFile(Logfile, "Line 4047: %s",query);}
	SQL_TQuery(db, createAtable, query);
}


public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

Lateload()
{
	if(!LibraryExists("adminmenu"))
		return;
	
	new Handle:topmenu = GetAdminTopMenu();
	if (topmenu != INVALID_HANDLE)
		OnAdminMenuReady(topmenu);
}

public OnAdminMenuReady(Handle:topmenu)
{
	if(topmenu == hTopMenu)
		return;
	
	hTopMenu = topmenu;
	new TopMenuObject:server_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_SERVERCOMMANDS);
	if (server_commands != INVALID_TOPMENUOBJECT)
		AddToTopMenu(hTopMenu, "rank_adminmenu", TopMenuObject_Item, AdminMenu_Rank, server_commands, "rank_admin", ADMFLAG_ROOT);
}

public AdminMenu_Rank(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Rankmenu", LANG_SERVER);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		RankAdminMenu(param, 0);
	}
}

public Action:RankAdminMenu(client, args)
{
	new Handle:menu = CreateMenu(RankAdminMenuFS);
	decl String:buffer[100];
	Format(buffer, sizeof(buffer), "%T", "Rankmenu", client);
	SetMenuTitle(menu, buffer);
	
	if(ME_Enable == 0)
		Format(buffer, sizeof(buffer), "%T", "Enable Ranking", client);
	else
		Format(buffer, sizeof(buffer), "%T", "Disable Ranking", client);
	
	AddMenuItem(menu, "Ranking On/Off", buffer);
	Format(buffer, sizeof(buffer), "%T", "Reset Session", client);
	AddMenuItem(menu, "Reset Session", buffer);
	Format(buffer, sizeof(buffer), "%T", "Reset Database", client);
	AddMenuItem(menu, "Reset DB", buffer);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}
public Flip(flipNum)
{
	if(flipNum == 0)
		return 1;
	else
		return 0;
}
public RankAdminMenuFS(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 0)
		{
			new enBuf = Flip(ME_Enable);
			SetConVarInt(CV_enable, enBuf);
			RankAdminMenu(param1, 0);
		}
		else if(param2 == 1)
		{
			ResetSession();
		}
		else if(param2 == 2)
		{
			ResetAsk(param1, 0);
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public Action:ResetAsk(client, args)
{
	new Handle:menu = CreateMenu(ResetAskFS);
	new String:bb[256];
	Format(bb, sizeof(bb), "%T", "Really", client);
	SetMenuTitle(menu, bb);
	Format(bb, sizeof(bb), "%T", "rYes", client);
	AddMenuItem(menu, "ask_yes", bb);
	Format(bb, sizeof(bb), "%T", "rNo", client);
	AddMenuItem(menu, "ask_no", bb);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}
public ResetAskFS(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 0)
		{
			ResetReask(param1, 0);
		}
		else if(param2 == 1)
		{
			//reserved
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action:ResetReask(client, args)
{
	new Handle:menu = CreateMenu(ResetReaskFS);
	new String:bb[256];
	Format(bb, sizeof(bb), "%T", "ReallyReally", client);
	SetMenuTitle(menu, bb);
	Format(bb, sizeof(bb), "%T", "rNo", client);
	AddMenuItem(menu, "reask_no", bb);
	Format(bb, sizeof(bb), "%T", "rYes", client);
	AddMenuItem(menu, "reask_yes", bb);
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}
public ResetReaskFS(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		if(param2 == 1)
		{
			AreYouSure(param1, 0);
		}
		else if(param2 == 0)
		{
			//reserved
		}
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
public Action:AreYouSure(client, args)
{
	new Handle:menu = CreateMenu(AreYouSureFS);
	RandomApproval = GetRandomInt(1, 5);
	new String:rString[255];
	new String:rBuffer[255];
	if(RandomApproval == 1)
		Format(rString, sizeof(rString), "%T", "two",client);
	else if(RandomApproval == 2)
		Format(rString, sizeof(rString), "%T", "three",client);
	else if(RandomApproval == 3)
		Format(rString, sizeof(rString), "%T", "four",client);
	else if(RandomApproval == 4)
		Format(rString, sizeof(rString), "%T", "five",client);
	else if(RandomApproval == 5)
		Format(rString, sizeof(rString), "%T", "six",client);
	Format(rBuffer, sizeof(rBuffer), "%T %s %T", "Please press", client, rString, "confirm", client);
	SetMenuTitle(menu, rBuffer);
	AddMenuItem(menu, "ask_1", "1");
	AddMenuItem(menu, "ask_2", "2");
	AddMenuItem(menu, "ask_3", "3");
	AddMenuItem(menu, "ask_4", "4");
	AddMenuItem(menu, "ask_5", "5");
	AddMenuItem(menu, "ask_6", "6");
	
	DisplayMenu(menu, client, 20);
	return Plugin_Handled;
}

PrintHintToAll(String:tPhrase[])
{
	new String:Buffer[255];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i))
		{
			continue;
		}
		Format(Buffer, sizeof(Buffer), "%T", tPhrase, i);
		PrintHintText(i, "%s", Buffer);
	}
}

public AreYouSureFS(Handle:menu, MenuAction:action, param1, param2)
{
	new String:sClient[32];
	new String:sCName[64];
	if(action == MenuAction_Select)
	{
		if(param2 == RandomApproval)
		{
			resetdb();
			PrintHintToAll("HasBeenDeleted");
			TopMessage("Warning");
			PrintToChatAll("%t", "HasBeenDeleted");
			GetClientAuthString(param1, sClient, 32); 
			GetClientName(param1, sCName, 64);
			LogToFile(Logfile, "Client %s, SteamID: %s has deleted the rankings!", sCName, sClient);
		}
		else
		{
			//reserved
		}
	}
	else if(action == MenuAction_End)
		CloseHandle(menu);
}

public Action:cmd_importgg(client, args)
{
	if(import_running)
	{
		ReplyToCommand(client, "[rank] An Import is already in progress!");
		return Plugin_Handled;
	}
	import_client = client;
	import_running = true;
	new String:GGFile[1024];
	BuildPath(Path_SM, GGFile, sizeof(GGFile), "data/gungame/playerdata.txt");
	if(!FileExists(GGFile))
	{
		ReplyToCommand(client, "[rank] GG import failed. File <%s> not found", GGFile);
		import_running = false;
		return Plugin_Handled;
	}
	
	hGGimport = CreateKeyValues("gg_PlayerData");
	FileToKeyValues(hGGimport,GGFile);
	KvRewind(hGGimport);
	if(!KvGotoFirstSubKey(hGGimport))
	{
		ReplyToCommand(client, "[rank] GG import failed. File <%s> contains no or invalid data", GGFile);
		CloseHandle(hGGimport);
		import_running = false;
		return Plugin_Handled;
	}
	decl String:SteamID[66];
	decl String:Query[255];
	new ggWins = KvGetNum(hGGimport, "Wins");
	KvGetSectionName(hGGimport, SteamID, 66);
	Format(Query, sizeof(Query), "SELECT * FROM %s WHERE STEAMID = '%s'", tableplayer, SteamID);
	//if(debug_version == 1){LogToFile(Logfile, "Line 4298: %s",Query);}
	SQL_TQuery(db, T_ImportGG_check, Query, ggWins);
	return Plugin_Continue;
}

public T_ImportGG_check(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		if(import_client == 0)
			PrintToServer("[rank] GG:SM import failed! SQL Error: %s", error);
		else
		{
			PrintToConsole(import_client, "[rank] GG:SM import failed! SQL Error: %s", error);
			PrintToChat(import_client, "[rank] GG:SM import failed! SQL Error: %s", error);
		}
		CloseHandle(hGGimport);
		import_running = false;
		return;
	}
	new ggWins = data;
	new String:ClientSteamID[66];
	KvGetSectionName(hGGimport, ClientSteamID, 66);
	new String:clientname[12];
	strcopy(clientname, sizeof(clientname), "Unknown");
	new String:buffer[2048];
	if (!SQL_GetRowCount(hndl))
	{
		new thaTime = GetTime();
		/*insert user*/
		if (sqllite != 1)
		{
			Format(buffer, sizeof(buffer), "INSERT INTO %s (`NAME`,`STEAMID`,`LASTONTIME`,`LASTDEDUCT`,`gungamewins`) VALUES ('%s','%s',%i,%i,%i)", tableplayer, clientname, ClientSteamID, thaTime, thaTime, ggWins);
			//if(debug_version == 1){LogToFile(Logfile, "Line 4331: %s",buffer);}
			SQL_TQuery(db, T_ImportGG_check_callback, buffer);
			Format(buffer, sizeof(buffer), "INSERT INTO %s (`STEAMID`,`LASTONTIME`) VALUES ('%s',%i)", tableaccuracy, ClientSteamID,thaTime);
			//if(debug_version == 1){LogToFile(Logfile, "Line 4333: %s",buffer);}
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_133: %s",buffer);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, buffer,dataPackHandle);
		}
		else
		{
			Format(buffer, sizeof(buffer), "INSERT INTO %s VALUES('%s','%s',0,%i,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,%i,0,%i);", tableplayer, ClientSteamID,clientname,thaTime,ggWins,thaTime);
			//if(debug_version == 1){LogToFile(Logfile, "Line 4339: %s",buffer);}
			SQL_TQuery(db, T_ImportGG_check_callback, buffer);
			new tlen = 0;
			decl String:query[2048];
			tlen += Format(query[tlen], sizeof(query)-tlen, "INSERT INTO %s VALUES('%s',%i", tableaccuracy, ClientSteamID,thaTime);
			for(new i = 0; i < WEAPON_COUNT; i++)
			{
				tlen += Format(query[tlen], sizeof(query)-tlen, ",0");
				tlen += Format(query[tlen], sizeof(query)-tlen, ",0");
			}
			tlen += Format(query[tlen], sizeof(query)-tlen, ");");
			//if(debug_version == 1){LogToFile(Logfile, "Line 4350: %s",query);}
			new Handle:dataPackHandle = INVALID_HANDLE;
			if(debug_version == 1)
			{
				//********DEBUG QUERY STRING PUSH************
				dataPackHandle = CreateDataPack();
				new String:DEBUGSTRING[2048];
				Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_134: %s",query);
				WritePackString(dataPackHandle, DEBUGSTRING);
			}
			SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
		}
	}
	else
	{
		/*update*/
		Format(buffer, sizeof(buffer), "UPDATE %s SET gungamewins = %i WHERE STEAMID = '%s'", tableplayer, ggWins, ClientSteamID);
		//if(debug_version == 1){LogToFile(Logfile, "Line 4358: %s",buffer);}
		SQL_TQuery(db,T_ImportGG_check_callback, buffer);
	}
}

public T_ImportGG_check_callback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		if(import_client == 0)
			PrintToServer("[rank] GG:SM import failed! SQL Error: %s", error);
		else
		{
			PrintToConsole(import_client, "[rank] GG:SM import failed! SQL Error: %s", error);
			PrintToChat(import_client, "[rank] GG:SM import failed! SQL Error: %s", error);
		}
		CloseHandle(hGGimport);
		import_running = false;
		return;
	}
	if(!KvGotoNextKey(hGGimport))
	{
		//import complete
		if(import_client == 0)
			PrintToServer("[rank] GG:SM import complete!");
		else
		{
			PrintToConsole(import_client, "[rank] GG:SM import complete!");
			PrintToChat(import_client, "[rank] GG:SM import complete!");
		}
		CloseHandle(hGGimport);
		import_running = false;
		return;
	}
	decl String:SteamID[66];
	decl String:Query[255];
	new ggWins = KvGetNum(hGGimport, "Wins");
	KvGetSectionName(hGGimport, SteamID, 66);
	Format(Query, sizeof(Query), "SELECT * FROM %s WHERE STEAMID = '%s'", tableplayer, SteamID);
	//if(debug_version == 1){LogToFile(Logfile, "Line 4397: %s",Query);}
	SQL_TQuery(db, T_ImportGG_check, Query, ggWins);
}

public GG_OnWinner(client, const String:weapon[])
{
	if(ME_Enable == 0 || rankingactive == false || !IsClientInGame(client))
		return;
	if(IsFakeClient(client))
		return;
	new String:SteamID[66];
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	new String:query[255];
	Format(query, sizeof(query), "UPDATE %s SET gungamewins = gungamewins + 1 WHERE steamId = '%s'", tableplayer, SteamID);
	//if(debug_version == 1){LogToFile(Logfile, "ollowing query formatted on Line 5106: %s",query);}
	//if(debug_version == 1){LogToFile(Logfile, "Line 4411: %s",query);}
	new Handle:dataPackHandle = INVALID_HANDLE;
	if(debug_version == 1)
	{
		//********DEBUG QUERY STRING PUSH************
		dataPackHandle = CreateDataPack();
		new String:DEBUGSTRING[2048];
		Format(DEBUGSTRING, sizeof(DEBUGSTRING), "Marker X_DEB_135: %s",query);
		WritePackString(dataPackHandle, DEBUGSTRING);
	}
	SQL_TQuery(db,SQLErrorCheckCallback, query,dataPackHandle);
}
public Action:EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(ME_Enable == 0 || blockranking())
		return Plugin_Continue;

	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker == 0)
		return Plugin_Continue;
	new team_victim = GetClientTeam(victim);
	new team_attacker = GetClientTeam(attacker);
	if(team_victim == team_attacker)
		return Plugin_Continue;

	new String: weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	new weapon_index = get_weapon_index(weapon);
	if (weapon_index > -1)
		weapon_stats[attacker][weapon_index][1]++;
	new bodypart = GetEventInt(event, "hitgroup");
	hitbox_stats[attacker][bodypart]++;
	return Plugin_Continue;
}

public Action:EventWeaponFire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(ME_Enable == 0 || blockranking())
		return Plugin_Continue;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client == 0)
		return Plugin_Continue;
	
	new String: weapon[64];
	GetEventString(event, "weapon", weapon, 64);
	new weapon_index = get_weapon_index(weapon);
	if (weapon_index > -1)
		weapon_stats[client][weapon_index][0]++;
	
	return Plugin_Continue;
}
