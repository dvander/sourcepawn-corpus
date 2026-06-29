#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
int g_iVoteCount; 
bool voted[MAXPLAYERS + 1] = false;
Handle convar = INVALID_HANDLE;
public Plugin myinfo = 
{
	name = "AllTalk vote by players",
	author = "BraveFox",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/bravefox"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_voteforalltalk", Vote, 0);
	RegAdminCmd("sm_vfalltalk", Vote, 0);
	convar = FindConVar("sv_alltalk");
}
public Action Vote(int client,int args) 
{ 
    char steamid[64]; 
    GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)); 
     
    if (!voted[client]) 
    { 
        int playercount = (GetClientCount(true) / 2); 
        g_iVoteCount++; 
        int Missing = playercount - g_iVoteCount + 1; 
        voted[client] = true;
        if(g_iVoteCount > playercount) 
        { 
	Menu menu = new Menu(Handle_VoteMenu);
	menu.SetTitle("Turn On AllTalk?");
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
	PrintToChatAll("AllTalk vote has started!")
        return Plugin_Handled;
        } 
        else PrintToChatAll("%N has voted for alltalk vote need %i more players", client, Missing); 
    } 
    else if(voted[client])
    {
    ReplyToCommand(client, "You Already voted"); 
    return Plugin_Handled;
    }
     
    return Plugin_Handled; 
}  

public int Handle_VoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	} 
	else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
            PrintToChatAll("Alltalk has turend on!");
            SetConVarString(convar, "1", true);
		}
		if (param1 == 1)
		{
                    PrintToChatAll("Alltalk will not turn on!");
                    SetConVarString(convar, "0", true);
		}
	}
}