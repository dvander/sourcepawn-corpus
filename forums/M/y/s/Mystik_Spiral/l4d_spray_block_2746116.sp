/*

Blocks client sprays.
It is suggested to also set the following in the server.cfg file:

sm_cvar sv_allowupload 0
sm_cvar sv_allowdownload 0

Although many players have interesting sprays, there are an increasing number of players/griefers who are using custom sprays that are unbelievably disgusting or hateful/political in nature. So much so that I decided to just block all sprays as I am tired of people trying to ruin the fun and enjoyment of playing L4D(2).

I suspect there are similar plugins out there somewhere, but this is what I'm using and thought I would share. I am not taking feature requests at this time, but please let me know if it is not working and/or you get any errors.

Want to contribute code enhancements?
Create a pull request using this GitHub repository: https://github.com/Mystik-Spiral/l4d_spray_block

Plugin discussion: https://forums.alliedmods.net/showthread.php?t=TBDxx

*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0a"

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Spray Block",
	description = "Blocks client sprays",
	author = "Mystik Spiral",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=332342"
}
 
public void OnPluginStart()
{
	CreateConVar("sprayblock_version", PLUGIN_VERSION, "Blocks client sprays", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddTempEntHook("Player Decal", SprayBlock);
}
 
public Action SprayBlock(const char[] name, const int[] Players, int numClients, float delay)
{
	return Plugin_Stop;
}