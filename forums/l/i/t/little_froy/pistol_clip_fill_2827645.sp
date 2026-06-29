#define PLUGIN_VERSION	"2.0"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

public Plugin myinfo =
{
	name = "Pistol Clip Fill",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349148"
};

void fill_doing(int client, const char[] class_name)
{
    int weapon = GetPlayerWeaponSlot(client, L4D2_GetIntWeaponAttribute(class_name, L4D2IWA_Bucket));
    if(weapon == -1)
    {
        return;
    }
    char name[64];
    GetEntityClassname(weapon, name, sizeof(name));
    if(strcmp(name, class_name) != 0)
    {
        return;
    }
    int max = L4D2_GetIntWeaponAttribute(class_name, L4D2IWA_ClipSize);
    if(GetEntProp(weapon, Prop_Send, "m_isDualWielding"))
    {
        max *= 2;
    }
    if(GetEntProp(weapon, Prop_Data, "m_iClip1") < max)
    {
        SetEntProp(weapon, Prop_Data, "m_iClip1", max);
        if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") == weapon && GetEntProp(weapon, Prop_Data, "m_bInReload"))
        {
            RemovePlayerItem(client, weapon);
            EquipPlayerWeapon(client, weapon);
        }
    }
}

void fill_pistol_clip(int client)
{
    if(!IsClientInGame(client) || GetClientTeam(client) != 2 || !IsPlayerAlive(client))
    {
        return;
    }
    fill_doing(client, "weapon_pistol");
    fill_doing(client, "weapon_pistol_magnum");
}

void event_player_incapacitated(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(client > 0)
    {
        fill_pistol_clip(client);
    }
}

void event_revive_success(Event event, const char[] name, bool dontBroadcast)
{
    if(event.GetBool("ledge_hang"))
    {
        return;
    }
    int client = GetClientOfUserId(event.GetInt("subject"));
    if(client > 0)
    {
        fill_pistol_clip(client);
    }
}

void event_defibrillator_used(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("subject"));
    if(client > 0)
    {
        fill_pistol_clip(client);
    }
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
    for(int client = 1; client <= MaxClients; client++)
    {
        fill_pistol_clip(client);
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
    HookEvent("player_incapacitated", event_player_incapacitated);
    HookEvent("revive_success", event_revive_success);
    HookEvent("defibrillator_used", event_defibrillator_used);
    HookEvent("map_transition", event_map_transition);

    CreateConVar("pistol_clip_fill_version", PLUGIN_VERSION, "version of Pistol Clip Fill", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
