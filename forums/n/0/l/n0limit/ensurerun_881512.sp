/* Plugin Template generated by Pawn Studio */

#include <sourcemod>

new Handle:hCrawling;

public Plugin:myinfo = 
{
	name = "EnsureRun",
	author = "n0limit",
	description = "Reruns cfg file that contains sourcemod commands to make sure they worked",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	// Add your own code here...
	hCrawling = FindConVar("survivor_allow_crawling");
}
public OnAllPluginsLoaded()
{
	//simply rerun the config now that it's loaded
	//CEVO server
	PrintToServer("Running cfg!");
	ServerCommand("exec extra.cfg");
	
}

public OnMapStart()
{ 
	//check every map load to make sure CEVO and other changes are running
	if(!GetConVarBool(hCrawling))
	{ 
		//crawling isn't enabled, vars have been reset. 
		ServerCommand("exec extra.cfg");
	}
}