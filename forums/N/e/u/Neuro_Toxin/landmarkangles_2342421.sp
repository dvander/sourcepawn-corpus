#include <sdkhooks>

public Plugin myinfo =
{
	name = "Force Landmark Angles",
	author = "Neuro Toxin",
	description = "Forces trigger teleports to use Landmark Angles",
	version = "1.0.0",
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "trigger_teleport"))
		return;
	
	SDKHook(entity, SDKHook_Spawn, OnEntitySpawned);
}

public OnEntitySpawned(entity)
{
	SDKUnhook(entity, SDKHook_Spawn, OnEntitySpawned);
	SetEntProp(entity, Prop_Data, "m_bUseLandmarkAngles", 1);	
}