#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"
#define CONF_NAME "map_weapon_manager.txt"

StringMap g_valid_weapon;
StringMap g_valid_weapon_clone;
StringMapSnapshot g_valid_weapon_snapshot;
StringMapSnapshot g_valid_weapon_clone_snapshot;

public Plugin myinfo =
{
	name = "[L4D2] Map Spawn Weapon Manager",
	author = "Miuwiki",
	description = "Make server ban or only spawn the weapon you want.",
	version = PLUGIN_VERSION,
	url = "http://www.miuwiki.site"
}

// static const char g_all_spawn[][] = {
//     "ae", // adrenaline
//     "ao", // ammo
//     "an", // autoshotgun
//     "cw", // chainsaw
//     "dr", // defibrillator
//     "ft", // first_aid_kit
//     "gn", // gascan
//     "gr", // gernade launcher
//     "he", // hunting rifle
//     "im", // item
//     "me", // melee
//     "mv", // molotov
//     "ps", // pain pils
//     "pb", // pipe bomb
//     "pm", // pistol magnum
//     "pl", // pistol
//     "pn", // pump shotgun
//     "r7", // ak47
//     "rt", // desert
//     "r0", // m60
//     "r2", // sg552
//     "re", // rifle 
//     "sm", // scavenge
//     "se", // chrome
//     "ss", // spass
//     "s5", // mp5
//     "sd", // silenced
//     "sg", // smg
//     "sp", // awp
//     "sy", // military
//     "st", // scout
//     "ue", // ammo explosive
//     "uu", // ammo incendiary 
//     "vr" // vomitjar
// };

static const char g_weapon_spawn[][] = {
    "weapon_pistol_spawn",
    "weapon_pistol_magnum_spawn",

    "weapon_smg_spawn",
    "weapon_smg_silenced_spawn",
    "weapon_smg_mp5_spawn",

    "weapon_pumpshotgun_spawn",
    "weapon_shotgun_chrome_spawn",
    "weapon_autoshotgun_spawn",
    "weapon_shotgun_spas_spawn",

    "weapon_rifle_spawn",
    "weapon_rifle_ak47_spawn",
    "weapon_rifle_desert_spawn",
    "weapon_rifle_sg552_spawn",

    "weapon_hunting_rifle_spawn",
    "weapon_sniper_military_spawn",
    "weapon_sniper_awp_spawn",
    "weapon_sniper_scout_spawn",
    
    "weapon_rifle_m60_spawn",
    "weapon_grenade_launcher_spawn"
};
// see weapon_***_spawn in https://developer.valvesoftware.com/wiki/Weapon_spawn
static const char g_main_weapon_spawn[][] = {
    "pl", // pistol
    "pm", // pistol magnum

    "sg", // smg
    "sd", // silenced
    "s5", // mp5
    
    "pn", // pump shotgun
    "se", // chrome
    "an", // autoshotgun
    "ss", // spass

    "re", // rifle 
    "r7", // ak47
    "rt", // desert
    "r2", // sg552
    
    "sp", // awp
    "sy", // military
    "st", // scout
    "he", // hunting rifle

    "gr", // gernade launcher
    "r0" // m60
};

public void OnPluginStart()
{
    HookEvent("round_start",Event_RoundStart);
    g_valid_weapon = new StringMap();
    LoadPluginConfig();
}
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    LoadPluginConfig();
}
public void OnEntityCreated(int entity, const char[] classname)
{
    int dot_word = strlen(classname) - 6;
    if( strncmp(classname, "weapon_",7) == 0 && strcmp(classname[dot_word],"_spawn") == 0 )
    {
        if( strlen(classname) == 12 ) 
            SDKHook(entity,SDKHook_Spawn,SDK_SpawnCallback);// weapon_spawn
        else 
        {
            for(int i = 0; i < sizeof(g_main_weapon_spawn); i++)
            {
                if( strncmp(g_main_weapon_spawn[i][0], classname[7] , 1) == 0
                && strncmp(g_main_weapon_spawn[i][1], classname[strlen(classname) - 7], 1) == 0 // compare char "*" in weapon_* and *_spawn;
                )
                {
                    SDKHook(entity,SDKHook_SpawnPost,SDK_SpawnPostCallback); // now it is weapon not include first_aid_kit etc...
                }
            }
        }
            
    }
}
Action SDK_SpawnCallback(int entity)
{
    if( entity && IsValidEntity(entity) )
    {
        char info[32],pieces[2][32];
        int index = GetRandomInt(0,g_valid_weapon_clone_snapshot.Length - 1);
        g_valid_weapon_clone_snapshot.GetKey(index,info,sizeof(info));
        ExplodeString(info,"_spawn",pieces,2,32);

        DispatchKeyValue(entity, "weapon_selection", pieces[0]);
        PrintToServer("[miuwiki_map_spawn_manager]: weapon_spawn entity has been replace to %s",pieces[0]);
    }
    return Plugin_Continue;
}
void SDK_SpawnPostCallback(int entity)
{
    if( entity && IsValidEntity(entity) )
    {
        char classname[32],key[32];
        GetEntityClassname(entity,classname,sizeof(classname));

        for(int i = 0; i < g_valid_weapon_snapshot.Length; i++)
        {
            g_valid_weapon_snapshot.GetKey(i,key,sizeof(key));
            if( strncmp(key[7], classname[7] , 1) == 0
             && strncmp(key[strlen(key) - 7], classname[strlen(classname) - 7], 1) == 0 // compare char "*" in weapon_* and *_spawn;
            )
            {
                return; // that's mean this weapon_**_spawn is need in map. don't remove it.
            }
        }

        RemoveEntity(entity);
        PrintToServer("[miuwiki_map_spawn_manager]: %s has been remove",classname);
    }
}

void LoadPluginConfig()
{
    g_valid_weapon.Clear();
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM,path,sizeof(path),"data/%s",CONF_NAME);
    if( FileExists(path) == false )
    {
        File hFile = OpenFile(path, "w");
        delete hFile;

        KeyValues kv = CreateKeyValues("weapon");
        kv.ImportFromFile(path);

        for(int i = 0; i < sizeof(g_weapon_spawn); i++)
        {
            kv.JumpToKey(g_weapon_spawn[i],true);
            kv.SetNum("enable",1);
            g_valid_weapon.SetValue(g_weapon_spawn[i],i);
            kv.Rewind();
        }
        kv.ExportToFile(path);
        delete kv;
    }
    else
    {
        KeyValues kv = CreateKeyValues("weapon");
        kv.ImportFromFile(path);
        for(int i = 0; i < sizeof(g_weapon_spawn); i++)
        {
            kv.JumpToKey(g_weapon_spawn[i],true);
            if( kv.GetNum("enable") == 1)
                g_valid_weapon.SetValue(g_weapon_spawn[i],i);
            kv.Rewind();
        }
        delete kv;
    }

    
    delete g_valid_weapon_clone;
    g_valid_weapon_clone = g_valid_weapon.Clone();
    g_valid_weapon_clone.Remove(g_weapon_spawn[17]);
    g_valid_weapon_clone.Remove(g_weapon_spawn[18]);

    delete g_valid_weapon_snapshot;
    g_valid_weapon_snapshot = g_valid_weapon.Snapshot();

    delete g_valid_weapon_clone_snapshot;
    g_valid_weapon_clone_snapshot= g_valid_weapon_clone.Snapshot();
}