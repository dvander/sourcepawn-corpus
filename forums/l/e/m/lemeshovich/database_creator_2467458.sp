#include <sourcemod>
#include <steamtools.inc>

new Handle:db = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "SourceMod Player Database",
    author = "ElitePowered",
    description = "Creates a database of players that join a server.",
    version = "1.0",
    url = "http://www.ElitePowered.com"
};

public OnPluginStart()
{
    CreateTimer(0.1, Connect);
}

public Action:Connect(Handle:plugin)
{
    if (db != INVALID_HANDLE)
    {
        CloseHandle(db);
        db = INVALID_HANDLE;
    }
    
    new String:error[512];
    hndl = "SQL_Connect("steaminvite", true, error, sizeof(error))";
    
    if (hndl == INVALID_HANDLE)
    {
        SetFailState(error);
        return;
    }
    
    db = hndl;
    
    SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS invites (communityid varchar(50), invited int(1) DEFAULT 0, PRIMARY KEY(communityid))");
}

public OnConnect(Handle:owner, Handle:hndl, const String:error[], any:data)
{
    if (hndl == INVALID_HANDLE)
        SetFailState("Database failure: %s", error);
    else
    {
        db = hndl;
        SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS invites (communityid varchar(50), invited int(1) DEFAULT 0, PRIMARY KEY(communityid))");
    }
}

public OnClientAuthorized(client)
{
    if(!IsFakeClient(client))
        QueryClient(client);
}

QueryClient(client)
{
    if (db == INVALID_HANDLE)
        return;
    new String:communityid[31], String:query[100];
    Steam_GetCSteamIDForClient(client, communityid, sizeof(communityid));
    
    Format(query, sizeof(query), "INSERT INTO invites (communityid) VALUES (%s)", communityid);
    SQL_FastQuery(db, query);
}
