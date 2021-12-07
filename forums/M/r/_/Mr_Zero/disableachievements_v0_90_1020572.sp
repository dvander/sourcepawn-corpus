#define PLUGIN_VERSION	"0.90"
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Disable Achievements",
	author = "Mr. Zero",
	description = "Disables achievements for clients",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
	CreateConVar("sm_disableachievements_version",PLUGIN_VERSION,"Disable Achievements Version",FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
}

public OnClientPostAdminCheck(client)
{
	SendConVarValue(client, FindConVar("sv_cheats"), "1");
	CreateTimer(0.1,DisableCheatsTimer,client);
}

public Action:DisableCheatsTimer(Handle:timer,any:client)
{
	SendConVarValue(client, FindConVar("sv_cheats"), "0");
}