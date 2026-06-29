#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME                   "[L4D] Incap Tank punch fix"
#define PLUGIN_AUTHOR                 "DrThunder & Thraka"
#define PLUGIN_DESCRIPTION            "This fixes the Incap Tank punch. As it works now, if a punch is going to incap a survivor they just get incapped with out getting hit back. This makes it so they get hit into the air then incapped."
#define PLUGIN_VERSION                "1.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=96075"

public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

ConVar g_hIncapHealth;

public void OnPluginStart()
{
    g_hIncapHealth = FindConVar("survivor_incap_health");
    HookEvent("player_incapacitated", PlayerIncap);
}

public void PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "userid");
    int client = GetClientOfUserId(userid);

    if (client == 0)
        return;

    char weapon[11];
    event.GetString("weapon", weapon, sizeof(weapon));

    if (!StrEqual(weapon, "tank_claw"))
        return;

    SetEntProp(client, Prop_Send, "m_isIncapacitated", 0);
    SetEntityHealth(client, 1);

    CreateTimer(0.4, IncapTimer_Function, userid);
}

public Action IncapTimer_Function(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0)
        return Plugin_Handled;

    SetEntProp(client, Prop_Send, "m_isIncapacitated", 1);
    SetEntityHealth(client, g_hIncapHealth.IntValue);

    return Plugin_Handled;
}
