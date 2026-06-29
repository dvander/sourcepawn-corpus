#define PLUGIN_VERSION	"1.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define UPGRADE_LASER_SIGHT (1 << 2)

public Plugin myinfo =
{
	name = "Pistol Laser Exclude Incapacitated",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=340358"
};

int get_upgrade(int weapon)
{
    return GetEntProp(weapon, Prop_Send, "m_upgradeBitVec");
}

void set_upgrade(int weapon, int upgrade)
{
    SetEntProp(weapon, Prop_Send, "m_upgradeBitVec", upgrade);
}

bool is_player_hanging(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

bool is_player_alright(int client)
{
	return !GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool is_player_down(int client)
{
	return !is_player_alright(client) && !is_player_hanging(client);
}

void OnWeaponEquipPost(int client, int weapon)
{
    if(weapon == -1 || GetClientTeam(client) != 2 || !IsPlayerAlive(client) || is_player_down(client))
    {
        return;
    }
    char class_name[64];
    GetEntityClassname(weapon, class_name, sizeof(class_name));
    if(strcmp(class_name, "weapon_pistol") == 0)
    {
        set_upgrade(weapon, get_upgrade(weapon) | UPGRADE_LASER_SIGHT);
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

void event_weapon_drop(Event event, const char[] name, bool dontBroadcast)
{
    int weapon = event.GetInt("propid");
    if(weapon > 0 && IsValidEntity(weapon))
    {
        char class_name[64];
        GetEntityClassname(weapon, class_name, sizeof(class_name));
        if(strcmp(class_name, "weapon_pistol") == 0)
        {
            set_upgrade(weapon, get_upgrade(weapon) & ~UPGRADE_LASER_SIGHT);
        }
    }
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
    HookEvent("weapon_drop", event_weapon_drop);

	CreateConVar("pistol_laser_exclude_incapacitated_version", PLUGIN_VERSION, "version of Pistol Laser Exclude Incapacitated", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            OnClientPutInServer(client);
        }
    }
}
