#define PLUGIN_VERSION	"3.11"
#define PLUGIN_NAME     "Infinite Reserve Ammo"
#define PLUGIN_PREFIX	"infinite_reserve_ammo"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340877"
};

char Data_path[PLATFORM_MAX_PATH];

StringMap Enabled_weapons;

bool is_reloading(int weapon)
{
    return !!GetEntProp(weapon, Prop_Data, "m_bInReload");
}

int get_ammo_type(int weapon)
{
    return GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType");
}

int get_reserve_ammo(int client, int ammo_type)
{
    return GetEntProp(client, Prop_Data, "m_iAmmo", _, ammo_type);
}

void set_reserve_ammo(int client, int ammo_type, int count)
{
    SetEntProp(client, Prop_Data, "m_iAmmo", count, _, ammo_type);
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(GetClientTeam(client) == 2)
    {
        for(int i = 0; i < 2; i++)
        {
            int slot = GetPlayerWeaponSlot(client, i);
            if(slot == -1)
            {
                continue;
            }
            int ammo_type = get_ammo_type(slot);
            if(ammo_type == -1 || is_reloading(slot))
            {
                continue;
            }
            char class_name[PLATFORM_MAX_PATH];
            GetEntityClassname(slot, class_name, sizeof(class_name));
            int reserve_ammo = 0;
            if(Enabled_weapons.GetValue(class_name, reserve_ammo) && get_reserve_ammo(client, ammo_type) < reserve_ammo)
            {
                set_reserve_ammo(client, ammo_type, reserve_ammo);
            }
        }
    }  
}

void check_configs()
{
    Enabled_weapons.Clear();    
    if(FileExists(Data_path))
    { 
        KeyValues kv = new KeyValues(PLUGIN_PREFIX);
        if(kv.ImportFromFile(Data_path) && kv.GotoFirstSubKey())
        {
            do
            {
                char key[PLATFORM_MAX_PATH];
                if(kv.GetSectionName(key, sizeof(key)))
                {
                    int reserve_ammo = kv.GetNum("reserve_ammo", 0);
                    if(reserve_ammo > 0)
                    {
                        Enabled_weapons.SetValue(key, reserve_ammo);
                    }
                }
            }
            while(kv.GotoNextKey());
        }
        delete kv;
    }
}

Action cmd_reload(int client, int args)
{
    check_configs();
    return Plugin_Handled;
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
    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/%s.cfg", PLUGIN_PREFIX);

    Enabled_weapons = new StringMap();

    check_configs();

    RegAdminCmd("sm_" ... PLUGIN_PREFIX ... "_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");

	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);
}