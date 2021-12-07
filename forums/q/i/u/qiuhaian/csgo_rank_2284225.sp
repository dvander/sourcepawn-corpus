#include <sourcemod>
#include <sdktools>
#include <csgocolors>
#include <cstrike>

/* *********************************************************************

// {NORMAL}, {DARKRED}, {PINK}, {YELLOW}, {GREEN}, {LIGHTGREEN}, {RED}, {GRAY}, {BLUE}, {DARKBLUE}, {PURPLE} 
Thanks for people that help me:
- dalto (http://forums.alliedmods.net/member.php?u=29575)


Updates:
 * Display FIX
 * Query FIXES
 * New: OLD STATS deleting
 * Update TABLE on UTF8 and Setting NAMES to UTF8 on DatabaseConnect
 * Changes in Database Connect
 * New: Added "/headhunters"
 * New: played_time, we will creat most active players TOP
 * New: last_active ON this we will base is this player stats not to old.. (we dont want have BIG MySQL DataBase)
   in future, maybe i will creat archive table, that there we will be have those player's, and they will be come back from archive when they will connect.
 * Anti Flood Protection (new userFlood[64];)
 * New announce message on: onClientPutInServer(client)
 * WWW sie Cvar ("sm_lrcss_www",)
 * PHP site nick protection:
 [		ReplaceString(name, sizeof(name), "'", "");
		ReplaceString(name, sizeof(name), "<", "");
		ReplaceString(name, sizeof(name), "\"", "");
]
* Changed SQL_Query on SQL_TQuery Functions, Helper: - dalto
* Added Debug Mode for MySQL Queries: new DEBUG = 0;
* Added: new String:steamIdSave[64][255]; for Player Disconnect useage in: SQL_TQuery
* Added: if(hndl == INVALID_HANDLE) function check in all: SQL_TQuery

MySQL Query:

CREATE TABLE `rank_go1`(
`rank_id` int(64) NOT NULL auto_increment,
`steamId` varchar(32) NOT NULL default '',
`nick` varchar(128) NOT NULL default '',
`kills` int(12) NOT NULL default '0',
`deaths` int(12) NOT NULL default '0',
`assists` int(12) NOT NULL default '0',
`headshots` int(12) NOT NULL default '0',
`sucsides` int(12) NOT NULL default '0',
`last_active` int(12) NOT NULL default '0',
`played_time` int(12) NOT NULL default '0',
PRIMARY KEY  (`rank_id`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8;

database.cfg

	"csgo_rank"
	{
		"driver"			"default"
		//"host"			"localhost"
		"host"				"127.0.0.1"
		"database"			"rank"
		"user"				"root"
		"pass"				"root"
		//"timeout"			"0"
		"port"				"3306"
	}

*************************************************************************** */

// KOLOROWE KREDKI
//#define YELLOW 0x01
//#define GREEN 0x04

// DEBUG MODE (1 = ON, 0 = OFF)
new DEBUG = 0;

// SOME DEFINES
#define MAX_LINE_WIDTH 60
#define PLUGIN_VERSION "1.4"

// STATS TIME (SET DAYS AFTER STATS ARE DELETE OF NONACTIVE PLAYERS)
#define PLAYER_STATSOLD 30

// STATS DEFINATION FOR PLAYERS
new Kills[64];
new Deaths[64];
new Assists[64];
new HeadShots[64];
new SucSides[64];
new userInit[64];
new userFlood[64];
new userPtime[64];
new String:steamIdSave[64][255];

// HANDLE OF DATABASE
new Handle:db;

public Plugin:myinfo = 
{
	name = "Simple CS:S Rank",
	author = "graczu",
	description = "Simple CS:S Rank System based on MYSQL",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	RegConsoleCmd("say", Command_Say);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_hurt", EventPlayerHurt);
	SQL_TConnect(LoadMySQLBase, "csgo_rank");
	
	HookEvent("player_spawn", eventPlayerSpawn);
}

public LoadMySQLBase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Failed to connect: %s", error)
		db = INVALID_HANDLE;
		return;
	} else {
		PrintToServer("DEBUG: DatabaseInit (CONNECTED)");
	}

	db = hndl;
	decl String:query[1024];
	decl String:query2[1024];
	FormatEx(query, sizeof(query), "SET NAMES \"UTF8\"");
	SQL_TQuery(db, SQLErrorCheckCallback, query);
	FormatEx(query2, sizeof(query2), "DELETE FROM rank_go1 WHERE last_active <= %i", GetTime() - PLAYER_STATSOLD * 12 * 60 * 60);
	SQL_TQuery(db, SQLErrorCheckCallback, query2);
}


public OnClientAuthorized(client, const String:auth[])
{
	InitializeClient(client);
}


public InitializeClient( client )
{
	if (!IsFakeClient(client))
	{
		Kills[client]=0;
		Deaths[client]=0;
		Assists[client]=0;
		HeadShots[client]=0;
		SucSides[client]=0;
		userFlood[client]=0;
		userPtime[client]=GetTime();
		decl String:steamId[64];
		GetClientAuthString(client, steamId, sizeof(steamId));
		steamIdSave[client] = steamId;
		CreateTimer(25.0, initPlayerBase, client);
	}
}

public Action:initPlayerBase(Handle:timer, any:client){
		if (db != INVALID_HANDLE)
		{
			decl String:buffer[200];
			Format(buffer, sizeof(buffer), "SELECT * FROM rank_go1 WHERE steamId = '%s'", steamIdSave[client]);
			if(DEBUG == 1){
				PrintToServer("DEBUG: Action:initPlayerBase (%s)", buffer);
			}
			SQL_TQuery(db, SQLUserLoad, buffer, client);
		}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		saveUser(client);
	}

	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new assisterId = GetEventInt(event, "assister");
	
	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);
	new assister = GetClientOfUserId(assisterId);

	if(victim != attacker){
		Kills[attacker]++;
		Assists[assister]++;
		Deaths[victim]++;

	} else {
		SucSides[victim]++;
		Deaths[victim]++;
	}
}

public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attackerId = GetEventInt(event, "attacker");
	new hitgroup = GetEventInt(event,"hitgroup");

	new attacker = GetClientOfUserId(attackerId);

	if ( hitgroup == 1 )
	{
		HeadShots[attacker]++;
	}
}


public OnClientDisconnect (client)
{
	if ( !IsFakeClient(client) && userInit[client] == 1)
	{		
		if (db != INVALID_HANDLE)
		{
			saveUser(client);
			userInit[client] = 0;
		}
	}
}

public saveUser(client){
	if ( !IsFakeClient(client) && userInit[client] == 1)
	{		
		if (db != INVALID_HANDLE)
		{
			new String:buffer[200];
			Format(buffer, sizeof(buffer), "SELECT * FROM rank_go1 WHERE steamId = '%s'", steamIdSave[client]);
			if(DEBUG == 1){
				PrintToServer("DEBUG: saveUser (%s)", buffer);
			}
			SQL_TQuery(db, SQLUserSave, buffer, client);
		}
	}
}

public Action:Command_Say(client, args){

	decl String:text[192], String:command[64];

	new startidx = 0;

	GetCmdArgString(text, sizeof(text));

	if (text[strlen(text)-1] == '"')
	{		
		text[strlen(text)-1] = '\0';
		startidx = 1;	
	} 	
	if (strcmp(command, "say2", false) == 0)

	startidx += 4;

	if (strcmp(text[startidx], "rank", false) == 0)	{
		if(userFlood[client] != 1){
			saveUser(client);
			GetMyRank(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			CPrintToChat(client,"{GREEN}请{PINK}勿{LIGHTGREEN}灌{RED}水{LIGHTGREEN}!");
		}
	} else	if (strcmp(text[startidx], "top10", false) == 0)
	{		
		if(userFlood[client] != 1){
			saveUser(client);
			showTOP(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			CPrintToChat(client,"{GREEN}请{PINK}勿{LIGHTGREEN}灌{RED}水{LIGHTGREEN}!");
		}
	} else	if (strcmp(text[startidx], "headhunters", false) == 0)
	{		
		if(userFlood[client] != 1){
			saveUser(client);
			showTOPHeadHunter(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			CPrintToChat(client,"{GREEN}请{PINK}勿{LIGHTGREEN}灌{RED}水{LIGHTGREEN}!");
		}
	}
	return Plugin_Continue;
}

public Action:removeFlood(Handle:timer, any:client){
	userFlood[client]=0;
}

public GetMyRank(client){
	if (db != INVALID_HANDLE)
	{
		if(userInit[client] == 1){

			decl String:buffer[200];
			Format(buffer, sizeof(buffer), "SELECT `kills`, `deaths`, `assists`, `headshots`, `sucsides` FROM `rank_go1` WHERE `steamId` = '%s' LIMIT 1", steamIdSave[client]);
			if(DEBUG == 1){
				PrintToServer("DEBUG: GetMyRank (%s)", buffer);
			}
			SQL_TQuery(db, SQLGetMyRank, buffer, client);

		} else {

			CPrintToChat(client,">> {PINK}请稍等，{RED}正在载入你的 {GREEN}战绩和排名{LIGHTGREEN}.");

		}
	} else {
		CPrintToChat(client, "Rank System is now not avilable");
	}
}

public showTOP(client){

	if (db != INVALID_HANDLE)
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT *, (`deaths`/(`kills`+(`assists`/2))) / `played_time` AS rankn FROM `rank_go1` WHERE `kills` > 0 AND `deaths` > 0 ORDER BY rankn ASC LIMIT 10");
		if(DEBUG == 1){
			PrintToServer("DEBUG: showTOP (%s)", buffer);
		}
		SQL_TQuery(db, SQLTopShow, buffer, client);
	} else {
		CPrintToChat(client, "Rank System is now not avilable");
	}
}

public showTOPHeadHunter(client){

	if (db != INVALID_HANDLE)
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT * FROM rank_go1 ORDER BY headshots DESC LIMIT 10");
		if(DEBUG == 1){
			PrintToServer("DEBUG: showTOPHeadHunter (%s)", buffer);
		}
		SQL_TQuery(db, SQLTopShowHS, buffer, client);
	} else {
		CPrintToChat(client, "Rank System is now not avilable");
	}
}

public TopMenu(Handle:menu, MenuAction:action, param1, param2)
{
}

// ================================================================================

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		PrintToServer("Last Connect SQL Error: %s", error);
	}
}


public SQLUserLoad(Handle:owner, Handle:hndl, const String:error[], any:client){
	if (!IsClientInGame(client)) return;

	if(SQL_FetchRow(hndl))
	{
		decl String:name[MAX_LINE_WIDTH];
		GetClientName( client, name, sizeof(name) );

		ReplaceString(name, sizeof(name), "'", "");
		ReplaceString(name, sizeof(name), "<", "");
		ReplaceString(name, sizeof(name), "\"", "");

		decl String:buffer[512];
		Format(buffer, sizeof(buffer), "UPDATE rank_go1 SET nick = '%s', last_active = '%i' WHERE steamId = '%s'", name, GetTime(), steamIdSave[client])
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLUserLoad (%s)", buffer);
		}
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);

		userInit[client] = 1;
	} else {

		decl String:name[MAX_LINE_WIDTH];
		decl String:buffer[200];

		GetClientName( client, name, sizeof(name) );

		ReplaceString(name, sizeof(name), "'", "");
		ReplaceString(name, sizeof(name), "<", "");
		ReplaceString(name, sizeof(name), "\"", "");

		Format(buffer, sizeof(buffer), "INSERT INTO rank_go1 (steamId, nick, last_active) VALUES('%s','%s', '%i')", steamIdSave[client], name, GetTime())
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLUserLoad (%s)", buffer);
		}
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);

		userInit[client] = 1;
	}
}

public SQLUserSave(Handle:owner, Handle:hndl, const String:error[], any:client){
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}

	decl QueryReadRow_KILL;
	decl QueryReadRow_DEATHS;
	decl QueryReadRow_ASSISTS;
	decl QueryReadRow_HEADSHOTS;
	decl QueryReadRow_SUCSIDES;
	decl QueryReadRow_PTIME;

	if(SQL_FetchRow(hndl)) 
	{
		QueryReadRow_KILL=SQL_FetchInt(hndl,3) + Kills[client];
		QueryReadRow_DEATHS=SQL_FetchInt(hndl,4) + Deaths[client];
	        QueryReadRow_ASSISTS=SQL_FetchInt(hndl,5) + Assists[client];
		QueryReadRow_HEADSHOTS=SQL_FetchInt(hndl,6) + HeadShots[client];
		QueryReadRow_SUCSIDES=SQL_FetchInt(hndl,7) + SucSides[client];
		QueryReadRow_PTIME=SQL_FetchInt(hndl,9) + GetTime() - userPtime[client];
		Kills[client] = 0;
		Deaths[client] = 0;
		Assists[client] = 0;
		HeadShots[client] = 0;
		SucSides[client] = 0;
		userPtime[client] = GetTime();
		decl String:buffer[512];
		Format(buffer, sizeof(buffer), "UPDATE rank_go1 SET kills = '%i', deaths = '%i', assists = '%i', headshots = '%i', sucsides = '%i', played_time = '%i' WHERE steamId = '%s'", QueryReadRow_KILL, QueryReadRow_DEATHS, QueryReadRow_ASSISTS, QueryReadRow_HEADSHOTS, QueryReadRow_SUCSIDES, QueryReadRow_PTIME, steamIdSave[client])
		
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLUserSave (%s)", buffer);
		}

		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}

}

public SQLGetMyRank(Handle:owner, Handle:hndl, const String:error[], any:client){
	if (!IsValidClient(client)) return;
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
    
	decl RAkills;
	decl RAdeaths;
	decl RAassists;
	decl RAheadshots;
	//decl RAsucsides;

	if(SQL_FetchRow(hndl)) 
	{
		RAkills=SQL_FetchInt(hndl, 0);
		RAdeaths=SQL_FetchInt(hndl, 1);
		RAassists=SQL_FetchInt(hndl, 2);
		RAheadshots=SQL_FetchInt(hndl, 3);
		//RAsucsides=SQL_FetchInt(hndl, 4);
		decl String:buffer[512];
		//test
		// 0.00027144
		//STEAM_0:1:13462423
		Format(buffer, sizeof(buffer), "SELECT ((`deaths`/(`kills`+(`assists`/2)))/`played_time`) AS rankn FROM `rank_go1` WHERE (`kills` > 0 AND `deaths` > 0) AND ((`deaths`/(`kills`+(`assists`/2)))/`played_time`) < (SELECT ((`deaths`/(`kills`+(`assists`/2)))/`played_time`) FROM `rank_go1` WHERE steamId = '%s' LIMIT 1) AND `steamId` != '%s' ORDER BY rankn ASC", steamIdSave[client], steamIdSave[client]);
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLGetMyRank (%s)", buffer);
		}
		SQL_TQuery(db, SQLShowRank, buffer, client);
		if (!IsValidClient(client)) return;
		CPrintToChat(client,">> {PINK}你的战绩：{RED}杀敌: {GREEN}%i {NORMAL}| {RED}阵亡: {GREEN}%i {NORMAL}| {RED}助杀: {GREEN}%i {NORMAL}| {RED}爆头: {GREEN}%i", RAkills, RAdeaths, RAassists, RAheadshots);
	} else {
		CPrintToChat(client, "Your rank is not avlilable!");
	}
}

public SQLShowRank(Handle:owner, Handle:hndl, const String:error[], any:client){
	if (!IsValidClient(client)) return;
	if (SQL_HasResultSet(hndl))
	{
		decl String:tag[64];
		new rows = SQL_GetRowCount(hndl);
		if(GetUserFlagBits(client) & ADMFLAG_ROOT) 
		{
			if (IsClientInGame(client))
			{
				Format(tag, sizeof(tag), "Ьδss.%d", rows);
				CS_SetClientClanTag(client, tag);
			}
		}
		else if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1)	//o权限
		{
			if (IsClientInGame(client))
			{
				Format(tag, sizeof(tag), "adm!n.%d", rows);
				CS_SetClientClanTag(client, tag);
			}
		}
		else if (GetUserFlagBits(client) & ADMFLAG_CUSTOM2)	//P权限
		{
			if (IsClientInGame(client))
			{
				Format(tag, sizeof(tag), "OP.%d", rows);
				CS_SetClientClanTag(client, tag);
			}
		}
		else if (GetUserFlagBits(client) & ADMFLAG_CUSTOM3)	//q权限
		{
			if (IsClientInGame(client))
			{
				Format(tag, sizeof(tag), "SVIP.%d", rows);
				CS_SetClientClanTag(client, tag);
			}
		}
		else if (GetUserFlagBits(client) & ADMFLAG_RESERVATION)	//a权限
		{
			if (IsClientInGame(client))
			{
				Format(tag, sizeof(tag), "VIP.%d", rows);
				CS_SetClientClanTag(client, tag);
			}
		} else { 
			if (IsClientInGame(client))
			{
				Format(tag, sizeof(tag), "Top-%d", rows);
				CS_SetClientClanTag(client, tag);
			}
		}
		
		CPrintToChat(client,">> {PINK}你的排名：{RED}第 {GREEN}%i {RED}名{LIGHTGREEN}.", rows);
	}
}

public Action:eventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	if (IsValidClient(client))
	{
		GetMyRank(client);
	}
}

public SQLTopShow(Handle:owner, Handle:hndl, const String:error[], any:client){

		if(hndl == INVALID_HANDLE)
		{
			LogError(error);
			PrintToServer("Last Connect SQL Error: %s", error);
			return;
		}

		new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
		new String:text[128];
		Format(text,127,"TOP 10");
		SetPanelTitle(Panel,text);

		decl row;
		decl String:name[64];
		decl kills;
		decl deaths;
		decl assists;

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
				row++
				SQL_FetchString(hndl, 2, name, sizeof(name));
				kills=SQL_FetchInt(hndl,3);
				deaths=SQL_FetchInt(hndl,4);
				assists=SQL_FetchInt(hndl,5);
				Format(text,127,"%d) %s", row, name);
				DrawPanelText(Panel, text);
				Format(text,127,"杀敌: %i - 阵亡: %i - 助杀: %i", kills, deaths, assists);
				DrawPanelText(Panel, text);

			}
		} else {
				Format(text,127,"TOP 10 为空!");
				DrawPanelText(Panel, text);
		}

		DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

		Format(text,59,"Exit")
		DrawPanelItem(Panel, text)
		
		SendPanelToClient(Panel, client, TopMenu, 20);

		CloseHandle(Panel);

}

public SQLTopShowHS(Handle:owner, Handle:hndl, const String:error[], any:client){

		if(hndl == INVALID_HANDLE)
		{
			LogError(error);
			PrintToServer("Last Connect SQL Error: %s", error);
			return;
		}

		new Handle:Panel = CreatePanel(GetMenuStyleHandle(MenuStyle_Radio));
		new String:text[128];
		Format(text,127,"Top 10 爆头");
		SetPanelTitle(Panel,text);

		decl row;
		decl String:name[64];
		decl shoths;
		decl ptimed;
		decl String:textime[64];

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
				row++
				SQL_FetchString(hndl, 2, name, sizeof(name));
				shoths=SQL_FetchInt(hndl,5);
				ptimed=SQL_FetchInt(hndl,8);

				if(ptimed <= 3600){
					Format(textime,63,"%i m.", ptimed / 60);
				} else if(ptimed <= 43200){
					Format(textime,63,"%i h.", ptimed / 60 / 60);
				} else if(ptimed <= 1339200){
					Format(textime,63,"%i d.", ptimed / 60 / 60 / 12);
				} else {
					Format(textime,63,"%i mo.", ptimed / 60 / 60 / 12 / 31);
				}

				Format(text,127,"%d: %s", row, name);
				DrawPanelText(Panel, text);
				Format(text,127,"爆头: %i - In Time: %s", shoths, textime);
				DrawPanelText(Panel, text);

			}
		} else {
				Format(text,127,"TOP 10 爆头排行 为空!");
				DrawPanelText(Panel, text);
		}

		DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

		Format(text,59,"Exit")
		DrawPanelItem(Panel, text)
		
		SendPanelToClient(Panel, client, TopMenu, 20);

		CloseHandle(Panel);

}
/*
PrintQueryData(Handle:query)
{
	if (!SQL_HasResultSet(query))
	{
		PrintToServer("Query Handle %x has no results", query)
		return
	}
	
	new rows = SQL_GetRowCount(query)
	new fields = SQL_GetFieldCount(query)
	
	decl String:fieldNames[fields][32]
	PrintToServer("Fields: %d", fields)
	for (new i=0; i<fields; i++)
	{
		SQL_FieldNumToName(query, i, fieldNames[i], 32)
		PrintToServer("-> Field %d: \"%s\"", i, fieldNames[i])
	}
	
	PrintToServer("Rows: %d", rows)
	decl String:result[255]
	new row
	while (SQL_FetchRow(query))
	{
		row++
		PrintToServer("Row %d:", row)
		for (new i=0; i<fields; i++)
		{
			SQL_FetchString(query, i, result, sizeof(result))
			PrintToServer(" [%s] %s", fieldNames[i], result)
		}
	}
}
*/
bool:IsValidClient(client)
{
	if (!IsClientInGame(client)) return false;
	if (IsFakeClient(client)) return false;
	return true;
}
