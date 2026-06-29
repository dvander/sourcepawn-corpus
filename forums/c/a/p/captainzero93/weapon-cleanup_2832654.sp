#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = {
    name = "Weapon Cleanup",
    author = "captainzero93",
    description = "Removes dropped weapons from the map",
    version = "1.0",
    url = ""
};

public OnPluginStart()
{
    CreateTimer(5.0, CleanupTimer, _, TIMER_REPEAT);
}

public Action CleanupTimer(Handle timer)
{
    for (int x = 0; x < 4028; x++)
    {
        if(IsValidEntity(x))
        {
            char model[128];
            GetEntPropString(x, Prop_Data, "m_ModelName", model, sizeof(model));
            
            // Check for all HL2DM weapon models
            if(StrEqual(model, "models/weapons/w_357.mdl", false) || 
               StrEqual(model, "models/weapons/w_crossbow.mdl", false) ||
               StrEqual(model, "models/Weapons/w_IRifle.mdl", false) ||
               StrEqual(model, "models/Weapons/w_grenade.mdl", false) ||
               StrEqual(model, "models/Weapons/w_rocket_launcher.mdl", false) ||
               StrEqual(model, "models/Weapons/w_shotgun.mdl", false) ||
               StrEqual(model, "models/Weapons/W_pistol.mdl", false) ||
               StrEqual(model, "models/Weapons/w_smg1.mdl", false) ||
               StrEqual(model, "models/Weapons/w_stunbaton.mdl", false) ||
               StrEqual(model, "models/Weapons/w_slam.mdl", false) ||          // Added SLAM
               StrEqual(model, "models/Weapons/w_hopwire.mdl", false) ||       // Added Hopwire
               StrEqual(model, "models/Weapons/w_grenade_frag.mdl", false) ||  // Added Frag Grenade
               StrEqual(model, "models/Weapons/w_bugbait.mdl", false))         // Added Bugbait
            {
                AcceptEntityInput(x, "Kill");
            }
        }
    }
    return Plugin_Continue;
}
