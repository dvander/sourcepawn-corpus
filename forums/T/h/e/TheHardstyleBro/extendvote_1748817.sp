#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

//Has a vote seems to be completed?
new bool:vote_already;

new Handle:sm_extendvote_maxtime = INVALID_HANDLE;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "Extend map vote",
	author = "The.Hardstyle.Bro^_^",
	description = "Extend the map",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	AutoExecConfig(true, "Extendvote");
	CreateConVar("sm_extendvote_version", PLUGIN_VERSION, "Defines the version of the Extend Vote plugin installed on this server", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	sm_extendvote_maxtime = CreateConVar("sm_extendvote_maxtime", "100", "Amount of maxium time to extend");
	RegAdminCmd("sm_voteextend", Command_VoteExtend, ADMFLAG_VOTE, "Vote extend command");
	RegAdminCmd("sm_extendvote", Command_VoteExtend, ADMFLAG_VOTE, "Vote extend command");

}

public OnMapStart()
{
	vote_already = false;

}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		CloseHandle(menu);
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			new String:minutes[64];
			GetMenuItem(menu, param1, minutes, sizeof(minutes));
			ExtendMap(StringToInt(minutes));
			vote_already = true;
		}
		else
		{
			PrintToChatAll("\x04[Extend-Vote] \x03Vote has failed. Map has not been extended.");	
		}
	}
}

ExtendMap(mins)
{
	ExtendMapTimeLimit(mins*60);
	PrintToChatAll("\x04[Extend-Vote] \x03Map has been extended for %d minutes", mins);
}

public Action:Command_VoteExtend(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_voteextend <minutes>");
		return Plugin_Handled;	
	}
	if (vote_already)
    {
		PrintToChat(client, "\x04[Extend-Vote]\x03 There was already an extend vote.");
		return Plugin_Handled;	
 	}
	
	new String:minutes[64];
	GetCmdArg(1, minutes, sizeof(minutes));
	if (StringToInt(minutes) > GetConVarInt(sm_extendvote_maxtime))
	{
	ReplyToCommand(client, "[SM] The amount of time is too high too extend");
	return Plugin_Handled;	
	}
	ShowActivity2(client, "[SM] ", "Initiated Vote Extend map");
	LogAction(client, -1, "\"%L\" used sm_voteextend.", client);
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, "Extend map by %d minutes?", StringToInt(minutes));
	AddMenuItem(menu, minutes, "Yes");
	AddMenuItem(menu, "no", "No");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 20);
		
	return Plugin_Handled;
}