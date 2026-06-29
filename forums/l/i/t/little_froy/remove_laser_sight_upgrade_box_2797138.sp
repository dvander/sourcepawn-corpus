#define PLUGIN_VERSION	"1.2"
#define PLUGIN_NAME     "Remove Laser Sight Upgrade Box"
#define PLUGIN_PREFIX   "remove_laser_sight_upgrade_box"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks> 

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=341269"
};

bool Late_load;

void next_frame(any ref)
{
    int entity = EntRefToEntIndex(ref);
    if(entity != -1)
    {
        RemoveEntity(entity);
    }
}

void on_spawn_post_upgrade_laser_sight_box(int entity)
{
    RequestFrame(next_frame, EntIndexToEntRef(entity));
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if(strcmp(classname, "upgrade_laser_sight") == 0)
    {
        SDKHook(entity, SDKHook_SpawnPost, on_spawn_post_upgrade_laser_sight_box);
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
        while((entity = FindEntityByClassname(entity, "upgrade_laser_sight")) != -1)
        {
            RemoveEntity(entity);
        }
    }
}