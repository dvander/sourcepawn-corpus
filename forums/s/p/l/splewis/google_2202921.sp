#include <sourcemod>
#pragma semicolon 1

public Plugin:myinfo = {
    name = "Google",
    author = "SoulSharD, Franc1sco, Dark Star HD, splewis",
    description = "",
    version = "1.0.0",
    url = "https://forums.alliedmods.net/showthread.php?t=248552"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_google", Command_Google);
}

public Action:Command_Google(client, args)
{
    new String:strSearch[512];
    GetCmdArgString(strSearch, sizeof(strSearch));
    Format(strSearch, sizeof(strSearch), "https://www.google.com/search?q=%s", strSearch);
    FixMotdCSGO(strSearch);
    ShowMOTDPanel(client, "Google", strSearch, MOTDPANEL_TYPE_URL);
    return Plugin_Handled;
}

stock FixMotdCSGO(String:web[512])
{
    // Thanks to Franc1sco for this service, pulled from "Web shortcuts" plugin for CS:GO
    Format(web, sizeof(web), "http://www.cola-team.es/franug/webshortcuts.html?web=%s", web);
}
