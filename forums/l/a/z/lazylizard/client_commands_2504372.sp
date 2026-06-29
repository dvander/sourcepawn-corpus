
#include <sdktools>

public Plugin:myinfo = {
	name = "Client !Commands for EmPires (plasma not inculded)",
	author = "LazyLizard",
	description = "Client !Commands for EmPires ",
	version = "1.7",
	
}


public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
//!kill command to kill one self
	if (strcmp(sArgs, "!kill", false) == 0)
	{
		ClientCommand (client,"kill");
		PrintToChat(client, "Stop killing yourself you are wasting tickets!!");
								
	}
//!recwalls commant to recycle all eng walls
	if (strcmp(sArgs, "!recwalls", false) == 0)
	{
	ClientCommand (client,"emp_eng_recycle_walls");
	}
	
	
	// Used to bind space for jetpacks purpose 
	//MFZB Gaming Community jetpack plugin
	//https://forums.alliedmods.net/showthread.php?p=488779
 	if (strcmp(sArgs, "!jetpack", false) == 0)
	{
	ClientCommand (client,"bind space +sm_jetpack");
	}
   	if (strcmp(sArgs, "!fartpack", false) == 0)
	{
	ClientCommand (client,"bind space +sm_jetpack");
	}
 
 
	/* Let say continue normally */
				return Plugin_Continue;
}
