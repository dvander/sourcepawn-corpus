#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "exd"
#define PLUGIN_VERSION "1.00"
#define PLUGIN_URL "https://steamcommunity.com/id/exd1337/"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "RemoveBreakables",
	author = PLUGIN_AUTHOR,
	description = "Delete ALL breakable entityes and pre-open all doors",
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnEntityCreated(int entity, const char[] classname)
{
	if (IsValidEntity(entity))
	{
		if(StrEqual(classname, "func_breakable") || StrEqual(classname, "func_breakable_surf") || StrEqual(classname, "prop_door_rotating"))
		{
			SDKHook(entity, SDKHook_Spawn, SDKHook_OnEntitySpawn);
		}
	}
}

stock int Entity_GetHealth(int entity)
{	
	return GetEntProp(entity, Prop_Data, "m_iHealth");
}

public Action SDKHook_OnEntitySpawn(int entity)
{
	char className[35];
	GetEdictClassname(entity, className, sizeof(className));
	
	if (StrEqual(className, "prop_door_rotating"))
	{
		SetEntProp(entity, Prop_Data, "m_fFlags", 1);
	}
	else if (Entity_GetHealth(entity) < 400)
	{
		AcceptEntityInput(entity, "Kill");
	}

	return Plugin_Handled;
}