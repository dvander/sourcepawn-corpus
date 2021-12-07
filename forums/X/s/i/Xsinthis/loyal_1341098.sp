#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "2.1.1"

/*
* (2.1.1b)
* -Fixed typos in query to delete old entries
* -Added message for better tracking problems
*(2.1.0)
* -Droped _sourcebans suffix
* -Added automatic Sourceban checker(dropped sm_loyal_sourcebans)
* -Added flatfile support
* -Added fully automatic admin method detection(flatfile, sql, sourcebans)
* -Added admin group use for all methods(untested for MySQL admins)
* -Added bonus points column
* -Added command to modify user's points
* -Cleaned up minor coding issues
* 
* (2.0.4)
* - Fixed interpretation of use sourcebans cvar
*
* (2.0.3)
* -Fixed silly typo in version cvar
* -Fixed error in menu selection
*(2.0.2)
*-Fixed an error in a query to remove outdated entries
*
*(2.0.1)
*-Added sm_loyal_version cvar for plugin tracking and general information
*/
new Handle:db = INVALID_HANDLE;
new Handle:admdb =  INVALID_HANDLE;
new Handle:sm_loyal_version;
new bool:sqlite_db = false, bool:sqlite_admdb = false;
new kills[MAXPLAYERS+1];
new assists[MAXPLAYERS+1];
new timep[MAXPLAYERS+1];
new joined[MAXPLAYERS+1];
new spent[MAXPLAYERS+1];
new bonus[MAXPLAYERS+1];
new cost[13];
new killsReq, assistsReq, timeReq;
new bool:useSourcebans;
new bool:useFlatfile = false;
new String:userGroup[512], String:serverGroup[512];

public Plugin:myinfo =
{
	name = "Loyalty Plugin",
	author = "MikeJS, Sourceban compatibility added by Xsinthis`",
	description = "Users can get loyal points by playing on your server and they can buy slots with them",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=139036"
}

public OnPluginStart() {
	
	/* Now for the ConVars */
	new Handle:sm_loyal_user_group = CreateConVar("sm_loyal_user_group", "Loyal Members", "User group to add loyalty members too");
	new Handle:sm_loyal_server_group = CreateConVar("sm_loyal_server_group", "All Servers", "What Sourcebans Server Group to add loyalty members too(if applicable)");
	new Handle:sm_loyal_cost = CreateConVar("sm_loyal_cost", "300", "Loyalty point cost per week of reserved slot");
	new Handle:sm_loyal_kills = CreateConVar("sm_loyal_kills", "10", "Kills required per loyalty point(Warning: Changes in this are retroactive)");
	new Handle:sm_loyal_assists = CreateConVar("sm_loyal_assists", "10", "Assists required per loyalty point(Warning: Changes in this are retroactive)");
	new Handle:sm_loyal_time = CreateConVar("sm_loyal_time", "10", "Minutes of play required per loyalty point(Warning: Changes in this are retroactive)");
	sm_loyal_version = CreateConVar("sm_loyal_version", PLUGIN_VERSION, "Version of Loyalty Plugin installed, do not touch", FCVAR_NOTIFY);
	SetConVarString(sm_loyal_version, PLUGIN_VERSION);
	
	
	for(new i; i <= 12; i++) {
		cost[i] = GetConVarInt(sm_loyal_cost) * i;
	}
	
	GetConVarString(sm_loyal_server_group, serverGroup, sizeof(serverGroup));
	GetConVarString(sm_loyal_user_group, userGroup, sizeof(userGroup));
	killsReq = GetConVarInt(sm_loyal_kills);
	assistsReq = GetConVarInt(sm_loyal_assists);
	timeReq = GetConVarInt(sm_loyal_time);
	if(FindConVar("sb_version") == INVALID_HANDLE){
		useSourcebans = false;
		LogMessage("Did not fins Sourcebans, will use Sourcemod SQL admins if available");
	}else{
		useSourcebans = true;
		LogMessage("Found Sourcebans version, will continue using Sourcebans");
	}

	AutoExecConfig(true, "loyal", "sourcemod"); //Creates config file
	
	/*End of convars */
	
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_loyal", Command_loyal, "See someone's loyalty points."); //Registers console command
	RegAdminCmd("sm_loyal_modify", Command_modify, ADMFLAG_ROOT, "Modifies someone's points"); //Regist Admin command for modfying bonus points
	HookEvent("player_changename", Event_player_changename);
	HookEvent("player_death", Event_player_death);
	decl String:steamid[32];
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientConnected(i) && IsClientAuthorized(i)) {
			GetClientAuthString(i, steamid, sizeof(steamid));
			OnClientAuthorized(i, steamid);
		}
	}

	/*SQL Database Crap */
	decl String:error[256];
	if(SQL_CheckConfig("sourcebans")){
		admdb = SQL_Connect("sourcebans", true, error, sizeof(error));
		LogMessage("Connecting to Sourcebans database");
	}else if(SQL_CheckConfig("admins")){
		admdb = SQL_Connect("admins", true, error, sizeof(error));
		LogMessage("Connecting to Sourcemod SQL Admins datavase");
	}else{
		admdb = INVALID_HANDLE;
		useFlatfile = true;
		LogMessage("Could not find a database entry for Sourcebans or Sourcemod SQL admins, using flatfile");
	}
	
	if(SQL_CheckConfig("loyal")) {
		db = SQL_Connect("loyal", true, error, sizeof(error));
		LogMessage("Found loyal entry, using it for Loyal database");
	} else {
		db = SQL_Connect("storage-local", true, error, sizeof(error));
		LogMessage("Using default storage-local for Loyalty database");
	}
	if(db==INVALID_HANDLE)
		SetFailState("Could not connect to database: %s", error);
	
	decl String:ident[16];
	SQL_ReadDriver(db, ident, sizeof(ident));
	if(strcmp(ident, "mysql", false)==0) {
		sqlite_db = false;
	} else if(strcmp(ident, "sqlite", false)==0) {
		sqlite_db = true;
	} else {
		SetFailState("Invalid database.");
	}
	
	SQL_ReadDriver(admdb, ident, sizeof(ident));
	if(strcmp(ident, "mysql", false)==0){
		sqlite_admdb = false;
	}else if(strcmp(ident, "sqlite", false)==0) {
		sqlite_admdb = true;
	} else {
		SetFailState("Invalid database: sourcebans or admins or storage-local");
	}
	
	if(sqlite_db) {
		if(!useFlatfile){
			SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS loyal (name TEXT, steamid TEXT, kills INTEGER, assists INTEGER, time INTEGER, spent INTEGER, bonus INTEGER)");
		}else{
			SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS loyal (name TEXT, steamid TEXT, kills INTEGER, assists INTEGER, time INTEGER, spent INTEGER, bonus INTEGER, adminuntil INTEGER)");
		}
	}else {
		if(!useFlatfile){
			SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS loyal (name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, kills INT(8) NOT NULL, assists INT(8) NOT NULL, time INT(8) NOT NULL, spent INT(8) NOT NULL, bonus INT(8) NOT NULL)");
		}else{
			SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS loyal (name VARCHAR(32) NOT NULL, steamid VARCHAR(32) NOT NULL, kills INT(8) NOT NULL, assists INT(8) NOT NULL, time INT(8) NOT NULL, spent INT(8) NOT NULL, bonus INT(8) NOT NULL, adminuntil INT(11) NOT NULL)");
		}
	}
	/*End of SQL Database Crap */

	
}
public OnMapStart() {
	decl String:query[512];
	if(!useFlatfile){
		if(useSourcebans){
			Format(query, sizeof(query), "DELETE FROM sb_admins WHERE adminuntil<%i AND srv_group = '%s'", GetTime(), userGroup);
			SQL_TQuery(admdb, SQLErrorCheckCallback, query);
		}else{
			Format(query, sizeof(query), "DELETE FROM sm_admins WHERE adminuntil<%i AND immunity = 0", GetTime());
			SQL_TQuery(admdb, SQLErrorCheckCallback, query);
		}
	}else{
		Format(query, sizeof(query), "SELECT FROM loyal WHERE adminuntil<%i", GetTime());
		SQL_TQuery(db, SQLClearFlatfile, query);
	}
}
public OnClientAuthorized(client, const String:steamid[]) {
	if(!IsFakeClient(client)) {
		decl String:query[512];
		Format(query, sizeof(query), "SELECT kills,assists,time,spent,bonus FROM loyal WHERE steamid='%s'", steamid);
		SQL_TQuery(db, SQLQueryConnect, query, GetClientUserId(client));
		joined[client] = GetTime();
	}
}
public OnClientDisconnect(client) {
	if(!IsFakeClient(client)) {
		decl String:steamid[32], String:query[512];
		GetClientAuthString(client, steamid, sizeof(steamid));
		Format(query, sizeof(query), "UPDATE loyal SET kills=%i,assists=%i,time=time+%i,spent=%i WHERE steamid='%s'", kills[client], assists[client], GetTime()-joined[client], spent[client], steamid);
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}
}
public Action:Command_loyal(client, args) {
	if(args==0) {
		new points = (kills[client]/killsReq)+(assists[client]/assistsReq)+((timep[client]/60)/timeReq)-spent[client]+bonus[client];
		new Handle:menu = CreateMenu(Menu_buy);
		decl String:menuText[512];
		SetMenuTitle(menu, "You have %i loyalty points", points);
		Format(menuText, sizeof(menuText), "%i: 1 week of reserved slot", cost[1]);
		AddMenuItem(menu, menuText, menuText, points<cost[1]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		Format(menuText, sizeof(menuText), "%i: 2 weeks of reserved slot", cost[2]);
		AddMenuItem(menu, menuText, menuText, points<cost[2]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		Format(menuText, sizeof(menuText), "%i: 1 month of reserved slot", cost[4]);
		AddMenuItem(menu, menuText, menuText, points<cost[4]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		Format(menuText, sizeof(menuText), "%i: 2 months of reserved slot", cost[8]);
		AddMenuItem(menu, menuText, menuText, points<cost[8]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		Format(menuText, sizeof(menuText), "%i: 3 months of reserved slot", cost[12]);
		AddMenuItem(menu, menuText, menuText, points<cost[12]?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	} else {
		decl String:argstr[64];
		GetCmdArgString(argstr, sizeof(argstr));
		new targ = FindTarget(0, argstr, false, false);
		if(targ!=-1)
			PrintToChat(client, "\x03%N\x01 has \x04%i\x01 loyalty points.", targ, ((kills[targ]+assists[targ]+(timep[targ]/60))/10)-spent[targ]+bonus[targ]);
	}
	return Plugin_Handled;
}
public Action:Command_modify(client, args) 
{
	if (args < 2)
	{
		PrintToConsole(client, "Usage: sm_loyal_modify <NAME> <CHANGE>");
		return Plugin_Handled;
	}
	else
	{
		new String:arg1[32], String:arg2[32];
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		new String:name[32], change;
		GetCmdArg(1, name, sizeof(name));

		change = StringToInt(arg2);
		client = FindTarget(0, arg1, true, false);
		
		bonus[client] += change;
	}
	return Plugin_Handled;
}
public Menu_buy(Handle:menu, MenuAction:action, param1, param2) {
	if(action==MenuAction_End) {
		CloseHandle(menu);
	} else if(action!=MenuAction_Cancel) {
		switch(param2) {
			case 0: {
				AddReservedSlotTime(param1, 604800);
				spent[param1] += cost[1];
			}
			case 1: {
				AddReservedSlotTime(param1, 1209600);
				spent[param1] += cost[2];
			}
			case 2: {
				AddReservedSlotTime(param1, 2592000);
				spent[param1] += cost[4];
			}
			case 3: {
				AddReservedSlotTime(param1, 5184000);
				spent[param1] += cost[8];
			}
			case 4: {
				AddReservedSlotTime(param1, 7776000);
				spent[param1] += cost[12];
			}
		}
	}
}
public AddReservedSlotTime(client, time) {

	decl String:name[MAX_NAME_LENGTH], String:steamid[32], String:query[512], String:consoleCommand[512];
	new adminuntil, gid;
	GetClientName(client, name, sizeof(name));
	ReplaceString(name, sizeof(name), "'", "");
	GetClientAuthString(client, steamid, sizeof(steamid));
	if(!useFlatfile){
		if(sqlite_admdb) {
			Format(query, sizeof(query), "INSERT INTO sm_admins (authtype, identity, name, adminuntil) VALUES ('steam', '%s', '%s', %i) ON DUPLICATE KEY UPDATE adminuntil=adminuntil+%i", steamid, name, GetTime()+time, time, steamid);
		} else if (useSourcebans) {
			Format(query, sizeof(query), "INSERT INTO sb_admins (authid, user, immunity, srv_group, adminuntil) VALUES ('%s', '%s', 0, '%s', %i) ON DUPLICATE KEY UPDATE adminuntil=adminuntil+%i", steamid, name, userGroup, GetTime()+time, time);
		} else {
			Format(query, sizeof(query), "INSERT INTO sm_admins (authtype, identity, flags, name, immunity, adminuntil) VALUES ('steam', '%s', 'a', '%s', 0, %i) ON DUPLICATE KEY UPDATE adminuntil=adminuntil+%i", steamid, name, GetTime()+time, time, steamid);
		}
		SQL_TQuery(admdb, SQLErrorCheckCallback, query, DBPrio_High);
	}
	else{
		GetClientName(client, name, sizeof(name));
		CreateAdmin(name);
		AdminInheritGroup(GetUserAdmin(client), FindAdmGroup(userGroup));
		Format(query, sizeof(query), "SELECT adminuntil FROM loyal WHERE steamid='%s'", steamid);
		adminuntil = SQL_TQuery(db, SQLGetGID, query);
		if (adminuntil < GetTime()){
			Format(query, sizeof(query), "UPDATE loyal SET adminuntil=%i WHERE steamid='%s'", GetTime()+time, steamid);
		}else{
			Format(query, sizeof(query), "UPDATE loyal SET adminuntil=%i WHERE steamid='%s'", adminuntil+time, steamid);
		}
		SQL_TQuery(db, SQLErrorCheckCallback, query);
	}

	if(!useSourcebans && !useFlatfile){
		Format(query, sizeof(query), "SELECT id FROM sm_groups WHERE name='%s'", steamid);
		gid = SQL_TQuery(admdb, SQLGetGID, query);
		ServerCommand("sm_reloadadmins");
		Format(query, sizeof(query), "INSERT INTO sm_admins_groups (admin_id, group_id, inherit_order) VALUES (%i, %i, 0)", GetUserAdmin(client), gid);
		SQL_TQuery(admdb, SQLErrorCheckCallback, query);
		ServerCommand("sm_reloadadmins");
	}
	
	if (useSourcebans){
		Format(query, sizeof(query), "SELECT adminuntil FROM sb_admins WHERE steamid='%s'", steamid);
		SQL_TQuery(admdb, SQLAddTime, query);
		Format(query, sizeof(query), "SELECT aid FROM sb_admins WHERE authid = '%s'", steamid);
		SQL_TQuery(admdb, SQLAddServerPermission, query, client);
		Format(consoleCommand, sizeof(consoleCommand), "sm_rehash");
		ServerCommand(consoleCommand);
	}else if (!useFlatfile){
		Format(query, sizeof(query), "SELECT adminuntil FROM sm_admins WHERE steamid='%s'", steamid);
		SQL_TQuery(admdb, SQLAddTime, query);
	}
}
public Action:Event_player_changename(Handle:event, const String:name[], bool:dontBroadcast) {
	decl String:clientname[MAX_NAME_LENGTH], String:steamid[32], String:query[512];
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GetClientName(client, clientname, sizeof(clientname));
	ReplaceString(clientname, sizeof(clientname), "'", "");
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(query, sizeof(query), "UPDATE loyal SET name='%s' WHERE steamid='%s'", clientname, steamid);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
}
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	if(attacker!=0)
		kills[attacker]++;
	if(assister!=0)
		assists[assister]++;
}

public SQLAddServerPermission(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:query[512];
	Format(query, sizeof(query), "SELECT gid FROM sb_groups WHERE name = '%s'", serverGroup);
	new gid = SQL_TQuery(admdb, SQLGetGID, query);
	Format(query, sizeof(query), "SELECT id FROM sb_srvgroups WHERE name = '%s'", userGroup);
	new ugid = SQL_TQuery(admdb, SQLGetGID, query);
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed(SQLAddServerPermission)! %s", error);
		
	}
	else
	{
		if(SQL_FetchRow(hndl)) 
		{
			new aid = SQL_FetchInt(hndl, 0);
			if(!SQL_TQuery(admdb, SQLCheckServerPermission, query, aid))
			{
				Format(query, sizeof(query), "INSERT INTO sb_admins_servers_groups (admin_id, group_id, srv_group_id, server_id) VALUES ( %i, %i, %i, 0)", aid, ugid, gid);
				SQL_TQuery(admdb, SQLErrorCheckCallback, query);
			}
		}		
	}
}

public SQLCheckServerPermission(Handle:owner, Handle:hndl, const String:error[], any:aid)
{
	new bool:IsAidPresent;
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed(SQLCheckServerPermission)! %s", error);
	}
	else
	{
		while(SQL_FetchRow(hndl))
		{
			if((SQL_FetchInt(hndl, 0) == aid))
			{
				IsAidPresent = true;
				break;
			}
		}
	}
	return IsAidPresent;
}

public SQLGetGID(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new gid;
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed(SQLGetGID)! %s", error);
		
	}
	else
	{
		if(SQL_FetchRow(hndl)) 
		{
			gid = SQL_FetchInt(hndl, 0);
		}		
	}
	
	return gid;
}

public SQLClearFlatfile(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:steamid[512], String:comparedSteamId[512];
	while(SQL_FetchRow(hndl)){
		SQL_FetchString(hndl, 1, steamid, sizeof(steamid));
		for(new i = 1; i <= GetMaxClients(); i++){
			GetClientAuthString(i, comparedSteamId, sizeof(comparedSteamId));
			if (StrEqual(steamid, comparedSteamId, false)){
				RemoveAdmin(GetUserAdmin(i));
				break;
			}
		}
	}
}
public SQLQueryConnect(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0)
		return;
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed(SQLQueryConnect): %s", error);
	} else {
		decl String:query[512], String:clientname[MAX_NAME_LENGTH], String:steamid[32];
		GetClientName(client, clientname, sizeof(clientname));
		ReplaceString(clientname, sizeof(clientname), "'", "");
		GetClientAuthString(client, steamid, sizeof(steamid));
		if(!SQL_MoreRows(hndl)) {
			if(sqlite_db) {
				Format(query, sizeof(query), "INSERT INTO loyal VALUES('%s', '%s', 0, 0, 0, 0, 0)", clientname, steamid);
			} else {
				Format(query, sizeof(query), "INSERT INTO loyal (name, steamid, kills, assists, time, spent, bonus) VALUES ('%s', '%s', 0, 0, 0, 0, 0)", clientname, steamid);
			}
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			kills[client] = 0;
			assists[client] = 0;
			timep[client] = 0;
			spent[client] = 0;
			bonus[client] = 0;
		} else if(SQL_FetchRow(hndl)) {
			Format(query, sizeof(query), "UPDATE loyal SET name='%s' WHERE steamid='%s'", clientname, steamid);
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			kills[client] = SQL_FetchInt(hndl, 0);
			assists[client] = SQL_FetchInt(hndl, 1);
			timep[client] = SQL_FetchInt(hndl, 2);
			spent[client] = SQL_FetchInt(hndl, 3);
			bonus[client] = SQL_FetchInt(hndl, 4);
		}
		new points = (kills[client]/killsReq)+(assists[client]/assistsReq)+((timep[client]/60)/timeReq)-spent[client]+bonus[client];
		PrintToChatAll("\x03%N\x01 has \x04%i\x01 loyalty points.", client, points);
	}
}
public SQLAddTime(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0)
		return;
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed(SQLAddTime): %s", error);
	} else {
		new expires = SQL_FetchInt(hndl, 0);
		decl String:duration[32];
		expires = (expires-GetTime())/60;
		if(expires<60) {
			Format(duration, sizeof(duration), "%i min%s", expires, expires==1?"":"s");
		} else {
			new hours = expires/60;
			expires = expires%60;
			if(hours<24) {
				Format(duration, sizeof(duration), "%i hr%s %i min%s", hours, hours==1?"":"s", expires, expires==1?"":"s");
			} else {
				new days = hours/24;
				hours = hours%24;
				Format(duration, sizeof(duration), "%i day%s %i hr%s %i min%s", days, days==1?"":"s", hours, hours==1?"":"s", expires, expires==1?"":"s");
			}
		}
		PrintToChat(client, "\x01You have \x04%s\x01 remaining on your reserved slot.", duration);
	}
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if(!StrEqual("", error))
		LogError("Query failed(SQLErrorCheckCallback): %s", error);
}