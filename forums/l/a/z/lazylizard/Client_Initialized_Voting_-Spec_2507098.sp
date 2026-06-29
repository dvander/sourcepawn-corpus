#include <sourcemod>

//Change the following to limit the number of time this kind of vote is called
#define maxVote 3

int voteTimes;

public Plugin:myinfo = {
	name = "Client Initialized Voting -Spec",
	author = "LazyLizard",
	description = "!votespec",
	version = "1.7",
	
}

public OnMapStart()
{
	voteTimes = 0;

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
			
			 PrintToChatAll("YES is the answer to Spec");
			voteTimes = voteTimes+1;
			ServerCommand("emp_allowspectators 1");
		}
		else
		{
			PrintToChatAll("Vote has failed. I dont see not ghost");
			voteTimes = voteTimes+1;
			ServerCommand("emp_allowspectators 0");
		}
	}
}




public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!votespec", false) == 0)
	{
	
if (voteTimes >= maxVote)
    {
		PrintToChat(client, "\x04[Vote-Spec]\x03 There was already an Spec vote.");
		return Plugin_Handled;	
 	}
	
	
	
	ShowActivity2(client, "[SM] ", "Initiated Vote Spec");
	LogAction(client, -1, "\"%L\" used vote-Spec", client);
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, "Turn on Spec so noobs can ghost for the blue team?");
	AddMenuItem(menu, "notsure1", "Yes spec will be able to spy on you");
	AddMenuItem(menu, "notsure2", "No- hey lazybums join the game");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 18);
		
	return Plugin_Handled;

	
}

 
	/* Let say continue normally */
				return Plugin_Continue;
}
