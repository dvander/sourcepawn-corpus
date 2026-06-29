
#include <sdktools>

public Plugin:myinfo = {
	name = "Changmap x level",
	author = "LazyLizard",
	description = "!pplchoice",
	version = "1.7",
	
}

//Max amount of people after which this plugin does nothing
#define MAXPEPS 6

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!pplchoice", false) == 0)
	{
	

		if( GetClientCount() <= MAXPEPS ) {
  
		//Change to any map of your choice replace "emp_minigames_2017c" with your map
    
		ServerCommand("changelevel emp_minigames_2017c");

	
	
  }
  else{
  PrintToChat(client,"Doing nothing too many ppl on atm so ask admin.");
  }
}


 
	/* Let say continue normally */
				return Plugin_Continue;
}
