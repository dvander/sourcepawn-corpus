/*
-----------------------------------------------------------------------------
MEDIGUN STRIP PLUGIN - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2008
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This plugin was written at the request of community mapper Mr. Happy for a
jump map he was creating. Feel free to use and modify this code as necessary.

Thank you and enjoy!
- msleeper
* 
* Modified by Necrosect for a change of weapon
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
    name = "Medigun Striper",
    author = "necrosect",
    description = "Strips Medigun from all Medics",
    version = PLUGIN_VERSION,
    url = "http://www.yuckfouclan.com/"
};

// Main plugin init - here we go!
public OnPluginStart()
{
    CreateConVar("sm_medigunstrip_version", PLUGIN_VERSION, "Medigun Strip Mod Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    cvarEnabled = CreateConVar("sm_medigunstrip_enable", "1", "Enable/Disable the Medigun Strip plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	HookEvent("player_spawn",stripMedigun);
}

// Remove Medigun from all Meeic
public Action:stripMedigun(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.1,timer_stripMedigun, client);
}

public Action:timer_stripMedigun(Handle:timer)
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
            if (class == 5)
                TF2_RemoveWeaponSlot(i, 1);
        }
    }
}