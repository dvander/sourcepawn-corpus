/**
 * ====================
 *     SM Bot Quota
 *   File: smbotquota.sp
 *   Author: Greyscale
 * ==================== 
 */
 
#pragma semicolon 1
#include <sourcemod>
#include <cstrike>

#define VERSION "1.0"

public Plugin:myinfo =
{
    name = "SM Bot Quota",
    author = "Greyscale",
    description = "Bypasses Valve's limit of 21 when adding bots",
    version = VERSION,
    url = ""
};

public OnPluginStart()
{
    // ======================================================================
    
    RegAdminCmd("sm_bot_quota", Command_SMBotQuota, ADMFLAG_RCON, "sm_bot_quota <botcount>");
}

public Action:Command_SMBotQuota(client, argc)
{
    ServerCommand("bot_quota 50");
    
    CreateTimer(7.0, MoveBots);
}

public Action:MoveBots(Handle:timer)
{
    new maxplayers = GetMaxClients();
    for (new x = 1; x <= maxplayers; x++)
    {
        if (!IsClientInGame(x) || !IsFakeClient(x))
            continue;
        
        CS_SwitchTeam(x, CS_TEAM_T);
    }
}