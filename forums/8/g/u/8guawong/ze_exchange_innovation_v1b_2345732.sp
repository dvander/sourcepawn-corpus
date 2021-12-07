#include <sdktools>
#include <sdkhooks>

new bool:enabled;

public OnConfigsExecuted()
{
	decl String:mapname[128];
	GetCurrentMap(mapname, sizeof(mapname));
	
	if (StrEqual(mapname, "ze_exchange_innovation_v1b", false))
	{
		HookEntityOutput("func_door" , "OnOpen", OnDoorOpen);

		enabled = true;
	}
}

public OnMapEnd()
{
	if (enabled)
	{
		UnhookEntityOutput("func_door" , "OnOpen", OnDoorOpen);
		enabled = false;
	}
}

public OnDoorOpen(const String:output[], caller, activator, Float:delay)
{
	if (caller == 574)
	{
		SetEntPropFloat(caller, Prop_Data, "m_flSpeed", 0.3);
	}
}