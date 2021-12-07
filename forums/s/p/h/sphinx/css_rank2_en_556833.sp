#include <sourcemod>
#include <sdktools>

/* *********************************************************************

Thanks for people that help me:
- dalto (http://forums.alliedmods.net/member.php?u=29575)


Updates:
 * Anti Flood Protection (new userFlood[64];)
 * New announce message on: onClientPutInServer(client)
 * WWW sie Cvar ("sm_lrcss_www",)
 * PHP site nick protection:
 [		ReplaceString(name, sizeof(name), "'", "");
		ReplaceString(name, sizeof(name), "<?", "");
		ReplaceString(name, sizeof(name), "?>", "");
		ReplaceString(name, sizeof(name), "\"", "");
		ReplaceString(name, sizeof(name), "<?PHP", "");
		ReplaceString(name, sizeof(name), "<?php", "");
]
* Changed SQL_Query on SQL_TQuery Functions, Helper: - dalto
* Added Debug Mode for MySQL Queries: new DEBUG = 0;
* Added: new String:steamIdSave[64][255]; for Player Disconnect useage in: SQL_TQuery
* Added: if(hndl == INVALID_HANDLE) function check in all: SQL_TQuery



MySQL Query:

CREATE TABLE `css_rank`(
`rank_id` int(64) NOT NULL auto_increment,
`steamId` varchar(255) NOT NULL default '',
`nick` varchar(255) NOT NULL default '',
`kills` int(12) NOT NULL default '0',
`deaths` int(12) NOT NULL default '0',
`headshots` int(12) NOT NULL default '0',
`sucsides` int(12) NOT NULL default '0',
PRIMARY KEY  (`rank_id`));


*************************************************************************** */

// Colors
#define YELLOW 0x01
#define GREEN 0x04

// MySQL Queries DEBUG MODE 0 = off
new DEBUG = 0;

// defines
#define MAX_LINE_WIDTH 60
#define PLUGIN_VERSION "1.2"

// user stats based on ID
new Kills[64];
new Deaths[64];
new HeadShots[64];
new SucSides[64];
new userInit[64];
new userFlood[64];
new String:steamIdSave[64][255];

// mysql connection is ok
new Handle:db;

// www
new String:g_szWww[64];

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

	CreateConVar(
		"sm_lrcss_www",
		"http://your.site.url",
		"LRCSS www Page for this server.",
		FCVAR_PLUGIN
	);

	DatabaseInit();

}

public OnClientAuthorized(client, const String:auth[])
{
	InitializeClient(client);
}


public InitializeClient( client )
{
	if ( !IsFakeClient(client) )
	{
		Kills[client]=0;
		Deaths[client]=0;
		HeadShots[client]=0;
		SucSides[client]=0;
		userFlood[client]=0;
		decl String:steamId[64];
		GetClientAuthString(client, steamId, sizeof(steamId));
		steamIdSave[client] = steamId;
		CreateTimer(1.0, initPlayerBase, client);
		CreateTimer(15.0, publicMSGrank, client);
	}
}

public Action:initPlayerBase(Handle:timer, any:client){
		if (db != INVALID_HANDLE)
		{
			decl String:buffer[200];
			Format(buffer, sizeof(buffer), "SELECT * FROM css_rank WHERE steamId = '%s'", steamIdSave[client]);
			if(DEBUG == 1){
				PrintToServer("DEBUG: Action:initPlayerBase (%s)", buffer);
			}
			SQL_TQuery(db, SQLUserLoad, buffer, client);
		}
}

public Action:publicMSGrank(Handle:timer, any:client){
	if (db != INVALID_HANDLE && userInit[client] == 1)
	{
		GetConVarString(FindConVar("sm_lrcss_www"), g_szWww, sizeof(g_szWww));
		PrintToChat(client, "[RANK] available commands: /rank, /top10", GREEN, YELLOW);
/*		PrintToChat(client, "%c[LRCSS]%c Site with Statistics: %s", GREEN, YELLOW, g_szWww);*/
	} else {
		PrintToChat(client, "Rank System is now not avilable");
	}
}

public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{

	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	
	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);

	if(victim != attacker){
		Kills[attacker]++;
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
			Format(buffer, sizeof(buffer), "SELECT * FROM css_rank WHERE steamId = '%s'", steamIdSave[client]);
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
			GetMyRank(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			PrintToChat(client,"[RANK] Do not flood the server!");
		}
	} else	if (strcmp(text[startidx], "top10", false) == 0)
	{		
		if(userFlood[client] != 1){
			showTOP(client);
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			PrintToChat(client,"[RANK] Do not flood the server!");
		}
	} else	if (strcmp(text[startidx], "/rank", false) == 0)
	{
		if(userFlood[client] != 1){
			GetMyRank(client);	
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			PrintToChat(client,"[RANK] Do not flood the server!");
		}
	} else	if (strcmp(text[startidx], "/top10", false) == 0)	
	{
		if(userFlood[client] != 1){
			showTOP(client);	
			userFlood[client]=1;
			CreateTimer(10.0, removeFlood, client);
		} else {
			PrintToChat(client,"[RANK] Do not flood the server!");
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
			Format(buffer, sizeof(buffer), "SELECT kills, deaths, headshots, sucsides FROM css_rank WHERE steamId = '%s'", steamIdSave[client]);
			if(DEBUG == 1){
				PrintToServer("DEBUG: GetMyRank (%s)", buffer);
			}
			SQL_TQuery(db, SQLGetMyRank, buffer, client);

		} else {

			PrintToChat(client,"[RANK] Wait for system load you from database");

		}
	} else {
		PrintToChat(client, "Rank System is now not avilable");
	}
}

public showTOP(client){

	if (db != INVALID_HANDLE)
	{
		decl String:buffer[200];
		Format(buffer, sizeof(buffer), "SELECT * FROM css_rank ORDER BY kills DESC LIMIT 10");
		if(DEBUG == 1){
			PrintToServer("DEBUG: showTOP (%s)", buffer);
		}
		SQL_TQuery(db, SQLTopShow, buffer, client);
	} else {
		PrintToChat(client, "Rank System is now not avilable");
	}
}

public TopMenu(Handle:menu, MenuAction:action, param1, param2)
{
}


public DatabaseInit(){

		new String:error[255]
		db = SQL_DefConnect(error, sizeof(error))
		if (db == INVALID_HANDLE)
		{
			PrintToServer("Failed to connect: %s", error)
		} else {
			PrintToServer("DEBUG: DatabaseInit (CONNECTED)");
		}
		
		new Handle:queryBase = SQL_Query(db, "SELECT * FROM css_rank")
		if (queryBase == INVALID_HANDLE)
		{
			SQL_GetError(db, error, sizeof(error))
			PrintToServer("Failed to query: %s", error)
		} else {
			PrintToServer("DEBUG: DatabaseInit (NOT CONNECTED)");
			CloseHandle(queryBase)
		}
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
	if(SQL_FetchRow(hndl))
	{
		decl String:name[MAX_LINE_WIDTH];
		GetClientName( client, name, sizeof(name) );

		ReplaceString(name, sizeof(name), "'", "");
		ReplaceString(name, sizeof(name), "<?", "");
		ReplaceString(name, sizeof(name), "?>", "");
		ReplaceString(name, sizeof(name), "\"", "");
		ReplaceString(name, sizeof(name), "<?PHP", "");
		ReplaceString(name, sizeof(name), "<?php", "");


		decl String:buffer[512];
		Format(buffer, sizeof(buffer), "UPDATE css_rank SET nick = '%s' WHERE steamId = '%s'", name, steamIdSave[client])
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
		ReplaceString(name, sizeof(name), "<?", "");
		ReplaceString(name, sizeof(name), "?>", "");
		ReplaceString(name, sizeof(name), "\"", "");
		ReplaceString(name, sizeof(name), "<?PHP", "");
		ReplaceString(name, sizeof(name), "<?php", "");

		Format(buffer, sizeof(buffer), "INSERT INTO css_rank VALUES('','%s','%s','0','0','0','0')", steamIdSave[client], name)
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
	decl QueryReadRow_HEADSHOTS;
	decl QueryReadRow_SUCSIDES;

	if(SQL_FetchRow(hndl)) 
	{
		QueryReadRow_KILL=SQL_FetchInt(hndl,3) + Kills[client];
		QueryReadRow_DEATHS=SQL_FetchInt(hndl,4) + Deaths[client];
		QueryReadRow_HEADSHOTS=SQL_FetchInt(hndl,5) + HeadShots[client];
		QueryReadRow_SUCSIDES=SQL_FetchInt(hndl,6) + SucSides[client];


		decl String:buffer[512];
		Format(buffer, sizeof(buffer), "UPDATE css_rank SET kills = '%i', deaths = '%i', headshots = '%i', sucsides = '%i' WHERE steamId = '%s'", QueryReadRow_KILL, QueryReadRow_DEATHS, QueryReadRow_HEADSHOTS, QueryReadRow_SUCSIDES, steamIdSave[client])
		
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLUserSave (%s)", buffer);
		}

		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}

}

public SQLGetMyRank(Handle:owner, Handle:hndl, const String:error[], any:client){
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
    
	decl RAkills;
	decl RAdeaths;
	decl RAheadshots;
	decl RAsucsides;

	if(SQL_FetchRow(hndl)) 
	{
		RAkills=SQL_FetchInt(hndl,0);
		RAdeaths=SQL_FetchInt(hndl,1);
		RAheadshots=SQL_FetchInt(hndl,2);
		RAsucsides=SQL_FetchInt(hndl,3);
        
		decl String:buffer[512];
		Format(buffer, sizeof(buffer), "SELECT rank_id FROM css_rank WHERE kills >= '%i'", RAkills);
		if(DEBUG == 1){
			PrintToServer("DEBUG: SQLGetMyRank (%s)", buffer);
		}
		SQL_TQuery(db, SQLShowRank, buffer, client);
		PrintToChat(client,"Frags: %i | Deaths: %i | Headshots: %i | Sucsides: %i", RAkills, RAdeaths, RAheadshots, RAsucsides);
	} else {
		PrintToChat(client, "[STATS] Your rank is not available!");
	}
}

public SQLShowRank(Handle:owner, Handle:hndl, const String:error[], any:client){
		if (SQL_HasResultSet(hndl))
		{
			new rows = SQL_GetRowCount(hndl);
			PrintToChat(client,"Your rank is: %i.", rows);
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
		Format(text,127,"==[ Top 10 Players ]==");
		SetPanelTitle(Panel,text);

		decl row;
		decl String:name[64];
		decl kills;
		decl deaths;
		decl headshots;

		if (SQL_HasResultSet(hndl))
		{
			while (SQL_FetchRow(hndl))
			{
				row++
				SQL_FetchString(hndl, 2, name, sizeof(name));
				kills=SQL_FetchInt(hndl,3);
				deaths=SQL_FetchInt(hndl,4);
				headshots=SQL_FetchInt(hndl,5);
				Format(text,127,"->%d. %s", row, name);
				DrawPanelText(Panel, text);
				Format(text,127," K: %i - D: %i - Hs: %i", kills, deaths, headshots);
				DrawPanelText(Panel, text);

			}
		} else {
				Format(text,127,"Top 10 is empty!");
				DrawPanelText(Panel, text);
		}

		DrawPanelItem(Panel, " ", ITEMDRAW_SPACER|ITEMDRAW_RAWLINE);

		Format(text,59,"Exit")
		DrawPanelItem(Panel, text)
		
		SendPanelToClient(Panel, client, TopMenu, 20);

		CloseHandle(Panel);

}