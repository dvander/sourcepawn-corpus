#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "AllTalk Vote",
	author      = "BraveFox",
	description = "AllTalk vote by cmd",
	version     = "1.0",
	url         = "http://steamcommunity.com/id/bravefox"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_alltalkvote", Command_vote, ADMFLAG_GENERIC);
	RegAdminCmd("sm_alltalkv", Command_vote, ADMFLAG_GENERIC);
}

public Action Command_vote(int client, int args)
{
	if (IsVoteInProgress())
	{
		return;
	}
 
	Menu menu = new Menu(Handle_VoteMenu);
	menu.SetTitle("Enable AllTalk?");
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
	PrintToChatAll("[AllTalk]AllTalk vote has started! vote now!");
}
public int Handle_VoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	} 
	else if (action == MenuAction_VoteEnd) {
	if(parma1 == 0)
	{
		PrintToChatAll("[AllTalk]AllTalk vote has ended! AllTalk will turn on!(vote result)");
		ServerCommand("sv_alltalk 1");
	}
	if(parma1 == 1)
	{
		PrintToChatAll("[AllTalk]AllTalk vote has ended! AllTalk will not turn on!(vote result)");
	}
	}
}	