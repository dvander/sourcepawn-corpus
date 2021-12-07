/*
CREATE TABLE IF NOT EXISTS whois_names (
    entry INT NOT NULL AUTO_INCREMENT,
    steam_id VARCHAR(64),
    name VARCHAR(128),
    permname VARCHAR(128),
    date DATE,
    PRIMARY KEY(entry)
);
*/
#include <sourcemod>
#include <multicolors>

Database g_Database = null;
bool g_Late = false;

public void OnPluginStart()
{
    Database.Connect(SQL_ConnectDatabase, "whois");
    HookEvent("player_changename", Event_ChangeName);

    RegAdminCmd("sm_whois", Command_ShowName, ADMFLAG_GENERIC, "View set name of a player");
    RegAdminCmd("sm_whois_full", Command_Activity, ADMFLAG_GENERIC, "View names of a player");
    RegAdminCmd("sm_thisis", Command_SetName, ADMFLAG_GENERIC, "Set name of a player");
    LoadTranslations("common.phrases");
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_Late = late;
}

public void CreateTable()
{
    char sQuery[1024] = "";
    StrCat(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS whois_names(");
    StrCat(sQuery, sizeof(sQuery), "entry INT NOT NULL AUTO_INCREMENT, ");
    StrCat(sQuery, sizeof(sQuery), "steam_id VARCHAR(64), ");
    StrCat(sQuery, sizeof(sQuery), "name VARCHAR(128), ");
    StrCat(sQuery, sizeof(sQuery), "date DATE, ");
    StrCat(sQuery, sizeof(sQuery), "PRIMARY KEY(entry)");
    StrCat(sQuery, sizeof(sQuery), ");");
    g_Database.Query(SQL_GenericQuery, sQuery);

    sQuery = "";
    StrCat(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS whois_permname(");
    StrCat(sQuery, sizeof(sQuery), "steam_id VARCHAR(64), ");
    StrCat(sQuery, sizeof(sQuery), "name VARCHAR(128), ");
    StrCat(sQuery, sizeof(sQuery), "PRIMARY KEY(steam_id)");
    StrCat(sQuery, sizeof(sQuery), ");");
    g_Database.Query(SQL_GenericQuery, sQuery);
}

public Action Command_SetName(int client, int args)
{
    if(g_Database == null)
        ThrowError("Database not connected");

    if(args != 2)
    {
        CReplyToCommand(client, "{green}[WhoIs]{default} Usage: sm_thisis <player> <name>");
        return Plugin_Handled;
    }

    char arg[32]; GetCmdArg(1, arg, sizeof(arg));
    char name[32]; GetCmdArg(2, name, sizeof(name));
    int target = FindTarget(client, arg, true, false);

    //Invalid Target:
    if(target == -1)
    {
        CReplyToCommand(client, "{green}[WhoIs]{default} Invalid Player: {green}%s{default}.", arg);
        return Plugin_Handled;
    }

    char steamid[32]; GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
    char query[256]; Format(query, sizeof(query), "INSERT INTO whois_permname VALUES('%s', '%s') ON DUPLICATE KEY UPDATE name='%s';", steamid, name, name);
    g_Database.Query(SQL_GenericQuery, query);
    return Plugin_Handled;
}

public Action Command_ShowName(int client, int args)
{
    if(g_Database == null)
        ThrowError("Database not connected");

    if(args != 1)
    {
        CReplyToCommand(client, "{green}[WhoIs]{default} Usage: sm_whois <player>");
        return Plugin_Handled;
    }

    char arg[32]; GetCmdArg(1, arg, sizeof(arg));
    int target = FindTarget(client, arg, true, false);

    //Invalid Target:
    if(target == -1)
    {
        CReplyToCommand(client, "{green}[WhoIs]{default} Invalid Player: {green}%s{default}.", arg);
        return Plugin_Handled;
    }

    char steamid[32]; GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
    char query[256]; Format(query, sizeof(query), "SELECT name FROM whois_permname WHERE steam_id='%s';", steamid);

    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteCell(target);
    g_Database.Query(SQL_SelectPermName, query, pack);
    return Plugin_Handled;
}

public void SQL_SelectPermName(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    if(db == null)
    {
        LogError("[WhoIs] SQL_SelectPermName Error >> %s", error);
        PrintToServer("WhoIs >> Failed to query: %s", error);
        return;
    }

    if(results == null)
    {
        LogError("[WhoIs] SQL_SelectPermName Error >> %s", error);
        PrintToServer("WhoIs >> Failed to query: %s", error);
        return;
    }

    pack.Reset();
    int client = pack.ReadCell();
    int target = pack.ReadCell();

    if(!results.FetchRow())
    {
        CPrintToChat(client, "{green}[WhoIs]{default} %N doesn't have a name set.", target);
        return;
    }

    int nameCol
    results.FieldNameToNum("name", nameCol);

    char name[128];
    results.FetchString(nameCol, name, sizeof(name));
    CPrintToChat(client, "{green}[WhoIs]{default} %N's set name is: {green}%s{default}.", target, name);
}

public Action Command_Activity(int client, int args)
{
    if(g_Database == null)
        ThrowError("Database not connected");

    //variable args accepted:
    switch(args)
    {
        //0 args = open player menu:
        case 0:
        {
            if(client == 0)
            {
                CReplyToCommand(client, "{green}[WhoIs]{default} This variant cannot be ran from server console.");
                return Plugin_Handled;
            }

            Menu menu = new Menu(Handler_ActivityList);
            menu.SetTitle("Select a Player:");
            for(int i = 1; i <= MaxClients; i++)
            {
                if(!IsClientConnected(i) || !IsClientAuthorized(i) || IsFakeClient(i)) continue;
                char id[8]; IntToString(i, id, sizeof(id));
                char name[MAX_NAME_LENGTH]; GetClientName(i, name, sizeof(name));
                menu.AddItem(id, name);
            }

            menu.Display(client, 30);
            return Plugin_Handled;
        }

        //1 args = targeted player:
        case 1:
        {
            char arg[32]; GetCmdArg(1, arg, sizeof(arg));
            int target = FindTarget(client, arg, true, false);

            //Invalid Target:
            if(target == -1)
            {
                CReplyToCommand(client, "{green}[WhoIs]{default} Invalid Player: {green}%s{default}.", arg);
                return Plugin_Handled;
            }

            char steamid[32]; GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
            char query[256]; Format(query, sizeof(query), "SELECT DISTINCT name, date FROM whois_names WHERE steam_id = '%s';", steamid);
            g_Database.Query(SQL_GetPlayerActivity, query, GetClientSerial(client));
            return Plugin_Handled;
        }

        default: 
        {
            if(client == 0)
            {
                CReplyToCommand(client, "{green}[WhoIs]{default} This variant cannot be ran from server console.");
                return Plugin_Handled;
            }

            Menu menu = new Menu(Handler_ActivityList);
            menu.SetTitle("Select a Player:");
            for(int i = 1; i <= MaxClients; i++)
            {
                if(!IsClientConnected(i) || !IsClientAuthorized(i) || IsFakeClient(i)) continue;
                char id[8]; IntToString(i, id, sizeof(id));
                char name[MAX_NAME_LENGTH]; GetClientName(i, name, sizeof(name));
                menu.AddItem(id, name);
            }

            menu.Display(client, 30);
            return Plugin_Handled;
        }
    }

    return Plugin_Handled;
}

public int Handler_ActivityList(Menu hMenu, MenuAction action, int client, int selection)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            //Info = Client Index:
            char info[64]; hMenu.GetItem(selection, info, sizeof(info));
            int target = StringToInt(info);

            if(!IsClientConnected(target) || !IsClientAuthorized(target)) return 0;

            char steamid[32]; GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
            char query[256]; Format(query, sizeof(query), "SELECT DISTINCT name, date FROM whois_names WHERE steam_id = '%s';", steamid);
            g_Database.Query(SQL_GetPlayerActivity, query, GetClientSerial(client));
            return 1;
        }

        case MenuAction_End:
        {
            delete hMenu;
            return 0;
        }
    }

    return 1;
}

public void OnClientAuthorized(int client)
{
    InsertPlayerData(client);
}

public void Event_ChangeName(Event e, const char[] name, bool noBroadcast)
{
    //This is called the frame after the event occurs so newname will be in effect already
    int client = GetClientOfUserId(e.GetInt("userid"));
    InsertPlayerData(client);
}

void InsertPlayerData(int client)
{
    if(g_Database == null)
    {
        LogError("Database not connected");
        return;
    }

    //Run this to stop from inserting STEAM_ID_RETVALS into the database:
    if(!IsClientConnected(client) || !IsClientAuthorized(client) || IsFakeClient(client)) return;

    char steamid[32], name[MAX_NAME_LENGTH], safeName[129];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
    GetClientName(client, name, sizeof(name));
    g_Database.Escape(name, safeName, sizeof(safeName));

    char query[256];
    Format(query, sizeof(query), "INSERT INTO whois_names (steam_id, name, date) VALUES ('%s', '%s', NOW());", steamid, safeName);
    g_Database.Query(SQL_GenericQuery, query);
}

public int Handler_Nothing(Menu hMenu, MenuAction action, int client, int selection)
{
    switch(action)
    {
        case MenuAction_Select:
        {
            return 1;
        }

        case MenuAction_End:
        {
            delete hMenu;
            return 1;
        }
    }

    return 1;
}

public void SQL_GetPlayerActivity(Database db, DBResultSet results, const char[] error, any data)
{
    if(db == null)
    {
        LogError("[WhoIs] SQL_GetPlayerActivity Error >> %s", error);
        PrintToServer("WhoIs >> Failed to query: %s", error);
        return;
    }

    if(results == null)
    {
        LogError("[WhoIs] SQL_GetPlayerActivity Error >> %s", error);
        PrintToServer("WhoIs >> Failed to query: %s", error);
        return;
    }

    int client = GetClientFromSerial(data);

    int nameCol, dateCol;
    results.FieldNameToNum("name", nameCol);
    results.FieldNameToNum("date", dateCol);

    int count = 0;
    Menu menu = new Menu(Handler_Nothing);
    menu.SetTitle("Player Name Activity:");

    while(results.FetchRow())
    {
        count++;
        char name[64]; results.FetchString(nameCol, name, sizeof(name));
        char date[32]; results.FetchString(dateCol, date, sizeof(date));
        char entry[128]; Format(entry, sizeof(entry), "%s - %s", name, date);
        char id[16]; IntToString(count, id, sizeof(id));
        menu.AddItem(id, entry, ITEMDRAW_DISABLED);
    }

    menu.ExitBackButton = true;
    menu.Display(client, 30);
}

public void SQL_GenericQuery(Database db, DBResultSet results, const char[] error, any data)
{
    if(db == null)
    {
        LogError("[WhoIs] SQL_GenericQuery Error >> %s", error);
        PrintToServer("WhoIs >> Failed to query: %s", error);
        return;
    }

    if(results == null)
    {
        LogError("[WhoIs] SQL_GenericQuery Error >> %s", error);
        PrintToServer("WhoIs >> Failed to query: %s", error);
        return;
    }
}

public void SQL_ConnectDatabase(Database db, const char[] error, any data)
{
    //Error:
    if(db == null)
    {
        LogError("[WhoIs] SQL_ConnectDatabase Error >> %s", error);
        PrintToServer("WhoIs >> Failed to connect to database: %s", error);
        return;
    }

    g_Database = db;
    CreateTable();

    if(g_Late)
    {
        for(int i = 1; i <= MaxClients; i++)
        {
            InsertPlayerData(i);
        }
    }
    return;
}

public Plugin myinfo = 
{
    name = "WhoIs",
    author = "Sidezz/The Doggy",
    description = "SGgsghjhedjh.",
    version = "1",
    url = "www.coldcommunity.com"
}