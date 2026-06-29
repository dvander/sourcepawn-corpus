#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

new Handle:hCvarHoliday;
public OnPluginStart()
{
	hCvarHoliday = FindConVar("tf_forced_holiday");
}

public OnEntityCreated(entity, const String:classname[])
{
	new hall = GetConVarInt(hCvarHoliday);
	if (hall != 2 && hall != 6) return;	//probably unnecessary
	if (strncmp(classname, "item_healthkit_", 15) != 0) return;
	SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}
public OnSpawnPost(entity)
{
	SetEntProp(entity, Prop_Send, "m_nModelIndexOverrides", 0, _, 2);
}