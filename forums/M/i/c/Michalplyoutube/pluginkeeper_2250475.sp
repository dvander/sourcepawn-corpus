#include <sourcemod>

public Plugin:myinfo = {
    name = "[Plugin Keeper]",
    author = "Michal(TF2BWRR)",
    description = "Keeps plugin that uses tf2itemsinfo alive",
    version = "0.5",
    url = ""
};

#define PLUGINNAME	"tf2bwr" //plugin file name that uses tf2itemsinfo without .smx example "tf2ibwr"

public OnPluginStart()
{
	CreateTimer(1.0, Timer_Check, _, TIMER_REPEAT)
}
public Action:Timer_Check(Handle:timer)
{
	if (FindPluginByFile("tf2itemsinfo.smx") != INVALID_HANDLE) //check if plugin haven't crashed
		return;
	if (FindPluginByFile("tf2itemsinfo.smx") == INVALID_HANDLE) //check if plugin has crashed
	{
		ServerCommand("sm plugins unload %s", PLUGINNAME);
		PrintToChatAll("[Plugin Keeper] TF2ItemsInfo have crashed => reloading it (Please wait it will lag for a while)");
		LogMessage("[Plugin Keeper] TF2ItemsInfo have crashed => reloading it");
		ServerCommand("sm plugins load tf2itemsinfo"); 
		ServerCommand("sm plugins load %s", PLUGINNAME); 
	} 
}