#include <sourcemod>
#define PLUGIN_VERSION "0.1"

public Plugin:myinfo =
{
	name = "Events Test",
	author = "RU_6uK",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

new String:g_sEventsLog[PLATFORM_MAX_PATH];

public OnPluginStart()
{
	HookEvent("finale_start", Event_FS);
	HookEvent("finale_win", Event_FW);
	HookEvent("finale_escape_start", Event_FES);
	HookEvent("finale_vehicle_ready", Event_FVR);
	HookEvent("finale_vehicle_leaving", Event_FVL);
	
	BuildPath(Path_SM, g_sEventsLog, sizeof(g_sEventsLog), "logs/events-test.log");
}

public Event_FS(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iRushes = GetEventInt(event, "rushes");
	PrintToChatAll("[EVENT-TEST] Event 'finale_start' fired, 'rushes' = %d.", iRushes);
	LogToFileEx(g_sEventsLog, "Event 'finale_start' fired, 'rushes' = %d.", iRushes);
}

public Event_FW(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sMapName[24];
	GetEventString(event, "map_name", sMapName, sizeof(sMapName));
	new iDifficulty = GetEventInt(event, "difficulty");
	PrintToChatAll("[EVENT-TEST] Event 'finale_win' fired, 'map_name' = %s, 'difficulty' = %d.", sMapName, iDifficulty);
	LogToFileEx(g_sEventsLog, "Event 'finale_win' fired, 'map_name' = %s, 'difficulty' = %d.", sMapName, iDifficulty);
}

public Event_FES(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("[EVENT-TEST] Event 'finale_escape_start' fired.");
	LogToFileEx(g_sEventsLog, "Event 'finale_escape_start' fired.");
}

public Event_FVR(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:sCampaign[24];
	GetEventString(event, "campaign", sCampaign, sizeof(sCampaign));
	PrintToChatAll("[EVENT-TEST] Event 'finale_vehicle_ready' fired, 'campaign' = %s.", sCampaign);
	LogToFileEx(g_sEventsLog, "Event 'finale_vehicle_ready' fired, 'campaign' = %s.", sCampaign);
}

public Event_FVL(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iSurvivorCount = GetEventInt(event, "survivorcount");
	PrintToChatAll("[EVENT-TEST] Event 'finale_vehicle_leaving' fired, 'survivorcount' = %d.", iSurvivorCount);
	LogToFileEx(g_sEventsLog, "Event 'finale_vehicle_leaving' fired, 'survivorcount' = %d.", iSurvivorCount);
}