#pragma semicolon 1
#include <sourcemod>

new crownCounter = 0;
public Plugin:myinfo = 
{
	name = "Cr0wned Counter",
	author = "Oshroth",
	description = "Records number of witch crowns",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	RegConsoleCmd("witch_crown", Cmd_WitchCrown);
	HookEvent("witch_kill", Event_WitchKill);
}
public Action:Event_WitchKill(Handle:event, const String:name[], bool:dontBroadcast) {
	new userId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userId);
	new bool:oneshot = GetEventBool(event, "oneshot");
	
	if(oneshot == true) {
		crownCounter++;
		PrintHintTextToAll("%N Cr0wned a witch. Witches Cr0wned so far: %d", client, crownCounter);
	} else {
		PrintHintTextToAll("%N failed to Cr0wn the witch. Witches Cr0wned so far: %d", client, crownCounter);
	}
	
	return Plugin_Continue;
}

public Action:Cmd_WitchCrown(client, args) {
	PrintHintText(client, "Witches Cr0wned so far: %d", crownCounter);
	
	return Plugin_Handled;
}
