#pragma semicolon 1
#include <sourcemod>
#pragma newdecls required

#define TimerAfk 0.5  /// After some time, the saved will go to AFK*/

public Plugin myinfo = 
{
	name = "[L4D] AFK After Salvation",
	author = "AlexMy",
	description = "",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=300260"
}
public void OnPluginStart()
{
	HookEvent("survivor_rescued", Event_SurvivorRescued);
}
public void Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(TimerAfk, timer_afk, GetClientOfUserId(event.GetInt("victim")), TIMER_FLAG_NO_MAPCHANGE);
}
public Action timer_afk(Handle timer, any client)
{
	if (IsClientInGame(client) && !IsFakeClient(client)) 
	{
		FakeClientCommand(client, "say /afk");
	}
	return Plugin_Stop;
}