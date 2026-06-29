#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <cstrike>
#pragma newdecls required

#define PLUGIN_VERSION "1.0"

int g_ChickenMod;
Handle changecolor = INVALID_HANDLE;

public Plugin myinfo = {
    name = "Chicken Colors",
    author = "TonyBaretta",
    description = "Random colors chickens",
    version = PLUGIN_VERSION,
    url = "http://www.wantedgov.it"
};

public void OnPluginStart()
{
	CreateConVar("chicken_colors_version", PLUGIN_VERSION, "Current Chicken Colors version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (entity > MaxClients && IsValidEntity(entity)){ 
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
	}
}
public void OnEntitySpawned(int entity)
{
	char classname[32]
	if (entity > MaxClients && IsValidEntity(entity)){ 
		GetEntityClassname(entity, classname, 32);
		if (StrContains(classname, "chicken") != -1)
		{
			g_ChickenMod = GetRandomInt(1,3);
			if(g_ChickenMod == 1){
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 0, 0, 0, 255);
			}
			if(g_ChickenMod == 2){
				int Rent = EntIndexToEntRef(entity); 
				changecolor = CreateTimer(0.1, UpdateColor, Rent, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
			if(g_ChickenMod == 3){
				SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
				SetEntityRenderColor(entity, 210, 186, 0, 255);
			}
		}
	}
}
public Action UpdateColor(Handle timer, int entity)
{
	if(IsValidEntity(entity)){
		//SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, GetRandomInt(0,255), GetRandomInt(0,255), GetRandomInt(0,255), 255);
	}
	else
	CloseHandle(changecolor);
	changecolor = INVALID_HANDLE;
}