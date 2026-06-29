/*
    sm_retry

    Rewritten from sm_kick by: Chdata
*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION          "0x01"

//#define TF_MAX_PLAYERS          34
#define FCVAR_VERSION           FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_CHEAT

public Plugin:myinfo = {
    name = "Reconnector",
    author = "Chdata",
    description = "Allows connected players to be forcibly reconnected via sm_retry",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_retry", Cmd_Reconnect);
    RegConsoleCmd("sm_rejoin", Cmd_Reconnect);
    RegConsoleCmd("sm_reconnect", Cmd_Reconnect);
    LoadTranslations("core.phrases");
    LoadTranslations("common.phrases");
    LoadTranslations("retry.phrases");
    CreateConVar("cv_retry_version", PLUGIN_VERSION, "Retry Version", FCVAR_VERSION);
}

public Action:Cmd_Reconnect(iClient, iArgc)
{   
    //decl String:szTargetName[MAX_TARGET_LENGTH];
    //GetClientName(iClient, szTargetName, sizeof(szTargetName));

    if (!iArgc)
    {
        //ShowActivity2(iClient, "[SM] ", "%t", "Reconnected target", "_s", szTargetName); // "Reconnected by admin"
        //ReplyToCommand(iClient, "[SM] %t", "Reconnected target", "_s", szTargetName);
        //LogAction(iClient, iClient, "\"%L\" reconnected \"%L\" (reason \"%s\")", iClient, iClient, reason);
        ClientCommand(iClient, "retry");
    }
    else if (CheckCommandAccess(iClient, "sm_retry", ADMFLAG_KICK))
    {
        decl String:szTargetName[MAX_TARGET_LENGTH];
        GetClientName(iClient, szTargetName, sizeof(szTargetName));

        decl String:szArguments[256];
        GetCmdArgString(szArguments, sizeof(szArguments));

        decl String:szTarget[65];
        new iLen = BreakString(szArguments, szTarget, sizeof(szTarget));
        
        if (iLen == -1)
        {
            /* Safely null terminate */
            iLen = 0;
            szArguments[0] = '\0';
        }

        decl String:szReason[64];
        Format(szReason, sizeof(szReason), szArguments[iLen]);

        if (StrEqual(szTarget, "@me"))
        {
            if (szReason[0] == '\0')
            {
                ShowActivity2(iClient, "[SM] ", "%t", "Reconnected target", "_s", szTargetName);
                //ReplyToCommand(iClient, "[SM] %t", "Reconnected target", "_s", szTargetName);
            }
            else
            {
                ShowActivity2(iClient, "[SM] ", "%t", "Reconnected target reason", "_s", szTargetName, szReason);
                //ReplyToCommand(iClient, "[SM] %t", "Reconnected target reason", "_s", szTargetName, szReason);
            }

            //LogAction(iClient, iClient, "\"%L\" reconnected \"%L\" (reason \"%s\")", iClient, iClient, szReason);

            ClientCommand(iClient, "retry");
            return Plugin_Handled;
        }

        decl iTargetList[MAXPLAYERS], iTargetCount, bool:bMultiLang;
        
        if ((iTargetCount = ProcessTargetString(
                szTarget,
                iClient, 
                iTargetList, 
                MAXPLAYERS, 
                COMMAND_FILTER_CONNECTED|COMMAND_FILTER_NO_BOTS,
                szTargetName,
                sizeof(szTargetName),
                bMultiLang)) > 0)
        {
            if (bMultiLang)
            {
                if (szReason[0] == '\0')
                {
                    ShowActivity2(iClient, "[SM] ", "%t", "Reconnected target", szTargetName);
                    //ReplyToCommand(iClient, "[SM] %t", "Reconnected target", szTargetName);
                }
                else
                {
                    ShowActivity2(iClient, "[SM] ", "%t", "Reconnected target reason", szTargetName, szReason);
                    //ReplyToCommand(iClient, "[SM] %t", "Reconnected target reason", szTargetName, szReason);
                }
            }
            else
            {
                if (szReason[0] == '\0')
                {
                    ShowActivity2(iClient, "[SM] ", "%t", "Reconnected target", "_s", szTargetName);
                    //ReplyToCommand(iClient, "[SM] %t", "Reconnected target", "_s", szTargetName);
                }
                else
                {
                    ShowActivity2(iClient, "[SM] ", "%t", "Reconnected target reason", "_s", szTargetName, szReason);
                    //ReplyToCommand(iClient, "[SM] %t", "Reconnected target reason", "_s", szTargetName, szReason);
                }
            }

            new iKickMySelf = 0;
            
            for (new i = 0; i < iTargetCount; i++)
            {
                /* Kick everyone else first */
                if (iTargetList[i] == iClient)
                {
                    iKickMySelf = iClient;
                }
                else
                {
                    ClientCommand(iTargetList[i], "retry");
                    //LogAction(iClient, iTargetList[i], "\"%L\" reconnected \"%L\" (reason \"%s\")", iClient, iTargetList[i], szReason);
                }
            }
            
            if (iKickMySelf)
            {
                //LogAction(iClient, iClient, "\"%L\" reconnected \"%L\" (reason \"%s\")", iClient, iClient, szReason);
                ClientCommand(iClient, "retry");
            }
        }
        else
        {
            ReplyToTargetError(iClient, iTargetCount);
        }
    }
    else
    {
        ReplyToCommand(iClient, "[SM] You cannot target other players.");
    }
    
    return Plugin_Handled;
}
