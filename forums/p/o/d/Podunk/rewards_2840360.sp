
public Plugin myinfo =
{
    name        = "[TF2] Rewards",
    author      = "Podunk",
    description = "Automatically reward players in Team Fortress 2 (TF2) servers based on their accumulated points from the TF2Stats ReduxP plugin",
    version     = "1.0.0",
    url         = "none"
}

#include <sourcemod>
forward void TF2Stats_OnPlayerSessionPointsChanged(int client, const char[] name, const char[] steamId, int points);
forward void TF2Stats_OnPlayerTotalPointsChanged(int client, const char[] name, const char[] steamId, int points);

#pragma semicolon 1
#pragma newdecls required

#define INPUT_THRESHOLD   1
#define INPUT_START_DATE  2
#define INPUT_END_DATE    3
#define INPUT_GRANT_CMD   4
#define INPUT_REVOKE_CMD  5
#define INPUT_DESCRIPTION 6

#define DATABASE_NAME     "rewards"

enum struct Reward
{
    int  id;
    int  threshold;
    bool enabled;
    char start_date[20];
    char end_date[20];
    char grant_cmd[257];
    char revoke_cmd[257];
    char description[129];
}

Database  db;
ArrayList g_Rewards;
StringMap g_PrevPoints;    // Not used anymore, but kept if needed
StringMap g_PlayerStatuses;
int       g_InputType[MAXPLAYERS + 1];
int       g_InputRid[MAXPLAYERS + 1];
int       g_CurrentRid[MAXPLAYERS + 1];

public void OnPluginStart()
{
    if (!SQL_CheckConfig(DATABASE_NAME))
    {
        SetFailState("rewards database not configured");
        return;
    }

    g_Rewards        = new ArrayList(sizeof(Reward));
    g_PlayerStatuses = new StringMap();
    g_PrevPoints     = new StringMap();
    AddCommandListener(SayListener, "say");
    AddCommandListener(SayListener, "say_team");
    RegAdminCmd("sm_rewards", Command_Rewards, ADMFLAG_RCON, "Opens the rewards management menu");

    char error[256];
    db = SQL_Connect(DATABASE_NAME, true, error, sizeof(error));
    if (db == null)
    {
        LogError("Could not connect to database: %s", error);
        SetFailState("Database connection failed");
        return;
    }

    char create_sql[1024];
    Format(create_sql, sizeof(create_sql), "CREATE TABLE IF NOT EXISTS rewards ( \
        id INT AUTO_INCREMENT PRIMARY KEY, \
        threshold INT DEFAULT 0, \
        enabled TINYINT DEFAULT 1, \
        start_date VARCHAR(19) DEFAULT NULL, \
        end_date VARCHAR(19) DEFAULT NULL, \
        grant_cmd VARCHAR(256) DEFAULT '', \
        revoke_cmd VARCHAR(256) DEFAULT '', \
        description VARCHAR(128) DEFAULT '' \
    )");
    if (!SQL_FastQuery(db, create_sql))
    {
        SQL_GetError(db, error, sizeof(error));
        LogError("Create rewards table failed: %s", error);
    }

    Format(create_sql, sizeof(create_sql), "CREATE TABLE IF NOT EXISTS player_reward_status ( \
        steamid VARCHAR(64), \
        reward_id INT, \
        status TINYINT DEFAULT 0, \
        PRIMARY KEY (steamid, reward_id) \
    )");
    if (!SQL_FastQuery(db, create_sql))
    {
        SQL_GetError(db, error, sizeof(error));
        LogError("Create status table failed: %s", error);
    }

    char        query[256] = "SELECT COUNT(*) as cnt FROM rewards";
    DBResultSet rs         = SQL_Query(db, query);
    if (rs == null)
    {
        SQL_GetError(db, error, sizeof(error));
        LogError("Count query failed: %s", error);
    }
    else {
        if (rs.FetchRow())
        {
            int count = rs.FetchInt(0);
            if (count == 0)
            {
                SQL_FastQuery(db, "INSERT INTO rewards (threshold, enabled, grant_cmd, revoke_cmd, description) VALUES (250, 1, 'sm_assign_by_id %d Headcrab', '', 'Headcrab Companion')");
                SQL_FastQuery(db, "INSERT INTO rewards (threshold, enabled, grant_cmd, revoke_cmd, description) VALUES (2500, 1, 'sm_assign_by_id %d Antlion', '', 'Antlion Companion')");
                SQL_FastQuery(db, "INSERT INTO rewards (threshold, enabled, grant_cmd, revoke_cmd, description) VALUES (25000, 1, 'sm_assign_by_id %d Buggy', '', 'Buggy Companion')");
                SQL_FastQuery(db, "INSERT INTO rewards (threshold, enabled, grant_cmd, revoke_cmd, description) VALUES (250000, 1, 'sm_assign_by_id %d Stalker', '', 'Stalker Companion')");
                SQL_FastQuery(db, "INSERT INTO rewards (threshold, enabled, grant_cmd, revoke_cmd, description) VALUES (2500000, 1, 'sm_assign_by_id %d Dog', '', 'Dog Companion')");
            }
        }
        delete rs;
    }

    LoadRewards();
}

public void OnPluginEnd()
{
    if (db != null)
    {
        delete db;
    }
    StringMapSnapshot snap = g_PlayerStatuses.Snapshot();
    for (int i = 0; i < snap.Length; i++)
    {
        char key[64];
        snap.GetKey(i, key, sizeof(key));
        StringMap inner;
        g_PlayerStatuses.GetValue(key, inner);
        delete inner;
    }
    delete snap;
    delete g_PlayerStatuses;
    delete g_Rewards;
    delete g_PrevPoints;
}

public void OnClientDisconnect(int client)
{
    char auth[64];
    if (GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth)))
    {
        StringMap inner;
        if (g_PlayerStatuses.GetValue(auth, inner))
        {
            g_PlayerStatuses.Remove(auth);
            delete inner;
        }
        g_PrevPoints.Remove(auth);
    }
    g_InputType[client]  = 0;
    g_InputRid[client]   = 0;
    g_CurrentRid[client] = 0;
}

void LoadRewards()
{
    char        query[512] = "SELECT id, threshold, enabled, IFNULL(start_date, '') as start_date, IFNULL(end_date, '') as end_date, grant_cmd, revoke_cmd, description FROM rewards ORDER BY threshold ASC";
    DBResultSet rs         = SQL_Query(db, query);
    if (rs == null)
    {
        char error[256];
        SQL_GetError(db, error, sizeof(error));
        LogError("Load rewards failed: %s", error);
        return;
    }
    g_Rewards.Clear();
    while (rs.FetchRow())
    {
        Reward r;
        r.id        = rs.FetchInt(0);
        r.threshold = rs.FetchInt(1);
        r.enabled   = rs.FetchInt(2) != 0;
        rs.FetchString(3, r.start_date, sizeof(r.start_date));
        rs.FetchString(4, r.end_date, sizeof(r.end_date));
        rs.FetchString(5, r.grant_cmd, sizeof(r.grant_cmd));
        rs.FetchString(6, r.revoke_cmd, sizeof(r.revoke_cmd));
        rs.FetchString(7, r.description, sizeof(r.description));
        g_Rewards.PushArray(r);
    }
    delete rs;
}

bool GetRewardById(int id, Reward r)
{
    for (int i = 0; i < g_Rewards.Length; i++)
    {
        Reward tr;
        g_Rewards.GetArray(i, tr, sizeof(tr));
        if (tr.id == id)
        {
            r = tr;
            return true;
        }
    }
    return false;
}

bool IsActive(const Reward r)
{
    if (!r.enabled) return false;
    char now[20];
    FormatTime(now, sizeof(now), "%Y-%m-%d %H:%M:%S", GetTime());
    bool startOk = (r.start_date[0] == '\0' || strcmp(now, r.start_date) >= 0);
    bool endOk   = (r.end_date[0] == '\0' || strcmp(now, r.end_date) < 0);
    return startOk && endOk;
}

public void TF2Stats_OnPlayerTotalPointsChanged(int userid, const char[] name, const char[] steamId, int points)
{
    int client;
    if ((client = GetClientOfUserId(userid)) == 0)
    {
        return;
    }

    if (client < 1 || client > MaxClients || !IsClientInGame(client)) return;
    if (strcmp(steamId, "BOT") == 0) return;

    char auth[64];
    strcopy(auth, sizeof(auth), steamId);

    StringMap statuses;
    if (!g_PlayerStatuses.GetValue(auth, statuses))
    {
        statuses = new StringMap();
        g_PlayerStatuses.SetValue(auth, statuses);

        char escaped[128];
        db.Escape(auth, escaped, sizeof(escaped));
        char sql[512];
        Format(sql, sizeof(sql), "SELECT reward_id, status FROM player_reward_status WHERE steamid = '%s'", escaped);
        DBResultSet rs = SQL_Query(db, sql);
        if (rs != null)
        {
            while (rs.FetchRow())
            {
                int  rid  = rs.FetchInt(0);
                int  stat = rs.FetchInt(1);
                char key[16];
                IntToString(rid, key, sizeof(key));
                statuses.SetValue(key, stat);
            }
            delete rs;
        }
        else {
            char error[256];
            SQL_GetError(db, error, sizeof(error));
            LogError("Load status failed for %s: %s", auth, error);
        }
    }

    for (int i = 0; i < g_Rewards.Length; i++)
    {
        Reward r;
        g_Rewards.GetArray(i, r, sizeof(r));
        if (!IsActive(r)) continue;

        char key[16];
        IntToString(r.id, key, sizeof(key));
        int stat;
        statuses.GetValue(key, stat);
        bool had     = stat != 0;
        bool has_now = points >= r.threshold;
        bool gave    = false;
        if (has_now != had)
        {
            char cmd[512];
            if (has_now)
            {
                Format(cmd, sizeof(cmd), r.grant_cmd, client);
                gave = true;
            }
            else {
                Format(cmd, sizeof(cmd), r.revoke_cmd, client);
            }
            ServerCommand(cmd);

            statuses.SetValue(key, has_now ? 1 : 0);
            UpdateStatus(auth, r.id, has_now ? 1 : 0);
        }
        if (gave)
        {
            DataPack pack;  // This will be set by CreateDataTimer
            Handle timer = CreateDataTimer(0.5, PrintColorfulCongrats0, pack, TIMER_FLAG_NO_MAPCHANGE);
            
            if (timer == null) {
                LogError("Failed to create timer!");
                return;
            }
            // Write data to the pack before the timer fires
            pack.WriteCell(GetClientUserId(client));
            pack.WriteCell(r.threshold);
            pack.WriteString(r.description);
        }
    }

    // Update prev points if needed, but not necessary now
    g_PrevPoints.SetValue(auth, points);
}
Action PrintColorfulCongrats0(Handle timer, DataPack pack)
{
    pack.Reset();  // Reset position to read from the start
    int userid = pack.ReadCell();
    int client;
    if ((client = GetClientOfUserId(userid)) == 0)
    {
        return Plugin_Continue;
    }
    int thresh = pack.ReadCell();
    char desc[128];
    pack.ReadString(desc, sizeof(desc));

    int i = 0;
    for (i = 0; i < 1; i++)
    {
        PrintColorfulCongrats(client, desc, thresh);
    }
    return Plugin_Continue;
}

void PrintColorfulCongrats(int client, const char[] rewardDesc, int threshold)
{
    if (!IsValidClient(client)) return;    // Basic validation for the client index

    char message[512];
    message[0]        = '\0';

    // Rainbow color hex codes (cycling through red, orange, yellow, green, blue, indigo, violet)
    char colors[7][7] = {
        "FF0000",    // Red
        "FF8C00",    // Orange
        "FFFF00",    // Yellow
        "00FF00",    // Green
        "0000FF",    // Blue
        "4B0082",    // Indigo
        "9400D3"     // Violet
    };

    // Flair: Golden stars for celebration (gold hex: FFD700)
    StrCat(message, sizeof(message), "\x07FFD700★★★ \x01");

    // The word "CONGRATULATIONS!" in rainbow colors, one color per letter
    char congrats[] = "CONGRATULATIONS!";
    int  len        = strlen(congrats);
    for (int i = 0; i < len; i++)
    {
        char part[32];
        int  colorIdx = i % 7;    // Cycle through the 7 colors
        Format(part, sizeof(part), "\x07%s%c", colors[colorIdx], congrats[i]);
        StrCat(message, sizeof(message), part);
    }

    char sThresh[128];

    Format(sThresh, sizeof(sThresh), "For reaching %d points, you have been rewarded the %s", threshold, rewardDesc);
    // More flair and the rest of the message
    StrCat(message, sizeof(message), "\x01 \x07FFD700★★★\x01 ");
    StrCat(message, sizeof(message), sThresh);
    // StrCat(message, sizeof(message), " 🎉");
    // Print to the specific client's chat (colors use TF2-supported \x07RRGGBB codes)
    PrintToChat(client, message);
}

// Helper to check if client is valid (optional but recommended)
bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

void UpdateStatus(const char[] steamid, int rid, int status)
{
    char sql[512];
    char escaped[128];
    db.Escape(steamid, escaped, sizeof(escaped));
    Format(sql, sizeof(sql), "INSERT INTO player_reward_status (steamid, reward_id, status) VALUES ('%s', %d, %d) ON DUPLICATE KEY UPDATE status = %d", escaped, rid, status, status);
    char error[256];
    if (!SQL_FastQuery(db, sql))
    {
        SQL_GetError(db, error, sizeof(error));
        LogError("Update status failed: %s", error);
    }
}

public Action Command_Rewards(int client, int args)
{
    LoadRewards();
    ShowRewardsMenu(client);
    return Plugin_Handled;
}

void ShowRewardsMenu(int client)
{
    Menu menu = new Menu(RewardsMenuHandler);
    menu.SetTitle("Rewards Management");
    menu.AddItem("add", "Add New Reward");
    char idstr[16], infobuf[256];
    for (int i = 0; i < g_Rewards.Length; i++)
    {
        Reward r;
        g_Rewards.GetArray(i, r, sizeof(r));
        IntToString(r.id, idstr, sizeof(idstr));
        Format(infobuf, sizeof(infobuf), "%s - %d points - %s", r.enabled ? "Enabled" : "Disabled", r.threshold, r.description);
        menu.AddItem(idstr, infobuf);
    }
    menu.Display(client, MENU_TIME_FOREVER);
}

public int RewardsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        char info[16];
        menu.GetItem(param2, info, sizeof(info));
        if (StrEqual(info, "add"))
        {
            char sql[1024];
            Format(sql, sizeof(sql), "INSERT INTO rewards (threshold, enabled, start_date, end_date, grant_cmd, revoke_cmd, description) VALUES (0, 1, NULL, NULL, '', '', '')");
            char error[256];
            if (!SQL_FastQuery(db, sql))
            {
                SQL_GetError(db, error, sizeof(error));
                PrintToChat(param1, "Error adding reward: %s", error);
                return 0;
            }
            DBResultSet rs = SQL_Query(db, "SELECT LAST_INSERT_ID() AS id");
            if (rs == null || !rs.FetchRow())
            {
                if (rs != null)
                {
                    SQL_GetError(db, error, sizeof(error));
                    PrintToChat(param1, "Error getting id: %s", error);
                }
                else {
                    PrintToChat(param1, "Error getting id");
                }
                delete rs;
                return 0;
            }
            int newid = rs.FetchInt(0);
            delete rs;
            LoadRewards();
            ShowEditMenu(param1, newid);
        }
        else {
            int id = StringToInt(info);
            ShowEditMenu(param1, id);
        }
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

void ShowEditMenu(int client, int rid)
{
    Reward r;
    if (!GetRewardById(rid, r))
    {
        PrintToChat(client, "Reward not found.");
        return;
    }
    g_CurrentRid[client] = rid;
    Menu menu            = new Menu(EditMenuHandler);
    char tmp[512];
    Format(tmp, sizeof(tmp), "Threshold: %d", r.threshold);
    menu.AddItem("threshold", tmp);
    Format(tmp, sizeof(tmp), "Enabled: %s", r.enabled ? "Yes" : "No");
    menu.AddItem("enabled", tmp);
    Format(tmp, sizeof(tmp), "Start Date: %s", r.start_date[0] ? r.start_date : "None");
    menu.AddItem("start_date", tmp);
    Format(tmp, sizeof(tmp), "End Date: %s", r.end_date[0] ? r.end_date : "None");
    menu.AddItem("end_date", tmp);
    Format(tmp, sizeof(tmp), "Grant Cmd: %s", r.grant_cmd);
    menu.AddItem("grant_cmd", tmp);
    Format(tmp, sizeof(tmp), "Revoke Cmd: %s", r.revoke_cmd);
    menu.AddItem("revoke_cmd", tmp);
    Format(tmp, sizeof(tmp), "Description: %s", r.description);
    menu.AddItem("description", tmp);
    menu.AddItem("remove", "Remove this reward");
    menu.AddItem("back", "Back to list");
    menu.SetTitle("Edit Reward ID: %d", rid);
    menu.Display(client, MENU_TIME_FOREVER);
}

public int EditMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        int  rid = g_CurrentRid[param1];
        char key[32];
        menu.GetItem(param2, key, sizeof(key));
        char error[256];
        if (StrEqual(key, "enabled"))
        {
            Reward r;
            if (GetRewardById(rid, r))
            {
                int  new_enabled = r.enabled ? 0 : 1;
                char sql[512];
                Format(sql, sizeof(sql), "UPDATE rewards SET enabled = %d WHERE id = %d", new_enabled, rid);
                if (!SQL_FastQuery(db, sql))
                {
                    SQL_GetError(db, error, sizeof(error));
                    PrintToChat(param1, "Error updating: %s", error);
                    return 0;
                }
                LoadRewards();
                ShowEditMenu(param1, rid);
            }
        }
        else if (StrEqual(key, "remove")) {
            char sql[512];
            Format(sql, sizeof(sql), "DELETE FROM rewards WHERE id = %d", rid);
            if (!SQL_FastQuery(db, sql))
            {
                SQL_GetError(db, error, sizeof(error));
                PrintToChat(param1, "Error removing: %s", error);
                return 0;
            }
            LoadRewards();
            ShowRewardsMenu(param1);
        }
        else if (StrEqual(key, "back")) {
            ShowRewardsMenu(param1);
        }
        else if (StrEqual(key, "threshold")) {
            PromptInput(param1, rid, INPUT_THRESHOLD, "Enter threshold (positive integer):");
        }
        else if (StrEqual(key, "start_date")) {
            PromptInput(param1, rid, INPUT_START_DATE, "Enter start date (YYYY-MM-DD HH:MM:SS) or empty for none:");
        }
        else if (StrEqual(key, "end_date")) {
            PromptInput(param1, rid, INPUT_END_DATE, "Enter end date (YYYY-MM-DD HH:MM:SS) or empty for none:");
        }
        else if (StrEqual(key, "grant_cmd")) {
            PromptInput(param1, rid, INPUT_GRANT_CMD, "Enter grant command (use %d for client index):");
        }
        else if (StrEqual(key, "revoke_cmd")) {
            PromptInput(param1, rid, INPUT_REVOKE_CMD, "Enter revoke command (use %d for client index):");
        }
        else if (StrEqual(key, "description")) {
            PromptInput(param1, rid, INPUT_DESCRIPTION, "Enter description:");
        }
    }
    else if (action == MenuAction_End) {
        delete menu;
    }
    return 0;
}

void PromptInput(int client, int rid, int type, const char[] prompt_msg)
{
    g_InputType[client] = type;
    g_InputRid[client]  = rid;
    PrintToChat(client, prompt_msg);
}

public Action SayListener(int client, const char[] command, int argc)
{
    if (g_InputType[client] == 0 || !IsClientInGame(client)) return Plugin_Continue;
    char text[256];
    GetCmdArgString(text, sizeof(text));
    TrimString(text);
    int type            = g_InputType[client];
    int rid             = g_InputRid[client];
    g_InputType[client] = 0;
    g_InputRid[client]  = 0;
    char error[256];
    switch (type)
    {
        case INPUT_THRESHOLD:
        {
            int val = StringToInt(text);
            if (val <= 0)
            {
                PrintToChat(client, "Invalid threshold. Please enter a positive integer.");
                PromptInput(client, rid, INPUT_THRESHOLD, "Enter threshold (positive integer):");
                return Plugin_Handled;
            }
            char sql[512];
            Format(sql, sizeof(sql), "UPDATE rewards SET threshold = %d WHERE id = %d", val, rid);
            if (!SQL_FastQuery(db, sql))
            {
                SQL_GetError(db, error, sizeof(error));
                PrintToChat(client, "Error updating: %s", error);
                return Plugin_Handled;
            }
            LoadRewards();
            ShowEditMenu(client, rid);
        }
        case INPUT_START_DATE, INPUT_END_DATE:
        {
            char val[20];
            strcopy(val, sizeof(val), text);
            char field[16];
            if (type == INPUT_START_DATE) strcopy(field, sizeof(field), "start_date");
            else strcopy(field, sizeof(field), "end_date");
            char sql[512];
            if (strlen(val) == 0)
            {
                Format(sql, sizeof(sql), "UPDATE rewards SET %s = NULL WHERE id = %d", field, rid);
            }
            else {
                if (strlen(val) != 19 || val[4] != '-' || val[7] != '-' || val[10] != ' ' || val[13] != ':' || val[16] != ':')
                {
                    PrintToChat(client, "Invalid date format. Use YYYY-MM-DD HH:MM:SS");
                    PromptInput(client, rid, type, "Enter date (YYYY-MM-DD HH:MM:SS) or empty for none:");
                    return Plugin_Handled;
                }
                char escaped[24];
                db.Escape(val, escaped, sizeof(escaped));
                Format(sql, sizeof(sql), "UPDATE rewards SET %s = '%s' WHERE id = %d", field, escaped, rid);
            }
            if (!SQL_FastQuery(db, sql))
            {
                SQL_GetError(db, error, sizeof(error));
                PrintToChat(client, "Error updating: %s", error);
                return Plugin_Handled;
            }
            LoadRewards();
            ShowEditMenu(client, rid);
        }
        case INPUT_GRANT_CMD:
        {
            char escaped[512];
            db.Escape(text, escaped, sizeof(escaped));
            char sql[1024];
            Format(sql, sizeof(sql), "UPDATE rewards SET grant_cmd = '%s' WHERE id = %d", escaped, rid);
            if (!SQL_FastQuery(db, sql))
            {
                SQL_GetError(db, error, sizeof(error));
                PrintToChat(client, "Error updating: %s", error);
                return Plugin_Handled;
            }
            LoadRewards();
            ShowEditMenu(client, rid);
        }
        case INPUT_REVOKE_CMD:
        {
            char escaped[512];
            db.Escape(text, escaped, sizeof(escaped));
            char sql[1024];
            Format(sql, sizeof(sql), "UPDATE rewards SET revoke_cmd = '%s' WHERE id = %d", escaped, rid);
            if (!SQL_FastQuery(db, sql))
            {
                SQL_GetError(db, error, sizeof(error));
                PrintToChat(client, "Error updating: %s", error);
                return Plugin_Handled;
            }
            LoadRewards();
            ShowEditMenu(client, rid);
        }
        case INPUT_DESCRIPTION:
        {
            char escaped[512];
            db.Escape(text, escaped, sizeof(escaped));
            char sql[1024];
            Format(sql, sizeof(sql), "UPDATE rewards SET description = '%s' WHERE id = %d", escaped, rid);
            if (!SQL_FastQuery(db, sql))
            {
                SQL_GetError(db, error, sizeof(error));
                PrintToChat(client, "Error updating: %s", error);
                return Plugin_Handled;
            }
            LoadRewards();
            ShowEditMenu(client, rid);
        }
    }
    return Plugin_Handled;
}