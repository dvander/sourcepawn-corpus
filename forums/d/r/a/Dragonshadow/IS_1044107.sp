#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION  "1"

new Handle:plugin_enable = INVALID_HANDLE;
new bool:sd;

new enablehook = 0;

public Plugin:myinfo = 
{
    name = "Instant Spawn",
    author = "Fire - Dragonshadow",
    description = "Instant Respawn",
    version = PLUGIN_VERSION,
    url = "www.snigsclan.com"
}

public OnPluginStart()
{
    
    CreateConVar("sm_is_version", PLUGIN_VERSION, "Instant Spawn Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    plugin_enable = CreateConVar("sm_is_enable", "0", "Enable/Disable Instant Spawn", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

    HookEvent("player_death", death);
    HookEvent("teamplay_round_stalemate", Event_SuddenDeathStart);
    HookEvent("teamplay_round_start", Event_SuddenDeathEnd);
    HookEvent("teamplay_round_win", Event_SuddenDeathStart);
    HookEvent("teamplay_win_panel", Event_SuddenDeathStart);
    
    HookConVarChange(plugin_enable, OnCvarChanged);
}

public OnConfigsExecuted() 
{
    enablehook = GetConVarInt(plugin_enable);
} 

public OnCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
    enablehook = GetConVarInt(plugin_enable);
} 

public Action:respawn(Handle:timer, any:client)
{
    if(enablehook)
    {
        if(!sd)
        {
            if (IsClientConnected(client) && IsClientInGame(client)) 
            {
                TF2_RespawnPlayer(client);
            }
        }
    }
    return Plugin_Continue;
}

public death(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(enablehook)
    {
        if(!sd)
        {
            new deathflags = GetEventInt(event, "death_flags");
            if(!(deathflags & 32))
            {
            new client = GetClientOfUserId(GetEventInt(event,"userid"));
            CreateTimer(0.1, respawn, client);
            }
        }
    }
}

public Event_SuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    sd = true;
}

public Event_SuddenDeathEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    sd = false;
}