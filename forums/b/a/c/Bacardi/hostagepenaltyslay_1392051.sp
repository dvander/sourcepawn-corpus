#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Hostage Penalty-Slay",
	author = "Bacardi",
	description = "Slay player who killed hostage",
	version = "0.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("hostage_killed", Event_HostageKilled);	// Hook event
}

public Action:Event_HostageKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); // Get client from event
	new String:iname[MAX_NAME_LENGTH];

	GetClientName(client, iname, sizeof(iname));	// Get client name
	PrintToChatAll("\x01\x03%s \x01kills hostages, now we kill \x03%s", iname, iname);	// Chat output to all
	ForcePlayerSuicide(client);	// Kill player
}