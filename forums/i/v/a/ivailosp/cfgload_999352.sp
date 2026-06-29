#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.0"
public Plugin:myinfo = 
{
	name = "cfgload",
	author = "ivailosp",
	description = "cfgload",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	ServerCommand("exec l4dtoolz.cfg");
}