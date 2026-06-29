#define PLUGIN_VERSION	"1.5"
#define PLUGIN_NAME     "Remove Ammo Stack"
#define PLUGIN_PREFIX   "remove_ammo_stack"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>  

#define MODEL_AMMO_STACK1   "models/props/terror/ammo_stack.mdl"
#define MODEL_AMMO_STACK2   "models/props_unique/spawn_apartment/coffeeammo.mdl"

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340048"
};

bool Late_load;

void next_frame_ammo_stack(any ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        RemoveEntity(entity);
    }
}

void next_frame_prop_dynamic(any ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        char model[PLATFORM_MAX_PATH];
        GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
        if(strcmp(model, MODEL_AMMO_STACK1) == 0 || strcmp(model, MODEL_AMMO_STACK2) == 0)
        {
            RemoveEntity(entity);
        }
    }
}

void on_spawn_post_ammo_stack(int entity)
{
    RequestFrame(next_frame_ammo_stack, EntIndexToEntRef(entity));
}

void on_spawn_post_prop_dynamic(int entity)
{
    RequestFrame(next_frame_prop_dynamic, EntIndexToEntRef(entity));
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(strcmp(classname, "weapon_ammo_spawn") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, on_spawn_post_ammo_stack);
    }
    else if(strcmp(classname, "prop_dynamic") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, on_spawn_post_prop_dynamic);
    }
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    Late_load = late;
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

    if(Late_load)
    {
        int entity = -1;
        while((entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != -1)
        {
            RemoveEntity(entity);
        }
        while((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
        {
            char model[PLATFORM_MAX_PATH];
            GetEntPropString(entity, Prop_Data, "m_ModelName", model, sizeof(model));
            if(strcmp(model, MODEL_AMMO_STACK1) == 0 || strcmp(model, MODEL_AMMO_STACK2) == 0)
            {
                RemoveEntity(entity);
            }
        }
    }
}