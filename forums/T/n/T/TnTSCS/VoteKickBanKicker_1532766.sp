/* Plugin to kick certain playerss who type !votekick or !voteban
* Requested by ph (http://forums.alliedmods.net/member.php?u=9808)
* Request thread is http://forums.alliedmods.net/showthread.php?t=164704 
* 
* Version 1.0 - Initial release
* Version 1.1 - Added code to only kick those that are assigned custom5 flag ("s")
* 
* */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "VoteKickBan Kicker",
	author = "TnTSCS aKa ClarKKent",
	description = "Kicks certain players who use !votekick or !voteban",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=164704"
}

public OnPluginStart()
{
	CreateConVar("sm_VoteKickBanKicker_version", PLUGIN_VERSION, "The version of 'VoteKickBanKicker'", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
}

public KickForVote(client)
{
	if(IsClientConnected(client))
	{
		KickClient(client, "You are not allowed to use !votekick or !voteban");
	}
}

public Action:Command_Say(client, args)
{
	
	// When someone types !votekick or !voteban
	decl String:text[192], String:command[64];
	new startidx = 0;
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	if (strcmp(text[startidx], "!voteban", false) == 0 || strcmp(text[startidx], "!votekick", false) == 0)
	{
		if(client == 0)
		{
			return Plugin_Handled;
		}
		if(GetUserFlagBits(client) & ADMFLAG_CUSTOM5)
		{
			KickForVote(client);
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}