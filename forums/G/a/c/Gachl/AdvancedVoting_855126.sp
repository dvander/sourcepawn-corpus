#include <sourcemod>

#define PLUGIN_VERSION "1.1.4"

public Plugin:myinfo = 
{
	name = "Advanced Voting",
	author = "GachL",
	description = "Provides advanced functionality to voting",
	version = PLUGIN_VERSION,
	url = "http://bloodisgood.org"
}

public OnPluginStart()
{
	CreateConVar("sm_avote_version", PLUGIN_VERSION, "Advanced voting version", FCVAR_PLUGIN|FCVAR_PROTECTED|FCVAR_NOTIFY);
	RegAdminCmd("sm_avote", Command_AVote, ADMFLAG_GENERIC, "Initiate a vote");
	RegAdminCmd("sm_asvote", Command_ASVote, ADMFLAG_BAN, "Initiate a vote, commands are executed on the server");
}

new String:commands[10][32];
new String:results[10][32];
new whoDidIt;
new bool:onServer = false;

public Action:Command_ASVote(client, args)
{
	onServer = true;
	return Command_AVote(client, args);
}

public Action:Command_AVote(client, args)
{
	if (args < 3)
	{
		ShowActivity2(client, "[SM] ", "Using: sm_avote <title> <answ1> <exec1> <answ2> <exec2> ... <answ6> <exec6>");
		onServer = false;
		return Plugin_Handled;
	}
	if (args > 21)
	{
		ShowActivity2(client, "[SM] ", "Max. 10 answers allowed.");
		onServer = false;
		return Plugin_Handled;
	}
	if ((args - 1) % 2 != 0)
	{
		ShowActivity2(client, "[SM] ", "Equal count of answers and commands is needed (pairs).");
		onServer = false;
		return Plugin_Handled;
	}
	
	for (new y = 0; y < 10; y++)
	{
		commands[y] = "";
		results[y] = "";
	}
	
	whoDidIt = client;
	
	new String:name[32];
	GetCmdArg(1, name, sizeof(name));
	for (new i = 2; i <= args; i+=2)
	{
		new realPos = (i/2)-1;
		GetCmdArg(i, results[realPos], 32);
		GetCmdArg(i+1, commands[realPos], 32);
	}
	
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetVoteResultCallback(menu, Handle_VoteResults);
	SetMenuTitle(menu, name);
	for (new j = 2; j <= args; j++)
	{
		new String:buf[32];
		IntToString(j, buf, 32);
		AddMenuItem(menu, buf, results[j-2]);
	}
	
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 20);
	return Plugin_Handled;
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}
 
public Handle_VoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
	new winner = 0;
	if (num_items > 1 && (item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES]))
	{
		winner = GetRandomInt(0, 1);
	}
	
	new String:pos[32];
	GetMenuItem(menu, item_info[winner][VOTEINFO_ITEM_INDEX], pos, sizeof(pos))
	
	new iPos = StringToInt(pos);
	
	if (!onServer)
	{
		FakeClientCommandEx(whoDidIt, commands[iPos-2]);
	} else {
		ServerCommand(commands[iPos-2]);
	}
	
	onServer = false;
}
