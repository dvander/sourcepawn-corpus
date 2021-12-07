/*
-----------------------------------------------------------------------------
SPAWN KILLER RETRIBUTION - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2009
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This is a basic spawn protection plugin with a little twist - any damage
dealt to someone who has recently spawned will instead be dealt to the person
who attacked them. The damage reversal code is based off of the Mirror Damage
plugin written by strontiumdog.

This plugin should work on most Source games/mods, but has only been tested
thoroughly on Team Fortress 2.

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
Version History

-- 1.0 (6/11/09)
 . Initial release!

-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>

#define PLUGIN_VERSION "1.0"

// Player spawn checking array
new PlayerSpawnTimer[MAXPLAYERS + 1];
new PlayerHealth[MAXPLAYERS + 1];
new PlayerNotice[MAXPLAYERS + 1];

// Cvar handles
new Handle:cvar_EnableTeam2 = INVALID_HANDLE;
new Handle:cvar_EnableTeam3 = INVALID_HANDLE;
new Handle:cvar_Announce = INVALID_HANDLE;
new Handle:cvar_Duration = INVALID_HANDLE;

// Plugin Info
public Plugin:myinfo =
{
    name = "Spawn Killer Retribution",
    author = "msleeper",
    description = "Reverses damage done to spawn campers",
    version = PLUGIN_VERSION,
    url = "http://www.msleeper.com/"
};

// Here we go!
public OnPluginStart()
{
    // Plugin version public Cvar
    CreateConVar("sm_retribution_version", PLUGIN_VERSION, "Spawn Killer Retribution Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

    // Config Cvars
    cvar_EnableTeam2 = CreateConVar("sm_ret_enableteam2", "0", "Enable retribution for Red/Terrorist/Team 2 Attackers", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_EnableTeam3 = CreateConVar("sm_ret_enableteam3", "1", "Enable retribution for Blu/CT/Team3 Attackers", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_Announce = CreateConVar("sm_ret_announce", "1", "Announce to relevent players that the plugin is active for them at their first spawn of a game", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    cvar_Duration = CreateConVar("sm_ret_duration", "5", "Duration of protection", FCVAR_PLUGIN);

    // Hook the events
    HookEvent("player_hurt", event_PlayerHurt);
    HookEvent("player_spawn", event_PlayerSpawn);

    // Make that config!
    AutoExecConfig(true, "retribution");

    // Init player values
    new maxplayers = GetMaxClients();
    for (new i = 1; i <= maxplayers; i++)
    {
        PlayerHealth[i] = 0;
        PlayerNotice[i] = 0;

        if (IsClientInGame(i) && IsPlayerAlive(i))
            CreateTimer(0.1, timer_GetPlayerHealth, i);
    }
}

// Initialize client's notice when they connect.

public OnClientPostAdminCheck(client)
{
    PlayerNotice[client] = 0;
}

// When someone spawns, get their health and their protection, and
// if they haven't been notified, send them a notice.

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(0.1, timer_GetPlayerHealth, client);

    PlayerSpawnTimer[client] = GetConVarInt(cvar_Duration);
    CreateTimer(1.0, timer_CheckProtection, client, TIMER_REPEAT);

    if (!PlayerNotice[client])
        CreateTimer(3.0, timer_SendNotice, client);
}

// Get the player's health and store it in the array.

public Action:timer_GetPlayerHealth(Handle:timer, any:client)
{
    if (IsClientInGame(client))
        PlayerHealth[client] = GetClientHealth(client);
}

// Check if a player's protection has expired.

public Action:timer_CheckProtection(Handle:timer, any:client)
{
    PlayerSpawnTimer[client] = PlayerSpawnTimer[client] - 1;

    if (PlayerSpawnTimer[client] == 0)
        return Plugin_Stop;
    else
        return Plugin_Continue;
}

// Send a notification if notifications are enabled, and if the player
// is on a relevent team. This will only send 1 notice per game to them.

public Action:timer_SendNotice(Handle:timer, any:client)
{
    if (PlayerNotice[client] || !GetConVarBool(cvar_Announce))
        return Plugin_Stop;

    new Team = GetClientTeam(client);

    if ((Team == 2 && GetConVarInt(cvar_EnableTeam2)) || (Team == 3 && GetConVarInt(cvar_EnableTeam3)))
    {
        PrintToChat(client, "[SM] Spawn protection is active! Spawn camping will be punished");
        PlayerNotice[client] = 1;
    }

    return Plugin_Stop;
}

// When someone is attacked, check if they have spawn protection, and if
// so then run the protection check. This code is based off of the
// "Mirror Damage" plugin written by strontiumdog.

public Action:event_PlayerHurt(Handle:event,  const String:name[], bool:dontBroadcast)
{
    new Victim = GetClientOfUserId(GetEventInt(event, "userid"));
    new Health = GetEventInt(event, "health");
    new Attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new Damage;

    if (PlayerSpawnTimer[Victim] > 0 && Attacker != Victim)
    {
        if (Victim && IsClientInGame(Victim) && IsPlayerAlive(Victim))
            SetEntityHealth(Victim, PlayerHealth[Victim]);

        if (Attacker && IsClientInGame(Attacker) && IsPlayerAlive(Attacker))
        {
            new Team = GetClientTeam(Attacker);
            if ((Team == 2 && !GetConVarInt(cvar_EnableTeam2)) || (Team == 3 && !GetConVarInt(cvar_EnableTeam3)))
                return;

            Damage = PlayerHealth[Victim] - Health;

            if (GetClientHealth(Attacker) - Damage <= 0)
                ForcePlayerSuicide(Attacker);
            else
                SetEntityHealth(Attacker, GetClientHealth(Attacker) - Damage);
        }
    }
}
