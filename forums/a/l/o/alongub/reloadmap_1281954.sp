#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Reload Map",
	author = "alongub",
	description = "A simple way to reload the current map.",
	version = "0.01"
};

public OnPluginStart()
{
	RegAdminCmd("sm_reloadmap",
		Command_ReloadMap,
		ADMFLAG_CHANGEMAP,
		"Reloads the current map");
}

public Action:Command_ReloadMap(client, args)
{
	new String:map[128]; 
	GetCurrentMap(map, sizeof(map));
	
	ForceChangeLevel(map, "sm_reloadmap Command");
}