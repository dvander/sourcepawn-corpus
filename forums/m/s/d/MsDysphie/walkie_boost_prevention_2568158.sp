#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#define COLLISION_GROUP_DEBRIS 1

public Plugin myinfo =
{
	name = "[NMRiH] Walkie-talkie Prop Surf Prevention",
	description = "Alters the properties of walkie-talkies so that players cannot boost with them",
	author = "Dysphie",
	version = "1.1"
};

ConVar IsPluginEnabled;

public void OnPluginStart()
{
	IsPluginEnabled = CreateConVar("sm_walkie_boost_prevention_enabled", "1", "Enables or disables the plugin.", _, true, 0.0, true, 1.0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "item_walkietalkie"))
	{
		SDKHook(entity, SDKHook_ThinkPost, Hook_WalkieFix);
	}
}

public void Hook_WalkieFix(int walkie)
{
	if (GetConVarBool(IsPluginEnabled))
	{
		SetEntProp(walkie, Prop_Send, "m_CollisionGroup", COLLISION_GROUP_DEBRIS);
	}
}