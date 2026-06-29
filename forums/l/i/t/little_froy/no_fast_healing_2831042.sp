#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "No Fast Healing",
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=349778"
};

void change_weapon(int client)
{
    if(GetEntProp(client, Prop_Send, "m_iCurrentUseAction") != 1)
    {
        return;
    }
    int active = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if(active == -1)
    {
        return;
    }
    char class_name[64];
    GetEntityClassname(active, class_name, sizeof(class_name));
    if(strcmp(class_name, "weapon_first_aid_kit") != 0)
    {
        return;
    }
    for(int i = 0; i < 5; i++)
    {
        int slot = GetPlayerWeaponSlot(client, i);
        if(slot != -1 && slot != active)
        {
            GetEntityClassname(slot, class_name, sizeof(class_name));
            FakeClientCommand(client, "use %s", class_name);
            FakeClientCommand(client, "use weapon_first_aid_kit");
            return;
        }
    }
}

void event_map_transition(Event event, const char[] name, bool dontBroadcast)
{
	for(int client = 1; client <= MaxClients; client++)
	{
        if(IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
        {
            change_weapon(client);
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
    HookEvent("map_transition", event_map_transition);

    CreateConVar("no_fast_healing_version", PLUGIN_VERSION, "version of No Fast Healing", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}
