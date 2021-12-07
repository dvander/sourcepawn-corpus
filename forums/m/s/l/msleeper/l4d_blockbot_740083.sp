/*
-----------------------------------------------------------------------------
LEFT 4 DEAD STATS - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2008
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This simple plugin gives warnings to players if the attempt to exploit
Infected by spawning unlimited AI bots. After X warnings, they are banned for
Y minutes.

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"
#define MAX_LINE_WIDTH 60

new Handle:cvar_MaxWarnings;
new Handle:cvar_BanLength;
new Handle:versus = INVALID_HANDLE;

new ExploitWarn[MAXPLAYERS + 1];

// Plugin Info
public Plugin:myinfo =
{
    name = "Infected Spawn Exploit Block",
    author = "msleeper",
    description = "Blocks players from exploiting unlimited infected spawning",
    version = PLUGIN_VERSION,
    url = "http://www.msleeper.com/"
};

public OnPluginStart()
{
    CreateConVar("sm_blockbot_version", PLUGIN_VERSION, "Infected Spawn Blocker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

    cvar_MaxWarnings = CreateConVar("sm_blockbot_warnings", "3", "Warnings needed before ban", FCVAR_PLUGIN, true, 1.0, false);
    cvar_BanLength = CreateConVar("sm_blockbot_banlength", "10", "Length of exploit ban", FCVAR_PLUGIN, true, 0.0, false);

    versus = FindConVar("director_no_human_zombies");

    HookEvent("player_team", event_CheckTeam);
}

public Action:event_CheckTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarBool(versus))
        return;
        
    if (GetEventBool(event, "isbot"))
        return;

    new Player = GetClientOfUserId(GetEventInt(event, "userid"));

    if (!Player)
        return;

    new Team = GetEventInt(event, "team");
    new OldTeam = GetEventInt(event, "oldteam");
    new WarningsLeft = 0;

    if (Team == 1 && OldTeam == 3)
    {
        if (ExploitWarn[Player] > GetConVarInt(cvar_MaxWarnings))
            BanClient(Player, GetConVarInt(cvar_BanLength), BANFLAG_AUTHID, "Infected spawn exploiting", "Infected spawn exploiting");

        WarningsLeft = GetConVarInt(cvar_MaxWarnings) - ExploitWarn[Player];
        PrintHintText(Player, "You will be kicked for exploiting! You have %i warnings left!", WarningsLeft);

        ExploitWarn[Player]++;
    }
}
