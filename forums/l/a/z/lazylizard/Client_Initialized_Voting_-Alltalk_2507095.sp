#include <sourcemod>

//Change the following to limit the number of time this kind of vote is called
#define maxVote 3

int voteTimes;

public Plugin:myinfo = {
	name = "Client Initialized Voting -Alltalk",
	author = "LazyLizard",
	description = "!alltalk",
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
			
			 PrintToChatAll("YES is the answer to alltalk");
			voteTimes = voteTimes+1;
			ServerCommand("sv_alltalk 1");
		}
		else
		{
			PrintToChatAll("Vote has failed. YOU fools voted no!!! How dare you incoming bands");
			voteTimes = voteTimes+1;
			ServerCommand("sv_alltalk 0");
		}
	}
}




public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!alltalk", false) == 0)
	{
	
if (voteTimes >= maxVote)
    {
		PrintToChat(client, "\x04[Vote-AllTalk]\x03 There was already an AllTalk vote.");
		return Plugin_Handled;	
 	}
	
	
	
	ShowActivity2(client, "[SM] ", "Initiated Vote alltalk");
	LogAction(client, -1, "\"%L\" used vote-alltalk", client);
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, "Turn on all Talk so you can hear my jokes?");
	AddMenuItem(menu, "notsure1", "Yes");
	AddMenuItem(menu, "notsure2", "No");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 18);
		
	return Plugin_Handled;

	
}

 
	/* Let say continue normally */
				return Plugin_Continue;
}
