#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

static const String:BUG_MODEL[] = "models/props/terror/Ammo_Can.mdl";

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsModelPrecached(BUG_MODEL))
	{
		PrecacheModel(BUG_MODEL);
	}
}