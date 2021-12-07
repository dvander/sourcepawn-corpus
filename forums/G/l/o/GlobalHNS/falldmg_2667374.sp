#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Global HNS"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdkhooks>

#define LoopAllPlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1))

public Plugin myinfo = 
{
    name = "Print Fall Damage",
    author = PLUGIN_AUTHOR,
    description = "Prints how many fall damage players have received.",
    version = PLUGIN_VERSION,
    url = "https://discord.gg/unt5ffP"
};

public void OnPluginStart()
{
    LoopAllPlayers(i)
        SDKHook(i, SDKHook_OnTakeDamage, Event_OnTakeDamage);
    
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public Action Event_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{
    
    if(damagetype & DMG_FALL || damagetype & DMG_VEHICLE)
    {
        PrintToChatAll(" \x10[HNS] \x07%N\x01 just took \x07%d\x01 fall damage.", victim, RoundFloat(damage));
    }
    
    return Plugin_Continue;
}