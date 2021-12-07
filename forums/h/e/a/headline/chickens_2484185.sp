#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define CHICKEN_COUNT 10 // edit chicken count here

public void OnMapStart()
{
	int entity = FindEntityByClassname(-1, "info_map_parameters");
	if (!IsValidEntity(entity))
	{
		entity = CreateEntityByName("info_map_parameters");
		DispatchSpawn(entity);
	}
	
	SetEntProp(entity, Prop_Data, "m_iPetPopulation", CHICKEN_COUNT);
}