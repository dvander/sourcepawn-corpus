#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

static const	L4D2_INFLICTOR_INFECTED	  = 4095;

public OnPluginStart()
{
	HookEvent("round_start", event_RoundStart);
}

public event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:buffer[64];
	GetCurrentMap(buffer, sizeof(buffer));
	if (StrContains(buffer, "c8m3_sewers") == -1) return;
	
	new ent;
	while (((ent = FindEntityByClassname(ent, "prop_dynamic")) != -1))
	{
		GetEntPropString(ent, Prop_Data, "m_ModelName", buffer, sizeof(buffer));
		if (StrEqual(buffer, "models/props_interiors/door_sliding_breakable01.mdl")) break;
	}
	if (ent == -1)
	{
		LogError("No exploit door found?!");
	}
	else
	{
		SDKHook(ent, SDKHook_OnTakeDamage, OnTakeDamage);
	}	
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (inflictor != L4D2_INFLICTOR_INFECTED) // case Survivor attack
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}