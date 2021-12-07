#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new String:Map[32];

public Plugin:myinfo = 
{
	name = "bhop_exodus fix",
	author = "Glite",
	description = "Fix teleporter beetween 6 and 7 lvl.",
	version = "1.0",
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public OnMapStart()
{
	PrecacheModel("weapons/w_knife_t.mdl", true);
	GetCurrentMap(Map, sizeof(Map));
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (StrEqual(Map, "bhop_exodus"))
	{
		new trigger = CreateEntityByName("trigger_teleport");
		if (trigger > 0)
		{
			new Float:origin[3] = {2688.0, 8832.0, 5400.0};
			
			DispatchKeyValue(trigger, "classname", "trigger_teleport");
			DispatchKeyValue(trigger, "spawnflags", "15");
			DispatchKeyValue(trigger, "StartDisabled", "0");
			DispatchKeyValue(trigger, "target", "13");
			DispatchSpawn(trigger);
			ActivateEntity(trigger);
			SetEntityModel(trigger, "weapons/w_knife_t.mdl");

			new Float:minbounds[3] = {-264.0, -264.0, 0.0}; 
			new Float:maxbounds[3] = {264.0, 264.0, 32.0};

			SetEntPropVector(trigger, Prop_Send, "m_vecMins", minbounds);
			SetEntPropVector(trigger, Prop_Send, "m_vecMaxs", maxbounds);
   
			SetEntProp(trigger, Prop_Send, "m_nSolidType", 2);
		
			new enteffects = GetEntProp(trigger, Prop_Send, "m_fEffects");
			enteffects |= 32;
			SetEntProp(trigger, Prop_Send, "m_fEffects", enteffects); 
			TeleportEntity(trigger, origin, NULL_VECTOR, NULL_VECTOR);
		}
    } 	
}