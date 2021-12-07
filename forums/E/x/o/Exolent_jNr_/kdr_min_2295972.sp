#include <sourcemod>

Database g_Database = null;

ConVar sm_kdr_min;
ConVar sm_kdr_sqlgroup;

char g_WhitelistFile[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
    sm_kdr_min = CreateConVar("sm_kdr_min", "1.2", "Minimum KDR for player to stay in the server.");
    sm_kdr_sqlgroup = CreateConVar("sm_kdr_sqlgroup", "default", "SQL Configuration to use");

    AutoExecConfig(true, "kdr", "sourcemod");

    BuildPath(Path_SM, g_WhitelistFile, sizeof(g_WhitelistFile), "configs/kdr/whitelist.txt");
}

public void OnConfigsExecuted()
{
    char group[64];
    sm_kdr_sqlgroup.GetString(group, sizeof(group));

    Database.Connect(SQL_OnDatabaseConnect, group);
}

public void SQL_OnDatabaseConnect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        LogError("Error connecting to database: %s", error);
        return;
    }

    g_Database = db;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            CheckClientKDR(client);
        }
    }
}

public void OnClientPostAdminCheck(int client)
{
    if (g_Database == null) return;

    CheckClientKDR(client);
}

void CheckClientKDR(int client)
{
    static char auth[64];
    GetClientAuthId(client, AuthId_Steam3, auth, sizeof(auth));

    File f = OpenFile(g_WhitelistFile, "r");

    if (f != null)
    {
        static char line[128];
        bool inFile = false;

        while (!f.EndOfFile())
        {
            f.ReadLine(line, sizeof(line));
            TrimString(line);

            if (StrEqual(line, auth))
            {
                inFile = true;
                break;
            }
        }

        delete f;

        if (inFile)
            return;
    }

    static char query[256];
    FormatEx(query, sizeof(query), "SELECT Kills, Deaths FROM Players WHERE Steam3 = '%s';", auth);

    g_Database.Query(SQL_QueryPlayerKDR, query, GetClientSerial(client));
}

public void SQL_QueryPlayerKDR(Database db, DBResultSet results, const char[] error, any data)
{
    if (results == null)
    {
        LogError("Error getting client KDR: %s", error);
        return;
    }

    int client = GetClientFromSerial(data);

    if (!client)
        return;

    if (!results.FetchRow())
    {
        // Player does not exist in database
        KickClient(client, "You have no stats recorded to play here.");
    }
    else
    {
        int kills = results.FetchInt(0);
        int deaths = results.FetchInt(1);

        float KDR = float(kills);

        if (deaths > 0)
            KDR /= float(deaths);

        float minKDR = sm_kdr_min.FloatValue;

        if (KDR < minKDR)
        {
            // Player does not meet minimum KDR
            KickClient(client, "Your KDR of %0.2f is below the minimum of %0.2f", KDR, minKDR);
        }
    }
}