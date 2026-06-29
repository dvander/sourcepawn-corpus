// 2023 • noil.lt • https://github.com/noillt

#include <sourcemod>
#include <morecolors>

#pragma newdecls required
#define DB_NAME "maptier-db"

// Prepare for database connection
Database g_db;

// Additional variables
char g_currentMap[128];
int g_mapTier;

// Plugin info
public Plugin myinfo = {
    name = "Map Tier",
    author = "noil.lt",
    description = "Get current surf map tier",
    version = "0.0.5",
    url = "https://noil.lt/"
};

// Needed for morecolors.inc
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
    MarkNativeAsOptional("GetUserMessageType");
    return APLRes_Success;
} 

public void OnPluginStart() {
    AutoExecConfig(true);

    RegConsoleCmd("sm_tier", Command_Tier);
    LoadTranslations("maptier.phrases.txt");

    ConnectToDB();
}

void ConnectToDB() {
    if (!SQL_CheckConfig(DB_NAME)) {
        LogError("[maptier] Database config for 'maptier' not found in sourcemod/configs/databases.cfg");
        return;
    }
    Database.Connect(DB_OnConnect, DB_NAME);
}

void DB_OnConnect(Database i_db, const char[] error, any data) {
    if (i_db == null || error[0]){
        LogError("[maptier] Connection to the database failed. Error: %s", error);
        return;
    }
    g_db = i_db;
}

void GetMapTier(Database i_db, int client, char[] i_mapname) {
    DataPack i_data = new DataPack();
    i_data.WriteCell(GetClientUserId(client));
    i_data.WriteString(i_mapname);

    char mapTierQuery[100];
    FormatEx(mapTierQuery, sizeof(mapTierQuery), "SELECT tier FROM maps WHERE mapname = '%s'", i_mapname);
    // Run the query
    i_db.Query(c_GetMapTier, mapTierQuery, i_data);
}

public void c_GetMapTier(Database i_db, DBResultSet i_results, const char[] error, DataPack i_data) {
    if (i_db == null || i_results == null || error[0] != '\0') {
        LogError("[maptier] Query failed! %s", error);
    }

    if (!i_results.FetchRow()) {
        g_mapTier = 0;
    } else {
        g_mapTier = i_results.FetchInt(0);
    }

    i_data.Reset();
    int client = GetClientOfUserId(i_data.ReadCell());
    if (!client) {
        delete i_data;
        return;
    }

    char i_mapname[128];
    i_data.ReadString(i_mapname, sizeof(i_mapname));

    if (g_mapTier == 0) {
        // If the query returned a 0 that means the map was not found in the database
        MC_PrintToChat(client, "%t", "MapTierNotFound", i_mapname);
        delete i_data;
        return;
    }

    MC_PrintToChatAll("%t", "CurrentMapTier", i_mapname, g_mapTier);
    delete i_data;
}

public void OnMapStart() {
    GetCurrentMap(g_currentMap, sizeof(g_currentMap));
}

public Action Command_Tier(int client, int args) {
    char i_arg[128];
    char mapname[128];

    GetCmdArg(1, i_arg, sizeof(i_arg));
    if (args >= 1) {
        mapname = i_arg;
    } else {
        if (IsNullString(g_currentMap)) {
            GetCurrentMap(g_currentMap, sizeof(g_currentMap));
        }
        mapname = g_currentMap;
    }

    GetMapTier(g_db, client, mapname)
    return Plugin_Handled; 
}