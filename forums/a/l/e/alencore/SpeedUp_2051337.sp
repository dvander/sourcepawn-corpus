/*
* SourceMod Script
* 
* Developed by Mosalar
* April 2009
* http://www.budznetwork.com
*
*
* DESCRIPTION:
* 
* A general plugin to globally speed up
* player speed and weight/personal grav.
* Originally made for FoF, but can 
* be used in most source games.
*
* Update 20.10.2013
* Different mode for different players (non-admin, admin, bots)
* 
*/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

new Handle:g_hEnabled;
new Handle:g_Cvar_Speed
new Handle:g_Cvar_Weight
new bool:g_bHaveAccess[MAXPLAYERS+1];

public Plugin:myinfo = 
{
    name = "SpeedUp",
    author = "Mosalar, Bacardi",
    description = "Speeds Up Gameplay",
    version = PLUGIN_VERSION,
    url = "http://www.budznetwork.com"
};


public OnPluginStart()
{
    CreateConVar("sm_speedup_version", PLUGIN_VERSION, "SpeedUp Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
    g_hEnabled  = CreateConVar("sm_speedup_enabled", "4",  "0 = disable\n1 + non-admins\n2 + admins\n4 + bots\nTo EVERYONE (1+2+4 = 7) sm_speedup_enabled \"7\"",           FCVAR_PLUGIN, true, 0.0, true, 7.0);
    g_Cvar_Speed    = CreateConVar("sm_speedup_speed", "1.47", " Sets the players speed ", FCVAR_PLUGIN)
    g_Cvar_Weight   = CreateConVar("sm_speedup_weight", "0.0", " Sets the players weight", FCVAR_PLUGIN)
    
    HookEvent("player_spawn", PlayerSpawnEvent)
    
    AutoExecConfig();

    for(new i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
        {
            OnClientPostAdminCheck(i);
        }
    }
}

public OnClientPostAdminCheck(client)
{
    g_bHaveAccess[client] = CheckCommandAccess(client, "sm_speedup", ADMFLAG_RESERVATION);
}


public PlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    CreateTimer(0.0, delayed_spawn, userid, TIMER_FLAG_NO_MAPCHANGE); // because hl2mp deathmatch (mp_teamplay 0) players are in team 0
}

public Action:delayed_spawn(Handle:timer, any:userid)
{
    new client = GetClientOfUserId(userid);
    if(client == 0 || !IsPlayerAlive(client))
    {
        return;
    }

    new mode = GetConVarInt(g_hEnabled);
    if (mode == 0)
    {
        return;
    }

    if(IsFakeClient(client))
    {
        if(!(mode & 4))
        {
            return;
        }
    }
    else if(!g_bHaveAccess[client] && !(mode & 1) || g_bHaveAccess[client] && !(mode & 2))
    {
        return;
    }

    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", GetConVarFloat(g_Cvar_Speed))
    SetEntityGravity(client, GetConVarFloat(g_Cvar_Weight))
}  