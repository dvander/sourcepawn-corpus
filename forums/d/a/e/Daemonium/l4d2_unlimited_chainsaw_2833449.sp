#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks> // Added for SDKHook support

public Plugin myinfo =
{
    name = "[L4D2] Unlimited Chainsaw",
    author = "Daemonium",
    description = "Chainsaw fuel always at 100% with on/off config",
    version = "1.2",
    url = ""
};

ConVar g_hChainsawEnabled;

public void OnPluginStart()
{
    // Create config ConVar
    g_hChainsawEnabled = CreateConVar("sm_chainsaw_unlimited", "1", "Enable or disable unlimited chainsaw fuel (1 = On, 0 = Off)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // Auto-create config file
    AutoExecConfig(true, "l4d2_unlimited_chainsaw");
    
    // Hook player spawn to detect weapon switches
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && IsClientInGame(client))
    {
        SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
    }
}

public void OnWeaponSwitch(int client, int weapon)
{
    // Check if the feature is enabled
    if (!g_hChainsawEnabled.BoolValue)
    {
        return;
    }

    if (weapon > 0)
    {
        char classname[64];
        GetEdictClassname(weapon, classname, sizeof(classname));
        if (StrEqual(classname, "weapon_chainsaw"))
        {
            SetEntProp(weapon, Prop_Send, "m_iClip1", 100); // Set fuel to max
        }
    }
}
