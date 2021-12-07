/* This is a quick hack to stop grab_teleport from working */

#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	RegConsoleCmd("grab_teleport", CSR_NoTeleport)
}

public Action:CSR_NoTeleport(client, args)
{
	PrintToChat(client,"Computer says no.");
	return Plugin_Handled;
}
