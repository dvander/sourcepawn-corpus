#include <sourcemod>

//Change the following to limit the number of time this kind of vote is called
#define maxVote 3

int voteTimes;

public Plugin:myinfo = {
	name = "Client Initialized Voting -Jetpack Pick Map Edition",
	author = "LazyLizard",
	description = "!votejp",
	version = "1.7.1",
	
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
			
			 PrintToChatAll("\x04 YES is the answer to Fartpacks");
			voteTimes = voteTimes+1;
			ServerCommand("sm_jetpack 1");
		}
		else
		{
			PrintToChatAll("\x04 Vote has failed. YOU fools voted no!!! How dare you incoming bands");
			voteTimes = voteTimes+1;
			ServerCommand("sm_jetpack 0");
		}
	}
}



public module1(int client)

{


	

	
	
	ShowActivity2(client, "[SM] ", "\x04 Initiated Vote Jetpack");
	LogAction(client, -1, "\"%L\" used vote-Jetpack", client);
	new Handle:menu = CreateMenu(Handle_VoteMenu);
	SetMenuTitle(menu, "Turn on !fartpack or in proper english !jetpack?");
	AddMenuItem(menu, "notsure1", "Yes of course i ate to many beans");
	AddMenuItem(menu, "notsure2", "No i am a vet and i dont want to cheat");
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 18);
		
	return Plugin_Handled;

}


public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!votejp", false) == 0)
	{
	
	
	if (voteTimes >= maxVote)
    {
		PrintToChat(client, "\x04[Vote-Jetpack]\x03 There was already an Jetpack vote.");
		return Plugin_Handled;	
 	}
		char currentMap[PLATFORM_MAX_PATH];
	GetCurrentMap(currentMap, sizeof(currentMap));
	
	
	  	if (strcmp(currentMap, "emp_blast_ob1", false) == 0)
	{
	
	PrintToChat(client,  "\x04 Voting is being procesed THIS IS An infantry map sucker");	
	module1(client);
	}	
	else if (strcmp(currentMap, "emp_castle_ob2", false) == 0)
	{
	PrintToChat(client,  "\x04 Voting is being procesed THIS IS An infantry map sucker");	
	module1(client);
	}	
	else if (strcmp(currentMap, "emp_district402", false) == 0)
	{
	PrintToChat(client,  "\x04 Voting is being procesed THIS IS An infantry map sucker");	
	module1(client);
	}	
	else if (strcmp(currentMap, "emp_eastborough", false) == 0)
	{
	PrintToChat(client,  "\x04 Voting is being procesed THIS IS An infantry map sucker");	
	module1(client);
	}
	else if (strcmp(currentMap, "emp_tunnelrats_rv3a", false) == 0)
	{
	PrintToChat(client,  "\x04 Voting is being procesed THIS IS An infantry map sucker");
module1(client);	
	}
	else if (strcmp(currentMap, "emp_minigames_2017c", false) == 0)
	{
	PrintToChat(client,  "\x04 Voting is being procesed THIS IS An infantry map sucker");	
	module1(client);
	}
	else 
	{
	PrintToChat(client,  "\x04 Are You Trying To Crash The Server????? You cannot vote for !votejp on a non infantry map");


	}
	
	
	
	
	
	
	
	
	

	
}

 
	/* Let say continue normally */
				return Plugin_Continue;
}
