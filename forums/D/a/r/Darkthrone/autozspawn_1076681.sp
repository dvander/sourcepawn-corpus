#pragma semicolon 1

#define VERSION "1.0.1"

#include <sourcemod>

public Plugin:myinfo = 
{
    name = "Auto !zspawn",
    author = "Darkthrone, Otstrel Team, TigerOx, TechKnow, AlliedModders LLC",
    description = "Automatically exec !zspawn command on dead players",
    version = VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=117601"
};

new Handle:g_Respawn[MAXPLAYERS + 1]    = {INVALID_HANDLE, ...};
new Handle:g_Cvar_RespawnTime           = INVALID_HANDLE;
new Float:g_respawnTime;
new bool:g_roundStarted;
new g_playerClass[MAXPLAYERS + 1];

public OnPluginStart()
{
    g_Cvar_RespawnTime = CreateConVar("autozspawn_delay", "0.1", "Delay before !zspawn");
    g_respawnTime = GetConVarFloat(g_Cvar_RespawnTime);
    
    new Handle:Cvar_Version = CreateConVar("autozspawn_version", VERSION, "Version of the Auto !zspawn", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    /* Just to make sure they it updates the convar version if they just had the plugin reload on map change */
    SetConVarString(Cvar_Version, VERSION);
    
    HookConVarChange(g_Cvar_RespawnTime, CvarChanged);

    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_team", Event_PlayerTeam);
    g_roundStarted = true;
    RegConsoleCmd("joinclass", Event_JoinClass);
}

public Action:Event_JoinClass(client, args)
{
    g_Respawn[client] = CreateTimer(g_respawnTime, ExecRespawn, client);
    g_playerClass[client] = 1;
}

public CvarChanged(Handle:cvar, const String:oldValue[], const String:newValue[])
{
    if ( cvar == g_Cvar_RespawnTime )
    {
        g_respawnTime = GetConVarFloat(g_Cvar_RespawnTime);
        if ( g_respawnTime < 2 )
        {
            g_respawnTime = 2.0;
        }
        return;
    }
}

public Action:Event_RoundEnd(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_roundStarted = false;
}

public Action:Event_RoundStart(Handle:event,const String:name[],bool:dontBroadcast)
{
    g_roundStarted = true;
}

public Action:ExecRespawn(Handle:timer, any:client)
{
    if ( client && IsClientInGame(client) && (GetClientTeam(client) > 1) && (!IsPlayerAlive(client)) && g_playerClass[client] )
    {
        if ( !g_roundStarted )
        {
            PrintToChat(client,"\x04[Auto !zspawn] \x01You will respawn next round");
        }
        else if (FindConVar("gs_zombiereloaded_version") != INVALID_HANDLE)
        {
            FakeClientCommand(client, "zspawn");
        }
        else if (FindConVar("zombie_version") != INVALID_HANDLE)
        {
            FakeClientCommand(client, "zombie_respawn");
        }
        else
        {
            FakeClientCommand(client, "say !zspawn");
        }
    }    
    g_Respawn[client] = INVALID_HANDLE;
    return Plugin_Stop;
}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    new newTeam = GetEventInt(event, "team");
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if ( !client || (newTeam < 2) )
    {
        return;
    }
    
    if ( IsFakeClient(client) )
    {
        g_playerClass[client] = 1;
        // Fake clients does not exec joinclass, so we need to spawn them 
        // just when they joined team
        g_Respawn[client] = CreateTimer(g_respawnTime, ExecRespawn, client);
    }
    else
    {
        g_playerClass[client] = 0;
    }
}

