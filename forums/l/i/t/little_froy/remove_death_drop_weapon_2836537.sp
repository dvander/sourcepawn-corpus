#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <little_froy_utils>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Remove Death Drop Weapon",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=347163"
};

ConVar C_filter;
ArrayList O_filter;

public void L4D_OnDeathDroppedWeapons(int client, int weapons[6])
{
    if(weapons[0] != -1)
    {
        char class_name[64];
        GetEntityClassname(weapons[0], class_name, sizeof(class_name));
        if(O_filter.FindString(class_name) == -1)
        {
            RemoveEntity(weapons[0]);
        }
    }
}

void get_all_cvars()
{
	char buffer[2048];
	O_filter.Clear();
	C_filter.GetString(buffer, sizeof(buffer));
	if(buffer[0] != '\0')
	{
		explode_string_to_list(buffer, ",", O_filter, 64, StringExplodeType_String);
	}
}

void get_single_cvar(ConVar convar)
{
	if(convar == C_filter)
	{
		O_filter.Clear();
		char buffer[2048];
		C_filter.GetString(buffer, sizeof(buffer));
		if(buffer[0] != '\0')
		{
			explode_string_to_list(buffer, ",", O_filter, 64, StringExplodeType_String);
		}
	}
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_single_cvar(convar);
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
	O_filter = new ArrayList(ByteCountToCells(64));

    C_filter = CreateConVar("remove_death_drop_weapon_filter", "weapon_rifle_m60,weapon_grenade_launcher,weapon_rifle,weapon_rifle_ak47,weapon_rifle_desert,weapon_rifle_sg552,weapon_autoshotgun,weapon_shotgun_spas,weapon_sniper_military,weapon_sniper_scout,weapon_sniper_awp", "don't remove these weapons, split up with \",\"");
    C_filter.AddChangeHook(convar_changed);
    CreateConVar("remove_death_drop_weapon_version", PLUGIN_VERSION, "version of Remove Death Drop Weapon", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    //AutoExecConfig(true, "remove_death_drop_weapon");
    get_all_cvars();
}
