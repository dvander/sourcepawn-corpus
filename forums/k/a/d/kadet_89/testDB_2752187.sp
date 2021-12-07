#include <sourcemod>
#include <cstrike>

Handle g_SQL = null;

public void OnPluginStart()
{
    SQL_TConnect(GotDatabase, "bans");
}

public void GotDatabase(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl == INVALID_HANDLE)
    {
        g_SQL = INVALID_HANDLE;
        LogError("%s", error);
    } 
    else 
    {
        g_SQL = hndl;
        
        LogMessage("SQL_SetCharset(g_SQL, \"utf8mb4\")");
        SQL_SetCharset(g_SQL, "utf8mb4");

        SQL_TQuery(g_SQL, ErrorCheckCallback, "CREATE TABLE IF NOT EXISTS `groups` (playerauthid VARCHAR(32), indexgroup INT(2), UNIQUE (playerauthid))", 0); 
        LogMessage( "Connected to database");
    }
}

public void ErrorCheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{ 
    if (hndl == INVALID_HANDLE) LogMessage(error);
}