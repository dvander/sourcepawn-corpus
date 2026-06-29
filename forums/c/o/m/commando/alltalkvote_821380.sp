//Includes:
#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new bool:firstclientconnected = false

public Plugin:myinfo = 
{
	name = "TF2 Alltalk Vote",
	author = "R-Hehl",
	description = "TF2 Alltalk",
	version = PLUGIN_VERSION,
	url = "http://HLPortal.de"
};
public OnPluginStart()
{
	CreateConVar("sm_tf2_alltalk_version", PLUGIN_VERSION, "TF2 Alltalk", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}
public OnMapStart()
{
	firstclientconnected = false
}
public OnClientPostAdminCheck()
{
	if (!firstclientconnected)
	{
	CreateTimer(30.0, StartVote)
	firstclientconnected = true
	}
}
public Action:StartVote(Handle:timer)
{
	DoVoteMenu()
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} else if (action == MenuAction_VoteEnd) {
		/* 1=yes, 0=no */
		if (param1 == 0)
		{
			ServerCommand("sv_alltalk 1");
			PrintToChatAll("\x04[\x03TF2-Alltalk\x04]\x01 Alltalk Enabled")
		}
		else
		{
			PrintToChatAll("\x04[\x03TF2-Alltalk\x04]\x01 Alltalk Disabled")
			ServerCommand("sv_alltalk 0");
		}
	}
}
 
DoVoteMenu()
{
	if (IsVoteInProgress())
	{
		return;
	}
 
	new Handle:menu = CreateMenu(Handle_VoteMenu)
	SetMenuTitle(menu, "Allow Alltalk?")
	AddMenuItem(menu, "yes", "Yes")
	AddMenuItem(menu, "no", "No")
	SetMenuExitButton(menu, false)
	VoteMenuToAll(menu, 20);
}
