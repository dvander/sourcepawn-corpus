
#include <sdktools>

public Plugin:myinfo = {
	name = "Client can speed up research",
	author = "LazyLizard",
	description = "!speedupradar",
	version = "1.7",
	
}

//Max amount of people after which this plugin does nothing
#define MAXPEPS 8

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!speedupradar", false) == 0)
	{
	

	  if( GetClientCount() <= MAXPEPS ) {
   

   //edit command list this is unique to empires mod.
		ServerCommand("emp_sv_research_multiplier 1.7");

	  }
	  else{
	  PrintToChat(client,"\x04 Doing nothing too many ppl on atm so no speed up research can ask admin though.");
  	}
}

	/* Let say continue normally */
	return Plugin_Continue;
}
