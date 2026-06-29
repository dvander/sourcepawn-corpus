#include <sourcemod>

//Change the following to limit the number of time this kind of vote is called
#define maxVote 3

int voteTimes;

public Plugin:myinfo = {
	name = "Client Initialized Voting -MeempMeep",
	author = "LazyLizard",
	description = "!meepmeep",
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
			
			 PrintToChatAll("\x04 YES is the answer to MeepMeep");
			voteTimes = voteTimes+1;
			ServerCommand("host_timescale 1.7");
			ServerCommand("sv_cheats 1");
		}
		else
		{
			PrintToChatAll("\x04 Vote has failed. YOU fools voted no!!! How dare you incoming bands");
			voteTimes = voteTimes+1;
			ServerCommand("host_timescale 1");
			ServerCommand("sv_cheats 0");
		}
	}
}




public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!meepmeep", false) == 0)
	{
	
if (voteTimes >= maxVote)
    {
		PrintToChat(client, "\x04[Vote-MeepMeep]\x03 There was already a MeepMeep vote.");
		return Plugin_Handled;	
 	}
	
	
	
	ShowActivity2(client, "[SM] ", "\x04 Initiated Vote MeepMeep");
	LogAction(client, -1, "\"%L\" used vote-MeepMeep", client);
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, "Turn on MeepMeep 4 road runner speeeds?");
	AddMenuItem(menu, "notsure1", "Yes of course i want to finish in half the time (where is the life part).");
	AddMenuItem(menu, "notsure2", "No we want it old skools.");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 18);
		
	return Plugin_Handled;

	
}

 
	/* Let say continue normally */
				return Plugin_Continue;
}
