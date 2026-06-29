#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
HookEvent("round_start", Event_RoundStart);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
ServerCommand("sm_cvar mp_solid_teammates 0");
CreateTimer(5.0, Timer);
}

public Action:Timer(Handle:timer)
{
ServerCommand("sm_cvar mp_solid_teammates 1");
}  