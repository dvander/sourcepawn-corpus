#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1"

//Info
public Plugin:myinfo=
{
	name="Scavenge Test",
	author="muukis",
	description="Test sourcemod functionality",
	version=PLUGIN_VERSION,
	url=""
}


public OnPluginStart()
{
	HookEvent("scavenge_round_start", Event, EventHookMode_Post);
	HookEvent("scavenge_round_halftime", Event, EventHookMode_Post);
	HookEvent("scavenge_round_finished", Event, EventHookMode_Post);
	HookEvent("scavenge_score_tied", Event, EventHookMode_Post);
	HookEvent("gascan_pour_blocked", Event, EventHookMode_Post);
	HookEvent("gascan_pour_completed", Event, EventHookMode_Post);
	HookEvent("gascan_dropped", Event, EventHookMode_Post);
	HookEvent("gascan_pour_interrupted", Event, EventHookMode_Post);
	HookEvent("scavenge_match_finished", Event, EventHookMode_Post);
	HookEvent("explain_scavenge_goal", Event, EventHookMode_Post);
	HookEvent("scavenge_gas_can_destroyed", Event, EventHookMode_Post);
	HookEvent("explain_scavenge_leave_area", Event, EventHookMode_Post);
	HookEvent("begin_scavenge_overtime", Event, EventHookMode_Post);
}


//=============================
//	TESTING METHODS
//=============================

public Action:Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("\x04[\x03SCAVENGE TEST\x04] \x01%s", name);
	LogMessage("[SCAVENGE TEST] %s", name);

	return Plugin_Continue;
}
