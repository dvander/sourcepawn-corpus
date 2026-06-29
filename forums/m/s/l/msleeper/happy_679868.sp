/*
-----------------------------------------------------------------------------
STICKY STRIP PLUGIN - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2008
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This plugin was written at the request of community mapper Mr. Happy for a
jump map he was creating. Feel free to use and modify this code as necessary.

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
Version History

-- 1.0.0 (9/2/08)
 . Initial release!
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

//
// Global definitions
//

// Plugin version
#define PLUGIN_VERSION  "1.0.0"

// CVars
new Handle:cvarEnabled;

// Plugin Info
public Plugin:myinfo =
{
    name = "Sticky Striper",
    author = "msleeper",
    description = "Strips Sticky Launcher from all Demomen",
    version = PLUGIN_VERSION,
    url = "http://www.msleeper.com/"
};

// Main plugin init - here we go!
public OnPluginStart()
{
    CreateConVar("sm_stickystrip_version", PLUGIN_VERSION, "Sticky Strip Mod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvarEnabled = CreateConVar("sm_stickystrip_enable", "0", "Enable/Disable the Sticky Strip plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    CreateTimer(0.1, timer_StickyStrip, INVALID_HANDLE, TIMER_REPEAT);
}

// Remove Sticky Launcher from all Demomen
public Action:timer_StickyStrip(Handle:timer)
{
    if (!GetConVarInt(cvarEnabled))
        return;

    new maxplayers = GetMaxClients();
    new class;

    for (new i = 1; i <= maxplayers; i++)
    {
        if (IsClientConnected(i) && IsClientInGame(i))
        {
            class = TF2_GetPlayerClass(i);
            if (class == 4)
                TF2_RemoveWeaponSlot(i, 1);
        }
    }
}