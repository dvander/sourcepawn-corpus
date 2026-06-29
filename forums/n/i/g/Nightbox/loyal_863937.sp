#pragma semicolon 1
#include <sourcemod>
#include <tf2_stocks>
new Handle:db = INVALID_HANDLE;
new bool:sqlite = false;
new Handle:g_hKv = INVALID_HANDLE;
new kills[MAXPLAYERS+1];
new assists[MAXPLAYERS+1];
new timep[MAXPLAYERS+1];
new joined[MAXPLAYERS+1];
new spent[MAXPLAYERS+1];
public OnPluginStart() {
	decl String:error[256];
	if(SQL_CheckConfig("loyal")) {
		db = SQL_Connect("loyal", true, error, sizeof(error));
	} else {
		db = SQL_Connect("storage-local", true, error, sizeof(error));
	}
	if(db==INVALID_HANDLE) {
		LogError("Could not connect to database: %s", error);
		return;
	}
	decl String:ident[16];
	SQL_ReadDriver(db, ident, sizeof(ident));
	if(strcmp(ident, "mysql", false)==0) {
		sqlite = false;
	} else if(strcmp(ident, "sqlite", false)==0) {
		sqlite = true;
	} else {
		LogError("Invalid database.");
		return;
	}
	if(sqlite) {
		SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS loyal (steamid TEXT, kills INTEGER, assists INTEGER, time INTEGER, spent INTEGER)");
	} else {
		SQL_TQuery(db, SQLErrorCheckCallback, "CREATE TABLE IF NOT EXISTS loyal (steamid varchar(32) NOT NULL, kills int(8) NOT NULL, assists int(8) NOT NULL, time int(8) NOT NULL, spent int(8) NOT NULL)");
	}
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_loyal", Command_loyal, "See someone's loyalty points.");
	//RegConsoleCmd("sm_ladd", Command_add, "See someone's loyalty points.");
	HookEvent("player_death", Event_player_death);
}
public OnMapStart() {
	if(g_hKv!=INVALID_HANDLE)
		CloseHandle(g_hKv);
	g_hKv = CreateKeyValues("Admins");
	decl String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "configs/admins.cfg");
	if(FileExists(path)) {
		FileToKeyValues(g_hKv, path);
		if(KvGotoFirstSubKey(g_hKv)) {
			new expires;
			do {
				expires = KvGetNum(g_hKv, "expires");
				if(expires!=0 && expires<GetTime())
					KvDeleteThis(g_hKv);
			} while(KvGotoNextKey(g_hKv));
			KvRewind(g_hKv);
			KeyValuesToFile(g_hKv, path);
		}
	} else {
		SetFailState("Can't find admins.cfg");
	}
}
public OnClientAuthorized(client) {
	decl String:clientid[32], String:query[256];
	new userid = GetClientUserId(client);
	GetClientAuthString(client, clientid, sizeof(clientid));
	Format(query, sizeof(query), "SELECT kills,assists,time,spent FROM loyal WHERE steamid='%s'", clientid);
	SQL_TQuery(db, SQLQueryConnect, query, userid);
	joined[client] = GetTime();
}
public OnClientDisconnect(client) {
	decl String:steamid[32], String:query[256];
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(query, sizeof(query), "UPDATE loyal SET kills=%i,assists=%i,time=time+%i,spent=%i WHERE steamid='%s'", kills[client], assists[client], GetTime()-joined[client], spent[client], steamid);
	SQL_TQuery(db, SQLErrorCheckCallback, query);
}
public Action:Command_loyal(client, args) {
	if(args==0) {
		new points = ((kills[client]+assists[client]+(timep[client]/60))/10)-spent[client];
		new Handle:menu = CreateMenu(Menu_buy);
		SetMenuTitle(menu, "You have %i loyalty points", points);
		AddMenuItem(menu, "300: 1 week reserved slot", "300: 1 week reserved slot", points<300?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		AddMenuItem(menu, "600: 2 weeks", "600: 2 weeks", points<600?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		AddMenuItem(menu, "1200: 1 month", "1200: 1 month", points<1200?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		AddMenuItem(menu, "2400: 2 months", "2400: 2 months", points<2400?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		AddMenuItem(menu, "3600: 3 months", "3600: 3 months", points<3600?ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
		SetMenuExitButton(menu, true);
		DisplayMenu(menu, client, 20);
	} else {
		decl String:argstr[64];
		GetCmdArgString(argstr, sizeof(argstr));
		new targ = FindTarget(0, argstr, false, false);
		if(targ!=-1)
			PrintToChat(client, "\x03%N\x01 has \x04%i\x01 loyalty points.", targ, ((kills[targ]+assists[targ]+(timep[targ]/60))/10)-spent[targ]);
	}
	return Plugin_Handled;
}
/*public Action:Command_add(client, args) {
	timep[client] += 999999;
	return Plugin_Handled;
}*/
public Menu_buy(Handle:menu, MenuAction:action, param1, param2) {
	if(action==MenuAction_End) {
		CloseHandle(menu);
	} else if(action!=MenuAction_Cancel) {
		switch(param2) {
			case 0: {
				AddReservedSlotTime(param1, 604800);
				spent[param1] += 300;
			}
			case 1: {
				AddReservedSlotTime(param1, 1209600);
				spent[param1] += 600;
			}
			case 2: {
				AddReservedSlotTime(param1, 2592000);
				spent[param1] += 1200;
			}
			case 3: {
				AddReservedSlotTime(param1, 5184000);
				spent[param1] += 2400;
			}
			case 4: {
				AddReservedSlotTime(param1, 7776000);
				spent[param1] += 3600;
			}
		}
	}
}
AddReservedSlotTime(client, time) {
	decl String:steamid[32], String:key[128];
	GetClientAuthString(client, steamid, sizeof(steamid));
	Format(key, sizeof(key), "%s_loyal", steamid);
	KvJumpToKey(g_hKv, key, true);
	new expires = KvGetNum(g_hKv, "expires");
	if(expires==0 || expires<GetTime()) {
		KvSetString(g_hKv, "auth", "steam");
		KvSetString(g_hKv, "identity", steamid);
		KvSetString(g_hKv, "flags", "a");
		expires = GetTime()+time;
		KvSetNum(g_hKv, "expires", expires);
	} else {
		expires += time;
		KvSetNum(g_hKv, "expires", expires);
	}
	KvRewind(g_hKv);
	decl String:path[256], String:duration[32];
	BuildPath(Path_SM, path, sizeof(path), "configs/admins.cfg");
	KeyValuesToFile(g_hKv, path);
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
public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new assister = GetClientOfUserId(GetEventInt(event, "assister"));
	if(attacker!=0)
		kills[attacker]++;
	if(assister!=0)
		assists[assister]++;
}
public SQLQueryConnect(Handle:owner, Handle:hndl, const String:error[], any:data) {
	new client;
	if((client = GetClientOfUserId(data))==0)
		return;
	if(hndl==INVALID_HANDLE) {
		LogError("Query failed: %s", error);
	} else {
		decl String:query[512], String:steamid[32];
		GetClientAuthString(client, steamid, sizeof(steamid));
		if(!SQL_MoreRows(hndl)) {
			if(sqlite) {
				Format(query, sizeof(query), "INSERT INTO loyal VALUES('%s', 0, 0, 0, 0)", steamid);
			} else {
				Format(query, sizeof(query), "INSERT INTO loyal (steamid, kills, assists, time, spent) VALUES ('%s', 0, 0, 0, 0)", steamid);
			}
			SQL_TQuery(db, SQLErrorCheckCallback, query);
			kills[client] = 0;
			assists[client] = 0;
			timep[client] = 0;
			spent[client] = 0;
		} else if(SQL_FetchRow(hndl)) {
			kills[client] = SQL_FetchInt(hndl, 0);
			assists[client] = SQL_FetchInt(hndl, 1);
			timep[client] = SQL_FetchInt(hndl, 2);
			spent[client] = SQL_FetchInt(hndl, 3);
		}
		PrintToChatAll("\x03%N\x01 has \x04%i\x01 loyalty points.", client, ((kills[client]+assists[client]+(timep[client]/60))/10)-spent[client]);
	}
}
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data) {
	if(!StrEqual("", error))
		LogError("Query failed: %s", error);
}