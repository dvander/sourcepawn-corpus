//
// SourceMod Script
//
// Developed by <eVa>Dog
// June 2008
// http://www.theville.org
//
//  Counts the number of times a player changes class between deaths
//  Kicks if number goes over a limit set by a cvar

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.100"

new class_changes[33]

new Handle:g_Cvar_Max = INVALID_HANDLE

public OnPluginStart()
{
	CreateConVar("sm_class_spam", PLUGIN_VERSION, "Version of Anti Class-Spam", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	g_Cvar_Max = CreateConVar("sm_class_spam_max", "8", "- maximum number of times class can be changed between spawns")
	
	HookEvent("player_changeclass", ChangeClassEvent)
	HookEvent("player_death", DeathEvent)
}

public Plugin:myinfo = 
{
	name = "Anti-Class Spam",
	author = "<eVa>Dog",
	description = "Will stop players crashing server due to quick class changing",
	version = PLUGIN_VERSION,
	url = "http://www.theville.org"
}

public OnClientPostAdminCheck(client)
{
	class_changes[client] = 0
}

public OnEventShutdown()
{
	UnhookEvent("player_changeclass", ChangeClassEvent)
	UnhookEvent("player_death", DeathEvent)
}

public DeathEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	class_changes[client] = 0
}

public ChangeClassEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	new String:clientName[64]
	new String:authID[64]
	
	class_changes[client]++
	
	if (class_changes[client] > GetConVarInt(g_Cvar_Max))
	{
		new userid = GetClientUserId(client)
		GetClientName(client,clientName,64)
		GetClientAuthString(client, authID, sizeof(authID))
			
		ServerCommand("kickid %i %s", userid, "For multiple class changes")
			
		LogMessage( "%s (%s) was kicked for spamming class changes", clientName, authID)
	}
}

