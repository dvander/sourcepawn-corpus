
#include <sdktools>

public Plugin:myinfo = {
	name = "Client can turn on tank_wars",
	author = "LazyLizard",
	description = "!tankwars",
	version = "1.7.1",
	
}

//Max amount of people after which this plugin does nothing
#define MAXPEPS 7

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{

	if (strcmp(sArgs, "!tankwars", false) == 0)
	{
	

	  if( GetClientCount() <= MAXPEPS ) {
   

   //edit command list this is unique to empires mod.
		ServerCommand("emp_allowspectators 0");
		ServerCommand("sv_alltalk 1");
		ServerCommand("mp_autoteambalance 0");
		ServerCommand("mp_teams_unbalance_limit 0");
		ServerCommand("emp_sv_max_turrets 2");
		ServerCommand("emp_sv_refinery_multiplier 50");
		ServerCommand("emp_sv_research_complete 1");
		ServerCommand("hostname (:WDT:)Tank_Wards_is_on_at_the_moment_DONT_ATTACK_EMEMY_MAIN_BASE");
		

		//// only use following if you have MFZB Gaming Community jetpack plugin
		//ServerCommand("sm_jetpack 1");
		
	  }
	  else{
	  PrintToChat(client,"Doing nothing too many ppl on atm so no tankwars can ask admin though.");
  	}
}

	/* Let say continue normally */
	return Plugin_Continue;
}
