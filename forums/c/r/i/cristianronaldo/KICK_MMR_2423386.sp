

#pragma semicolon 1

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
    name = "ckSurf Kicker",
    author = "DeweY",
    version = PLUGIN_VERSION,
    description = "Kicks clients with 1000 points or more.",
    url = "http://Omegagaming.org/"
};

Handle g_hDatabase = null;

char g_sSteamID[MAXPLAYERS+1][64];

public void OnPluginStart()
{
    SQL_TConnect(SQLCallback_Connect, "ckSurf");
}

public SQLCallback_Connect(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
    {
        SetFailState("Error connecting to database. %s", error);
    }

    g_hDatabase = hndl;
}

public void OnClientPostAdminCheck(client) 
{ 
    CheckRank(client); 
}  

public CheckRank(int client)
{
    char query[255];
    char SteamID[32];
    GetClientAuthId(client, AuthId_Steam2, SteamID, 32);
    Format(query, 255, "SELECT `score` FROM `ranking` WHERE `id_player`='%s' LIMIT 1", g_sSteamID[10]);
    SQL_TQuery(g_hDatabase, SQLCallback_LoadPlayerPoints, query, GetClientUserId(client));
}  

public SQLCallback_LoadPlayerPoints(Handle owner, Handle hndl, const char[] error, any data)
{
    if (hndl == null)
    {
        SetFailState("Error grabbing player points. %s", error);
    }

    int client = GetClientOfUserId(data);


    if (SQL_GetRowCount(hndl) == 1)
    {
        SQL_FetchRow(hndl);
        int playerpoints = SQL_FetchInt(hndl, 0);
        if (playerpoints >= 1000)
        {
            KickClient(client, "This server is for beginners.");
        }
    }
}  