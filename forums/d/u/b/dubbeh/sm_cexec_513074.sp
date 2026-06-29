/*
 * ma_cexec equivalent for sourcemod
 *
 * Coded by dubbeh - www.yegods.net
 *
 */

#include <sourcemod>

#pragma semicolon 1
#define PLUGIN_VERSION "1.0.0.3"

public Plugin:myinfo =
{
    name = "Client Execute",
    author = "dubbeh",
    description = "Execute commands on clients for SourceMod",
    version = PLUGIN_VERSION,
    url = "http://www.yegods.net/"
};


public OnPluginStart ()
{
    CreateConVar ("sm_cexec_version", PLUGIN_VERSION, "Client Exec version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    /* register the sm_cexec console command */
    RegAdminCmd ("sm_cexec", ClientExec, ADMFLAG_RCON);
}

public Action:ClientExec (client, args)
{
    decl String:szClient[MAX_NAME_LENGTH] = "";
    decl String:szCommand[80] = "";
    static iClient = -1, iMaxClients = 0;

    iMaxClients = GetMaxClients ();

    if (args == 2)
    {
        GetCmdArg (1, szClient, sizeof (szClient));
        GetCmdArg (2, szCommand, sizeof (szCommand));

        if (!strcmp (szClient, "#all", false))
        {
            for (iClient = 1; iClient <= iMaxClients; iClient++)
            {
                if (IsClientConnected (iClient) && IsClientInGame (iClient))
                {
                    if (IsFakeClient (iClient))
                        FakeClientCommand (iClient, szCommand);
                    else
                        ClientCommand (iClient, szCommand);
                }
            }
        }
        else if (!strcmp (szClient, "#bots", false))
        {
            for (iClient = 1; iClient <= iMaxClients; iClient++)
            {
                if (IsClientConnected (iClient) && IsClientInGame (iClient) && IsFakeClient (iClient))
                    FakeClientCommand (iClient, szCommand);
            }
        }
        else if ((iClient = FindTarget (client, szClient, false, true)) != -1)
        {
            if (IsFakeClient (iClient))
                FakeClientCommand (iClient, szCommand);
            else
                ClientCommand (iClient, szCommand);
        }
    }
    else
    {
        ReplyToCommand (client, "sm_cexec invalid format");
        ReplyToCommand (client, "Usage: sm_cexec \"<user>\" \"<command>\"");
    }

    return Plugin_Handled;
}

