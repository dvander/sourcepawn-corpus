#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
    name        = "SDKHooks SDKHook_WeaponSwitchPost crash",
    author      = "Mecha the Slag",
    description = "Test plugin",
    version     = "1.0",
    url         = "http://MechaTheSlag.net/"
};

public OnPluginStart()
{
    // late load
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i)) SDKHook(i, SDKHook_WeaponSwitchPost, ClientSwitchWeapon);
    }
}

public OnClientPostAdminCheck(iClient)
{
    SDKHook(iClient, SDKHook_WeaponSwitchPost, ClientSwitchWeapon);
}

public Action:ClientSwitchWeapon(iClient, iEntity)
{
    // nothing happens
}