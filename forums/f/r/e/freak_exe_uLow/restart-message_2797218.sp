#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

int g_iTimestamp;

public void OnPluginStart()
{
    AddCommandListener(ListenCommand_Timeleft, "timeleft");

    char sError[256];
    Database hDatabase = SQLite_UseDatabase("storage-local", sError, sizeof(sError));

    if (hDatabase == null)
    {
        SetFailState("Error while connecting to database! Error: %s", sError);
        return;
    }

    DBResultSet hResults = SQL_Query(hDatabase, "SELECT strftime('%s','now','start of day','+5 hours','-1 seconds','utc')");

    if (!SQL_FetchRow(hResults))
    {
        SetFailState("No rows found!");
        return;
    }

    g_iTimestamp = SQL_FetchInt(hResults, 0);

    if ((g_iTimestamp - GetTime()) < 5 )
    {
        delete hResults;

        hResults = SQL_Query(hDatabase, "SELECT strftime('%s','now','start of day','+1 day','+5 hours','-1 seconds','utc')");

        if (!SQL_FetchRow(hResults))
        {
            SetFailState("No rows found!");
            return;
        }

        g_iTimestamp = SQL_FetchInt(hResults, 0);
    }

    CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);
    
    delete hResults;
    delete hDatabase;
}

public Action ListenCommand_Timeleft(int client, const char[] command, int argc)
{
    int iTimeleft = g_iTimestamp - GetTime();

    char sDatetime[60];
    FormatTime(sDatetime, sizeof(sDatetime), NULL_STRING, g_iTimestamp);

    ReplyToCommand(client, "[SM] Restart server in \
                            %02iHours %02iMinutes %02iSeconds\
                            \nDatetime = %s",
                            iTimeleft / 3600 % 24, iTimeleft / 60 % 60, iTimeleft % 60,
                            sDatetime);

    return Plugin_Continue;
}


public Action Timer_Second(Handle timer)
{
    int iTimeleft = g_iTimestamp - GetTime();

    switch(iTimeleft)
    {
        case 900:
        {
            PrintToChatAll("[Server Message] Server restart in %i minutes", iTimeleft / 60);
        }
        case 600:
        {
            PrintToChatAll("[Server Message] Server restart in %i minutes", iTimeleft / 60);
        }
        case 10,5,4,3,2:
        {
            PrintToChatAll("[Server Message] Server restart in %i seconds", iTimeleft);
        }
        case 1:
        {
            PrintToChatAll("[Server Message] Server restart in %i second", iTimeleft);
        }
        case 0:
        {
            PrintToChatAll("[Server Message] Server restart Now!");
        }
    }

    return Plugin_Continue;
}