#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

public Plugin:myinfo =
{
	name = "Item's text remover",
	author = "CloveR",
	description = "Removes the found and trade text",
	version = "1.0.0.0",
	url = "http://forums.alliedmods.net/showthread.php?t=146270"
}

public OnPluginStart()
{
	HookEvent("item_found", Event_ItemFound, EventHookMode_Pre)
}

public Action:Event_ItemFound(Handle:event, const String:item[], bool:dontBroadcast)
{
	if (GetEventBool(event, "propername"))
	{
		return Plugin_Handled
	}
	return Plugin_Continue
}