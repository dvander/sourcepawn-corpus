#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

public void OnPluginStart()
{
	AddCommandListener(Listener_Say, "sm_say");
}

public Action Listener_Say(int client, const char[] command, int argc)
{
	if(client == 0)
		return Plugin_Handled;
		
	return Plugin_Continue;
}