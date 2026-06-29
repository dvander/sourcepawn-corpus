// vim: ts=8 syntax=cpp
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = {
	name =		"[INS] Hunt Beacons",
	version =	"1.12.1.1",
	description =	"After cache is destroyed, run delayed 'sm_beacon' and 'sm_slay' on bots.",
	author =	"JeremiahK (RedDeathOfMe)",
	url =		"https://forums.alliedmods.net/member.php?u=347772"
}

ConVar gCvarDelayBeacon;
ConVar gCvarDelaySlay;

Handle gTimerBeacon;
Handle gTimerSlay;

public APLRes AskPluginLoad2(Handle handle, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Insurgency) {
		strcopy(error, err_max, "Only compatible with Insurgency");
		return APLRes_SilentFailure;
	}
}

public void OnPluginStart()
{
	HookEvent("object_destroyed", Event_StartTimers, EventHookMode_Post);
	HookEvent("round_start", Event_KillTimers, EventHookMode_Post);
	HookEvent("round_end", Event_KillTimers, EventHookMode_Post);

	gCvarDelayBeacon = CreateConVar(
		"hunt_beacons_delay",
		"150",
		"Delay after cache destroyed to enable beacons, in seconds"
	);
	gCvarDelaySlay = CreateConVar(
		"hunt_beacons_delay_slay",
		"300",
		"Delay after cache destroyed to slay bots, in seconds"
	);
}

static Action Event_StartTimers(Event event, const char[] name, bool dontBroadcast)
{
	if (gCvarDelayBeacon.IntValue > 0) {
		gTimerBeacon = CreateTimer(gCvarDelayBeacon.FloatValue, BeaconBots);
	}
	if (gCvarDelaySlay.IntValue > 0) {
		gTimerSlay = CreateTimer(gCvarDelaySlay.FloatValue, SlayBots);
	}

	return Plugin_Continue;
}

static Action Event_KillTimers(Event event, const char[] name, bool dontBroadcast)
{
	if (gTimerBeacon != INVALID_HANDLE) {
		KillTimer(gTimerBeacon);
		gTimerBeacon = INVALID_HANDLE;
	}
	if (gTimerSlay != INVALID_HANDLE) {
		KillTimer(gTimerSlay);
		gTimerSlay = INVALID_HANDLE;
	}

	return Plugin_Continue;
}

static void BeaconBots(Handle timer)
{
	ServerCommand("sm_beacon @bots");
	gTimerBeacon = INVALID_HANDLE;
}

static void SlayBots(Handle timer)
{
	ServerCommand("sm_slay @bots");
	gTimerSlay = INVALID_HANDLE;
}
