#include <sourcemod>
#include <regex>
#include <string>

#define PLUGIN_AUTHOR "DAYBR3AK1999"
#define PLUGIN_VERSION "2.0"

public Plugin:myinfo = 
{
	name = "Automated VIP System",
	author = PLUGIN_AUTHOR,
	description = "Automated Sourcebans VIP Trial Plugin where commands are used to become VIP.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=344460"
};

bool usedViptest[MAXPLAYERS + 1];

native SQL_ReadCallback(Handle:query, const FunctionName[], any:DataTuple = 0);

public void OnRebuildAdminCache(AdminCachePart part)
{
    switch(part)
    {
        case AdminCache_Admins:
        {
            if(SQL_CheckConfig("sourcebans"))
            {
				Database DB = SQL_Connect("sourcebans", false, "", 0);
				Connect_callback(null, DB, "", 0);
            }
        }
    }
}

void RefreshAdminCache()
{
    ServerCommand("sm_reloadadmins");
}

public void OnClientAuthorized(int client)
{
    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (SQL_CheckConfig("sourcebans"))
    {
        char buffer[300];
        Format(buffer, sizeof(buffer), "SELECT viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);
        SQL_TQuery(SQL_Connect("sourcebans", false, "", 0), OnClientAuthorized_QueryCallback, buffer, client, DBPrio_Low);
    }
}

public void OnClientAuthorized_QueryCallback(Handle owner, Handle hndl, const char[] error, any client)
{
    if(hndl == null)
    {
        SetFailState("ERROR - %s", error);
    }

    if (SQL_FetchRow(hndl))
    {
        int viptest_used_db = SQL_FetchInt(hndl, 0);
        usedViptest[client] = viptest_used_db == 1;
    }
    else
    {
        usedViptest[client] = false;
    }
    
    delete hndl;
}

bool IsValidClient(int client) {
    return client != 0 && IsClientInGame(client) && !IsFakeClient(client) && IsClientAuthorized(client);
}

void ResetUsedViptestArray()
{
    for (int i = 1; i <= MAXPLAYERS; i++)
    {
        usedViptest[i] = false;
    }
}

public void OnPluginStart()
{
    if (!SQL_CheckConfig("sourcebans")) {
        SetFailState("[SM] Invalid sourcebans database configuration.");
        return;
    }
    
    RegConsoleCmd("sm_vip_code", vip_code);
    RegConsoleCmd("sm_viptest", viptest);
    RegConsoleCmd("sm_myvipcode", myvipcode);
    RegConsoleCmd("sm_vipstatus", vipstatus);

    
    ResetUsedViptestArray();

    for (int i = 1; i <= MAXPLAYERS; i++)
    {
        if (IsClientConnected(i))
        {
            ClientConnect_Post(i);
            OnClientPostAdminCheck(i);
        }
    }
    OnRebuildAdminCache(AdminCache_Admins);
    PreloadVIPStatus();
    CreateTimer(60.0, Timer_CheckForExpiredVipCodes, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_CheckForExpiredVipCodes(Handle timer) {
    CheckForExpiredVipCodes();
    return Plugin_Continue;
}

public void OnMapStart() {
    CheckForExpiredVipCodes();
}

public void OnRoundStart(Handle event, const char[] name, bool dontBroadcast) {
    CheckForExpiredVipCodes();
}

public void CheckForExpiredVipCodes() {
    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) {
        LogError("Failed to connect to the database.");
        return;
    }

    char query[300];
    Format(query, sizeof(query), "UPDATE sb_vip_system SET admin_group = NULL WHERE expire < NOW() AND admin_group = 'vip'");
    
    LogMessage("Running expired VIP codes check with query: %s", query);

    if (!SQL_FastQuery(DB, query)) {
        char error[256];
        SQL_GetError(DB, error, sizeof(error));
        LogError("SQL Error: %s", error);
    } else {
        LogMessage("Expired VIP codes have been updated.");
        RefreshAdminCache();
    }

    delete DB;
}

void PreloadVIPStatus()
{
    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) return;

    char query[] = "SELECT steamid, viptest_used FROM sb_vip_system";
    SQL_TQuery(DB, PreloadVIPStatus_Callback, query, DBPrio_High);
    delete DB;
    for (int i = 1; i <= GetMaxClients(); i++)
    {
        if (IsClientConnected(i))
        {
            CheckVipTestStatus(i);
        }
    }
}

void CheckVipTestStatus(int client)
{
    if (!IsValidClient(client)) return;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    char buffer[300];
    Format(buffer, sizeof(buffer), "SELECT viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);
    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) return;

    SQL_TQuery(DB, OnClientAuthorized_QueryCallback, buffer, client, DBPrio_Low);
    delete DB;
}

public void PreloadVIPStatus_Callback(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
    {

        return;
    }

    while (SQL_FetchRow(hndl))
    {
        char steamid[32];
        SQL_FetchString(hndl, 0, steamid, sizeof(steamid));
    }

    delete hndl;
}

public void ClientConnect_Post(int client)
{
    if (!IsValidClient(client)) {
        return;
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsValidClient(client)) {
        return;
    }
}

public Action vip_code(int client, int arg) {
    if (!IsValidClient(client)) return Plugin_Handled;

    if (arg < 1) {
        PrintToChat(client, "[SM] Usage: sm_vip_code <YourCodeHere>");
        return Plugin_Handled;
    }

    static int spamblock[MAXPLAYERS+1];
    int time = GetTime();

    if (time < spamblock[client]) {
        PrintToChat(client, "[SM] Do not spam command!");
        return Plugin_Handled;
    }

    spamblock[client] = time + 3;

    char vipCode[20];
    GetCmdArg(1, vipCode, sizeof(vipCode));

    if (SimpleRegexMatch(vipCode, "[^a-zA-Z0-9]") > 0) {
        PrintToChat(client, "[SM] VIP code only contains numbers and letters, a-z, A-Z, 0-9");
        return Plugin_Handled;
    }

    if (SQL_CheckConfig("sourcebans")) {
        Database DB = SQL_Connect("sourcebans", false, "", 0);
        if (DB == null) return Plugin_Handled;

        char buffer[300];
        Format(buffer, sizeof(buffer), "SELECT used, steamid FROM sb_vip_system WHERE code = '%s'", vipCode);

        Handle hDataPack = CreateDataPack();
        WritePackCell(hDataPack, client);
        WritePackString(hDataPack, vipCode);
        SQL_TQuery(DB, vip_code_check_callback, buffer, hDataPack);
    }

    return Plugin_Handled;
}

public void vip_code_check_callback(Handle owner, Handle hndl, const char[] error, any dataPack) {
    if (hndl == null) {
        SetFailState("ERROR - %s", error);
        CloseHandle(dataPack);
        return;
    }

    Handle hDataPack = dataPack;
    ResetPack(hDataPack);
    int client = ReadPackCell(hDataPack);
    char code[20];
    ReadPackString(hDataPack, code, sizeof(code));

    char clientSteamID[32];
    GetClientAuthId(client, AuthId_Steam2, clientSteamID, sizeof(clientSteamID));

    if (SQL_FetchRow(hndl)) {
        int used = SQL_FetchInt(hndl, 0);
        char steamID[32];
        SQL_FetchString(hndl, 1, steamID, sizeof(steamID));

        if (used != 0) {
            PrintToChat(client, "[SM] This VIP code has already been claimed.");
        } else if (strlen(steamID) > 0 && strcmp(steamID, clientSteamID) != 0) {
            PrintToChat(client, "[SM] This VIP code is not yours to claim.");
        } else {
            activate_vip_code(client, code);
        }
    } else {
        PrintToChat(client, "[SM] Incorrect VIP code.");
    }

    delete hndl;
    CloseHandle(hDataPack);
}


void activate_vip_code(int client, const char[] code) {
    if (!IsValidClient(client)) return;

    Database DB = SQL_Connect("sourcebans", false, "", 0);
    if (DB == null) {
        LogError("Failed to connect to the database while activating VIP code.");
        return;
    }

    char buffer[300], steamID[64];
    GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));

    Format(buffer, sizeof(buffer), "UPDATE sb_vip_system SET steamid = '%s', expire = DATE_ADD(NOW(), INTERVAL 1 WEEK), used = 1, admin_group = 'vip' WHERE code = '%s'", steamID, code);
    
    if (!SQL_FastQuery(DB, buffer)) {
        char error[256];
        SQL_GetError(DB, error, sizeof(error));
        LogError("[VIP Plugin] SQL Error: %s", error);
        PrintToChat(client, "[SM] An error occurred while processing your VIP code.");
    } else {
        PrintToChat(client, "[SM] Your VIP code has been activated.");
        RefreshAdminCache();
    }

    delete DB;
}

public Action viptest(int client, int arg)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    if (usedViptest[client])
    {
        PrintToChat(client, "[SM] VIP Trial code already received.");
        return Plugin_Handled;
    }

    if (SQL_CheckConfig("sourcebans"))
    {
        Database DB = SQL_Connect("sourcebans", false, "", 0);

        if (DB == null) return Plugin_Handled;

        char steamid[32];
        GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

        char name[MAX_NAME_LENGTH];
        GetClientName(client, name, sizeof(name));

        char buffer[300];

        Format(buffer, sizeof(buffer), "SELECT code, used, expire, viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);

        DBResultSet result = SQL_Query(DB, buffer, sizeof(buffer));

        bool alreadyClaimed = false;
        char existingCode[32];
        bool used = false;
        int expire;
        int usedViptestDB;

        if (result != null)
        {
            if (SQL_FetchRow(result))
            {
                alreadyClaimed = true;
                SQL_FetchString(result, 0, existingCode, sizeof(existingCode));
                used = SQL_FetchInt(result, 1) == 1;
                expire = SQL_FetchInt(result, 2);
                usedViptestDB = SQL_FetchInt(result, 3);
            }
            delete result;
        }

        if (usedViptestDB)
        {
            PrintToChat(client, "[SM] You have already used the sm_viptest command (stored in database).");
            delete DB;
            return Plugin_Handled;
        }

        if (alreadyClaimed)
        {
            if (used)
            {
                if (expire >= GetTime())
                {
                    PrintToChat(client, "[SM] Your VIP Trial is active.");
                }
                else
                {
                    PrintToChat(client, "[SM] Your VIP Trial has expired.");
                }
            }
            else
            {
                PrintToChat(client, "[SM] You have already claimed a VIP trial code: %s. Activate it by writing sm_vip_code %s", existingCode, existingCode);
            }
        }
        else
        {
            char randomCode[32];
            GenerateRandomCode(randomCode, 10);

            Format(buffer, sizeof(buffer), "INSERT INTO sb_vip_system (code, steamid, name, viptest_used) SELECT '%s', '%s', '%s', 1 WHERE NOT EXISTS (SELECT 1 FROM sb_vip_system WHERE steamid = '%s')", randomCode, steamid, name, steamid);

            if (!SQL_FastQuery(DB, buffer))
            {
                SQL_GetError(DB, buffer, sizeof(buffer));
                LogError("%s", buffer);
            }
            else
            {
                PrintToChat(client, "[SM] Your new VIP code: %s", randomCode);
                usedViptest[client] = true;
            }
        }

        delete DB;
    }

    return Plugin_Handled;
}

void GenerateRandomCode(char[] buffer, int length)
{
    static const char charset[] = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    for (int i = 0; i < length; i++)
    {
        buffer[i] = charset[GetRandomInt(0, sizeof(charset) - 2)];
    }
    buffer[length] = '\0';
}

public Action myvipcode(int client, int arg)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (SQL_CheckConfig("sourcebans"))
    {
        Database DB = SQL_Connect("sourcebans", false, "", 0);

        if (DB == null) return Plugin_Handled;

        char buffer[300];
        Format(buffer, sizeof(buffer), "SELECT code, viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);

        DBResultSet result = SQL_Query(DB, buffer);

        if (result != null)
        {
            if (SQL_FetchRow(result))
            {
                int viptest_used_db = SQL_FetchInt(result, 1);

                if (viptest_used_db == 1)
                {
                    char code[32];
                    SQL_FetchString(result, 0, code, sizeof(code));
                    PrintToChat(client, "[SM] Your VIP code: %s", code);
                }
                else
                {
                    PrintToChat(client, "[SM] You haven't used the !viptest command yet. Use !viptest to receive a VIP code.");
                }
            }
            else
            {
                PrintToChat(client, "[SM] You haven't used the !viptest command yet. Use !viptest to receive a VIP code.");
            }
            delete result;
        }
        else
        {
            char error[256];
            SQL_GetError(DB, error, sizeof(error));
        }

        delete DB;
    }
    else
    {
        PrintToServer("[DEBUG] sourcebans config check failed");
    }

    return Plugin_Handled;
}

public Action vipstatus(int client, int arg)
{
    if (!IsValidClient(client)) return Plugin_Handled;

    char steamid[32];
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

    if (SQL_CheckConfig("sourcebans"))
    {
        Database DB = SQL_Connect("sourcebans", false, "", 0);

        if (DB == null) return Plugin_Handled;

        char buffer[300];
        Format(buffer, sizeof(buffer), "SELECT expire, viptest_used FROM sb_vip_system WHERE steamid = '%s'", steamid);

        DBResultSet result = SQL_Query(DB, buffer);

        if (result != null)
        {
            if (SQL_FetchRow(result))
            {
                int viptest_used_db = SQL_FetchInt(result, 1);

                if (viptest_used_db == 0)
                {
                    PrintToChat(client, "[SM] You didn't claim your VIP Trial yet. Claim it by writing !viptest");
                }
                else
                {
                    char expireDate[32];
                    SQL_FetchString(result, 0, expireDate, sizeof(expireDate));
                    if (strlen(expireDate) > 0)
                    {
                        PrintToChat(client, "[SM] Your VIP Trial expires/expired on %s.", expireDate);
                    }
                    else
                    {
                        PrintToChat(client, "[SM] You have not activated your VIP Trial yet.");
                    }
                }
            }
            else
            {
                PrintToChat(client, "[SM] You didn't claim your VIP Trial yet. Claim it by writing !viptest");
            }
            delete result;
        }
        delete DB;
    }

    return Plugin_Handled;
}

public void Connect_callback(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl == null) return;

    char buffer[300];

    Format(buffer, sizeof(buffer), "SELECT steamid, admin_group FROM sb_vip_system WHERE expire >= CURDATE() AND steamid REGEXP '^STEAM_[[:digit:]]\\:[[:digit:]]\\:[[:digit:]]+$'"); //"STEAM_1:1:111111"
    SQL_TQuery(hndl, Query_callback, buffer, data, DBPrio_Low);

    delete hndl;
}

public void Query_callback(Handle owner, Handle hndl, const char[] error, any data)
{

    if(hndl == null)
    {
        SetFailState("ERROR - %s", error);
    }

    GroupId group;
    AdminId admin;

    char buffer[300];

    while (SQL_FetchRow(hndl))
    {
        SQL_FetchString(hndl, 1, buffer, sizeof(buffer));

        group = FindAdmGroup(buffer);
        if(group == INVALID_GROUP_ID) continue;

        SQL_FetchString(hndl, 0, buffer, sizeof(buffer));

        admin = FindAdminByIdentity("steam", buffer);

        if(admin == INVALID_ADMIN_ID)
        {
            admin = CreateAdmin("vip");
            if(!BindAdminIdentity(admin, "steam", buffer))
            {
                RemoveAdmin(admin);
                continue;
            }
        }

        bool IsInGroup;

        for(int x = 0; x < GetAdminGroupCount(admin); x++)
        {
            if(GetAdminGroup(admin, x, "", 0) == group)
            {
                IsInGroup = true;
                break;
            }
        }

        if(IsInGroup) continue;

        AdminInheritGroup(admin, group);
    }
} 