#include <sdktools>
#include <cstrike>

public Plugin:myinfo = 
{
    name = "CT JAIL WEAPONS",
    author = "Azik",
    description = "Plugin qui donne une M4A1 et un deagle aux anti-terroristes.",
}

public OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if(IsClientInGame(client) &&  GetClientTeam(client) == 3)
    {
        if(GetPlayerWeaponSlot(client,CS_SLOT_SECONDARY) != -1)
        {
            new    weapon = GetPlayerWeaponSlot(client,CS_SLOT_SECONDARY);
            RemovePlayerItem(client,weapon);
        }
        GivePlayerItem(client,"weapon_deagle");
        GivePlayerItem(client,"weapon_m4a1");
    }
}