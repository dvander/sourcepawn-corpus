#include <sourcemod>
 
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
    name = "Infinite Reserve Ammo",
    author = "Modified for GunGame",
    description = "Gives all players infinite reserve ammo",
    version = PLUGIN_VERSION,
    url = ""
};

new activeoffset;
new maxclients;

public OnPluginStart()
{
    // Get weapon offset
    activeoffset = FindSendPropInfo("CAI_BaseNPC", "m_hActiveWeapon");
    
    // Create timer for infinite ammo checks
    CreateTimer(0.1, AmmoTimer, _, TIMER_REPEAT);
}

public OnMapStart() {
    maxclients = MaxClients;
}

public Action:AmmoTimer(Handle:timer)
{
    new iWeapon;
    new iAmmoType;
    
    for(new iClient = 1; iClient <= maxclients; iClient++)
    {
        if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
        {
            iWeapon = GetEntDataEnt2(iClient, activeoffset);
            if(IsValidEntity(iWeapon)) {
                // Get primary ammo type
                iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iPrimaryAmmoType");
                if(iAmmoType != -1) {
                    // Set reserve ammo to max (999)
                    SetEntProp(iClient, Prop_Send, "m_iAmmo", 999, _, iAmmoType);
                }
                
                // Get and set secondary ammo type
                iAmmoType = GetEntProp(iWeapon, Prop_Send, "m_iSecondaryAmmoType");
                if(iAmmoType != -1) {
                    // Set secondary reserve ammo to max
                    SetEntProp(iClient, Prop_Send, "m_iAmmo", 999, _, iAmmoType);
                }
            }
        }
    }
    return Plugin_Continue;
}