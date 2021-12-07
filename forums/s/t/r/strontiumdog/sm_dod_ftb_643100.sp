//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//

//
// DESCRIPTION:
// For Day of Defeat Source only
// This plugin is a part of the Realism Mod
// but extracted for those servers wishing to run
// FTB gameplay

//
//
// CHANGELOG:
// - 06.8.2008 Version 1.0.100


#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.101"

#define IN  0x0001
#define OUT 0x0002

new Handle:Cvar_FtbDelay = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "DoDS Fade to Black",
	author = "<eVa>Dog",
	description = "Fade to Black for Day of Defeat Source",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnPluginStart()
{
	CreateConVar("sm_dod_ftb_version", PLUGIN_VERSION, "Version of sm_dod_ftb", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	Cvar_FtbDelay = CreateConVar("sv_dod_ftb_delay", "5", " The duration of the Fade to Black screen fade", FCVAR_PLUGIN)
	
	HookEvent("player_death", PlayerDeathEvent)
}

public OnEventShutdown()
{
	UnhookEvent("player_death", PlayerDeathEvent)
}


public PlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))

	ScreenFade(client, 0, 0, 0, 255, GetConVarInt(Cvar_FtbDelay), OUT)
}


//Fade the screen
public ScreenFade(client, red, green, blue, alpha, delay, type)
{
	new Handle:msg
	new duration
	
	duration = delay * 1000
	
	msg = StartMessageOne("Fade", client)
	BfWriteShort(msg, 500)
	BfWriteShort(msg, duration)
	BfWriteShort(msg, type)
	BfWriteByte(msg, red)
	BfWriteByte(msg, green)
	BfWriteByte(msg, blue)	
	BfWriteByte(msg, alpha)
	EndMessage()
}