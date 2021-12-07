//Simple script setup
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <regex>
#define DLYCFG_VERSION "1.0.0"

//Give plugin info
public Plugin:myinfo =
{
	name		=	"Config Delayer",
	author		=	"Tonybear5",
	description	=	"Waits for server load then fires after a 60 second delay.",
	version		=	"DLYCFG_VERSION",
	url			=	"http://veterangiveaways.co.uk"
};

//Hook into server
public OnAllPluginsLoaded()
{
	CreateTimer(60.0, Command_FireConfig);
}

//Execute the config after the above delay
public Action:Command_FireConfig(Handle timer)
{
	ServerCommand("exec server.cfg");
}