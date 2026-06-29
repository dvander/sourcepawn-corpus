#include <sdkhooks>
#include <sourcemod>
#include <sdktools>

#define IsClient(client) ((client >= 1) && (client <= MaxClients) && IsClientInGame(client))
#define IsSurvivor(client) (IsClient(client) && GetClientTeam(client) == 2)

public Plugin myinfo = 
{
    name = "switch_throwables",
    author = "NoroHime + edits by Sunyata",
    description = "Tap RELOAD key to switch between molotov/pipe-bomb or pipe/molly",
    version = "1.2.0",
    url = "https://forums.alliedmods.net/showthread.php?p=2824951#post2824951"
};

ConVar cHoldTime;
float flHoldTime;

public void OnPluginStart() 
{
    cHoldTime = CreateConVar("switch_throwable_holdtime", "0.2", "Time (seconds) to hold the RELOAD key to switch types. Or 0=tap mode", FCVAR_NOTIFY);
    cHoldTime.AddChangeHook(OnConVarChanged);

    ApplyCvars();
}

void ApplyCvars() 
{
    flHoldTime = cHoldTime.FloatValue;
}

void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) 
{
    ApplyCvars();
}

float time_use_start[MAXPLAYERS + 1];
int buttons_last[MAXPLAYERS + 1];

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2]) 
{
    if (IsSurvivor(client) && IsPlayerAlive(client)) 
    {
        float time = GetEngineTime();
        bool reload_pressed = (buttons & IN_RELOAD) && !(buttons_last[client] & IN_RELOAD);
        bool reload_released = !(buttons & IN_RELOAD) && (buttons_last[client] & IN_RELOAD);

        if (reload_pressed)
            time_use_start[client] = time;

        if (reload_released)
            time_use_start[client] = 0.0;

        if ((!flHoldTime && reload_pressed) || (time_use_start[client] && (time - time_use_start[client] > flHoldTime))) 
        {
            time_use_start[client] = 0.0;

            static char name_weapon[32];
            int weapon_current = L4D_GetPlayerCurrentWeapon(client);

            if (weapon_current != INVALID_ENT_REFERENCE) 
            {
                GetEntityClassname(weapon_current, name_weapon, sizeof(name_weapon));

                if (strcmp(name_weapon, "weapon_pipe_bomb") == 0) 
                {
                    if (RemovePlayerItem(client, weapon_current)) 
                    {
                        RemoveEntity(weapon_current);
                        int new_weapon = GivePlayerItem(client, "weapon_molotov");
                        if (new_weapon != -1)
                        {
                            EquipPlayerWeapon(client, new_weapon);
                        }
                    }
                } 
                else if (strcmp(name_weapon, "weapon_molotov") == 0) 
                {
                    if (RemovePlayerItem(client, weapon_current)) 
                    {
                        RemoveEntity(weapon_current);
                        int new_weapon = GivePlayerItem(client, "weapon_pipe_bomb");
                        if (new_weapon != -1)
                        {
                            EquipPlayerWeapon(client, new_weapon);
                        }
                    }
                }
            }
        }
        buttons_last[client] = buttons;
    }
}

public void OnClientPutInServer(int client) 
{
    if (!IsFakeClient(client))
        SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

public void OnClientDisconnect_Post(int client) 
{
    time_use_start[client] = 0.0;
    buttons_last[client] = 0;
}

void OnWeaponSwitchPost(int client, int weapon) 
{
    time_use_start[client] = 0.0;
    static char name_weapon[32];

    GetEntityClassname(weapon, name_weapon, sizeof(name_weapon));

    // The PrintToChat line has been removed as requested
}

stock int L4D_GetPlayerCurrentWeapon(int client)
{
    return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
}
