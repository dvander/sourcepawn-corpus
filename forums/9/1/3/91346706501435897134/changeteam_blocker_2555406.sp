#include <sourcemod>



public Plugin myinfo =
{
	name = "changeteam_blocker",
	author = "91346706501435897134",
	description = "blocks changing of team",
	version = "1.0",
};



public void OnPluginStart()
{
	AddCommandListener(cmd_blocker, "changeteam");
	AddCommandListener(cmd_blocker, "jointeam");
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