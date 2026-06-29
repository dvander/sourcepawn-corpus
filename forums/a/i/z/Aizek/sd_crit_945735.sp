/*
 * ====================
 *     Extend Map
 *   File: sd_crit.sp
 *   Author: MOPO3KO
 * ==================== 
 */
 
#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.2"

new Handle:g_crit = INVALID_HANDLE;
new old_crit = -1;

public Plugin:myinfo =
{
    name        = "Sudden death crit off",
    author      = "MOPO3KO",
    description = "No critical hit in sudden death",
    version     = PLUGIN_VERSION,
    url         = "http://forums.alliedmods.net/showthread.php?p=945735"
};

public OnPluginStart()
{
    g_crit = FindConVar("tf_weapon_criticals");
    HookEvent("teamplay_round_stalemate", Event_teamplay_suddendeath);
    HookEvent("teamplay_round_win", Event_teamplay_roundwin);
}

public OnPluginEnd()
{
    OnMapEnd();
}

public OnMapEnd()
{
    if(old_crit) SetConVarInt(g_crit,1,false,false);
    old_crit = -1;
}

public Action:Event_teamplay_roundwin(Handle:event, const String:name[], bool:dontBroadcast) 
{
    OnMapEnd();
}

public Action:Event_teamplay_suddendeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
    old_crit = GetConVarInt(g_crit);
    notify(g_crit);
    new Handle:cvar = FindConVar("sv_tags");
    notify(cvar);
    if(old_crit) SetConVarInt(g_crit,0,false,false);
}

notify(Handle:cvar)
{
    new flags = GetConVarFlags(cvar);
    flags &= ~FCVAR_NOTIFY;
    SetConVarFlags(cvar, flags);
}