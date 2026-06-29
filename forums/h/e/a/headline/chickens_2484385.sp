#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define CHICKEN_COUNT 10 // edit chicken count here

public void OnEntityCreated(int entity, const char[] className)
{
	if (StrEqual(className, "info_map_parameters"))
	{
		SetEntProp(entity, Prop_Data, "m_iPetPopulation", CHICKEN_COUNT);
	}
}