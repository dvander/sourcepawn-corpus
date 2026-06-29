#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "Key Binder",
	author = "TESLA-X4",
	description = "Prepares players to use radio menus",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("sm_keybinder_version", PLUGIN_VERSION, "Version of Key Binder", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
}

public OnClientPostAdminCheck(client)
{
	ClientCommand(client, "bind 1 slot1");
	ClientCommand(client, "bind 2 slot2");
	ClientCommand(client, "bind 3 slot3");
	ClientCommand(client, "bind 4 slot4");
	ClientCommand(client, "bind 5 slot5");
	ClientCommand(client, "bind 6 slot6");
	ClientCommand(client, "bind 7 slot7");
	ClientCommand(client, "bind 8 slot8");
	ClientCommand(client, "bind 9 slot9");
	ClientCommand(client, "bind 0 slot10");
	ClientCommand(client, "host_writeconfig");
}
