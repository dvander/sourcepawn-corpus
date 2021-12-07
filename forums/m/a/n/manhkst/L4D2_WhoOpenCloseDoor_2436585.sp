#pragma semicolon 1
#include <sdktools>
#include <sourcemod>

public OnPluginStart()
{
	HookEvent("door_open",Event_OpenDoor); 
	HookEvent("door_unlocked",Event_OpenDoor); 
	HookEvent("rescue_door_open",Event_OpenDoor); 
	HookEvent("waiting_checkpoint_door_used",Event_OpenDoor); 
	HookEvent("door_close",Event_CloseDoor); 
}
public Action:Event_OpenDoor(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client!=0)
	{
		PrintToChatAll("%N has close door",client);
		LogMessage("%N has close door",client);
		LogError("%N has close door",client);
	}
}
public Action:Event_CloseDoor(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client!=0)
	{
		PrintToChatAll("%N has close door",client);
		LogMessage("%N has close door",client);
		LogError("%N has close door",client);
	}
}