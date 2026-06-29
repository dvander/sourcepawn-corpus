#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Player Announcer",
	author = "Fire-Games.ru",
	description = "Player Announcer",
	version = PLUGIN_VERSION,
	url = "http://www.fire-games.ru/"
};

new Handle:db = INVALID_HANDLE;
new Handle:g_Enabled = INVALID_HANDLE;
new Handle:g_DatabaseConfig = INVALID_HANDLE;
new Handle:g_ServerID = INVALID_HANDLE;
new Handle:g_hCenterText[MAXPLAYERS + 1];
new String:sm_player_announcer_dbconfig[32], String:sm_player_announcer_serverid[32];
static g_iSColors[5]             = {1,               3,              4,         6,			5};
static String:g_sSColors[5][13]  = {"{DEFAULT}",     "{LIGHTGREEN}", "{GREEN}", "{YELLOW}",	"{OLIVE}"};
static g_iTColors[13][3]         = {{255, 255, 255}, {255, 0, 0},    {0, 255, 0}, {0, 0, 255}, {255, 255, 0}, {255, 0, 255}, {0, 255, 255}, {255, 128, 0}, {255, 0, 128}, {128, 255, 0}, {0, 255, 128}, {128, 0, 255}, {0, 128, 255}};
static String:g_sTColors[13][12] = {"{WHITE}",       "{RED}",        "{GREEN}",   "{BLUE}",    "{YELLOW}",    "{PURPLE}",    "{CYAN}",      "{ORANGE}",    "{PINK}",      "{OLIVE}",     "{LIME}",      "{VIOLET}",    "{LIGHTBLUE}"};

public OnPluginStart()
{
	CreateConVar("sm_player_announcer_version", PLUGIN_VERSION, "Player Announcer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
   	g_Enabled = CreateConVar("sm_player_announcer_enable", "1", "Enables this plugin");
   	g_ServerID = CreateConVar("sm_player_announcer_serverid", "all", "Server ID for multiservers projects. Eg 1,2,3,CSDDM,public..., 'all' - for all servers, 'off' - Inactive this record");
   	g_DatabaseConfig = CreateConVar("sm_player_announcer_dbconfig", "player_announcer", "Name of database config in database.cfg");
   	AutoExecConfig(true, "player_announcer");
    }
public OnConfigsExecuted()
{
    if (!GetConVarBool(g_Enabled)) return;
    GetConVarString(g_DatabaseConfig, sm_player_announcer_dbconfig, 32);
    GetConVarString(g_ServerID, sm_player_announcer_serverid, 32);
    if (db != INVALID_HANDLE) CloseHandle(db);
    ConnectToMysql();
}

stock MysqlStart()
{
    new String:sql[128];
    Format(sql, sizeof(sql), "SELECT sound FROM player_announcer WHERE server_id='%s' OR server_id=0 AND server_id!='off'", sm_player_announcer_serverid);
    new Handle:hQuery = SQL_Query(db, sql);
    if (hQuery == INVALID_HANDLE) {
        LogError("Query failed! %s", sql);
    } else {
    decl String:sound[128],String:downloadFile[128];
    while (SQL_FetchRow(hQuery))
	{
        SQL_FetchString(hQuery, 0, sound, 128);
       	if (strlen(sound) > 1) {
        	Format(downloadFile, 128, "sound/%s", sound);
                if(!FileExists(downloadFile,true) && !FileExists(downloadFile,false)){
                    LogError("File not found - %s" , downloadFile);
                }else{
        	        PrecacheSound(sound, true);
        	        AddFileToDownloadsTable(downloadFile);
                }
    	}
    }
}
}

CheckPlayer(userid, const String:auth[])	{
	decl String:query[256];
	Format(query, sizeof(query), "SELECT steam_id,chat_text,top_text,center_text,menu_text,hint_text,sound FROM player_announcer WHERE steam_id='%s' AND server_id!='off' AND (server_id='%s' OR server_id='all')", auth, sm_player_announcer_serverid);
	CreateTimer(5.0, Timer_DelayStart2);
	SQL_TQuery(db, T_CheckPlayer, query, userid);
}

public OnClientPostAdminCheck(client)	{
    if (!GetConVarBool(g_Enabled) || !IsClientInGame(client) || IsFakeClient(client)) return;
    decl String:steamid[32];
    GetClientAuthString(client, steamid, sizeof(steamid));
    CheckPlayer(client,steamid);
}

public Action:Timer_DelayStart2(Handle:timer)
{
   return;



}
public T_CheckPlayer(Handle:owner, Handle:hndl, const String:error[], any:client)	{
 	if (!IsClientConnected(client))    {
        return;
    }
	if (hndl == INVALID_HANDLE)	{
		LogError("Query failed! %s", error);
	}
	else if (SQL_FetchRow(hndl))	{
        decl String:text[256],String:buffer[128],String:sColor[16],String:name[64];
        GetClientName(client, name, 64);

        // exist sound ?

        SQL_FetchString(hndl, 6, text, 256);
        if (strlen(text)>1) EmitSoundToAll(text);

        // Chat text

        SQL_FetchString(hndl, 1, text, 256);
        if (!StrEqual(text, "")) {
		if (StrContains(text, "\\n") != -1) {
			Format(buffer, sizeof(buffer), "%c", 13);
			ReplaceString(text, sizeof(text),"\\n",buffer);
		}
		if (StrContains(text, "{NAME}") != -1) {
			ReplaceString(text, sizeof(text),"{NAME}",name);
		}
        	for (new c = 0; c < sizeof(g_iSColors); c++)
        	{
        		if ( StrContains(text, g_sSColors[c]) != -1 )
        		{
        			Format(sColor, sizeof(sColor), "%c", g_iSColors[c]);
        			ReplaceString(text, sizeof(text), g_sSColors[c], sColor);
        		}
        	}
                PrintToChatAll(text);
        }

        // Top text

        SQL_FetchString(hndl, 2, text, 256);
        if (!StrEqual(text, "")) {
		if (StrContains(text, "{NAME}") != -1) ReplaceString(text, sizeof(text),"{NAME}",name);
		new iColor = -1, iPos = BreakString(text, sColor, sizeof(sColor));
		for (new i = 0; i < sizeof(g_sTColors); i++){
		    if (StrEqual(sColor, g_sTColors[i])) iColor = i;
		}
		if (iColor == -1) {
		    iPos     = 0;
		    iColor   = 0;
		}
		new Handle:hKv = CreateKeyValues("Stuff", "title", text[iPos]);
		KvSetColor(hKv, "color", g_iTColors[iColor][0], g_iTColors[iColor][1], g_iTColors[iColor][2], 255);
		KvSetNum(hKv,   "level", 1);
		KvSetNum(hKv,   "time",  10);
		for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) {
		    if (IsClientInGame(i) && !IsFakeClient(i)) {
			    CreateDialog(i, hKv, DialogType_Msg);
			}
		}
		CloseHandle(hKv);
        }

        // Center text

        SQL_FetchString(hndl, 3, text, 256);
        if (!StrEqual(text, "")) {
		if (StrContains(text, "{NAME}") != -1) ReplaceString(text, sizeof(text),"{NAME}",name);
		for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) {
		    if (IsClientInGame(i) && !IsFakeClient(i)) {
		        PrintCenterText(i,text);
                        new Handle:hCenterAd;
                        g_hCenterText[i] = CreateDataTimer(1.0, Timer_CenterText, hCenterAd, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
                        WritePackCell(hCenterAd,i); WritePackString(hCenterAd,text);
            }
        }
        }

        // Menu text

        SQL_FetchString(hndl, 4, text, 256);
        if (!StrEqual(text, "")) {
		if (StrContains(text, "\\n") != -1) {
			Format(buffer, sizeof(buffer), "%c", 13);
			ReplaceString(text, sizeof(text),"\\n",buffer);
		}
		if (StrContains(text, "{NAME}") != -1) ReplaceString(text, sizeof(text),"{NAME}",name);
		new Handle:hPl = CreatePanel();
		DrawPanelText(hPl, text);
		SetPanelCurrentKey(hPl, 10);
		for (new i = 1, iClients = GetClientCount(); i <= iClients; i++) {
            if (IsClientInGame(i) && !IsFakeClient(i))
                SendPanelToClient(hPl, i, Handler_DoNothing, 10);
        }
		CloseHandle(hPl);
        }

        // Hint text

        SQL_FetchString(hndl, 5, text, 256);
        if (!StrEqual(text, ""))
		if (StrContains(text, "{NAME}") != -1) {
			ReplaceString(text, sizeof(text),"{NAME}",name);
		}
        PrintHintTextToAll(text);

	}
        CloseHandle(hndl);
}

public OnPluginEnd()
{
    if(db != INVALID_HANDLE){
        CloseHandle(db);
    }
}

stock ConnectToMysql() {
    if(db != INVALID_HANDLE){
        CloseHandle(db);
    }    SQL_TConnect(OnSqlConnect,sm_player_announcer_dbconfig);
}

public OnSqlConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
	{
		LogError("Database connect failure: %s", error);
		LogError("plugins/player_announcer.smx was unloaded");
 		ServerCommand("sm plugins unload player_announcer");
	} else {
        db = hndl;
        decl String:buffer[1024];
        Format(buffer, sizeof(buffer), "CREATE TABLE IF NOT EXISTS `player_announcer` (  `id` mediumint(8) unsigned NOT NULL AUTO_INCREMENT,  `steam_id` varchar(24) NOT NULL,  `chat_text` varchar(256) NOT NULL,  `top_text` varchar(256) NOT NULL,  `center_text` varchar(256) NOT NULL,  `menu_text` varchar(256) NOT NULL,  `hint_text` varchar(256) NOT NULL,  `sound` varchar(256) NOT NULL,   `server_id` varchar(16) NOT NULL DEFAULT 'all',  PRIMARY KEY (`id`)) ENGINE=MyISAM  DEFAULT CHARSET=utf8 AUTO_INCREMENT=1 ;");
        SQL_FastQuery(db, buffer);
     	FormatEx(buffer, sizeof(buffer), "SET NAMES \"UTF8\"");
        SQL_Query(db, buffer);
        MysqlStart();
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2) {}
public Action:Timer_CenterText(Handle:timer, Handle:pack) {
	decl String:sText[256];
	static iCount = 0;
	ResetPack(pack);
	new iClient = ReadPackCell(pack);
	ReadPackString(pack, sText, sizeof(sText));
	if (IsClientInGame(iClient) && ++iCount < 5) {
		PrintCenterText(iClient, sText);
		return Plugin_Continue;
	} else {
		iCount = 0;
		g_hCenterText[iClient] = INVALID_HANDLE;
		return Plugin_Stop;
	}
}