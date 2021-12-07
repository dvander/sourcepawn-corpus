#include <sourcemod>
#include <sdktools>

#define KILLINGFLOOR "game: killing floor"
#define PERKS 6
#define LEVELS 6
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "killing floor perks",
	author = "gamemann",
	description = "killing floor with l4d",
	version = PLUGIN_VERSION,
	url = "http://games223.com/"
};

//handles
new Handle:Demolitions = INVALID_HANDLE;
new Handle:SharpShooter = INVALID_HANDLE;
new Handle:FireBug = INVALID_HANDLE;
new Handle:Commando = INVALID_HANDLE;
new Handle:Support Specialist = INVALID_HANDLE;
new Handle:Berserker = INVALID_HANDLE;

public OnPluginStart()
{

	//events


	//convars
	
	//notify + consolecmds
	RegConsoleCmd("sm_sharpshooter", SSinfo);
	AutoExecConfig(true, "l4d2_killingfloorperks");
}

public Action:SSinfo(client, args)
{
	PrintToCenter(client, "70% better rifle damage, 30% faster reload with rifles, spawn with scout");
	return Plugin_Handled;
}
