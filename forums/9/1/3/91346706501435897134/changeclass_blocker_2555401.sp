#include <sourcemod>



public Plugin myinfo =
{
	name = "changeclass_blocker",
	author = "91346706501435897134",
	description = "blocks changing of class",
	version = "1.0",
};



public void OnPluginStart()
{
	AddCommandListener(cmd_blocker, "changeclass");
	AddCommandListener(cmd_blocker, "joinclass");
	AddCommandListener(cmd_blocker, "join_class");
}



public Action cmd_blocker(int client, const char[] command, int argc)
{	
	if (IsPlayerAlive(client))
	{
		PrintToConsole(client, ">> %s is disabled", command);
		
		return Plugin_Handled;
	}
	else
	{
		return Plugin_Continue;
	}
}