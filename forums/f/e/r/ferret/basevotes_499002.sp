/**
 * basevotes.sp
 * Implements basic admin votes
 *
 * Changelog:
 *
 * Version 1.3
 * - Abandoned hungarian notation
 * - New cvar: sm_vote_say. Default is off. Allows players to use votekick and voteban by
 *     saying them. "say votekick player". Personally, I would NOT use it. But it was
 *     requested, so there you go. Don't get yourself banned!
 *
 * Version 1.2 (June 29th)
 * - Conform to plugin submission standards 
 * - Add version cvar sm_basevotes_version 
 *
 * Version 1.1 (June 28th)
 * - Several fixes due to bad "Replace All" 
 *
 * June 17th
 * - Requires SourceMod build R981 or higher 
 * - Took out timers that force cancel of menus, fixed in R981 
 * - Added a "no votes received" message if no one voted. 
 * - Took out vote counter variables, added to MenuAPI in R965 
 *
 * June 16th
 * - Fixed vote failure percents being 61% 
 * - using a time to force votes to end in 20 seconds until MENU Api is fixed. 
 * - Other little tweaks (Make sure to get the translation file) 
 * - Changed ALL commands to ADM_VOTE access. 
 *
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "Basic Votes",
	author = "ferret",
	description = "Basic Vote Commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:g_hVoteMenu = INVALID_HANDLE;
new Handle:g_hBanForward = INVALID_HANDLE;

new Handle:g_Cvar_VoteMap = INVALID_HANDLE;
new Handle:g_Cvar_Votekick = INVALID_HANDLE;
new Handle:g_Cvar_Voteban = INVALID_HANDLE;
new Handle:g_Cvar_Voteshow = INVALID_HANDLE;
new Handle:g_Cvar_Votesay = INVALID_HANDLE;

// Menu API does not provide us with a way to pass multiple peices of data with a single
// choice, so some globals are used to hold stuff.
//
new String:g_voteReason[256]; /* For Bans and Kicks */
new String:g_voteTarget[65]; /* For Bans and Kicks, target's name */
new g_voteClient; /* For Bans and Kicks, target's client index */
new String:g_voteQuestion[64]; /* For custom votes */

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");
	LoadTranslations("plugin.basevotes");
	
	CreateConVar("sm_basevotes_version", PLUGIN_VERSION, "BaseVotes Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	CreateConVar("sm_basevotes_version", PLUGIN_VERSION, "BaseVotes Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);	
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);	
	
	RegAdminCmd("sm_votemap", Command_Votemap, ADMFLAG_VOTE, "sm_votemap <mapname> [mapname2] ... [mapname5] ");
	RegAdminCmd("sm_votekick", Command_Votekick, ADMFLAG_VOTE, "sm_votekick <player> [reason]");
	RegAdminCmd("sm_voteban", Command_Voteban, ADMFLAG_VOTE, "sm_voteban <player> [reason]");
	RegAdminCmd("sm_vote", Command_Vote, ADMFLAG_VOTE, "sm_vote <question> [Answer1] [Answer2] ... [Answer5]");
	RegAdminCmd("sm_votecancel", Command_Votecancel, ADMFLAG_VOTE, "sm_votecancel");

	g_Cvar_VoteMap = CreateConVar("sm_vote_map", "0.60", "percent required for successful map vote.", 0, true, 0.05, true, 1.0);
	g_Cvar_Votekick = CreateConVar("sm_vote_kick", "0.60", "percent required for successful kick vote.", 0, true, 0.05, true, 1.0);	
	g_Cvar_Voteban = CreateConVar("sm_vote_ban", "0.60", "percent required for successful ban vote.", 0, true, 0.05, true, 1.0);	
	g_Cvar_Voteshow = CreateConVar("sm_vote_show", "1", "Show player's votes? Default on.", 0, true, 0.0, true, 1.0);	
	g_Cvar_Votesay = CreateConVar("sm_vote_say", "0", "Allows players to start votekick and voteban. Default off.", 0, true, 0.0, true, 1.0);	
	
	g_hBanForward = CreateGlobalForward("OnClientBanned", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String);
}

public Action:Command_Say(client, args)
{
	if (!GetConVarBool(g_Cvar_Votesay))
		return Plugin_Continue;
	
	decl String:text[192];
	GetCmdArgString(text, sizeof(text));
	text[strlen(text)-1] = '\0';
	
	decl String:command[8], String:target[64];
	new len = BreakString(text, command, 8);
	BreakString(text[len], target, 64);
	
	if (strcmp(command, "voteban", false) != 0 && strcmp(command, "votekick", false) != 0)
		return Plugin_Continue;

	new clients[2];
	new numClients = SearchForClients(target, clients, 2);
		
	if (numClients == 0)
	{
		PrintToChat(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (numClients > 1)
	{
		PrintToChat(client, "[SM] %t", "More than one client matches", target);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, clients[0]))
	{
		PrintToChat(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}		
	
	if (strcmp(command, "votekick", false) == 0)
	{
		g_voteClient = clients[0];
	
		strcopy(g_voteReason, sizeof(g_voteReason), "Player vote via 'say votekick'");

		new userId = GetClientUserId(clients[0]);
		GetClientName(clients[0], g_voteTarget, sizeof(g_voteTarget));
	
		new String:userIdStr[32];
		IntToString(userId, userIdStr, sizeof(userIdStr));
	
		g_hVoteMenu = CreateMenu(Handler_VoteKickMenu);
		SetMenuTitle(g_hVoteMenu, "%T", "Kick Player", LANG_SERVER, g_voteTarget);
		AddMenuItem(g_hVoteMenu, userIdStr, "Yes");
		AddMenuItem(g_hVoteMenu, "No", "No");
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);
	}
	else if (strcmp(command, "voteban", false) == 0)
	{
		if (IsFakeClient(clients[0]))
		{
			PrintToChat(client, "[SM] %t", "Cannot target bot");
			return Plugin_Handled;
		}
	
		g_voteClient = clients[0];

		strcopy(g_voteReason, sizeof(g_voteReason), "Player vote via 'say voteban'");
	
		new userId = GetClientUserId(clients[0]);
		GetClientName(clients[0], g_voteTarget, sizeof(g_voteTarget));

		new String:userIdStr[32];
		IntToString(userId, userIdStr, sizeof(userIdStr));
	
		g_hVoteMenu = CreateMenu(Handler_VoteBanMenu);
		SetMenuTitle(g_hVoteMenu, "%T", "Ban Player", LANG_SERVER, g_voteTarget);
		AddMenuItem(g_hVoteMenu, userIdStr, "Yes");
		AddMenuItem(g_hVoteMenu, "No", "No");
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);			
	}

	return Plugin_Continue;	
}


public Action:Command_Votemap(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_votemap <mapname> [mapname2] ... [mapname5]");
		return Plugin_Handled;	
	}
	
	if (g_hVoteMenu != INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}	
	
	new String:maps[5][64];
	new mapCount = 1;
	
	GetCmdArg(1, maps[0], 64); // Can't use sizeof() on multidimensional
	
	if (args > 1)
	{
		GetCmdArg(2, maps[1], 64);
		
		if (args > 2)
		{
			GetCmdArg(3, maps[2], 64);
		}
		
		if (args > 3)
		{
			GetCmdArg(4, maps[3], 64);
		}

		if (args > 4)
		{
			GetCmdArg(5, maps[4], 64);
			mapCount = 5;
		}
		else
			mapCount = args;
		
	}
	
	for (new i = 0; i < mapCount; i++)
	{
		if (!IsMapValid(maps[i]))
		{
			ReplyToCommand(client, "[SM] %t", "Map was not found", maps[i]);
			return Plugin_Handled;
		}
	}

	ShowActivity(client, "%t", "Initiated Vote Map");
	
	if (mapCount == 1)
	{
		g_hVoteMenu = CreateMenu(Handler_VoteMapMenu);
		SetMenuTitle(g_hVoteMenu, "%T", "Change Map To", LANG_SERVER, maps[0]);
		AddMenuItem(g_hVoteMenu, maps[0], "Yes");
		AddMenuItem(g_hVoteMenu, "no", "No");
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);		
	}
	else
	{
		g_hVoteMenu = CreateMenu(Handler_VoteMapMenu);
		SetMenuTitle(g_hVoteMenu, "%T", "Map Vote", LANG_SERVER);
		for (new i = 0; i < mapCount; i++)
		{
			AddMenuItem(g_hVoteMenu, maps[i], maps[i]);
		}	
		SetMenuExitButton(g_hVoteMenu, false);
		VoteMenuToAll(g_hVoteMenu, 20);		
	}
	
	return Plugin_Handled;	
}

public Action:Command_Votekick(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_votekick <player> [reason]");
		return Plugin_Handled;	
	}
	
	if (g_hVoteMenu != INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}	

	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	new clients[2];
	new numClients = SearchForClients(arg, clients, 2);
	
	if (numClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (numClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", arg);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, clients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	
	g_voteClient = clients[0];
	
	if (args < 2)
	{
		/* Safely null terminate */
		g_voteReason[0] = '\0';
	}
	else
	{
		GetCmdArg(2, g_voteReason, sizeof(g_voteReason));
	}

	new userId = GetClientUserId(clients[0]);
	GetClientName(clients[0], g_voteTarget, sizeof(g_voteTarget));

	ShowActivity(client, "%T", "Initiated Vote Kick", LANG_SERVER, g_voteTarget);
	
	new String:userIdStr[32];
	IntToString(userId, userIdStr, sizeof(userIdStr));
	
	g_hVoteMenu = CreateMenu(Handler_VoteKickMenu);
	SetMenuTitle(g_hVoteMenu, "%T", "Kick Player", LANG_SERVER, g_voteTarget);
	AddMenuItem(g_hVoteMenu, userIdStr, "Yes");
	AddMenuItem(g_hVoteMenu, "No", "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
	
	return Plugin_Handled;
}

public Action:Command_Voteban(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_voteban <player> [reason]");
		return Plugin_Handled;	
	}
	
	if (g_hVoteMenu != INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}	
	
	new String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	new clients[2];
	new numClients = SearchForClients(arg, clients, 2);
	
	if (numClients == 0)
	{
		ReplyToCommand(client, "[SM] %t", "No matching client");
		return Plugin_Handled;
	}
	else if (numClients > 1)
	{
		ReplyToCommand(client, "[SM] %t", "More than one client matches", arg);
		return Plugin_Handled;
	}
	else if (!CanUserTarget(client, clients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Unable to target");
		return Plugin_Handled;
	}
	else if (IsFakeClient(clients[0]))
	{
		ReplyToCommand(client, "[SM] %t", "Cannot target bot");
		return Plugin_Handled;
	}
	
	g_voteClient = clients[0];

	if (args >= 2)
	{
		GetCmdArg(2, g_voteReason, sizeof(g_voteReason));
	}
	else
	{
		g_voteReason[0] = '\0';
	}
	
	new userId = GetClientUserId(clients[0]);
	GetClientName(clients[0], g_voteTarget, sizeof(g_voteTarget));

	ShowActivity(client, "%t", "Initiated Vote Ban", g_voteTarget);
	
	new String:userIdStr[32];
	IntToString(userId, userIdStr, sizeof(userIdStr));
	
	g_hVoteMenu = CreateMenu(Handler_VoteBanMenu);
	SetMenuTitle(g_hVoteMenu, "%T", "Ban Player", LANG_SERVER, g_voteTarget);
	AddMenuItem(g_hVoteMenu, userIdStr, "Yes");
	AddMenuItem(g_hVoteMenu, "No", "No");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);	

	return Plugin_Handled;		
}

public Action:Command_Vote(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_vote <question> [Answer1] [Answer2] ... [Answer5]");
		return Plugin_Handled;	
	}

	if (g_hVoteMenu != INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] %t", "Vote in Progress");
		return Plugin_Handled;
	}
	
	new String:answers[5][64], answerCount = 1;
	GetCmdArg(1, g_voteQuestion, sizeof(g_voteQuestion));
	
	if (args > 1)
	{
		GetCmdArg(2, answers[0], 64);
		
		if (args > 2)
		{
			GetCmdArg(3, answers[1], 64);
		}
		if (args > 3)
		{
			GetCmdArg(4, answers[2], 64);
		}
		if (args > 4)
		{
			GetCmdArg(5, answers[3], 64);
		}
		
		if (args > 5)
		{
			GetCmdArg(6, answers[4], 64);
			answerCount = 5;
		}
		else
			answerCount = args - 1;
		
	}
	else
	{
		answers[0] = "Yes";
		answers[1] = "No";
		answerCount = 2;
	}

	ShowActivity(client, "%t", "Initiate Vote", g_voteQuestion);
	
	g_hVoteMenu = CreateMenu(Handler_VoteMenu);
	SetMenuTitle(g_hVoteMenu, "%s?", g_voteQuestion);
	for (new i = 0; i < answerCount; i++)
	{
		AddMenuItem(g_hVoteMenu, answers[i], answers[i]);
	}

	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);

	return Plugin_Handled;	
}

public Action:Command_Votecancel(client, args)
{
	if (g_hVoteMenu == INVALID_HANDLE)
	{
		ReplyToCommand(client, "[SM] %t", "Vote Not In Progress");
		return Plugin_Handled;
	}
	
	ShowActivity(client, "%t", "Cancelled Vote");
	
	CancelMenu(g_hVoteMenu);
	
	return Plugin_Handled;
}

public Handler_VoteMapMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:map[64], String:display[64], Float:percent;
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		
		if(totalVotes < 1)
		{
			PrintToChatAll("[SM] %T", "No Votes Cast", LANG_SERVER);
			return;
		}
		
		GetMenuItem(menu, param1, map, sizeof(map), _, display, sizeof(display));
		
		if(strcmp(display,"No") == 0 && param1 == 1)
		{
			votes = totalVotes - votes; // Reverse the votes to be in relation to the Yes option.
		}
		
		percent = VotePercent(votes, totalVotes);

		// A multimap vote is "always successful", but have to check if its a single map vote.
		if((strcmp(display,"Yes") == 0 && FloatCompare(percent,GetConVarFloat(g_Cvar_VoteMap)) < 0 && param1 == 0) || (strcmp(display,"No") == 0 && param1 == 1))
		{
			LogMessage("Vote map failed.");
			PrintToChatAll("[SM] %T", "Map Failed", LANG_SERVER, RoundToNearest(100.0*GetConVarFloat(g_Cvar_VoteMap)), RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			LogMessage("Vote map successful, changing to %s.", map);
			PrintToChatAll("[SM] %T", "Map Successful", LANG_SERVER, map, RoundToNearest(100.0*percent), totalVotes);
			new Handle:dp;
			CreateDataTimer(5.0, Timer_ChangeMap, dp);
			WritePackString(dp, map);
		}
	}
}

public Handler_VoteKickMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:userIdStr[64], userId, Float:percent;
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		
		if (totalVotes < 1)
		{
			PrintToChatAll("[SM] %T", "No Votes Cast", LANG_SERVER);
			return;
		}
		
		percent = VotePercent(votes, totalVotes);
		
		if (FloatCompare(percent, GetConVarFloat(g_Cvar_Votekick)) >= 0 && param1 == 0)
		{
			GetMenuItem(menu, param1, userIdStr, sizeof(userIdStr));
			userId = StringToInt(userIdStr);
		
			LogMessage("Vote kick successful, kicked \"%L\" (reason \"%s\")", g_voteClient, g_voteReason);
		
			if (g_voteReason[0] == '\0')
			{
				ServerCommand("kickid %d \"Votekicked.\"", userId);
			}
			else
			{
				ServerCommand("kickid %d \"%s\"", userId, g_voteReason);
			}				
		
			PrintToChatAll("[SM] %T", "Kick Successful", LANG_SERVER, g_voteTarget, RoundToNearest(100.0*percent), totalVotes);
		}
		else
		{
			LogMessage("Vote kick failed, \"%L\" not kicked.", g_voteClient);
			PrintToChatAll("[SM] %T", "Kick Failed", LANG_SERVER, g_voteTarget, RoundToNearest(100.0*GetConVarFloat(g_Cvar_VoteMap)), RoundToNearest(100.0*percent), totalVotes);
		}
	}
}

public Handler_VoteBanMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:userIdStr[64], userId, Float:percent;
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);

		if (totalVotes < 1)
		{
			PrintToChatAll("[SM] %T", "No Votes Cast", LANG_SERVER);
			return;
		}		
		
		percent = VotePercent(votes, totalVotes);
		
		if (FloatCompare(percent,GetConVarFloat(g_Cvar_Voteban)) >= 0 && param1 == 0)
		{
			GetMenuItem(menu, param1, userIdStr, sizeof(userIdStr));
			userId = StringToInt(userIdStr);
		
			LogMessage("Vote ban successful, banned \"%L\" (minutes \"30\") (reason \"%s\")", g_voteClient, g_voteReason);
			PrintToChatAll("[SM] %T", "Ban Successful", LANG_SERVER, g_voteTarget, RoundToCeil(100.0*percent), totalVotes);
			
			/* Fire the ban forward */
			Call_StartForward(g_hBanForward);
			Call_PushCell(0);
			Call_PushCell(g_voteClient);
			Call_PushCell(30);
			Call_PushString(g_voteReason);
			Call_Finish();
		
			if (g_voteReason[0] == '\0')
			{
				strcopy(g_voteReason, sizeof(g_voteReason), "Votebanned");
			}
			
			ServerCommand("banid %d %d", 30, userId);
			ServerCommand("kickid %d \"%s\"", userId, g_voteReason);
		}
		else
		{
			LogMessage("Vote ban failed, \"%L\" not banned.", g_voteClient);
			PrintToChatAll("[SM] %T", "Ban Failed", LANG_SERVER, g_voteTarget, RoundToNearest(100.0*GetConVarFloat(g_Cvar_VoteMap)), RoundToNearest(100.0*percent), totalVotes);
		}
	}
}

public Handler_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:answer[64], Float:percent;
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);		
		
		if (totalVotes < 1)
		{
			PrintToChatAll("[SM] %T", "No Votes Cast", LANG_SERVER);
			return;
		}		
		
		percent = VotePercent(votes, totalVotes);
		GetMenuItem(menu, param1, answer, sizeof(answer));
		PrintToChatAll("[SM] %T", "Vote End", LANG_SERVER, g_voteQuestion, answer, RoundToNearest(100.0*percent), totalVotes);
	}
}

VoteSelect(Handle:menu, param1, param2 = 0)
{
	if (GetConVarInt(g_Cvar_Voteshow) == 1)
	{
		new String:voter[64], String:junk[64], String:choice[64];
		GetClientName(param1, voter, sizeof(voter));
		GetMenuItem(menu, param2, junk, sizeof(junk), _, choice, sizeof(choice));
		PrintToChatAll("[SM] %T", "Vote Select", LANG_SERVER, voter, choice);
	}
}

VoteMenuClose()
{
	CloseHandle(g_hVoteMenu);
	g_hVoteMenu = INVALID_HANDLE;
}

Float:VotePercent(votes, totalVotes)
{
	return FloatDiv(float(votes),float(totalVotes));
}

public Action:Timer_ChangeMap(Handle:timer, Handle:dp)
{
	new String:map[65];
	
	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));
	
	ServerCommand("changelevel \"%s\"", map);
	
	return Plugin_Stop;
}