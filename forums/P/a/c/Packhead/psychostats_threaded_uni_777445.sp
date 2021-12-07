//******************************
//	7 June 2008 - MoggieX - Added Chat mode options
//		psychstats_mode - 1 = Just a menu, 2 = Chat Only, 3 = Both a menu and chat(default)
//		psychstats_url -  Alter to your own URL or own message
//
//	09 January 2009 - Axon (axon@thcc.pl - http://www.thcc.pl)- Modified say command handler and added "next" panel
//  	26 February 2009 - Packhead (s_s@sbcglobal.net) - Version 0.5 - Modified so "chat" rank text is now translated.  Also corrected floatdiv warning.
//		26 February 2009 - Packhead (s_s@sbcglobal.net) - Version 0.6 - Modified the chat text again, translating all the text but colorizing the players statistics.
//		07 March 2009 - Packhead (s_s@sbcglobal.net) - Version 0.7 - Removed some of the chat stuff (just way too much!  only lists player's name, skill and rank now.)
//
//******************************

#include <sourcemod>

#define PLUGIN_VERSION "0.8"

// Your psychostats tables prefix here
new String:MysqlPrefix[10] = "ps";

new String:typouid[16];

new Handle:hDatabase = INVALID_HANDLE;			/** Database connection */

//MoggieX: Added Handle for enablement in chat and URL
new Handle:cvarMode;
new Handle:cvarURL;
new Handle:cvarDetails;

//******************************
// PLUGIN INFO
//******************************

public Plugin:myinfo = 
{
	name = "PsychoStats rank`n`top",
	author = "O!KAK",
	description = "PsychoStats Ingame Interface",
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
	
	//MoggieX: Added enablement CVar which is disabled by default for showing the chat message instead fo a menu panel
	cvarMode = CreateConVar("psychstats_mode","3","1 = Just a menu, 2 = Chat Only, 3 = Both a menu and chat",FCVAR_PLUGIN,true,0.0,true,3.0);
	cvarURL = CreateConVar("psychstats_url", "", "URL to full stats.  Leave blank to not print this, useful if you advertise through another plugin.");
	cvarDetails = CreateConVar("psychstats_details","1","Level of detail in chat when user says rank, 1=Summary, 2=Detailed",FCVAR_PLUGIN,true,1.0,true,2.0);

	StartSQL();
	RegConsoleCmd("say", Command_Say);
}

//******************************
// DATABASE HANDLING
//******************************

StartSQL()
{
	SQL_TConnect(GotDatabase,"psstats");
}
 
public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
	} else {
		hDatabase = hndl;
		LogMessage("DatabaseInit (CONNECTED)");

		decl String:query5[255];
		Format(query5, sizeof(query5), "SELECT value FROM %s_config WHERE var LIKE 'uniqueid'", MysqlPrefix);
		SQL_TQuery(hDatabase, TypoCallback, query5)
	}
}

public TypoCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogError("MySQL Error: %s", error);
		return;
	}
	
	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		LogError("Can`t find uniqueid");
		return;
	}
	
	if(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, typouid, sizeof(typouid));
		LogMessage("Psychostats calculate stats by %s", typouid);
	}
}

//******************************
// SAY COMMAND HANDLING
//******************************

public Action:Command_Say(client, args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
 
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0'
		}
	}
 
	if (StrEqual(text[startidx], "rank") || StrEqual(text[startidx], "RANK"))
	{
		echo_rank(client);
		return Plugin_Continue ;
	}
	else if (StrEqual(text[startidx], "top10") || StrEqual(text[startidx], "TOP10") || StrEqual(text[startidx], "top 10") || StrEqual(text[startidx], "TOP 10") || StrEqual(text[startidx], "top") || StrEqual(text[startidx], "TOP")|| StrEqual(text[startidx], "statsme")|| StrEqual(text[startidx], "STATSME"))
	{
		top10pnl(client);
		return Plugin_Continue ;
	}
	else if (StrEqual(text[startidx], "next") || StrEqual(text[startidx], "NEXT"))
	{
		echo_next(client);
		return Plugin_Continue ;
	}
	return Plugin_Continue;
}

//******************************
// EMPTY MENU HANDLERS
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
// "RANK" HANDLING
//******************************
 
public Action:echo_rank(client)
{
	new String:useruid[64];
	if(strcmp(typouid, "ipaddr") == 0)
	{
		GetClientIP(client, useruid, sizeof(useruid));
	} else if(strcmp(typouid, "worldid") == 0) 
	{
		GetClientAuthString(client, useruid, sizeof(useruid));
	} else if(strcmp(typouid, "name") == 0) 
	{
		GetClientName(client, useruid, sizeof(useruid));
	}	
	rankpanel(client, useruid);
}

public Action:rankpanel(client, const String:useruid[])
{
	decl String:query[255];
	if(strcmp(typouid, "ipaddr") == 0) {
	   Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE INET_ATON('%s')", MysqlPrefix, useruid);
	   SQL_TQuery(hDatabase, RankCallback, query, client)
	} else if((strcmp(typouid, "worldid") == 0) || (strcmp(typouid, "name") == 0)) {
	   Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE '%s'", MysqlPrefix, useruid);
	   SQL_TQuery(hDatabase, RankCallback, query, client)
	}
	   
	   
}

public RankCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
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
			PrintToChat(client, "%t", "NotFoundRank");
		} else {
			LogMessage("Can`t find this player in stats");
		}
		return;
	}

	if(SQL_FetchRow(hndl))
	{
		decl playerid, plrank, plskill;
		playerid = SQL_FetchInt(hndl, 0);
		plrank = SQL_FetchInt(hndl, 1);
		plskill = SQL_FetchInt(hndl, 2);

		decl String:query2[255];
		Format(query2, sizeof(query2), "SELECT onlinetime,kills,deaths,headshotkills FROM %s_c_plr_data WHERE plrid LIKE '%i'", MysqlPrefix, playerid);

		decl String:username[64];
		GetClientName(client, username, sizeof(username));
		new Handle:RankPack = CreateDataPack();
		WritePackCell(RankPack, plrank);
		WritePackCell(RankPack, plskill);
		WritePackString(RankPack, username);
		WritePackCell(RankPack, client);
		ResetPack(RankPack);
		SQL_TQuery(hDatabase, RankTwoCallback, query2, RankPack)
	}
	return;
}

public RankTwoCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:plnick[64];
	new plrank, plskill, client;
	if(data != INVALID_HANDLE)
	{
		plrank = ReadPackCell(data);
		plskill = ReadPackCell(data);
		ReadPackString(data, plnick, sizeof(plnick));
		client = ReadPackCell(data);
		CloseHandle(data);
	}

	if(!StrEqual("", error))
	{
		LogError("MySQL Error: %s", error);
		return;
	}

	if(SQL_FetchRow(hndl))
	{
		decl onlinetime, plkills, pldeaths, headshots;
		onlinetime = SQL_FetchInt(hndl, 0);
		plkills = SQL_FetchInt(hndl, 1);
		pldeaths = SQL_FetchInt(hndl, 2);
		headshots = SQL_FetchInt(hndl, 3);

		new String:value[100];
		new Handle:rnkpanel = CreatePanel();
		Format(value, sizeof(value), "%T", "RankMenuTitle", client);
		//SetPanelTitle(rnkpanel, value);
		DrawPanelItem(rnkpanel, value);
		new hours, mins, Float:kdr;
		
		if (onlinetime > 0)
		{
			onlinetime = onlinetime / 60;
			hours = onlinetime / 60;
			mins = onlinetime % 60;		
		}
		if (pldeaths > 0)
		{
			kdr = FloatDiv(float(plkills), float(pldeaths));
		}
		else
		{
			kdr = float(plkills);
		}

		
		//MoggieX: This section I have added with the cvarEnable check to show the rank in chat as well as the menu
		new cvarValue = GetConVarInt(cvarMode);

		if(cvarValue == 1 || cvarValue == 3)
		{
			DrawPanelText(rnkpanel, " ");
			Format(value, sizeof(value), "%T", "Nick", client, plnick);
			DrawPanelText(rnkpanel, value);
			Format(value, sizeof(value), "%T", "Rank", client, plrank);
			DrawPanelText(rnkpanel, value);
			Format(value, sizeof(value), "%T", "Skill", client, plskill);
			DrawPanelText(rnkpanel, value);
			Format(value, sizeof(value), "%T", "Online", client, hours, mins);
			DrawPanelText(rnkpanel, value);
			Format(value, sizeof(value), "%T", "Kills", client, plkills);
			DrawPanelText(rnkpanel, value);
			Format(value, sizeof(value), "%T", "Deaths", client, pldeaths);
			DrawPanelText(rnkpanel, value);
			Format(value, sizeof(value), "%T", "KDR", client, kdr);
			DrawPanelText(rnkpanel, value);
			Format(value, sizeof(value), "%T", "Head", client, headshots);
			DrawPanelText(rnkpanel, value);
			DrawPanelText(rnkpanel, " ");

			SetPanelCurrentKey(rnkpanel, 10);
			Format(value, sizeof(value), "%T", "Exit", client);
			//DrawPanelItem(rnkpanel, value);

			SendPanelToClient(rnkpanel, client, RankPanelHandler, 20);
			CloseHandle(rnkpanel);
		}
		
		//MoggieX: This section I have added with the cvarEnable check to show the rank in chat as WELL as the menu
		// Packhead - 20090226 - Converted to use translation instead of hard code
		if (GetConVarInt(cvarMode) >= 2)
		{
			
			// If psychstats_details is set to 1 we'll only display rank and skill level.
			// If it's 2, we'll display a whooole lot more.
			if (GetConVarInt(cvarDetails) == 1) {
				PrintToChatAll("\x03[PsychoStats] \x04%s \x01%t \x03%i \x01%t \x03%i\x01.", plnick, "chat_isranked", plrank, "chat_withskill", plskill);			
			} else if (GetConVarInt(cvarDetails) == 2) {
				PrintToChatAll("\x03[PsychoStats] \x04%s \x01%t \x03%i \x01%t \x03%i\x01, \x03%i \x01%t %t \x03%i \x01%t (%t: %f). %t", plnick, "chat_isranked", plrank, "chat_withskill", plskill, plkills, "chat_kills", "and", pldeaths, "chat_deaths", "chat_KDR", kdr, "Online", hours, mins);
			}	

			// get convar for full stats URL
			// If url is null, we won't print anything.
			decl String:url[100];
			GetConVarString(cvarURL, url, 100);
			if (strcmp(url, "") == 1) {
				PrintToChatAll("\x01%t \x04%s", "chat_statsat", url);
			}
		}
	}

	return;
}

//******************************
// "NEXT" HANDLING
//******************************

public Action:echo_next(client)
{
	new String:useruid[64];
	if(strcmp(typouid, "ipaddr") == 0)
	{
		GetClientIP(client, useruid, sizeof(useruid));
	} else if(strcmp(typouid, "worldid") == 0)
	{
		GetClientAuthString(client, useruid, sizeof(useruid));
	} else if(strcmp(typouid, "name") == 0)
	{
		GetClientName(client, useruid, sizeof(useruid));
	}
	nextpanel(client, useruid);
}

public Action:nextpanel(client, const String:useruid[])
{
	decl String:query[255];
	if(strcmp(typouid, "ipaddr") == 0) 
	{
		Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE INET_ATON('%s')", MysqlPrefix, useruid);
		SQL_TQuery(hDatabase, NextCallback, query, client)
	} else if((strcmp(typouid, "worldid") == 0) || (strcmp(typouid, "name") == 0)) 
	{
		Format(query, sizeof(query), "SELECT plrid,rank,skill FROM %s_plr WHERE uniqueid LIKE '%s'", MysqlPrefix, useruid);
		SQL_TQuery(hDatabase, NextCallback, query, client)
	}
}

public NextCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
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
			PrintToChat(client, "%t", "NotFoundRank");
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
		Format(query2, sizeof(query2), "SELECT uniqueid,skill FROM %s_plr WHERE allowrank=1 AND skill>=%i ORDER BY skill ASC LIMIT 10", MysqlPrefix, plskill);

		decl String:username[64];
		GetClientName(client, username, sizeof(username));
		new Handle:NextPack = CreateDataPack();
		WritePackCell(NextPack, plrank);
		WritePackCell(NextPack, plskill);
		WritePackString(NextPack, username);
		WritePackCell(NextPack, client);
		ResetPack(NextPack);
		SQL_TQuery(hDatabase, NextTwoCallback, query2, client)
	}
	return;
}

public NextTwoCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
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
			PrintToChat(client, "%t", "NotFoundTop");
		} else {
			LogMessage("We get error here for next (skill select)");
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
	Format(query44, sizeof(query44), "SELECT pp.name, p.rank FROM %s_plr p, %s_plr_profile pp WHERE p.uniqueid = pp.uniqueid AND pp.uniqueid IN ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s') ORDER BY p.skill ASC LIMIT 10", MysqlPrefix, MysqlPrefix, topipa, topipb, topipc, topipd, topipe, topipf, topipg, topiph, topipi, topipj);

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
			PrintToChat(client, "%t", "NotFoundTop");
		} else {
			LogMessage("We get error here for next (name select)");
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

public Action:top10pnl(client)
{
	decl String:query3[255];
	Format(query3, sizeof(query3), "SELECT uniqueid,skill FROM %s_plr WHERE allowrank=1 ORDER BY skill DESC LIMIT 10", MysqlPrefix);
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
			PrintToChat(client, "%t", "NotFoundTop");
		} else {
			LogMessage("We get error here for top10 (skill select)");
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
	Format(query4, sizeof(query4), "SELECT pp.name FROM %s_plr p, %s_plr_profile pp WHERE p.uniqueid = pp.uniqueid AND pp.uniqueid IN ('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s') ORDER BY p.skill DESC LIMIT 10", MysqlPrefix, MysqlPrefix, topipa, topipb, topipc, topipd, topipe, topipf, topipg, topiph, topipi, topipj);

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
			PrintToChat(client, "%t", "NotFoundTop");
		} else {
			LogMessage("We get error here for top10 (name select)");
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
