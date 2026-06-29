#define PLUGIN_VERSION	"1.26"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define UPGRADE_LASER_SIGHT (1 << 2)

public Plugin myinfo =
{
	name = "Automatic Laser Sight Upgrade On Weapon Equip",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340358"
};

char Data_path[PLATFORM_MAX_PATH];

ArrayList Enabled_weapons;
int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];

int get_upgrade(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

void set_upgrade(int weapon, int upgrade)
{
    SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrade);
}

void OnWeaponEquipPost(int client, int weapon)
{
    if(weapon == -1 || GetClientTeam(client) != 2 || !HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
    {
        return;
    }
    char class_name[64];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    if(Enabled_weapons.FindString(class_name) != -1)
    {
        set_upgrade(weapon, get_upgrade(weapon) | UPGRADE_LASER_SIGHT);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

SMCResult OnEnterSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	Current_section_level++;
	if(Current_section_level == 2)
	{
        strcopy(Current_section_name, sizeof(Current_section_name), name);
	}
    return SMCParse_Continue;
}

SMCResult OnLeaveSection(SMCParser smc)
{
    Current_section_level--;
    return SMCParse_Continue;
}

SMCResult OnKeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if(Current_section_level == 2)
	{
        if(strcmp(key, "enable") == 0 && !!StringToInt(value))
        {
            Enabled_weapons.PushString(Current_section_name);
        }
	}
    return SMCParse_Continue;
}

void check_configs()
{
    Enabled_weapons.Clear();
    Current_section_level = 0;
    Current_section_name[0] = '\0';
    SMCParser parser = new SMCParser();
    parser.OnEnterSection = OnEnterSection;
    parser.OnLeaveSection = OnLeaveSection;
    parser.OnKeyValue = OnKeyValue;
    parser.ParseFile(Data_path);
    delete parser;
}

void check_weapons_all()
{
    int entity = -1;
    while((entity = FindEntityByClassname(entity, "*")) != -1)
    {
        if(entity > 0 && HasEntProp(entity, Prop_Send, "m_upgradeBitVec"))
        {
            char class_name[64];
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
    int weapon = event.GetInt("propid");
    if(weapon > 0 && IsValidEntity(weapon) && HasEntProp(weapon, Prop_Send, "m_upgradeBitVec"))
    {
        char class_name[64];
        GetEntityClassname(weapon, class_name, sizeof(class_name));
        if(Enabled_weapons.FindString(class_name) != -1)
        {
            set_upgrade(weapon, get_upgrade(weapon) & ~UPGRADE_LASER_SIGHT);
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
    return APLRes_Success;
}

public void OnPluginStart()
{
    Enabled_weapons = new ArrayList(ByteCountToCells(64));

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/laser_sight_upgrade_on_equip.cfg");

    HookEvent("weapon_drop", event_weapon_drop);

	CreateConVar("laser_sight_upgrade_on_equip_version", PLUGIN_VERSION, "version of Automatic Laser Sight Upgrade On Weapon Equip", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    check_configs();

    RegAdminCmd("sm_laser_sight_upgrade_on_equip_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
    check_weapons_all();
}
