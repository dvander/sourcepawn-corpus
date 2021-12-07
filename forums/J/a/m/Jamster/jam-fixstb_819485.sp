#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

new bool:b_Arena = false;
new Handle:g_Cvar_Arena = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Fix STB",
	author = "Jamster",
	description = "Fixes simple team balancer for NOT WORKING",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	g_Cvar_Arena = FindConVar("tf_gamemode_arena");
}

public OnMapStart()
{
	b_Arena = false;
	if (GetConVarInt(g_Cvar_Arena))
	{
		b_Arena = true;
	}
	CheckThatShit();
}

CheckThatShit()
{
	if (b_Arena)
	{
		return;
	}
	LogMessage("Reloading STB");
	ServerCommand("sm plugins reload simpleteambalancer");
}