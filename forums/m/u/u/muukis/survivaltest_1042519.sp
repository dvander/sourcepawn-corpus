#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1"

//Info
public Plugin:myinfo=
{
	name="Survival Test",
	author="muukis",
	description="Test sourcemod functionality",
	version=PLUGIN_VERSION,
	url=""
}


public OnPluginStart()
{
	HookEvent("survival_at_30min", Event, EventHookMode_Post);
	HookEvent("explain_stage_survival_start", Event, EventHookMode_Post);
	HookEvent("explain_survival_generic", Event, EventHookMode_Post);
	HookEvent("explain_survival_alarm", Event, EventHookMode_Post);
	HookEvent("explain_survival_radio", Event, EventHookMode_Post);
	HookEvent("explain_survival_carousel", Event, EventHookMode_Post);
	HookEvent("survival_round_start", Event, EventHookMode_Post);
}


//=============================
//	TESTING METHODS
//=============================

public Action:Event(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("\x04[\x03SURVIVAL TEST\x04] \x01%s", name);
	LogMessage("[SURVIVAL TEST] %s", name);

	return Plugin_Continue;
}
