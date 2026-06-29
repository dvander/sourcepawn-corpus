#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <tf2fasttele>
#define REQUIRE_PLUGIN

public Plugin:myinfo = 
{
	name = "FastTeleTest",
	author = "kim_perm",
	description = "Sample test plugin for tf2fastteleports",
	version = "0.0.1",
	url = "http://game.perm.ru"
}

public OnPluginStart() {
	RegConsoleCmd("teletest", teletest);
}

public Action:teletest(client, args) {
	SetTeleporterTime(client, 0.01);
	return Plugin_Handled;
}
