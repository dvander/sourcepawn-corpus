#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define BANTIME 90
#define HITGROUP_HEAD 1
#define HS_MAX 20

#define PLUGIN_VERSION            "0.0.1 player_death"
#define PLUGIN_DESCRIPTION        "rage aimbot detector"

public Plugin:myinfo =
{
    name         =    "rage aimbot detector",
    author        =    "S a d S c r u b",
    description    =    PLUGIN_DESCRIPTION,
    version        =    PLUGIN_VERSION,
    url        =    "http://SourceMod.net"
};

enum _:PastHS
{
    Steam_ID,
    HS_num
}

new HS_count[MAXPLAYERS+1] = 0;
new HS_past[MAXPLAYERS+1][PastHS];
new past_count = 0;

public OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_disconnect", Event_PlayerDisconnect);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    new headshot = GetEventBool(event, "headshot");

    if ( (attacker != 0) && headshot)
    {
        HS_count[attacker]++;

        if (HS_count[attacker] >= HS_MAX)
        {
			new AccountID = GetSteamAccountID(attacker, true);
            LogMessage("Banned Steam account ID %i for too many headshots in a row.", AccountID);
			
			new String:namebuf[128], String:ipbuf[17];
			GetClientName(attacker, namebuf, sizeof(namebuf));
			GetClientIP(attacker, ipbuf, sizeof(ipbuf), true);
			LogMessage("Additional info on ACC_ID %i: Name [ %s ] , IP [ %s ].", AccountID, namebuf, ipbuf);
			
            BanClient(attacker, BANTIME, BANFLAG_AUTO, "Improbable Aiming Skills", "Suspicion of aimbot.");
        }
    }
    else
        HS_count[attacker] = 0;
}

public OnClientAuthorized(client, const String:auth[])
{
    new SteamID = GetSteamAccountID(client, true);
    for (new i = 1; i <= MAXPLAYERS; i++)
    {
        if ( (SteamID != 0) && (SteamID == HS_past[i][Steam_ID]) )
            HS_count[client] = HS_past[i][HS_num];
    }
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (HS_count[client] > 0)
    {
        HS_past[past_count][Steam_ID] = GetSteamAccountID(client, true);
        HS_past[past_count][HS_num] = HS_count[client];

        past_count++;
        if (past_count > MAXPLAYERS)
            past_count = 0;

        HS_count[client] = 0;
    }
}