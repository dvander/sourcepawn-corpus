/*
 * AFK Manager for SourceMod - www.sourcemod.net
 *
 * Licensed under the GPLv3
 *
 * Coded by dubbeh - www.yegods.net
 *
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION	"1.0.2.5"
#define TEAM_UNASSIGNED	0
#define TEAM_SPEC		1
#define X				0
#define Y				1
#define Z				2

enum
{
    CHECK_TYPE_ROUNDS = 0,
    CHECK_TYPE_DEATHS,
    CHECK_TYPE_TIMER
};

enum
{
    MESSAGE_TYPE_DISABLED = 0,
    MESSAGE_TYPE_HINT,
    MESSAGE_TYPE_CHAT
};

public Plugin:myinfo =
{
    name = "AFK Manager",
    author = "dubbeh",
    description = "AFK Manager for SourceMod",
    version = PLUGIN_VERSION,
    url = "http://dubbeh.net/"
};

new Handle:g_cVarEnable = INVALID_HANDLE;
new Handle:g_cVarCheckType = INVALID_HANDLE;
new Handle:g_cVarInGameRoundsLimit = INVALID_HANDLE;
new Handle:g_cVarSpecRoundsLimit = INVALID_HANDLE;
new Handle:g_cVarUnassignedRoundsLimit = INVALID_HANDLE;
new Handle:g_cVarDeathsLimit = INVALID_HANDLE;
new Handle:g_cVarAdminsImmuneGlobal = INVALID_HANDLE;
new Handle:g_cVarWarnUser = INVALID_HANDLE;
new Handle:g_cVarMinPlayersToKickSpec = INVALID_HANDLE;
new Handle:g_cVarAdminsImmuneSpec = INVALID_HANDLE;
new Handle:g_cVarKickCountMapsRecorded = INVALID_HANDLE;
new Handle:g_cVarKickCountTimeRecorded = INVALID_HANDLE;
new Handle:g_cVarKickCountLimit = INVALID_HANDLE;
new Handle:g_cVarKickCountLimitBanTime = INVALID_HANDLE;
new Handle:g_cVarKickUnassignedTime = INVALID_HANDLE;
new Handle:g_cVarKickSpecTime = INVALID_HANDLE;
new Handle:g_cVarKickIngameTime = INVALID_HANDLE;
new Handle:g_cVarSwapToSpec = INVALID_HANDLE;
new Handle:g_cVarMessageType = INVALID_HANDLE;
new Handle:g_cVarSpecRemovalPanel = INVALID_HANDLE;

new g_iAFKCounts[MAXPLAYERS+1] = {0, 0, 0, ...};
new Float:g_vStartLoc[MAXPLAYERS+1][3];
new Float:g_vEndLoc[MAXPLAYERS+1][3];
static const Float:g_vZero[3] = {0.0, 0.0, 0.0};
new g_iKickCounts[MAXPLAYERS+1] = {0, 0, 0, ...};
new g_iSteamIds[MAXPLAYERS+1] = {0, 0, 0, ...};
new Handle:g_hArrayKickCounts = INVALID_HANDLE;
new bool:g_bTimerRunning = false;
new Handle:g_hTimer = INVALID_HANDLE;
static char g_szConfigFile[] = "sourcemod/plugin.afkm.cfg";

public OnPluginStart ()
{
    CreateConVar ("afk_manager_version", PLUGIN_VERSION, "AFK Manager version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    g_cVarEnable = CreateConVar ("afkm_enable", "1.0", "Enable the AFK Manager plugin", 0, true, 0.0, true, 1.0);
    g_cVarCheckType = CreateConVar ("afkm_check_type", "2.0", "Set the AFK manager check type 0 = (Rounds based) | 1 = (Consecutive deaths) | 2 = (Timelimit)", 0, true, 0.0, true, 2.0);
    g_cVarInGameRoundsLimit = CreateConVar ("afkm_ingame_rounds_limit", "3.0", "Number of rounds a player can be AFK in-game before getting kicked", 0, true, 0.0, true, 20.0);
    g_cVarSpecRoundsLimit = CreateConVar ("afkm_spec_rounds_limit", "3.0", "Number of rounds a player can be AFK before getting kicked/moved to spec", 0, true, 0.0, true, 20.0);
    g_cVarUnassignedRoundsLimit = CreateConVar ("afkm_unassigned_rounds_limit", "3.0", "Number of rounds a player can be unassigned before getting kicked", 0, true, 0.0, true, 20.0);
    g_cVarDeathsLimit = CreateConVar ("afkm_deaths_limit", "20.0", "Number of consecutive deaths a player can have before getting kicked", 0, true, 1.0, true, 100.0);
    g_cVarAdminsImmuneGlobal = CreateConVar ("afkm_admins_immune_global", "0.0", "Give admins global immunity from AFK counts", 0, true, 0.0, true, 1.0);
    g_cVarWarnUser = CreateConVar ("afkm_warn_user", "1.0", "Warn the user when they get an AFK count", 0, true, 0.0, true, 1.0);
    g_cVarMinPlayersToKickSpec = CreateConVar ("afkm_min_players_kick_spec", "8.0", "Minimum player count before players moved to spec start getting kicked", 0, true, 0.0, true, 32.0);
    g_cVarAdminsImmuneSpec = CreateConVar ("afkm_admins_immune_spec", "1.0", "Moves admins to spectator but doesn't kick them or add AFK counts when spec", 0, true, 0.0, true, 1.0);
    g_cVarKickCountLimit = CreateConVar ("afkm_kick_count_limit", "0.0", "Number of times a player can get kicked before getting banned", 0, true, 0.0, true, 20.0);
    g_cVarKickCountLimitBanTime = CreateConVar ("afkm_kick_count_ban_time", "60.0", "How long will a player get banned for when breaking the kick count limit", 0, true, 0.0, true, 9999.0);
    g_cVarKickCountMapsRecorded = CreateConVar ("afkm_kick_count_maps_record", "3.0", "How many maps to record kick counts for AFK violations", 0, true, 1.0, true, 50.0);
    g_cVarKickCountTimeRecorded = CreateConVar ("afkm_kick_count_time_record", "60.0", "How many minutes to record kick counts for AFK violations", 0, true, 1.0, true, 2880.0);
    g_cVarKickUnassignedTime = CreateConVar ("afkm_max_unassigned_time", "5.0", "How many minutes before kicking an unassigned client", 0, true, 0.0, true, 60.0);
    g_cVarKickSpecTime = CreateConVar ("afkm_max_spec_time", "5.0", "How many minutes before a spectator is kicked", 0, true, 0.0, true, 60.0);
    g_cVarKickIngameTime = CreateConVar ("afkm_max_ingame_time", "3.0", "How many minutes before a client is kicked for no movement in-game", 0, true, 0.0, true, 60.0);
    g_cVarSwapToSpec = CreateConVar ("afkm_swap_to_spec", "1.0", "Should players in-game be swapped to spec before getting kicked", 0, true, 0.0, true, 1.0);
    g_cVarMessageType = CreateConVar ("afkm_warn_msg_type", "1.0", "How should players get warned for AFK counts | 0 = Disabled | 1 = Hint | 2 = Chat", 0, true, 0.0, true, 2.0);
    g_cVarSpecRemovalPanel = CreateConVar ("afkm_spec_removal_panel", "1.0", "Allow the spectator AFK point removal panel", 0, true, 0.0, true, 1.0);

    if ((g_cVarEnable == INVALID_HANDLE) ||
        (g_cVarCheckType == INVALID_HANDLE) ||
        (g_cVarInGameRoundsLimit == INVALID_HANDLE) ||
        (g_cVarSpecRoundsLimit == INVALID_HANDLE) ||
        (g_cVarDeathsLimit == INVALID_HANDLE) ||
        (g_cVarAdminsImmuneGlobal == INVALID_HANDLE) ||
        (g_cVarWarnUser == INVALID_HANDLE) ||
        (g_cVarMinPlayersToKickSpec == INVALID_HANDLE) ||
        (g_cVarAdminsImmuneSpec == INVALID_HANDLE) ||
        (g_cVarKickCountLimit == INVALID_HANDLE) ||
        (g_cVarKickCountLimitBanTime == INVALID_HANDLE) ||
        (g_cVarKickCountMapsRecorded == INVALID_HANDLE) ||
        (g_cVarKickUnassignedTime == INVALID_HANDLE) ||
        (g_cVarKickSpecTime == INVALID_HANDLE) ||
        (g_cVarKickIngameTime == INVALID_HANDLE) ||
        (g_cVarKickCountTimeRecorded == INVALID_HANDLE) ||
        (g_cVarSwapToSpec == INVALID_HANDLE) ||
        (g_cVarMessageType == INVALID_HANDLE) ||
        (g_cVarSpecRemovalPanel == INVALID_HANDLE))
    {
        SetFailState ("AFK Manager Error - Unable to create a cVar");
    }

    if ((g_hArrayKickCounts = CreateArray (20, 0)) == INVALID_HANDLE)
    {
        SetFailState ("AFK Manager Error - Unable to create the kick counts array");
    }

    LoadTranslations ("afkm.phrases");

    HookConVarChange (g_cVarEnable, OnConvarChanged);

    HookEvent ("player_spawn", Event_PlayerSpawn);
    HookEvent ("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent ("round_start", Event_RoundStart);
    HookEvent ("round_end", Event_RoundEnd, EventHookMode_Pre);

    g_hTimer = CreateTimer (1.0, Timer_Main, _, TIMER_REPEAT);
    g_bTimerRunning = true;
    
    // Config hack
    ServerCommand("exec %s", g_szConfigFile);
}

public OnPluginEnd ()
{
    if (g_hTimer != INVALID_HANDLE)
    {
        KillTimer (g_hTimer);
    }

    if (g_hArrayKickCounts != INVALID_HANDLE)
	{
        ClearArray (g_hArrayKickCounts);
        CloseHandle (g_hArrayKickCounts);
    }
}

public OnConfigsExecuted ()
{
    AutoExecConfig (false, "plugin.afkm", "sourcemod");
    AutoExecConfig (false, "plugin.afkm", "");
}

public OnMapStart ()
{
	// Config hack
    ServerCommand("exec %s", g_szConfigFile);
    
    static i = 0, iMaxClients = 0;

    iMaxClients = GetMaxClients ();
    for (i = 1; i <= iMaxClients; i++)
    {
        g_iAFKCounts[i] = 0;
        g_vStartLoc[i] = g_vZero;
        g_vEndLoc[i] = g_vZero;
    }
}

public OnMapEnd ()
{
    static iMapCounts = 0;

    if ((GetConVarInt (g_cVarKickCountLimit) > 0) && (GetConVarInt (g_cVarKickCountMapsRecorded) > 0))
    {
        if (iMapCounts++ >= GetConVarInt (g_cVarKickCountMapsRecorded))
        {
            ClearArray (g_hArrayKickCounts);
            iMapCounts = 0;
        }
    }
}

public bool:OnClientConnect (client, String:rejectmsg[], maxlen)
{
    g_iAFKCounts[client] = 0;
    g_iKickCounts[client] = -1;
    g_iSteamIds[client] = 0;
    g_vStartLoc[client] = g_vZero;
    g_vEndLoc[client] = g_vZero;
    return true;
}

public OnClientDisconnect (client)
{
    g_iAFKCounts[client] = 0;
    g_iKickCounts[client] = -1;
    g_iSteamIds[client] = 0;
    g_vStartLoc[client] = g_vZero;
    g_vEndLoc[client] = g_vZero;
}

public OnClientAuthorized (client)
{
    if (client == 0)
        return;

    if (!IsFakeClient (client) && GetConVarInt (g_cVarKickCountLimit) > 0)
    {
        g_iSteamIds[client] = GetSteamID (client);
        g_iKickCounts[client] = GetClientKickCounts (client);
    }
}

GetSteamID (client)
{
    decl String:szSteamID[32];

    GetClientAuthString (client, szSteamID, sizeof (szSteamID));
    ReplaceString (szSteamID, sizeof (szSteamID), "STEAM_:0", "");
    ReplaceString (szSteamID, sizeof (szSteamID), ":", "");
    return StringToInt (szSteamID);
}

public Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarInt (g_cVarEnable) && (GetConVarInt (g_cVarCheckType) == CHECK_TYPE_ROUNDS))
    {
        static i = 0, iMaxClients = 0;

        iMaxClients = GetMaxClients ();
        for (i = 1; i <= iMaxClients; i++)
        {
            if (IsClientConnected (i) && IsClientInGame (i) && IsPlayerAlive (i))
            {
                GetClientAbsOrigin (i, g_vStartLoc[i]);
                g_vEndLoc[i] = g_vZero;
            }
        }
    }
}

public Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarInt (g_cVarEnable) && (GetEventInt (event, "reason") != 16) &&
        (GetConVarInt (g_cVarCheckType) == CHECK_TYPE_ROUNDS))
    {
        static i = 0, iMaxClients = 0;

        iMaxClients = GetMaxClients ();
        for (i = 1; i <= iMaxClients; i++)
        {
            if (IsClientConnected (i) && IsClientInGame (i) && !IsFakeClient (i) && !IsProtectedAdmin (i))
            {
                CheckRoundAFKCounts (i);
            }
        }
    }
}

public Event_PlayerSpawn (Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarInt (g_cVarEnable))
    {
        static iClient = 0;
        iClient = GetClientOfUserId (GetEventInt (event, "userid"));
        GetClientAbsOrigin (iClient, g_vStartLoc[iClient]);
        g_vEndLoc[iClient] = g_vZero;
    }
}

public Event_PlayerDeath (Handle:event, const String:name[], bool:dontBroadcast)
{
    if (GetConVarInt (g_cVarEnable))
    {
        static iClient = 0, iKiller = 0, iBalanceType = 0;

        iClient = GetClientOfUserId (GetEventInt (event, "userid"));
        iBalanceType = GetConVarInt (g_cVarCheckType);

        if (iBalanceType == CHECK_TYPE_ROUNDS)
        {
            GetClientAbsOrigin (iClient, g_vEndLoc[iClient]);
        }
        else if (iBalanceType == CHECK_TYPE_DEATHS)
        {
            iKiller = GetClientOfUserId (GetEventInt (event, "attacker"));
            CheckDeathAFKCounts (iClient, iKiller);
        }
    }
}

CheckDeathAFKCounts (client, killer)
{
    static iDeathsLimit = 0, iMessageType = 0;

    if ((killer != 0) && (client != killer))
    {
        iDeathsLimit = GetConVarInt (g_cVarDeathsLimit);

        if (!IsProtectedAdmin (client))
        {
            GetClientAbsOrigin (client, g_vEndLoc[client]);

            if (GetVectorDistance (g_vEndLoc[client], g_vStartLoc[client], true) <= 300.0)
            {
                g_iAFKCounts[client]++;
                if (GetConVarInt (g_cVarWarnUser))
                {
                    iMessageType = GetConVarInt (g_cVarMessageType);
                    if (iMessageType == MESSAGE_TYPE_HINT)
                        PrintHintText (client, "%t", "Death Based", iDeathsLimit - g_iAFKCounts[client]);
                    else if (iMessageType == MESSAGE_TYPE_CHAT)
                        PrintToChat (client, "\x01\x04 %t", "Death Based", iDeathsLimit - g_iAFKCounts[client]);
                }
            }
            else if (g_iAFKCounts[client] > 0)
            {
                g_iAFKCounts[client]--;
            }
        }

        g_iAFKCounts[killer] = 0;

        if (g_iAFKCounts[client] >= iDeathsLimit)
            KickClientWithReason (client);
    }
}

/* this is always called at round end */
CheckRoundAFKCounts (client)
{
    static iTeam = 0, iPrevTeam[MAXPLAYERS+1] = {0, 0, 0, ...};
    static iUnassignedRoundsLimit = 0, iSpecRoundsLimit = 0, iInGameRoundsLimit = 0, iMessageType = 0;

    iTeam = GetClientTeam (client);
    if (iTeam != iPrevTeam[client])
        g_iAFKCounts[client] = 0;
    iPrevTeam[client] = iTeam;

    switch (iTeam)
    {
    case TEAM_UNASSIGNED:
        if ((iUnassignedRoundsLimit = GetConVarInt (g_cVarUnassignedRoundsLimit)) > 0)
        {
            if (g_iAFKCounts[client]++ >= iUnassignedRoundsLimit)
            {
                KickClientWithReason (client);
            }
            else if (GetConVarInt (g_cVarWarnUser))
            {
                iMessageType = GetConVarInt (g_cVarMessageType);
                if (iMessageType == MESSAGE_TYPE_HINT)
                    PrintHintText (client, "%t", "Rounds Based Unassigned", (iUnassignedRoundsLimit - g_iAFKCounts[client]));
                else if (iMessageType == MESSAGE_TYPE_CHAT)
                    PrintToChat (client, "\x01\x04 %t", "Rounds Based Unassigned", (iUnassignedRoundsLimit - g_iAFKCounts[client]));
            }
        }
    case TEAM_SPEC:
        if ((iSpecRoundsLimit = GetConVarInt (g_cVarSpecRoundsLimit)) > 0)
        {
            if ((GetConVarInt (g_cVarMinPlayersToKickSpec) <= GetClientCount (true)) && !IsProtectedAdminSpec (client))
            {
                if (GetConVarInt (g_cVarSpecRemovalPanel))
                    DrawRoundsAFKCheckPanel (client);

                if (g_iAFKCounts[client]++ >= iSpecRoundsLimit)
                {
                    KickClientWithReason (client);
                }
                else if (GetConVarInt (g_cVarWarnUser))
                {
                    iMessageType = GetConVarInt (g_cVarMessageType);
                    if (iMessageType == MESSAGE_TYPE_HINT)
                        PrintHintText (client, "%t", "Rounds Based Spectator", (iSpecRoundsLimit - g_iAFKCounts[client]));
                    else if (iMessageType == MESSAGE_TYPE_CHAT)
                        PrintToChat (client, "\x01\x04 %t", "Rounds Based Spectator", (iSpecRoundsLimit - g_iAFKCounts[client]));
                }
            }
        }
    default:
        if ((iInGameRoundsLimit = GetConVarInt (g_cVarInGameRoundsLimit)) > 0)
        {
            if (IsPlayerAlive (client) && ((g_vEndLoc[client][X] == 0.0) && (g_vEndLoc[client][Y] == 0.0) && (g_vEndLoc[client][Z] == 0.0)))
                GetClientAbsOrigin (client, g_vEndLoc[client]);

            g_vStartLoc[client][Z] = 0.0;
            g_vEndLoc[client][Z] = 0.0;

            if (GetVectorDistance (g_vEndLoc[client], g_vStartLoc[client], true) <= 100.0)
            {
                g_iAFKCounts[client]++;
                if (GetConVarInt (g_cVarWarnUser))
                {
                    if (GetConVarInt (g_cVarSwapToSpec))
                    {
                        iMessageType = GetConVarInt (g_cVarMessageType);
                        if (iMessageType == MESSAGE_TYPE_HINT)
                            PrintHintText (client, "%t", "Rounds Based Swap Spec", (iInGameRoundsLimit - g_iAFKCounts[client]));
                        else if (iMessageType == MESSAGE_TYPE_HINT)
                            PrintToChat (client, "\x01\x04 %t", "Rounds Based Swap Spec", (iInGameRoundsLimit - g_iAFKCounts[client]));
                    }
                    else
                    {
                        iMessageType = GetConVarInt (g_cVarMessageType);
                        if (iMessageType == MESSAGE_TYPE_HINT)
                            PrintHintText (client, "%t", "Rounds Based Ingame", (iInGameRoundsLimit - g_iAFKCounts[client]));
                        else if (iMessageType == MESSAGE_TYPE_CHAT)
                            PrintToChat (client, "\x01\x04 %t", "Rounds Based Ingame", (iInGameRoundsLimit - g_iAFKCounts[client]));
                    }
                }
            }
            else if (g_iAFKCounts[client] > 0)
            {
                g_iAFKCounts[client]--;
            }

            if (g_iAFKCounts[client] >= iInGameRoundsLimit)
            {
                if (GetConVarInt (g_cVarSwapToSpec))
                {
                    iMessageType = GetConVarInt (g_cVarMessageType);
                    if (iMessageType == MESSAGE_TYPE_HINT)
                        PrintHintText (client, "%t", "Moving To Spec");
                    else if (iMessageType == MESSAGE_TYPE_CHAT)
                        PrintToChat (client, "\x01\x04 %t", "Moving To Spec");
                    ChangeClientTeam (client, TEAM_SPEC);
                }
                else
                {
                    KickClientWithReason (client);
                }
            }
        }
    }
}

bool:IsProtectedAdmin (client)
{
    new AdminId:aidUserAdmin = INVALID_ADMIN_ID;

    if (GetConVarBool (g_cVarAdminsImmuneGlobal))
    {
        aidUserAdmin = GetUserAdmin (client);
        if (aidUserAdmin != INVALID_ADMIN_ID)
            return GetAdminFlag (aidUserAdmin, Admin_Reservation, Access_Real);
    }

    return false;
}

bool:IsProtectedAdminSpec (client)
{
    new AdminId:aidUserAdmin = INVALID_ADMIN_ID;

    if (GetConVarBool (g_cVarAdminsImmuneSpec))
    {
        aidUserAdmin = GetUserAdmin (client);
        if (aidUserAdmin != INVALID_ADMIN_ID)
            return GetAdminFlag (aidUserAdmin, Admin_Generic, Access_Effective);
    }

    return false;
}

DrawRoundsAFKCheckPanel (client)
{
    new Handle:hCheckAFKPanel = INVALID_HANDLE;
    decl String:szBuffer[100] = "";

    hCheckAFKPanel = CreatePanel (GetMenuStyleHandle (MenuStyle_Default));
    SetPanelTitle (hCheckAFKPanel, "AFK Manager:");
    Format (szBuffer, sizeof (szBuffer), "%T", "Remove Spectator Count", LANG_SERVER);
    DrawPanelItem (hCheckAFKPanel, szBuffer);
    SendPanelToClient (hCheckAFKPanel, client, Handler_DrawRoundsAFKCheckPanel, 60);
    CloseHandle (hCheckAFKPanel);
}

public Handler_DrawRoundsAFKCheckPanel (Handle:menu, MenuAction:action, client, param)
{
    static iMessageType = 0;

    if (action == MenuAction_Select)
    {
        if (g_iAFKCounts[client] > 0)
        {
            g_iAFKCounts[client]--;
            if (GetConVarInt (g_cVarWarnUser))
            {
                iMessageType = GetConVarInt (g_cVarMessageType);
                if (iMessageType == MESSAGE_TYPE_HINT)
                    PrintHintText (client, "%t", "Removed Spec Count");
                else if (iMessageType == MESSAGE_TYPE_CHAT)
                    PrintToChat (client, "\x01\x04 %t", "Removed Spec Count");
            }
        }
    }
}

GetClientKickCounts (client)
{
    static iArraySize = 0, i = 0;

    iArraySize = GetArraySize (g_hArrayKickCounts);

    /* Does the client currently exist in the Kick Counts Array */
    for (i = 0; i < iArraySize; i += 2)
    {
        if (GetArrayCell (g_hArrayKickCounts, i) == g_iSteamIds[client])
        {
            /* Client exists so return the kick counts */
            return GetArrayCell (g_hArrayKickCounts, i + 1);
        }
    }

    return -1;
}

UpdateClientKickCounts (client)
{
    if (g_iKickCounts[client] == -1)
        g_iKickCounts[client] = 1;
    else
        g_iKickCounts[client]++;

    static iArraySize = 0, i = 0, iBanTime = 0;
    iArraySize = GetArraySize (g_hArrayKickCounts);

    if (g_iSteamIds[client] == 0)
        g_iSteamIds[client] = GetSteamID (client);

    /* Does the client exist in the Kick Counts Array */
    for (i = 0; i < iArraySize; i += 2)
    {
        if (GetArrayCell (g_hArrayKickCounts, i) == g_iSteamIds[client])
        {
            /* Client exists so set the kick counts */
            SetArrayCell (g_hArrayKickCounts, i + 1, g_iKickCounts[client]);

            if (g_iKickCounts[client] >= GetConVarInt (g_cVarKickCountLimit))
            {
                iBanTime = GetConVarInt (g_cVarKickCountLimitBanTime);
                PrintToConsole (client, "%t", "Hit Kick Counts", g_iKickCounts[client], iBanTime);
                ServerCommand ("banid %d %d kick", iBanTime, GetClientUserId (client));
                RemoveFromArray (g_hArrayKickCounts, i + 1);
                RemoveFromArray (g_hArrayKickCounts, i);
            }

            return;
        }
    }

    /* Client doesn't exist so we need to create a new entry */
    PushArrayCell (g_hArrayKickCounts, g_iSteamIds[client]);
    PushArrayCell (g_hArrayKickCounts, 1);
}

KickClientWithReason (client)
{
    static iBalanceType = 0, iTime = 0;
    decl String:szBuffer[100] = "";

    if (GetConVarInt (g_cVarKickCountLimit) > 0)
        UpdateClientKickCounts (client);

    if (IsClientConnected (client))
    {
        iBalanceType = GetConVarInt (g_cVarCheckType);
        if (iBalanceType == CHECK_TYPE_ROUNDS)
        {
            Format (szBuffer, sizeof (szBuffer), "%T", "Kick Message Rounds", LANG_SERVER, g_iAFKCounts[client]);
            KickClient (client, szBuffer);
        }
        else if (iBalanceType == CHECK_TYPE_DEATHS)
        {
            Format (szBuffer, sizeof (szBuffer), "%T", "Kick Message Deaths", LANG_SERVER, g_iAFKCounts[client]);
            KickClient (client, szBuffer);
        }
        else if (iBalanceType == CHECK_TYPE_TIMER)
        {
            if ((iTime = g_iAFKCounts[client]) > 60)
                iTime /= 60;
            else
                iTime = 1;
            Format (szBuffer, sizeof (szBuffer), "%T", "Kick Message Time", LANG_SERVER, iTime);
            KickClient (client, szBuffer);
        }
    }
}

public OnConvarChanged (Handle:convar, const String:oldValue[], const String:newValue[])
{
    static iNewVal = 0;

    if (convar == g_cVarEnable)
    {
        /* Check that the convar has changed from the old value */
        iNewVal = StringToInt (newValue);
        if (StringToInt (oldValue) != iNewVal)
        {
            if (iNewVal > 0)
            {
                if (!g_bTimerRunning)
                {
                    g_hTimer = CreateTimer (1.0, Timer_Main, _, TIMER_REPEAT);
                    g_bTimerRunning = true;
                }
            }
            else
            {
                g_bTimerRunning = false;
            }
        }
    }
}

public Action:Timer_Main (Handle:timer)
{
    static iMaxClients = 0, i = 0, iTeam = 0, iSecs = 0, iKickUnassignedTime = 0, iKickSpecTime = 0, iKickIngameTime = 0, iMessageType = 0;
    static Float:vPrevLoc[MAXPLAYERS+1][3];
    static iPrevTeam[MAXPLAYERS+1] = {0, 0, 0, ...};

    if (GetConVarInt (g_cVarEnable))
    {
        if (GetConVarInt (g_cVarCheckType) == CHECK_TYPE_TIMER)
        {
            iMaxClients = GetMaxClients ();
            for (i = 1; i <= iMaxClients; i++)
            {
                if (IsClientConnected (i) && IsClientInGame (i) && !IsFakeClient (i) && !IsProtectedAdmin (i))
                {
                    iTeam = GetClientTeam (i);
                    if (iPrevTeam[i] != iTeam)
                        g_iAFKCounts[i] = 0;
                    iPrevTeam[i] = iTeam;

                    switch (iTeam)
                    {
                    case TEAM_UNASSIGNED:
                        if ((iKickUnassignedTime = GetConVarInt (g_cVarKickUnassignedTime)) > 0)
                        {
                            if (g_iAFKCounts[i]++ >= (iKickUnassignedTime * 60))
                            {
                                KickClientWithReason (i);
                            }
                            else if (GetConVarInt (g_cVarWarnUser))
                            {
                                if ((((iKickUnassignedTime * 60) - g_iAFKCounts[i]) <= 10) || ((iKickUnassignedTime * 30) == g_iAFKCounts[i]))
                                {
                                    iMessageType = GetConVarInt (g_cVarMessageType);
                                    if (iMessageType == MESSAGE_TYPE_HINT)
                                        PrintHintText (i, "%t", "Seconds Remaining AFK Kicked", (iKickIngameTime * 60) - g_iAFKCounts[i]);
                                    else if (iMessageType == MESSAGE_TYPE_CHAT)
                                        PrintToChat (i, "\x01\x04 %t", "Seconds Remaining AFK Kicked", (iKickIngameTime * 60) - g_iAFKCounts[i]);
                                }
                            }
                        }
                    case TEAM_SPEC:
                        if (!IsProtectedAdminSpec (i) &&
                            ((iKickSpecTime = GetConVarInt (g_cVarKickSpecTime)) > 0) &&
                            (GetConVarInt (g_cVarMinPlayersToKickSpec) <= GetClientCount (true)))
                        {
                            if (GetConVarInt (g_cVarSpecRemovalPanel) && (g_iAFKCounts[i] > (iKickSpecTime * 30)))
                                DrawTimerAFKCheckPanel (i);

                            if (g_iAFKCounts[i]++ >= (iKickSpecTime * 60))
                            {
                                KickClientWithReason (i);
                            }
                            else if (GetConVarInt (g_cVarWarnUser))
                            {
                                if ((((iKickSpecTime * 60) - g_iAFKCounts[i]) <= 10) || ((iKickSpecTime * 30) == g_iAFKCounts[i]))
                                {
                                    iMessageType = GetConVarInt (g_cVarMessageType);
                                    if (iMessageType == MESSAGE_TYPE_HINT)
                                        PrintHintText (i, "%t", "Seconds Remaining AFK Kicked", ((iKickSpecTime * 60) - g_iAFKCounts[i]));
                                    else if (iMessageType == MESSAGE_TYPE_CHAT)
                                        PrintToChat (i, "\x01\x04 %t", "Seconds Remaining AFK Kicked", ((iKickSpecTime * 60) - g_iAFKCounts[i]));
                                }
                            }
                        }
                    default:
                        if (((iKickIngameTime = GetConVarInt (g_cVarKickIngameTime)) > 0) && IsPlayerAlive (i))
                        {
                            static Float:fNewLoc[3] = {0.0, 0.0, 0.0};

                            GetClientAbsOrigin (i, fNewLoc);

                            if (GetVectorDistance (fNewLoc, vPrevLoc[i], true) <= 1.0)
                                g_iAFKCounts[i]++;
                            else if ((g_iAFKCounts[i] > (iKickIngameTime * 20)) && (g_iAFKCounts[i] > 10))
                                g_iAFKCounts[i] -= 5;
                            else if (g_iAFKCounts[i] > 0)
                                g_iAFKCounts[i]--;

                            if ((iKickIngameTime * 60) <= g_iAFKCounts[i])
                            {
                                if (GetConVarInt (g_cVarSwapToSpec) > 0)
                                {
                                    iMessageType = GetConVarInt (g_cVarMessageType);
                                    if (iMessageType == MESSAGE_TYPE_HINT)
                                        PrintHintText (i, "%t", "Moving To Spec");
                                    else if (iMessageType == MESSAGE_TYPE_CHAT)
                                        PrintToChat (i, "\x01\x04 %t", "Moving To Spec");
                                    ChangeClientTeam (i, TEAM_SPEC);
                                }
                                else
                                {
                                    KickClientWithReason (i);
                                }
                            }
                            else if (GetConVarInt (g_cVarWarnUser))
                            {
                                if ((((iKickIngameTime * 60) - g_iAFKCounts[i]) <= 10) || ((iKickIngameTime * 30) == g_iAFKCounts[i]))
                                {
                                    if (GetConVarInt (g_cVarSwapToSpec) > 0)
                                    {
                                        iMessageType = GetConVarInt (g_cVarMessageType);
                                        if (iMessageType == MESSAGE_TYPE_HINT)
                                            PrintHintText (i, "%t", "Timer Based Spec Swap", ((iKickIngameTime * 60) - g_iAFKCounts[i]));
                                        else if (iMessageType == MESSAGE_TYPE_CHAT)
                                            PrintToChat (i, "\x01\x04 %t", "Timer Based Spec Swap", ((iKickIngameTime * 60) - g_iAFKCounts[i]));
                                    }
                                    else
                                    {
                                        iMessageType = GetConVarInt (g_cVarMessageType);
                                        if (iMessageType == MESSAGE_TYPE_HINT)
                                            PrintHintText (i, "%t", "Seconds Remaining AFK Kicked", ((iKickIngameTime * 60) - g_iAFKCounts[i]));
                                        else if (iMessageType == MESSAGE_TYPE_CHAT)
                                            PrintToChat (i, "\x01\x04 %t", "Seconds Remaining AFK Kicked", ((iKickIngameTime * 60) - g_iAFKCounts[i]));
                                    }
                                }
                            }

                            vPrevLoc[i][X] = fNewLoc[X];
                            vPrevLoc[i][Y] = fNewLoc[Y];
                            vPrevLoc[i][Z] = fNewLoc[Z];
                        }
                    }
                }
            }
        }

        if ((GetConVarInt (g_cVarKickCountLimit) > 0) && (iSecs++ >= (GetConVarInt (g_cVarKickCountTimeRecorded) * 60)))
        {
            ClearArray (g_hArrayKickCounts);
            iSecs = 0;
        }

        g_bTimerRunning = true;
        return Plugin_Continue;
    }

    ClearArray (g_hArrayKickCounts);
    iSecs = 0;
    g_bTimerRunning = false;
    g_hTimer = INVALID_HANDLE;
    return Plugin_Stop;
}

DrawTimerAFKCheckPanel (client)
{
    new Handle:hCheckAFKPanel = INVALID_HANDLE;
    decl String:szBuffer[100] = "";

    hCheckAFKPanel = CreatePanel (GetMenuStyleHandle (MenuStyle_Default));
    SetPanelTitle (hCheckAFKPanel, "AFK Manager:");
    Format (szBuffer, sizeof (szBuffer), "%T", "Remove Spectator Count", LANG_SERVER);
    DrawPanelItem (hCheckAFKPanel, szBuffer);
    SendPanelToClient (hCheckAFKPanel, client, Handler_DrawTimerAFKCheckPanel, 1);
    CloseHandle (hCheckAFKPanel);
}

public Handler_DrawTimerAFKCheckPanel (Handle:menu, MenuAction:action, client, param)
{
    static iMessageType = 0;

    if (action == MenuAction_Select)
    {
        g_iAFKCounts[client] = 0;
        if (GetConVarInt (g_cVarWarnUser))
        {
            iMessageType = GetConVarInt (g_cVarMessageType);
            if (iMessageType == MESSAGE_TYPE_HINT)
                PrintHintText (client, "%t", "Removed Spec Count");
            else if (iMessageType == MESSAGE_TYPE_CHAT)
                PrintToChat (client, "\x01\x04 %t", "Removed Spec Count");
        }
    }
}


