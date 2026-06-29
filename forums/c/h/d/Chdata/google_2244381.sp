#pragma semicolon 1
#include <sourcemod>

enum MOTDFailureReason {
    MOTDFailure_Unknown, // Failure reason unknown
    MOTDFailure_Disabled, // Client has explicitly disabled HTML MOTDs
    MOTDFailure_Matchmaking, // HTML MOTD is disabled by Quickplay/matchmaking (TF2 only)
    MOTDFailure_QueryFailed // cl_disablehtmlmotd convar query failed
};

functag public MOTDFailure(client, MOTDFailureReason:reason);

#define PLUGIN_VERSION  "0x05"

public Plugin:myinfo = {
    name = "Google Search Command",
    author = "Chdata",
    description = "Allows players to perform google searches.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_google", cdGoogle);
    RegAdminCmd("sm_lmgtfy", cdLmgtfy, ADMFLAG_KICK);
    RegConsoleCmd("sm_yt", cdYoutube);
    LoadTranslations("common.phrases");
}

public Action:cdGoogle(iClient, iArgc)
{
    if (!iArgc)
    {
        ReplyToCommand(iClient, "[SM] Usage: !google <search terms>");
        return Plugin_Handled;
    }

    if (!iClient)
    {
        ReplyToCommand(iClient, "[SM] Can't show html pages to console.");
        return Plugin_Handled;
    }

    decl String:szLink[512];
    GetCmdArgString(szLink, sizeof(szLink));
    Format(szLink, sizeof(szLink), "https://www.google.com/search?q=%s", szLink);
    //ShowMOTDPanel(iClient, "Google Search", szLink, MOTDPANEL_TYPE_URL);
    AdvMOTD_ShowMOTDPanel(iClient, "Google Search", szLink, MOTDPANEL_TYPE_URL, true, false, true, MOTDFailureCallback);

    return Plugin_Handled;
}

public Action:cdLmgtfy(iClient, iArgc)
{
    if (iArgc < 2)
    {
        ReplyToCommand(iClient, "[SM] Usage: !lmgtfy \"player name\" <search terms>");
        return Plugin_Handled;
    }

    decl String:szName[32];
    GetCmdArg(1, szName, sizeof(szName));

    new iTarget = FindTarget(iClient, szName, true, false);

    if (iTarget <= 0)
    {
        ReplyToCommand(iClient, "[SM] Could not find player \"%s\"", szName);
        return Plugin_Handled;
    }

    decl String:szLink[512];
    GetCmdArgString(szLink, sizeof(szLink));
    new iExtra = szLink[strlen(szName)+1] == '"' ? 2 : 1;
    Format(szLink, sizeof(szLink), "http://lmgtfy.com/?q=%s", szLink[strlen(szName)+iExtra]);
    //ShowMOTDPanel(iTarget, "LMGTFY", szLink, MOTDPANEL_TYPE_URL);
    AdvMOTD_ShowMOTDPanel(iClient, "LMGTFY", szLink, MOTDPANEL_TYPE_URL, true, false, true, MOTDFailureCallback);
    return Plugin_Handled;
}

public Action:cdYoutube(iClient, iArgc)
{
    if (!iArgc)
    {
        ReplyToCommand(iClient, "[SM] Usage: !yt <search terms>");
        return Plugin_Handled;
    }

    if (!iClient)
    {
        ReplyToCommand(iClient, "[SM] Can't show html pages to console.");
        return Plugin_Handled;
    }

    decl String:szLink[512];
    GetCmdArgString(szLink, sizeof(szLink));
    Format(szLink, sizeof(szLink), "https://www.youtube.com/results?search_query=%s", szLink);
    //ShowMOTDPanel(iClient, "Youtube Search", szLink, MOTDPANEL_TYPE_URL);
    AdvMOTD_ShowMOTDPanel(iClient, "Youtube Search", szLink, MOTDPANEL_TYPE_URL, true, false, true, MOTDFailureCallback);

    return Plugin_Handled;
}

public MOTDFailureCallback(iClient, MOTDFailureReason:iReason)
{
    PrintToChat(iClient, "[SM] You have MOTDs disabled. Consider enabling.");
}

// advanced_motd.inc

/**
 * Displays an MOTD panel to a client with advanced options
 * 
 * @param client        Client index the panel should be shown to
 * @param title         Title of the MOTD panel (not displayed on all games)
 * @param msg           Content of the MOTD panel; could be a URL, plain text, or a stringtable index
 * @param type          Type of MOTD this is, one of MOTDPANEL_TYPE_TEXT, MOTDPANEL_TYPE_INDEX, MOTDPANEL_TYPE_URL, MOTDPANEL_TYPE_FILE
 * @param visible       Whether the panel should be shown to the client
 * @param big           true if this should be a big MOTD panel (TF2 only)
 * @param verify        true if we should check if the client can actually receive HTML MOTDs before sending it, false otherwise
 * @param callback      A callback to be called if we determine that the client can't receive HTML MOTDs
 * @noreturn
 */
stock AdvMOTD_ShowMOTDPanel(client, const String:title[], const String:msg[], type=MOTDPANEL_TYPE_INDEX, bool:visible=true, bool:big=false, bool:verify=false, MOTDFailure:callback=INVALID_FUNCTION) {
    decl String:connectmethod[32];
    if(verify && GetClientInfo(client, "cl_connectmethod", connectmethod, sizeof(connectmethod))) {
        if(StrContains(connectmethod, "quickplay", false) != -1 || StrContains(connectmethod, "matchmaking", false) != -1) {
            if(callback != INVALID_FUNCTION) {
                AdvMOTD_CallFailure(callback, client, MOTDFailure_Matchmaking);
            }
            return;
        }
    }
    
    new Handle:kv = CreateKeyValues("data");
    KvSetString(kv, "title", title);
    KvSetNum(kv, "type", type);
    KvSetString(kv, "msg", msg);
    if(big) {
        KvSetNum(kv, "customsvr", 1);
    }
    
    if(verify) {
        new Handle:pack = CreateDataPack();
        WritePackCell(pack, _:kv);
        WritePackCell(pack, _:visible);
        WritePackCell(pack, _:callback);
        QueryClientConVar(client, "cl_disablehtmlmotd", AdvMOTD_OnQueryFinished, pack);
    } else {
        ShowVGUIPanel(client, "info", kv);
        CloseHandle(kv);
    }
}

public AdvMOTD_OnQueryFinished(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[], any:pack) {
    ResetPack(pack);
    new Handle:kv = Handle:ReadPackCell(pack);
    new bool:visible = bool:ReadPackCell(pack);
    new MOTDFailure:callback = MOTDFailure:ReadPackCell(pack);
    CloseHandle(pack);
    
    if(result != ConVarQuery_Okay || bool:StringToInt(cvarValue)) {
        CloseHandle(kv);
        if(callback != INVALID_FUNCTION) {
            AdvMOTD_CallFailure(callback, client, (result != ConVarQuery_Okay) ? MOTDFailure_QueryFailed : MOTDFailure_Disabled);
        }
        return;
    }
    
    ShowVGUIPanel(client, "info", kv, visible);
    CloseHandle(kv);
}

AdvMOTD_CallFailure(MOTDFailure:callback, client, MOTDFailureReason:reason) {
    Call_StartFunction(INVALID_HANDLE, callback);
    Call_PushCell(client);
    Call_PushCell(reason);
    Call_Finish();
}