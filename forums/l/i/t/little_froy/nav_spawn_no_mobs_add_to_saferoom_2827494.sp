#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "NAV_SPAWN_NO_MOBS Add To Saferoom",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349127"
};

void frame_nav()
{
    if(!L4D_HasMapStarted())
    {
        return;
    }
    ArrayList navs = new ArrayList();
    L4D_GetAllNavAreas(navs);
    for(int i = 0; i < navs.Length; i++)
    {
        Address nav = view_as<Address>(navs.Get(i));
        int flags = L4D_GetNavArea_SpawnAttributes(nav);
        if(!(flags & NAV_SPAWN_CHECKPOINT))
        {
            continue;
        }
        if(!(flags & NAV_SPAWN_NO_MOBS))
        {
            L4D_SetNavArea_SpawnAttributes(nav, flags | NAV_SPAWN_NO_MOBS);
        }
    }
    delete navs;
}

public void OnMapStart()
{
    RequestFrame(frame_nav);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    if(GetEngineVersion() != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "this plugin only runs in \"Left 4 Dead 2\"");
        return APLRes_SilentFailure;
    }
    return APLRes_Success;
}

public void OnPluginStart()
{
    CreateConVar("nav_spawn_no_mobs_add_to_saferoom_version", PLUGIN_VERSION, "version of NAV_SPAWN_NO_MOBS Add To Saferoom", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
