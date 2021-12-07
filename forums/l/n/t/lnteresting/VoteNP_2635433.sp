#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_AUTHOR "Interesting"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "Vote No Spread",
    author = PLUGIN_AUTHOR,
    description = "Voting for No Spread",
    version = PLUGIN_VERSION,
    url = "https://steamcommunity.com/id/WeShallGetThisBread/"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_votenp", Command_VoteNP, ADMFLAG_VOTE | ADMFLAG_SLAY);
    RegAdminCmd("sm_enablenp", Command_EnableNP, ADMFLAG_VOTE | ADMFLAG_SLAY);
    RegAdminCmd("sm_disablenp", Command_DisableNP, ADMFLAG_VOTE | ADMFLAG_SLAY);
}

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
    }
    else if (action == MenuAction_VoteEnd)
    {
        /* 0=yes, 1=no */
        if (param1 == 0)
        {
            ServerCommand("weapon_accuracy_nospread 1");
            PrintToChatAll("[SM] No-Spread has been enabled");
        }
        if (param1 == 1)
        {
        	ServerCommand("weapon_accuracy_nospread 0");
        	PrintToChatAll("[SM] No-Spread Vote has failed");
        }
    }
}

public Action Command_VoteNP(int client, int args)
{
    if(IsVoteInProgress())
    {
        return Plugin_Handled;
    }
    DoVoteMenu();
    return Plugin_Handled;
}

void DoVoteMenu()
{
    Menu menu = new Menu(Handle_VoteMenu);
    menu.SetTitle("Enable No-Spread?");
    menu.AddItem("", "Yes");
    menu.AddItem("", "No");
    menu.ExitButton = false;
    menu.DisplayVoteToAll(20);
}  

public Action Command_EnableNP(int client, int args)
{
	PrintToChatAll("[SM] No-Spread was enabled");
	ServerCommand("weapon_accuracy_nospread 1");
}

public Action Command_DisableNP(int client, int args)
{
	PrintToChatAll("[SM] No-Spread was disabled");
	ServerCommand("Weapon_accuracy_nospread 0");
}