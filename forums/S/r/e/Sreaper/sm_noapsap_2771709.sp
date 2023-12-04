#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = {
	name = "No Ap-Sap building",
	author = "Sreaper",
	description = "Blocks spy from using build",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{	
	CreateConVar("sm_noapsap_version", PLUGIN_VERSION, "No Ap-Sap building plugin version.", FCVAR_REPLICATED|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	AddCommandListener(Build_Callback, "build");
}

public Action Build_Callback(int client, const char[] command, int argc)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(TF2_GetPlayerClass(client) == TFClassType:TFClass_Spy)
		return Plugin_Handled;
	}
	return Plugin_Continue;
}