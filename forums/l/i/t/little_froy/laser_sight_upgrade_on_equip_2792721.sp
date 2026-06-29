#define PLUGIN_VERSION	"1.19"
#define PLUGIN_NAME     "Automatic Laser Sight Upgrade On Weapon Equip"
#define PLUGIN_PREFIX	"laser_sight_upgrade_on_equip"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define UPGRADE_LASER_SIGHT (1 << 2)

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340358"
};

char Data_path[PLATFORM_MAX_PATH];

bool Late_load;

ArrayList Enabled_weapons;

int get_upgrade(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

void set_upgrade(int weapon, int upgrade)
{
    SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrade);
}

void on_weapon_equip_post(int client, int weapon)
{
    if(GetClientTeam(client) != 2 || weapon == -1 || !HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
    {
        return;
    }
    char class_name[PLATFORM_MAX_PATH];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    if(Enabled_weapons.FindString(class_name) != -1)
    {
        set_upgrade(weapon, get_upgrade(weapon) | UPGRADE_LASER_SIGHT);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, on_weapon_equip_post);
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
                if(kv.GetSectionName(key, sizeof(key)) && kv.GetNum("enable", 0))
                {
                    Enabled_weapons.PushString(key);
                }
            }
            while(kv.GotoNextKey());
        }
        delete kv;
    }
}

void check_weapons_all()
{
    int entity = -1;
    while((entity = FindEntityByClassname(entity, "*")) != -1)
    {
        if(HasEntProp(entity, Prop_Send, "m_upgradeBitVec"))
        {
            char class_name[PLATFORM_MAX_PATH];
            GetEntityClassname(entity, class_name, sizeof(class_name));
            if(Enabled_weapons.FindString(class_name) != -1)
            {
                int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
                if(owner == -1)
                {
                    set_upgrade(entity, get_upgrade(entity) & ~UPGRADE_LASER_SIGHT);
                }
                else if(owner > 0 && owner <= MaxClients && IsClientInGame(owner) && GetClientTeam(owner) == 2)
                {
                    set_upgrade(entity, get_upgrade(entity) | UPGRADE_LASER_SIGHT); 
                }
            }
        }
    }
}

void event_weapon_drop(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client != 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
    {
        int weapon = event.GetInt("propid");
        if(weapon > 0 && IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
        {
            char class_name[PLATFORM_MAX_PATH];
            GetEntityClassname(weapon, class_name, sizeof(class_name));
            if(Enabled_weapons.FindString(class_name) != -1)
            {
                set_upgrade(weapon, get_upgrade(weapon) & ~UPGRADE_LASER_SIGHT);
            }
        }
    }
}

Action cmd_reload(int client, int args)
{
    check_configs();
    check_weapons_all();
    return Plugin_Handled;
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
    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/%s.cfg", PLUGIN_PREFIX);

    Enabled_weapons = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));

    check_configs();

    RegAdminCmd("sm_" ... PLUGIN_PREFIX ... "_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");

    HookEvent("weapon_drop", event_weapon_drop);

	CreateConVar(PLUGIN_PREFIX ... "_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

    if(Late_load)
    {
        for(int client = 1; client <= MaxClients; client++)
        {
            if(IsClientInGame(client))
            {
                OnClientPutInServer(client);
            }
        }
        check_weapons_all();
    }
}