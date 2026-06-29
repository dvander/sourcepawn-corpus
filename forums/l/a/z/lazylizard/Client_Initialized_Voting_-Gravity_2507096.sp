#include <sourcemod>

//Change the following to limit the number of time this kind of vote is called
#define maxVote 3

int voteTimes;

public Plugin:myinfo = {
	name = "Client Initialized Voting -Gravity",
	author = "LazyLizard",
	description = "!lowg",
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
			
			 PrintToChatAll("YES is the answer to LOW G");
			voteTimes = voteTimes+1;
			ServerCommand("sv_gravity 225");
		}
		else
		{
			PrintToChatAll("Vote has failed. YOU fools voted no!!! How dare you incoming bands");
			voteTimes = voteTimes+1;
			ServerCommand("sv_gravity 800");
		}
	}
}




public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!lowg", false) == 0)
	{
	
if (voteTimes >= maxVote)
    {
		PrintToChat(client, "\x04[Vote-Gravity]\x03 There was already an Gravity vote.");
		return Plugin_Handled;	
 	}
	
	
	
	ShowActivity2(client, "[SM] ", "Initiated Vote Gravity");
	LogAction(client, -1, "\"%L\" used vote-Gravity", client);
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, "Turn on low G at 225 so you can fill less fat?");
	AddMenuItem(menu, "notsure1", "Yes of course its a space game(sv_gravity 225)");
	AddMenuItem(menu, "notsure2", "No we sill on earth bro(sv_gravity 800)");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 18);
		
	return Plugin_Handled;

	
}

 
	/* Let say continue normally */
				return Plugin_Continue;
}
