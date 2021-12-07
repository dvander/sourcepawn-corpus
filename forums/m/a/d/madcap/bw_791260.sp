#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "Black and White Notifier",
	author = "Madcap",
	description = "Notify everyone when player is black and white.",
	version = "0.1",
	url = "http://maats.org"
};

public OnPluginStart()
{
	HookEvent("revive_success", EventReviveSuccess);
}

public EventReviveSuccess(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "lastlife"))
	{

		new target = GetClientOfUserId(GetEventInt(event, "subject"));
		decl String:targetName[64];
		GetClientName(target, targetName, sizeof(targetName));
		
		PrintToChatAll("%s is black and white.", targetName);
		
	}
	
}