#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = 
{
	name = "sexy",
	author = "ivailosp",
	description = "huh",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	new Handle:ff = FindConVar("mp_friendlyfire");
	SetConVarBounds(ff , ConVarBound_Lower, true, 0.0);
	SetConVarInt(ff, 0);
}