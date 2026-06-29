#define PLUGIN_VERSION	"3.7"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Limited Infinite Reserve Ammo",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336301"
};

char Data_path[PLATFORM_MAX_PATH];

StringMap Enabled_weapons;
int Current_section_level;
char Current_section_name[PLATFORM_MAX_PATH];

int get_clip(int weapon)
{
    return GetEntProp(weapon, Prop_Data, "m_iClip1");
}

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

public void OnGameFrame()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
        {
            for(int i = 0; i < 2; i++)
            {
                int slot = GetPlayerWeaponSlot(client, i);
                if(slot == -1)
                {
                    continue;
                }
                int ammo_type = get_ammo_type(slot);
                if(ammo_type == -1)
                {
                    continue;
                }
                if(is_reloading(slot))
                {
                    continue;
                }
                char class_name[64];
                GetEntityClassname(slot, class_name, sizeof(class_name));
                int max = 0;
                if(Enabled_weapons.GetValue(class_name, max))
                {
                    int clip = get_clip(slot);
                    if(clip + get_reserve_ammo(client, ammo_type) < max)
                    {
                        set_reserve_ammo(client, ammo_type, max - clip);
                    }
                }
            }
        }
    }  
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
        if(strcmp(key, "reserve_ammo") == 0)
        {
            int the_value = StringToInt(value);
            if(the_value > 0)
            {
                Enabled_weapons.SetValue(Current_section_name, the_value);
            }
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
    Enabled_weapons = new StringMap();

    BuildPath(Path_SM, Data_path, sizeof(Data_path), "data/limited_infinite_reserve_ammo.cfg");

    CreateConVar("limited_infinite_reserve_ammo_version", PLUGIN_VERSION, "version of Limited Infinite Reserve Ammo", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    check_configs();

    RegAdminCmd("sm_limited_infinite_reserve_ammo_reload", cmd_reload, ADMFLAG_ROOT, "reload config data from file");
}
