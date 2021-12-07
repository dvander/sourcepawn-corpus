//******************************
//	CHANGELOG:
//	
//	0.3	7 June 2008 - MoggieX 
//		 psychstats_mode - 1 = Just a menu, 2 = Chat Only, 3 = Both a menu and chat(default)
//		 psychstats_url -  Alter to your own URL or own message (to disable leave blank) 
//
//	0.4:	09 January 2009 - Axon (axon@thcc.pl - http://www.thcc.pl)
//		- Modified say command handler and added "next" panel
//
//	0.5:	26 February 2009 - Packhead (s_s@sbcglobal.net) 
//		 - Modified so "chat" rank text is now translated.  Also corrected floatdiv warning.
//
//	0.6:	26 February 2009 - Packhead (s_s@sbcglobal.net)
//		- Modified the chat text again, translating all the text but colorizing the players statistics.
//
//	0.7:	07 March 2009 - Packhead (s_s@sbcglobal.net) 
//		- Removed some of the chat stuff (just way too much!  only lists player's name, skill and rank now.)
//	
//	0.8:	27 August 2009 - Axon (axon@thcc.pl - http://www.thcc.pl)
//		
//
//
//******************************

#include <sourcemod>

#define PLUGIN_VERSION "0.8"
#define PSYCHOSTATS_VERSION "3.1"

#define YELLOW 0x01
#define TEAMCOLOR 0x02
#define LIGHTGREEN 0x03
#define GREEN 0x04 

#define REQUEST_RANK 0
#define REQUEST_PLACE 1
#define REQUEST_KDR 2
#define REQUEST_KDEATH 3
#define REQUEST_SESSION 4
#define REQUEST_STATSME 5

new Handle:hDatabase = INVALID_HANDLE;
new Handle:cvarMode = INVALID_HANDLE;
new Handle:cvarURL = INVALID_HANDLE;
new Handle:cvarDetails = INVALID_HANDLE;
new Handle:cvarDbPrefix = INVALID_HANDLE;
new Handle:cvarCommandPrefix = INVALID_HANDLE;
new Handle:cvarDbConfigName = INVALID_HANDLE;

new String:strCalculateType[16];
new String:strDbPrefix[10] = "";
new supported = true;

//******************************
// PLUGIN INFO
//******************************

public Plugin:myinfo = 
{
	name = "PsychoStats Interface Plugin",
	author = "O!KAK",
	description = "PsychoStats Ingame Plugin",
	version = PLUGIN_VERSION,
	url = ""
};

//******************************
// PLUGIN START
//******************************

public OnPluginStart()
{
	LoadTranslations("plugin.psychostats");
	CreateConVar("psychstats_version", PLUGIN_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarMode = CreateConVar("psychstats_mode","3","1 = Just a menu, 2 = Chat Only, 3 = Both a menu and chat",FCVAR_PLUGIN,true,0.0,true,3.0);
	cvarURL = CreateConVar("psychstats_url", "", "URL to full stats.  Leave blank to not print this, useful if you advertise through another plugin.");
	cvarDetails = CreateConVar("psychstats_chat_details","1","Level of detail in chat when user says rank, 1=Summary, 2=Detailed",FCVAR_PLUGIN,true,1.0,true,2.0);
	cvarDbPrefix = CreateConVar("psychstats_db_prefix","ps","Database tables prefix (without underscore)",FCVAR_PLUGIN);
	cvarCommandPrefix = CreateConVar("psychstats_command_prefix","","Command prefix ex. /",FCVAR_PLUGIN);
	cvarDbConfigName = CreateConVar("psychstats_db_config_prefix","psstats","Name of connection string in Sourcemod databese config",FCVAR_PLUGIN);
	
	AutoExecConfig(true, "plugin.psychostats","sourcemod");
	
	GetConVarString(Handle:cvarDbPrefix, String:strDbPrefix, 10);
	
	StartSQL();
	
	RegConsoleCmd("say", Command_Say);
	HookEvent("round_start", Event_RoundStart,EventHookMode_Post);
	
}

//******************************
// Error  reporting
//******************************
public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (hDatabase == INVALID_HANDLE)
	{
		PrintToChatAll("%t", "DatabaseError", GREEN, YELLOW);
	} 
	
	if (!supported)
	{
		PrintToChatAll("%t", "NotSupportedError", GREEN, YELLOW);
	} 
	
	return Plugin_Continue
}

//******************************
// DATABASE HANDLING
//******************************
StartSQL()
{
	//connection string
	new String:connectionString[50];
	//get connection string from convar
	GetConVarString(cvarDbConfigName, connectionString, sizeof(connectionString));
	SQL_TConnect(ConnectToDb,"psstats");
}
 
public ConnectToDb(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Psychostats -> Database: Connection failure: %s", error);
	} 
	else 
	{
		hDatabase = hndl;
		LogMessage("Psychostats -> Database: Connection successful");

		decl String:query[255];
		Format(query, sizeof(query), "SELECT value FROM %s_config WHERE var LIKE 'uniqueid' OR var LIKE 'version' ORDER BY var", strDbPrefix);
		SQL_TQuery(hDatabase, ReadConfigCallback, query)
	}
}

public ReadConfigCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogError("Psychostats -> MySQL Error: %s", error);
		return;
	}
	
	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		LogError("Psychostats -> Config error: Can`t find uniqueid var in config table");
		return;
	}
	
	if(SQL_FetchRow(hndl))
	{		
		SQL_FetchString(hndl, 0, strCalculateType, sizeof(strCalculateType));
		LogMessage("Psychostats -> Config: Calculating stats by %s", strCalculateType);
	}
	if(SQL_FetchRow(hndl))
	{
		new String:version[10];
		SQL_FetchString(hndl, 0, version, sizeof(version));
		LogMessage("Psychostats -> Config: Psychostats version is %s", version);		
		
		if (!StrEqual(version, PSYCHOSTATS_VERSION))
		{
			supported = false;
		}
	}
}

//******************************
// SAY COMMAND HANDLING
//******************************
public Action:Command_Say(client, args)
{
	if (!supported)
	{
		if (IsClientInGame(client))
			PrintToChat(client, "%t", "NotSupportedError", GREEN, YELLOW);
		return Plugin_Continue;
	} 
	
	//passed message
	new String:text[192];
	//command prefix from config
	new String:commandPrefix[50];
	
	GetCmdArgString(text, sizeof(text));
	//get prefix from convar
	GetConVarString(cvarCommandPrefix, commandPrefix, sizeof(commandPrefix));
 
	new startidx = 0;

	// Strip quotes (if any)
	if (text[0] == '"')
	{
		startidx = 1;
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
	
	new commLen = strlen(text[startidx]);
	new prefixLen = strlen(commandPrefix);

	if (strlen(commandPrefix) != 0)
		ReplaceString(text[startidx], strlen(text[startidx]), commandPrefix , "", true);

	new commLen2 = strlen(text[startidx]);
	
	if ((commLen2 + prefixLen) == commLen)
	{
		if (StrEqual(text[startidx], "rank") || StrEqual(text[startidx], "RANK"))
		{
			ProcessSayRequest(client, REQUEST_RANK);
			return Plugin_Continue ;
		}
		if (StrEqual(text[startidx], "place") || StrEqual(text[startidx], "PLACE"))
		{
			ProcessSayRequest(client, REQUEST_PLACE);
			return Plugin_Continue ;
		}
		if (StrEqual(text[startidx], "kdr") || StrEqual(text[startidx], "KDR"))
		{
			ProcessSayRequest(client, REQUEST_KDR);
			return Plugin_Continue ;
		}
		if (StrEqual(text[startidx], "kdeath") || StrEqual(text[startidx], "KDEATH"))
		{
			ProcessSayRequest(client, REQUEST_KDEATH);
			return Plugin_Continue ;
		}
		else if (StrEqual(text[startidx], "top10") || StrEqual(text[startidx], "TOP10") || StrEqual(text[startidx], "top 10") || StrEqual(text[startidx], "TOP 10") || StrEqual(text[startidx], "top") || StrEqual(text[startidx], "TOP"))
		{
			ProcessTopRequest(client);
			return Plugin_Continue ;
		}
		else if (StrEqual(text[startidx], "next") || StrEqual(text[startidx], "NEXT"))
		{
			ProcessNextRequestStep1(client);
			return Plugin_Continue ;
		}
		else if  (StrEqual(text[startidx], "statsme")|| StrEqual(text[startidx], "STATSME"))
		{
			ProcessStatsMeRequest(client);
			return Plugin_Continue ;
		}
		else if  (StrEqual(text[startidx], "help")|| StrEqual(text[startidx], "HELP"))
		{
			ProcessHelpRequest(client);
			return Plugin_Continue ;
		}
	}
	return Plugin_Continue;
}

//******************************
//  PANEL HANDLERS
//******************************

public RankPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
// Nothing
}

public NextPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
// Nothing
}

public TopPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
// Nothing
}

//******************************
// "HELP" HANDLING
//****************************** 
public Action:ProcessHelpRequest(client)
{
	new Handle:menu = CreateMenu(HelpMenuHandler);
	new String:value[100];
	
	Format(value, sizeof(value), "%t", "HELPMenuTitle");
	SetMenuTitle(menu, value);
	AddMenuItem(menu, "1", "rank");
	AddMenuItem(menu, "2", "place");
	AddMenuItem(menu, "3", "top10");
	AddMenuItem(menu, "4", "kdr");
	AddMenuItem(menu, "5", "kdeath");
	AddMenuItem(menu, "6", "next");
	AddMenuItem(menu, "7", "statsme");
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 20);

	return Plugin_Continue
}

public HelpMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		//new String:info[32];
		//new bool:found = GetMenuItem(menu, param2, info, sizeof(info));
		//PrintToConsole(param1, "You selected item: %d (found? %d info: %s)", param2, found, info);

		if (param2 == 0)
		{
			ProcessSayRequest(param1, REQUEST_RANK);
		}
		else if (param2 == 1)
		{
			ProcessSayRequest(param1, REQUEST_PLACE);
		}
		else if (param2 == 2)
		{
			ProcessTopRequest(param1);
		}
		else if (param2 == 3)
		{
			ProcessSayRequest(param1, REQUEST_KDR);
		}
		else if (param2 == 4)
		{
			ProcessSayRequest(param1, REQUEST_KDEATH);
		}
		else if (param2 == 5)
		{
			ProcessNextRequestStep1(param1);
		}
		else if (param2 == 6)
		{
			ProcessStatsMeRequest(param1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
	
	}
}

//******************************
// "RANK" HANDLING
//******************************
 
public Action:ProcessSayRequest(client, type)
{
	// Get client identification method
	new String:useruid[64];
	if (strcmp(strCalculateType, "ipaddr") == 0)
	{
		GetClientIP(client, useruid, sizeof(useruid));
	} 
	else if (strcmp(strCalculateType, "worldid") == 0) 
	{
		GetClientAuthString(client, useruid, sizeof(useruid));
	} 
	else if (strcmp(strCalculateType, "name") == 0) 
	{
		GetClientName(client, useruid, sizeof(useruid));
	}	
	ProcessSayRequestCallback1(client, useruid, type);
}

public Action:ProcessSayRequestCallback1(client, const String:useruid[], type)
{
	decl String:query[255];
	
	new Handle:RankPack = CreateDataPack();
	WritePackCell(RankPack, client);
	WritePackCell(RankPack, type);
	ResetPack(RankPack);
	
	if (strcmp(strCalculateType, "ipaddr") == 0) 
	{
	   Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE INET_ATON('%s')", strDbPrefix, useruid);
	   SQL_TQuery(hDatabase, ProcessSayRequestCallback2, query, RankPack)
	} 
	else if ((strcmp(strCalculateType, "worldid") == 0) || (strcmp(strCalculateType, "name") == 0)) 
	{
	   Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE '%s'", strDbPrefix, useruid);
	   SQL_TQuery(hDatabase, ProcessSayRequestCallback2, query, RankPack)
	}   
}

public ProcessSayRequestCallback2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client, type;
	if(data != INVALID_HANDLE)
	{
		client = ReadPackCell(data);
		type = ReadPackCell(data);
		CloseHandle(data);
	}
	
	if (!StrEqual("", error))
	{
		LogError("Psychostats -> MySQL Error: %s", error);
		return;
	}

	if (hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "%t", "NotFoundRank", GREEN, YELLOW);
		} 
		else 
		{
			LogMessage("Psychostats -> Can`t find this player in database");
		}
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		decl playerId, playerRank, playerSkill;
		decl String:playerNick[64];
		decl String:query[255];
		
		playerId = SQL_FetchInt(hndl, 0);
		playerRank = SQL_FetchInt(hndl, 1);
		playerSkill = SQL_FetchInt(hndl, 2);
		
		if (type == REQUEST_RANK || type == REQUEST_PLACE)
			Format(query, sizeof(query), "SELECT onlinetime,kills,deaths,headshotkills,headshotkillspct,killsperdeath FROM %s_c_plr_data WHERE plrid LIKE '%i'", strDbPrefix, playerId);
		else if (type == REQUEST_KDR || type == REQUEST_KDEATH)
			Format(query, sizeof(query), "SELECT killsperdeath FROM %s_c_plr_data WHERE plrid LIKE '%i'", strDbPrefix, playerId);
		
		GetClientName(client, playerNick, sizeof(playerNick));
		new Handle:RankPack = CreateDataPack();
		WritePackCell(RankPack, playerRank);
		WritePackCell(RankPack, playerSkill);
		WritePackString(RankPack, playerNick);
		WritePackCell(RankPack, client);
		WritePackCell(RankPack, type);
		ResetPack(RankPack);
		SQL_TQuery(hDatabase, ProcessSayRequestCallback3, query, RankPack)
	}
	return;
}

public ProcessSayRequestCallback3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:playerNick[64];
	new playerRank, playerSkill, client, type;
	if(data != INVALID_HANDLE)
	{
		playerRank = ReadPackCell(data);
		playerSkill = ReadPackCell(data);
		ReadPackString(data, playerNick, sizeof(playerNick));
		client = ReadPackCell(data);
		type = ReadPackCell(data);
		CloseHandle(data);
	}

	if(!StrEqual("", error))
	{
		LogError("Psychostats -> MySQL Error: %s", error);
		return;
	}

	if(SQL_FetchRow(hndl))
	{
		if (type == REQUEST_KDR || type == REQUEST_KDEATH)
		{
			decl Float:killPerDeath;
			killPerDeath = SQL_FetchFloat(hndl, 0);
			
			if (type == REQUEST_KDEATH)
			{
				PrintToChatAll("%t", "KDRChat", playerNick, killPerDeath, GREEN, YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN);
			}
			else if (type == REQUEST_KDR)
			{
				PrintToChat(client, "%t", "KDRChat", playerNick, killPerDeath, GREEN, YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN);
			}
			
		}
		else if (type == REQUEST_PLACE || type == REQUEST_RANK)
		{
			decl onlineTime, playerKills, playerDeaths, headShots, Float:headShotsPercent, Float:killPerDeath;
			onlineTime = SQL_FetchInt(hndl, 0);
			playerKills = SQL_FetchInt(hndl, 1);
			playerDeaths = SQL_FetchInt(hndl, 2);
			headShots = SQL_FetchInt(hndl, 3);
			headShotsPercent = SQL_FetchFloat(hndl, 4);
			killPerDeath = SQL_FetchFloat(hndl, 5);

			new String:value[100];
			new Handle:rankPanel = CreatePanel();
			Format(value, sizeof(value), "%T", "RankMenuTitle", client);

			DrawPanelItem(rankPanel, value);
			
			//new operator is used instead of decl, to initialize vars with zero values
			new days, hours, mins;
			
			if (onlineTime > 0)
			{
				onlineTime = onlineTime / 60;
				hours = onlineTime / 60;
				days = hours / 24;
				mins = onlineTime % 60;		
			}
			
			//MoggieX: This section I have added with the cvarEnable check to show the rank in chat as well as the menu
			new cvarValue = GetConVarInt(cvarMode);

			if(cvarValue == 1 || cvarValue == 3)
			{
				DrawPanelText(rankPanel, " ");
				Format(value, sizeof(value), "%T", "Nick", client, playerNick);
				DrawPanelText(rankPanel, value);
				Format(value, sizeof(value), "%T", "Rank", client, playerRank);
				DrawPanelText(rankPanel, value);
				Format(value, sizeof(value), "%T", "Skill", client, playerSkill);
				DrawPanelText(rankPanel, value);
				Format(value, sizeof(value), "%T", "OnlineTime", client, hours, mins);
				DrawPanelText(rankPanel, value);
				Format(value, sizeof(value), "%T", "Kills", client, playerKills);
				DrawPanelText(rankPanel, value);
				Format(value, sizeof(value), "%T", "Deaths", client, playerDeaths);
				DrawPanelText(rankPanel, value);
				Format(value, sizeof(value), "%T", "KDR", client, killPerDeath);
				DrawPanelText(rankPanel, value);
				Format(value, sizeof(value), "%T", "HeadShots", client, headShots,headShotsPercent );
				DrawPanelText(rankPanel, value);
				DrawPanelText(rankPanel, " ");

				SetPanelCurrentKey(rankPanel, 10);
				Format(value, sizeof(value), "%T", "Exit", client);
				//DrawPanelItem(rnkpanel, value);

				SendPanelToClient(rankPanel, client, RankPanelHandler, 20);
				CloseHandle(rankPanel);
			}
			
			//MoggieX: This section I have added with the cvarEnable check to show the rank in chat as WELL as the menu
			// Packhead - 20090226 - Converted to use translation instead of hard code
			if (cvarValue >= 2)
			{
				
				// If psychstats_chat_details is set to 1 we'll only display rank and skill level.
				// If it's 2, we'll display a whooole lot more.
				if (type == REQUEST_PLACE)
				{
					if (playerRank == 0)
					{
						PrintToChatAll("%t","PlayerNotRanked", playerNick, GREEN, LIGHTGREEN, YELLOW);
					}
					else
					{
						if (GetConVarInt(cvarDetails) == 1) {
							PrintToChatAll("%t","RankDetailsInChat", playerNick, playerRank, playerSkill, GREEN, LIGHTGREEN, YELLOW, GREEN, YELLOW, GREEN, YELLOW);
						} else if (GetConVarInt(cvarDetails) == 2) {
						
							PrintToChatAll("%t", "RankDetailsInChatFull", playerNick, playerRank, playerSkill, playerKills, playerDeaths, killPerDeath, days , hours, mins, GREEN, LIGHTGREEN, YELLOW, LIGHTGREEN,  YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN, YELLOW);
						}
					}
					// get convar for full stats URL
					// If url is null, we won't print anything.
					decl String:url[100];
					GetConVarString(cvarURL, url, 100);
					if (strcmp(url, "") == 1) {
						PrintToChatAll("%t", "FullRanksURL", url, GREEN, YELLOW, GREEN);
					}
				}
				else if (type == REQUEST_RANK)
				{
					if (playerRank == 0)
					{
						PrintToChat(client, "%t","PlayerNotRanked", playerNick, GREEN, LIGHTGREEN, YELLOW);
					}
					else
					{
						if (GetConVarInt(cvarDetails) == 1) {
							PrintToChat(client, "%t","RankDetailsInChat", playerNick, playerRank, playerSkill, GREEN, LIGHTGREEN, YELLOW, GREEN, YELLOW, GREEN, YELLOW);
						} else if (GetConVarInt(cvarDetails) == 2) {
						
							PrintToChat(client, "%t", "RankDetailsInChatFull", playerNick, playerRank, playerSkill, playerKills, playerDeaths, killPerDeath, days , hours, mins, GREEN, LIGHTGREEN, YELLOW, LIGHTGREEN,  YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN, YELLOW, LIGHTGREEN, YELLOW);
						}
					}
					// get convar for full stats URL
					// If url is null, we won't print anything.
					decl String:url[100];
					GetConVarString(cvarURL, url, 100);
					if (strcmp(url, "") == 1) {
						PrintToChatAll("%t", "FullRanksURL", url, GREEN, YELLOW, GREEN);
					}
				}
			}
		}
	}
	return;
}

//******************************
// "NEXT" HANDLING
//******************************

public Action:ProcessNextRequestStep1(client)
{
	new String:useruid[64];
	if(strcmp(strCalculateType, "ipaddr") == 0)
	{
		GetClientIP(client, useruid, sizeof(useruid));
	} else if(strcmp(strCalculateType, "worldid") == 0)
	{
		GetClientAuthString(client, useruid, sizeof(useruid));
	} else if(strcmp(strCalculateType, "name") == 0)
	{
		GetClientName(client, useruid, sizeof(useruid));
	}
	ProcessNextRequestStep2(client, useruid);
}

public Action:ProcessNextRequestStep2(client, const String:useruid[])
{
	decl String:query[255];
	if(strcmp(strCalculateType, "ipaddr") == 0) 
	{
		Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE INET_ATON('%s')", strDbPrefix, useruid);
		SQL_TQuery(hDatabase, ProcessNextRequestStep3, query, client)
	} else if((strcmp(strCalculateType, "worldid") == 0) || (strcmp(strCalculateType, "name") == 0)) 
	{
		Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE '%s'", strDbPrefix, useruid);
		SQL_TQuery(hDatabase, ProcessNextRequestStep3, query, client)
	}
}

public ProcessNextRequestStep3(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if(!StrEqual("", error))
	{
		LogError("MySQL Error: %s", error);
		return;
	}

	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if(IsClientInGame(client))
		{
			PrintToChat(client, "%t", "NotFoundRank", GREEN, YELLOW);
		} else {
			LogMessage("Can`t find this player in stats");
		}
		return;
	}

	if(SQL_FetchRow(hndl))
	{
		//decl playerid, plrank, plskill;
		decl plrank, plskill;
		//playerid = SQL_FetchInt(hndl, 0);
		plrank = SQL_FetchInt(hndl, 1);
		plskill = SQL_FetchInt(hndl, 2);

		decl String:query2[255];
		Format(query2, sizeof(query2), "SELECT uniqueid,skill FROM %s_plr WHERE allowrank=1 AND skill>=%i ORDER BY skill ASC LIMIT 10", strDbPrefix, plskill);

		decl String:username[64];
		GetClientName(client, username, sizeof(username));
		new Handle:NextPack = CreateDataPack();
		WritePackCell(NextPack, plrank);
		WritePackCell(NextPack, plskill);
		WritePackString(NextPack, username);
		WritePackCell(NextPack, client);
		ResetPack(NextPack);
		SQL_TQuery(hDatabase, ProcessNextRequestStep4, query2, client)
	}
	return;
}

public ProcessNextRequestStep4(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	decl String:topipa[32], String:topipb[32], String:topipc[32], String:topipd[32], String:topipe[32], String:topipf[32], String:topipg[32], String:topiph[32], String:topipi[32], String:topipj[32];
	decl topskilla, topskillb, topskillc, topskilld, topskille, topskillf, topskillg, topskillh, topskilli, topskillj;

	if(!StrEqual("", error))
	{
		LogError("MySQL Error: %s", error);
		return;
	}
	
	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if(IsClientInGame(client))
		{
			PrintToChat(client, "%t", "NotFoundTop", GREEN, YELLOW);
		} else {
			LogMessage("Psychostats -> Next command request failed");
		}
		return;
	}

	new i = 1;

	while (SQL_FetchRow(hndl))
	{
		if (i == 1){
			SQL_FetchString(hndl, 0, topipa, sizeof(topipa));
			topskilla = SQL_FetchInt(hndl, 1);
		} else if (i == 2) {
			SQL_FetchString(hndl, 0, topipb, sizeof(topipb));
			topskillb = SQL_FetchInt(hndl, 1);
		} else if (i == 3) {
			SQL_FetchString(hndl, 0, topipc, sizeof(topipc));
			topskillc = SQL_FetchInt(hndl, 1);
		} else if (i == 4) {
			SQL_FetchString(hndl, 0, topipd, sizeof(topipd));
			topskilld = SQL_FetchInt(hndl, 1);
		} else if (i == 5) {
			SQL_FetchString(hndl, 0, topipe, sizeof(topipe));
			topskille = SQL_FetchInt(hndl, 1);
		} else if (i == 6) {
			SQL_FetchString(hndl, 0, topipf, sizeof(topipf));
			topskillf = SQL_FetchInt(hndl, 1);
		} else if (i == 7) {
			SQL_FetchString(hndl, 0, topipg, sizeof(topipg));
			topskillg = SQL_FetchInt(hndl, 1);
		} else if (i == 8) {
			SQL_FetchString(hndl, 0, topiph, sizeof(topiph));
			topskillh = SQL_FetchInt(hndl, 1);
		} else if (i == 9) {
			SQL_FetchString(hndl, 0, topipi, sizeof(topipi));
			topskilli = SQL_FetchInt(hndl, 1);
		} else {
			SQL_FetchString(hndl, 0, topipj, sizeof(topipj));
			topskillj = SQL_FetchInt(hndl, 1);
		}

		i++;
	}

	decl String:query44[512];
	Format(query44, sizeof(query44), "SELECT pp.name, p.rank FROM %s_plr p, %s_plr_profile pp WHERE p.uniqueid = pp.uniqueid AND pp.uniqueid IN ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s') ORDER BY p.skill ASC LIMIT 10", strDbPrefix, strDbPrefix, topipa, topipb, topipc, topipd, topipe, topipf, topipg, topiph, topipi, topipj);

	new Handle:TopPack = CreateDataPack();
	WritePackCell(TopPack, topskilla);
	WritePackCell(TopPack, topskillb);
	WritePackCell(TopPack, topskillc);
	WritePackCell(TopPack, topskilld);
	WritePackCell(TopPack, topskille);
	WritePackCell(TopPack, topskillf);
	WritePackCell(TopPack, topskillg);
	WritePackCell(TopPack, topskillh);
	WritePackCell(TopPack, topskilli);
	WritePackCell(TopPack, topskillj);
	WritePackCell(TopPack, client);
	ResetPack(TopPack);

	SQL_TQuery(hDatabase, NextThreeCallback, query44, TopPack);

	return;
}

public NextThreeCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl topskilla, topskillb, topskillc, topskilld, topskille, topskillf, topskillg, topskillh, topskilli, topskillj, client;
	decl topplacea, topplaceb,topplacec,topplaced,topplacee,topplacef,topplaceg,topplaceh,topplacei,topplacej;
	decl String:namea[20], String:nameb[20], String:namec[20], String:named[20], String:namee[20], String:namef[20], String:nameg[20], String:nameh[20], String:namei[20], String:namej[20];

	if(data != INVALID_HANDLE)
	{
		topskilla = ReadPackCell(data);
		topskillb = ReadPackCell(data);
		topskillc = ReadPackCell(data);
		topskilld = ReadPackCell(data);
		topskille = ReadPackCell(data);
		topskillf = ReadPackCell(data);
		topskillg = ReadPackCell(data);
		topskillh = ReadPackCell(data);
		topskilli = ReadPackCell(data);
		topskillj = ReadPackCell(data);
		client = ReadPackCell(data);
		CloseHandle(data);
	}

	if(!StrEqual("", error))
	{
		LogError("MySQL Error: %s", error);
		return;
	}

	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if(IsClientInGame(client))
		{
			PrintToChat(client, "%t", "NotFoundTop", GREEN, YELLOW);
		} else {
			LogMessage("Psychostats -> Next comand request failed");
		}
		return;
	}

	new String:value2[100];
	new Handle:NextPanel = CreatePanel();
	Format(value2, sizeof(value2), "%T", "NextMenuTitle", client);
	//SetPanelTitle(NextPanel, value2);
	DrawPanelItem(NextPanel, value2);
	DrawPanelText(NextPanel, " ");
	Format(value2, sizeof(value2), "%T", "SecTitle", client);
	DrawPanelText(NextPanel, value2);

	new i = 1;

	while (SQL_FetchRow(hndl))
	{
		if (i == 1){
			SQL_FetchString(hndl, 0, namea, sizeof(namea));
			topplacea = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplacea, topskilla, namea);
			DrawPanelText(NextPanel, value2);
		} else if (i == 2) {
			SQL_FetchString(hndl, 0, nameb, sizeof(nameb));
			topplaceb = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplaceb, topskillb, nameb);
			DrawPanelText(NextPanel, value2);
		} else if (i == 3) {
			SQL_FetchString(hndl, 0, namec, sizeof(namec));
			topplacec = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplacec, topskillc, namec);
			DrawPanelText(NextPanel, value2);
		} else if (i == 4) {
			SQL_FetchString(hndl, 0, named, sizeof(named));
			topplaced = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplaced, topskilld, named);
			DrawPanelText(NextPanel, value2);
		} else if (i == 5) {
			SQL_FetchString(hndl, 0, namee, sizeof(namee));
			topplacee = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplacee, topskille, namee);
			DrawPanelText(NextPanel, value2);
		} else if (i == 6) {
			SQL_FetchString(hndl, 0, namef, sizeof(namef));
			topplacef = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplacef, topskillf, namef);
			DrawPanelText(NextPanel, value2);
		} else if (i == 7) {
			SQL_FetchString(hndl, 0, nameg, sizeof(nameg));
			topplaceg = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplaceg, topskillg, nameg);
			DrawPanelText(NextPanel, value2);
		} else if (i == 8) {
			SQL_FetchString(hndl, 0, nameh, sizeof(nameh));
			topplaceh = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplaceh, topskillh, nameh);
			DrawPanelText(NextPanel, value2);
		} else if (i == 9) {
			SQL_FetchString(hndl, 0, namei, sizeof(namei));
			topplacei = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplacei, topskilli, namei);
			DrawPanelText(NextPanel, value2);
		} else {
			SQL_FetchString(hndl, 0, namej, sizeof(namej));
			topplacej = SQL_FetchInt(hndl, 1);
			Format(value2, sizeof(value2), "%i.  %i  %s", topplacej, topskillj, namej);
			DrawPanelText(NextPanel, value2);
		}

		i++;
	}
 
	DrawPanelText(NextPanel, " ");
	SetPanelCurrentKey(NextPanel, 10);
	Format(value2, sizeof(value2), "%T", "Exit", client);
	//DrawPanelItem(NextPanel, value2);
	SendPanelToClient(NextPanel, client, NextPanelHandler, MENU_TIME_FOREVER);
	CloseHandle(NextPanel);

	return;
}

//******************************
// "TOP 10" HANDLING
//******************************

public Action:ProcessTopRequest(client)
{
	decl String:query3[255];
	Format(query3, sizeof(query3), "SELECT uniqueid,skill FROM %s_plr WHERE allowrank=1 ORDER BY skill DESC LIMIT 10", strDbPrefix);
	SQL_TQuery(hDatabase, TopCallback, query3, client)
}

public TopCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	decl String:topipa[32], String:topipb[32], String:topipc[32], String:topipd[32], String:topipe[32], String:topipf[32], String:topipg[32], String:topiph[32], String:topipi[32], String:topipj[32];
	decl topskilla, topskillb, topskillc, topskilld, topskille, topskillf, topskillg, topskillh, topskilli, topskillj;

	if(!StrEqual("", error))
	{
		LogError("MySQL Error: %s", error);
		return;
	}
	
	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if(IsClientInGame(client))
		{
			PrintToChat(client, "%t", "NotFoundTop", GREEN, YELLOW);
		} else {
			LogMessage("Psychostats -> Top command request failed");
		}
		return;
	}

	new i = 1;

	while (SQL_FetchRow(hndl))
	{
		if (i == 1){
			SQL_FetchString(hndl, 0, topipa, sizeof(topipa));
			topskilla = SQL_FetchInt(hndl, 1);
		} else if (i == 2) {
			SQL_FetchString(hndl, 0, topipb, sizeof(topipb));
			topskillb = SQL_FetchInt(hndl, 1);
		} else if (i == 3) {
			SQL_FetchString(hndl, 0, topipc, sizeof(topipc));
			topskillc = SQL_FetchInt(hndl, 1);
		} else if (i == 4) {
			SQL_FetchString(hndl, 0, topipd, sizeof(topipd));
			topskilld = SQL_FetchInt(hndl, 1);
		} else if (i == 5) {
			SQL_FetchString(hndl, 0, topipe, sizeof(topipe));
			topskille = SQL_FetchInt(hndl, 1);
		} else if (i == 6) {
			SQL_FetchString(hndl, 0, topipf, sizeof(topipf));
			topskillf = SQL_FetchInt(hndl, 1);
		} else if (i == 7) {
			SQL_FetchString(hndl, 0, topipg, sizeof(topipg));
			topskillg = SQL_FetchInt(hndl, 1);
		} else if (i == 8) {
			SQL_FetchString(hndl, 0, topiph, sizeof(topiph));
			topskillh = SQL_FetchInt(hndl, 1);
		} else if (i == 9) {
			SQL_FetchString(hndl, 0, topipi, sizeof(topipi));
			topskilli = SQL_FetchInt(hndl, 1);
		} else {
			SQL_FetchString(hndl, 0, topipj, sizeof(topipj));
			topskillj = SQL_FetchInt(hndl, 1);
		}

		i++;
	}

	decl String:query4[512];
	Format(query4, sizeof(query4), "SELECT pp.name FROM %s_plr p, %s_plr_profile pp WHERE p.uniqueid = pp.uniqueid AND pp.uniqueid IN ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s') ORDER BY p.skill DESC LIMIT 10", strDbPrefix, strDbPrefix, topipa, topipb, topipc, topipd, topipe, topipf, topipg, topiph, topipi, topipj);

	new Handle:TopPack = CreateDataPack();
	WritePackCell(TopPack, topskilla);
	WritePackCell(TopPack, topskillb);
	WritePackCell(TopPack, topskillc);
	WritePackCell(TopPack, topskilld);
	WritePackCell(TopPack, topskille);
	WritePackCell(TopPack, topskillf);
	WritePackCell(TopPack, topskillg);
	WritePackCell(TopPack, topskillh);
	WritePackCell(TopPack, topskilli);
	WritePackCell(TopPack, topskillj);
	WritePackCell(TopPack, client);
	ResetPack(TopPack);

	SQL_TQuery(hDatabase, TopTwoCallback, query4, TopPack);

	return;
}

public TopTwoCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl topskilla, topskillb, topskillc, topskilld, topskille, topskillf, topskillg, topskillh, topskilli, topskillj, client;
	decl String:namea[20], String:nameb[20], String:namec[20], String:named[20], String:namee[20], String:namef[20], String:nameg[20], String:nameh[20], String:namei[20], String:namej[20];

	if(data != INVALID_HANDLE)
	{
		topskilla = ReadPackCell(data);
		topskillb = ReadPackCell(data);
		topskillc = ReadPackCell(data);
		topskilld = ReadPackCell(data);
		topskille = ReadPackCell(data);
		topskillf = ReadPackCell(data);
		topskillg = ReadPackCell(data);
		topskillh = ReadPackCell(data);
		topskilli = ReadPackCell(data);
		topskillj = ReadPackCell(data);
		client = ReadPackCell(data);
		CloseHandle(data);
	}

	if(!StrEqual("", error))
	{
		LogError("MySQL Error: %s", error);
		return;
	}

	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if(IsClientInGame(client))
		{
			PrintToChat(client, "%t", "NotFoundTop", GREEN, YELLOW);
		} else {
			LogMessage("Psychostats -> Top command request failed");
		}
		return;
	}

	new String:value2[100];
	new Handle:top10panel = CreatePanel();
	Format(value2, sizeof(value2), "%T", "TopMenuTitle", client);
	//SetPanelTitle(top10panel, value2);
	DrawPanelItem(top10panel, value2);
	DrawPanelText(top10panel, " ");
	Format(value2, sizeof(value2), "%T", "SecTitle", client);
	DrawPanelText(top10panel, value2);

	new i = 1;

	while (SQL_FetchRow(hndl))
	{
		if (i == 1){
			SQL_FetchString(hndl, 0, namea, sizeof(namea));
			Format(value2, sizeof(value2), "01.  %i  %s", topskilla, namea);
			DrawPanelText(top10panel, value2);
		} else if (i == 2) {
			SQL_FetchString(hndl, 0, nameb, sizeof(nameb));
			Format(value2, sizeof(value2), "02.  %i  %s", topskillb, nameb);
			DrawPanelText(top10panel, value2);
		} else if (i == 3) {
			SQL_FetchString(hndl, 0, namec, sizeof(namec));
			Format(value2, sizeof(value2), "03.  %i  %s", topskillc, namec);
			DrawPanelText(top10panel, value2);
		} else if (i == 4) {
			SQL_FetchString(hndl, 0, named, sizeof(named));
			Format(value2, sizeof(value2), "04.  %i  %s", topskilld, named);
			DrawPanelText(top10panel, value2);
		} else if (i == 5) {
			SQL_FetchString(hndl, 0, namee, sizeof(namee));
			Format(value2, sizeof(value2), "05.  %i  %s", topskille, namee);
			DrawPanelText(top10panel, value2);
		} else if (i == 6) {
			SQL_FetchString(hndl, 0, namef, sizeof(namef));
			Format(value2, sizeof(value2), "06.  %i  %s", topskillf, namef);
			DrawPanelText(top10panel, value2);
		} else if (i == 7) {
			SQL_FetchString(hndl, 0, nameg, sizeof(nameg));
			Format(value2, sizeof(value2), "07.  %i  %s", topskillg, nameg);
			DrawPanelText(top10panel, value2);
		} else if (i == 8) {
			SQL_FetchString(hndl, 0, nameh, sizeof(nameh));
			Format(value2, sizeof(value2), "08.  %i  %s", topskillh, nameh);
			DrawPanelText(top10panel, value2);
		} else if (i == 9) {
			SQL_FetchString(hndl, 0, namei, sizeof(namei));
			Format(value2, sizeof(value2), "09.  %i  %s", topskilli, namei);
			DrawPanelText(top10panel, value2);
		} else {
			SQL_FetchString(hndl, 0, namej, sizeof(namej));
			Format(value2, sizeof(value2), "10.  %i  %s", topskillj, namej);
			DrawPanelText(top10panel, value2);
		}

		i++;
	}
 
	DrawPanelText(top10panel, " ");
	SetPanelCurrentKey(top10panel, 10);
	Format(value2, sizeof(value2), "%T", "Exit", client);
	//DrawPanelItem(top10panel, value2);
	SendPanelToClient(top10panel, client, TopPanelHandler, MENU_TIME_FOREVER);
	CloseHandle(top10panel);

	return;
}

//******************************
// "STATSME" HANDLING
//******************************
 
public Action:ProcessStatsMeRequest(client)
{
	// Get client identification method
	new String:useruid[64];
	if (strcmp(strCalculateType, "ipaddr") == 0)
	{
		GetClientIP(client, useruid, sizeof(useruid));
	} 
	else if (strcmp(strCalculateType, "worldid") == 0) 
	{
		GetClientAuthString(client, useruid, sizeof(useruid));
	} 
	else if (strcmp(strCalculateType, "name") == 0) 
	{
		GetClientName(client, useruid, sizeof(useruid));
	}	
	ProcessStatsMeRequestCallback1(client, useruid);
}

public Action:ProcessStatsMeRequestCallback1(client, const String:useruid[])
{
	decl String:query[255];
	if (strcmp(strCalculateType, "ipaddr") == 0) 
	{
	   Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE INET_ATON('%s')", strDbPrefix, useruid);
	   SQL_TQuery(hDatabase, ProcessStatsMeRequestCallback2, query, client)
	} 
	else if ((strcmp(strCalculateType, "worldid") == 0) || (strcmp(strCalculateType, "name") == 0)) 
	{
	   Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE '%s'", strDbPrefix, useruid);
	   SQL_TQuery(hDatabase, ProcessStatsMeRequestCallback2, query, client)
	}   
}

public ProcessStatsMeRequestCallback2(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (!StrEqual("", error))
	{
		LogError("Psychostats -> MySQL Error: %s", error);
		return;
	}

	if (hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if (IsClientInGame(client))
		{
			PrintToChat(client, "%t", "NotFoundRank", GREEN, YELLOW);
		} 
		else 
		{
			LogMessage("Psychostats -> Can`t find this player in database");
		}
		return;
	}

	if (SQL_FetchRow(hndl))
	{
		decl playerId, playerRank, playerSkill;
		decl String:playerNick[64];
		decl String:query[255];
		
		playerId = SQL_FetchInt(hndl, 0);
		playerRank = SQL_FetchInt(hndl, 1);
		playerSkill = SQL_FetchInt(hndl, 2);
		
		Format(query, sizeof(query), "SELECT * FROM %s_c_plr_data WHERE plrid LIKE '%i'", strDbPrefix, playerId);
		
		GetClientName(client, playerNick, sizeof(playerNick));
		new Handle:RankPack = CreateDataPack();
		WritePackCell(RankPack, playerRank);
		WritePackCell(RankPack, playerSkill);
		WritePackString(RankPack, playerNick);
		WritePackCell(RankPack, client);
		ResetPack(RankPack);
		SQL_TQuery(hDatabase, ProcessStatsMeRequestCallback3, query, RankPack)
	}
	return;
}

public ProcessStatsMeRequestCallback3(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:playerNick[64];
	new playerRank, playerSkill, client;
	if(data != INVALID_HANDLE)
	{
		playerRank = ReadPackCell(data);
		playerSkill = ReadPackCell(data);
		ReadPackString(data, playerNick, sizeof(playerNick));
		client = ReadPackCell(data);
		CloseHandle(data);
	}

	if(!StrEqual("", error))
	{
		LogError("Psychostats -> MySQL Error: %s", error);
		return;
	}

	if(SQL_FetchRow(hndl))
	{
		new Float:accuracy, String:firstDate[20], bombsDefused, bombDefuseAttempts, Float:bombsDefusedPercent;
		new bombsExploded, Float:bombsExplodedPercent, bombsPlanted, ctLost, ctWon,Float:ctWonPercent, damage;
		new deaths, ffKills, headShots, Float:headShotsPercent, hits, kills;
		new Float:kpd, onlineTime, hostagesRescued, hostagesTaken, Float:hostagesRescuedPercent;
		new rounds, shots, tWon, tLost, Float:tWonPercent;
		
		accuracy = SQL_FetchFloat(hndl, 4);
		SQL_FetchString(hndl, 2, firstDate, sizeof(firstDate));
		bombsDefused = SQL_FetchInt(hndl, 7);
		bombDefuseAttempts = SQL_FetchInt(hndl, 6);
		bombsDefusedPercent = SQL_FetchFloat(hndl, 8);
		bombsExploded = SQL_FetchInt(hndl, 9);
		bombsExplodedPercent = SQL_FetchFloat(hndl, 10);
		bombsPlanted = SQL_FetchInt(hndl, 11);
		ctLost = SQL_FetchInt(hndl, 20);
		ctWon = SQL_FetchInt(hndl, 21);
		ctWonPercent = SQL_FetchFloat(hndl, 22);
		damage = SQL_FetchInt(hndl, 23);
		deaths = SQL_FetchInt(hndl, 24);
		ffKills = SQL_FetchInt(hndl, 28);
		headShots = SQL_FetchInt(hndl, 31);
		headShotsPercent = SQL_FetchFloat(hndl, 32);
		hits = SQL_FetchInt(hndl, 33);
		kills = SQL_FetchInt(hndl, 39);
		kpd = SQL_FetchFloat(hndl, 41);
		onlineTime = SQL_FetchInt(hndl, 44);
		hostagesRescued = SQL_FetchInt(hndl, 45);
		hostagesTaken = SQL_FetchInt(hndl, 57);
		hostagesRescuedPercent = SQL_FetchFloat(hndl, 46);
		rounds = SQL_FetchInt(hndl, 47);
		shots = SQL_FetchInt(hndl, 48);
		tWon = SQL_FetchInt(hndl, 54);
		tLost = SQL_FetchInt(hndl, 53);
		tWonPercent = SQL_FetchFloat(hndl, 55);

		//new operator is used instead of decl, to initialize vars with zero values
		new /*days, */hours, mins;
		
		if (onlineTime > 0)
		{
			onlineTime = onlineTime / 60;
			hours = onlineTime / 60;
			//days = hours / 24;
			mins = onlineTime % 60;	
		}
		
		new String:value[100];
		new Handle:statsMePanel = CreatePanel();
		
		Format(value, sizeof(value), "%t", "StatsMePlayer", playerNick);
		DrawPanelItem(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Rank",  playerRank);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Skill",  playerSkill);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Kills",  kills);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Deaths",  deaths);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "HeadShots",  headShots, headShotsPercent);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "KDR",  kpd);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "FFKils",  ffKills);
		DrawPanelText(statsMePanel, value);		
		Format(value, sizeof(value), "%t", "StatsMeCss");
		DrawPanelItem(statsMePanel, value);
		Format(value, sizeof(value), "%t", "FirstDate",  firstDate);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "OnlineTime", hours, mins);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Shots",  shots);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Hits",  hits, accuracy);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Accuracy",  accuracy);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Damage",  damage);
		DrawPanelText(statsMePanel, value);
		
		Format(value, sizeof(value), "%t", "StatsMeBomb");
		DrawPanelItem(statsMePanel, value);
		Format(value, sizeof(value), "%t", "BombsExploded",  bombsExploded, bombsPlanted, bombsExplodedPercent);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "BombsDefused",  bombsDefused, bombDefuseAttempts, bombsDefusedPercent);
		DrawPanelText(statsMePanel, value);
		
		Format(value, sizeof(value), "%t", "StatsMeHostages");
		DrawPanelItem(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Hostages",  hostagesRescued, hostagesTaken, hostagesRescuedPercent);
		DrawPanelText(statsMePanel, value);
		
		Format(value, sizeof(value), "%t", "StatsMeRounds");
		DrawPanelItem(statsMePanel, value);
		Format(value, sizeof(value), "%t", "Rounds",  rounds);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "TRounds",  tLost, tWon, tWonPercent);
		DrawPanelText(statsMePanel, value);
		Format(value, sizeof(value), "%t", "CtRounds", ctLost, ctWon, ctWonPercent);
		DrawPanelText(statsMePanel, value);
		
		DrawPanelText(statsMePanel, " ");

		SetPanelCurrentKey(statsMePanel, 10);
		
		SendPanelToClient(statsMePanel, client, RankPanelHandler, 20);
		CloseHandle(statsMePanel);

	}

	return;
}
