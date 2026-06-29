#pragma semicolon 1
#include <sourcemod>
#define PL_VERSION "1.1"

public Plugin:myinfo = 
{
	name = "Pumpkin Precache",
	author = "Snaggle [UK]",
	description = "Precache pumpkins",
	version = PL_VERSION,
	url = "http://www.gmodtech.net"
}

public OnPluginStart()
{
	PrecacheModel("models/props_halloween/pumpkin_explode.mdl"); 
}