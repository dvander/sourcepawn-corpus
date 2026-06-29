#include <sourcemod>
//#include <sdktools>
//#include <cstrike>
//#include <sdkhooks>
//#include <multicolors>
//#include <clientprefs>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
    name = "Timeleft Panel",
    author = "Busted",
    description = "Timeleft in a Panel",
    version = "1.0",
    url = "https://attawaybaby.com/"
};

public void OnPluginStart() {
    //RegConsoleCmd("sm_panel", PanelCmd);
    CreateTimer(1.0, PanelCmd, _, TIMER_REPEAT);
    //PrintToChatAll("loaded");
}

//public Action PanelCmd(int client, int args)
public Action PanelCmd(Handle timer)
{
    //PrintToChatAll("cycle");
    for(int client = 1; client <= MaxClients; client++)
    {
        if (!IsValidClient(client) || IsFakeClient(client) || GetClientMenu(client) != MenuSource_None)
            continue;

        int iTimeleft;
        GetMapTimeLeft(iTimeleft);
        int mins = iTimeleft / 60;
        int secs = iTimeleft % 60;
        char sPanel[256], sMins[60], sSecs[60];

        if (mins > 0)
        {
            Format(sMins, sizeof(sMins), "Timeleft: %d mins", mins);

            Handle panel = CreatePanel();
            Format(sPanel, sizeof(sPanel), "%s", sMins);
            DrawPanelText(panel, sPanel);
            SendPanelToClient(panel, client, PanelHandler, 1);
            CloseHandle(panel);
        }
        else
        {
            Format(sSecs, sizeof(sSecs), "Timeleft: %d secs", secs);

            Handle panel = CreatePanel();
            Format(sPanel, sizeof(sPanel), "%s", sSecs);
            DrawPanelText(panel, sPanel);
            SendPanelToClient(panel, client, PanelHandler, 1);
            CloseHandle(panel);            
        }
    }

    return Plugin_Handled;
}

public int PanelHandler(Handle menu, MenuAction action, int param1, int param2)
{

}

stock bool IsValidClient(int client)
{
    if (client >= 1 && client <= MaxClients && IsValidEntity(client) && IsClientConnected(client) && IsClientInGame(client))
        return true;
    return false;
}