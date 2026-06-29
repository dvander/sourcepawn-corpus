#define PLUGIN_VERSION "1.0"

#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "[L4D2] Car Alarm Notify",
	author = "raziEiL [disawar1]",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/raziEiL"
}

static g_iAlarmCarClient;

public OnPluginStart()
{
	HookEvent("create_panic_event", event_PanicEvent);
	HookEvent("triggered_car_alarm", event_CarAlarm, EventHookMode_PostNoCopy);
}

public Action:event_PanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iAlarmCarClient = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(0.5, Clear, g_iAlarmCarClient);
}

public Action:Clear(Handle:timer) g_iAlarmCarClient = 0;

public Action:event_CarAlarm(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iAlarmCarClient && IsClientInGame(g_iAlarmCarClient) && GetClientTeam(g_iAlarmCarClient) == 2){

		PrintToChatAll("Car Alarm Triggered by %N", g_iAlarmCarClient);
		g_iAlarmCarClient = 0;
	}
}
