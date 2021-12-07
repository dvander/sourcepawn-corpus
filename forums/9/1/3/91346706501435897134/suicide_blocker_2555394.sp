#include <sourcemod>



public Plugin myinfo =
{
	name = "suicide blocker",
	author = "91346706501435897134",
	description = "blocks suicide attempts",
	version = "1.0",
};



public void OnPluginStart()
{
	AddCommandListener(cmd_blocker, "kill");
	AddCommandListener(cmd_blocker, "explode");
}



public Action cmd_blocker(int client, const char[] command, int argc)
{
	PrintToConsole(client, ">> %s is disabled", command);
	
	return Plugin_Handled;
}