#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN


#define PLUGIN_VERSION "1.0.500" 

new Handle:g_Cvar_Limits
new Handle:g_hVoteMenu = INVALID_HANDLE
new Handle:g_Cvar_TimeLimit = INVALID_HANDLE;
new Handle:g_Cvar_VoteTime = INVALID_HANDLE;


#define VOTE_CLIENTID	0
#define VOTE_USERID		1
#define VOTE_NAME		0
#define VOTE_NO 		"###no###"
#define VOTE_YES 		"###yes###"

new String:g_voteInfo[3][65]
new bool:g_CanVote = true;

public Plugin:myinfo =
{
	name = "Vote Scramble Teams",
	author = "KevLaR/Seb/Snipa",
	description = "Vote Scramble Teams",
	version = PLUGIN_VERSION,
	url = "http://www.3-pg.com"
}

public OnPluginStart()
{
	CreateConVar("sm_votescramble_version", PLUGIN_VERSION, "Version of VoteScramble", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Limits = CreateConVar("sm_votescramble_limit", "0.65", "Percent required for successful scramble vote.")
	g_Cvar_VoteTime = CreateConVar("sm_votescramble_timer", "180", "Time in seconds between votes")
	g_Cvar_TimeLimit = FindConVar("mp_timelimit"); 
	RegConsoleCmd("votescramble", Command_votescramble);
	RegAdminCmd("sm_scrambleteams", Command_scrambleteams, ADMFLAG_KICK);
}

public Action:Command_votescramble(client, args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %s", "Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (!g_CanVote)
	{
		ReplyToCommand(client, "[SM] VoteScramble is not allowed at this time");
		return Plugin_Handled;
	}	

	LogAction(client, -1, "\"%L\" initiated a Scramble vote.", client);
	ShowActivity(client, "%s", "Initiated Vote Scramble", g_voteInfo[VOTE_NAME]);
	g_hVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	SetMenuTitle(g_hVoteMenu, "Scramble Teams?");
	AddMenuItem(g_hVoteMenu, VOTE_NO, "No");
	AddMenuItem(g_hVoteMenu, VOTE_YES, "Yes");
	SetMenuExitButton(g_hVoteMenu, false);
	VoteMenuToAll(g_hVoteMenu, 20);
	return Plugin_Handled;
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	else if (action == MenuAction_Display)
	{
		decl String:title[64];
		GetMenuTitle(menu, title, sizeof(title));
		
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%s %s", title, g_voteInfo[VOTE_NAME]);

		new Handle:panel = Handle:param2;
		SetPanelTitle(panel, buffer);
	}
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "VOTE_NO") == 0 || strcmp(display, "VOTE_YES") == 0)
	 	{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%s", display);
			return RedrawMenuItem(buffer);
		}
	}
/*
	else if (action == MenuAction_Select)
	{
		VoteSelect(menu, param1, param2);
	}
*/
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %s", "No Votes Cast");
	}	
	else if (action == MenuAction_VoteEnd)
	{
		g_CanVote = false;
		decl String:buffer2[128]
		GetConVarString(g_Cvar_VoteTime, buffer2, sizeof(buffer2))
		new float:time = StringToFloat(buffer2)
		new float:votes, float:totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		new float:comp = FloatDiv(votes,totalVotes);
		decl String:buffer[128]
		GetConVarString(g_Cvar_Limits, buffer, sizeof(buffer))
		new float:comp2 = StringToFloat(buffer)
		if (param1 == 0) // Votes of no wins
      {
        PrintToChatAll("[SM] Vote Scramble has Failed")
        LogAction(-1, -1, "Vote Scramble has Failed due to an insufficient amount of votes");
        //Function for calling the timer to reset eventually according to time from the server cvar defined
        CreateTimer(time, Timer_VoteTimer);
      } 
		else if (comp >= comp2 && param1 == 1)
      {
        new float:hundred = 100.00;
        new float:percentage = FloatMul(comp,hundred);
        new percentage2 = RoundFloat(percentage);
        PrintToChatAll("[SM] %i Percent of %i Players Voted for Vote Scramble", percentage2, totalVotes);
        LogAction(-1, -1, "Vote Scramble successful");
        ServerCommand("mp_scrambleteams");
        new timeleft;
        GetMapTimeLeft(timeleft);
        new mins, secs;
        mins = timeleft / 60;
        secs = timeleft % 60;	
        if (secs >= 30)
        {
          mins = mins+1;
        }	
        CreateTimer(10.0, Timer_DelayRTS, mins);
        //Function for calling the timer to reset eventually according to time from the server cvar defined
        CreateTimer(time, Timer_VoteTimer);
      }
		else
      {
        new float:hundred = 100.00;
        new float:percentage = FloatMul(comp2,hundred);
        new percentage2 = RoundFloat(percentage);
        PrintToChatAll("[SM] Vote Scramble has failed due to insufficient Votes %i Percent", percentage2)
        LogAction(-1, -1, "Vote Scramble Failed due to less than %i Percent wanting to change", percentage2);
        //Function for calling the timer to reset eventually according to time from the server cvar defined
        CreateTimer(time, Timer_VoteTimer);
      }
	}
	return 0;
}

public Action:Timer_DelayRTS(Handle:timer, any:mins)
{
	SetConVarInt(g_Cvar_TimeLimit,mins)
}

VoteMenuClose()
{
	CloseHandle(g_hVoteMenu);
	g_hVoteMenu = INVALID_HANDLE;
}

public Action:Timer_VoteTimer(Handle:timer)
{
g_CanVote = true;
}
public Action:Command_scrambleteams(client, args)
{
			PrintToChat(client,"\x01\x04Scramble Teams has been initiated")
			ServerCommand("mp_scrambleteams");
			new timeleft;
			GetMapTimeLeft(timeleft);
			new mins, secs;
			mins = timeleft / 60;
			secs = timeleft % 60;	
			if (secs >= 30)
        {
			mins = mins+1;
        }	
			CreateTimer(10.0, Timer_DelayRTS, mins);
        //Function for calling the timer to reset eventually according to time from the server cvar defined

		return Plugin_Handled;
}
      
