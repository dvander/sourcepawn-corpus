/*
	Hosties - LR Kills Only
	by: databomb
 
	Copyrighted by databomb and released under the license of the 
GPL.
	This is a PRIVATE plugin distributed at cost to the plugin 
author
	and contains with it a disclosure agreeement between databomb, 
the
	plugin author, and you, the recipient. Remember that the GPL 
gives
	you the right to further distribute this plugin's source code 
without
	my permission. 
	
	The agreement is as follows:
	If it is discovered by the author 
	that anyone besides the author has distributed this plugin then 
the
	plugins value will be irrevocably lowered by the author 
releasing the
	plugin on gratiis in a public forum.  No further free support, 
help,
	or updates will be provided with the exception, at the author's 
sole
	discretion, to those posting public messages in the same medium 
and 
	web address as the plugin was released on gratiis.
	
	Description:
	
	Prevents cheap suicides when an LR is already lost.
	
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <hosties>
#include <lastrequest>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Hosties - LR Kills Only",
	author = "databomb",
	description = "Stops cheap suicides during LRs",
	version = PLUGIN_VERSION,
	url = "vintagejailbreak.org"
};

public OnPluginStart()
{
	AddCommandListener(Kill_Check, "kill");
	AddCommandListener(Kill_Check, "explode");
	
	AddCommandListener(Team_Check, "jointeam");
	AddCommandListener(Team_Check, "spectate");
}

public Action:Team_Check(client, const String:command[], args)
{
	if (client && IsClientInGame(client) && 
IsClientInLastRequest(client))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Kill_Check(client, const String:command[], args)
{
	if (client && IsClientInGame(client) && 
IsClientInLastRequest(client))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}