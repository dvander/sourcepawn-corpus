#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>

#define PLUGIN_VERSION "0.1"
public Plugin:myinfo =
{
	name = "L4D Bots",
	author = "devicenull",
	description = "Allow extra bots to be added to the game",
	version = PLUGIN_VERSION,
	url = "http://www.devicenull.org/"
};

public OnPluginStart()
{
	CreateConVar("l4dhax_version", PLUGIN_VERSION, "L4D Bots", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_l4dbot", l4dbot, ADMFLAG_CHEATS, "Add a bot to the game");
}

public Action:l4dbot(client, args)
{
	new bot = CreateFakeClient("I am not real.");
	ChangeClientTeam(bot,2);
	DispatchKeyValue(bot,"classname","SurvivorBot");
	DispatchSpawn(bot);
	CreateTimer(30.0,kickbot,bot);
}

public Action:kickbot(Handle:timer, any:value)
{
	KickClient(value,"fake player");
	return Plugin_Stop;
}
