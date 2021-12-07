/*
 * YeGods High Ping Remover [YGHPR] for SourceMod - www.sourcemod.net
 *
 * Licensed under the GPLv3
 *
 * Coded by dubbeh - www.yegods.net
 *
 */


#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION		"1.0.1.10"

public Plugin:myinfo =
{
    name = "YeGods High Ping Remover",
    author = "dubbeh",
    description = "Allow admins to keep the server free from bad connections & set maximum allowed ping/choke/loss :)",
    version = PLUGIN_VERSION,
    url = "http://www.yegods.net/"
};

new Handle:g_cVarEnable = INVALID_HANDLE;
new Handle:g_cVarMaxPing = INVALID_HANDLE;
new Handle:g_cVarMaxPingPoints = INVALID_HANDLE;
//new Handle:g_cVarMaxChoke = INVALID_HANDLE;
//new Handle:g_cVarMaxChokePoints = INVALID_HANDLE;
//new Handle:g_cVarMaxLoss = INVALID_HANDLE;
//new Handle:g_cVarMaxLossPoints = INVALID_HANDLE;
new Handle:g_cVarAdminsImmune = INVALID_HANDLE;
new Handle:g_cVarMaxKickCounts = INVALID_HANDLE;
new Handle:g_cVarKickCountLimitBanTime = INVALID_HANDLE;
new Handle:g_cVarConnectionBreakWarn = INVALID_HANDLE;
new Handle:g_cVarKickCountClearTime = INVALID_HANDLE;
new Handle:g_cVarImmunityExtraFlag = INVALID_HANDLE;
new g_iPingPoints[MAXPLAYERS+1];
//new g_iChokePoints[MAXPLAYERS+1];
//new g_iLossPoints[MAXPLAYERS+1];
new g_iKickCounts[MAXPLAYERS+1];
new g_iSteamIds[MAXPLAYERS+1];
new Float:g_fMaxPing = 0.0;
new g_iMaxPingPoints = 0;
//new Float:g_fMaxChoke = 0.0;
//new g_iMaxChokePoints = 0;
//new Float:g_fMaxLoss = 0.0;
//new g_iMaxLossPoints = 0;
new bool:g_bPingCheckThreadRunning = false;
new Handle:g_hArrayClientKickCounts = INVALID_HANDLE;


public OnPluginStart ()
{
    /* Create the plugin version console var */
    CreateConVar ("yg_hpr_version", PLUGIN_VERSION, "YeGods High Ping Remover version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);

    /* Create the plugin enable console var */
    g_cVarEnable = CreateConVar ("yghpr_enable", "1.0", "Enable the YeGods High Ping Remover", 0, true, 0.0, true, 1.0);

    /* Create the plugin max allowed ping var */
    g_cVarMaxPing = CreateConVar ("yghpr_maxping", "100.0", "Set the maximum ping allowed on the server", 0, true, 0.0, true, 9999.0);

    /* Create the plugin max allowed ping points var */
    g_cVarMaxPingPoints = CreateConVar ("yghpr_maxpingpoints", "60.0", "Set the maximum ping points, updated once a second", 0, true, 1.0, true, 900.0);

    /* Create the plugin max allowed choke var */
//    g_cVarMaxChoke = CreateConVar ("yghpr_maxchoke", "30.0", "Set the maximum choke allowed on the server", 0, true, 0.0, true, 9999.0);

    /* Create the plugin max allowed choke points var */
//    g_cVarMaxChokePoints = CreateConVar ("yghpr_maxchokepoints", "60.0", "Set the maximum choke points, updated once a second", 0, true, 1.0, true, 900.0);

    /* Create the plugin max allowed loss var */
//    g_cVarMaxLoss = CreateConVar ("yghpr_maxloss", "5.0", "Set the maximum loss allowed on the server", 0, true, 0.0, true, 9999.0);

    /* Create the plugin max allowed loss points var */
//    g_cVarMaxLossPoints = CreateConVar ("yghpr_maxlosspoints", "60.0", "Set the maximum loss points, updated once a second", 0, true, 1.0, true, 900.0);

    /* Creat the admins immune cVar option */
    g_cVarAdminsImmune = CreateConVar ("yghpr_adminsimmune", "0.0", "Allow admins to be immune from getting kicked for high a ping", 0, true, 0.0, true, 1.0);

    /* Create the convar to warn the user for the last 10 connection limit breaks */
    g_cVarConnectionBreakWarn = CreateConVar ("yghpr_connectionbreakwarn", "1.0", "Warn the user for the last 10 connection limit breaks every second until kicked/& banned", 0, true, 0.0, true, 1.0);

    /* Create the convar for the maximum allowed kick counts before getting banned */
    g_cVarMaxKickCounts = CreateConVar ("yghpr_maxkickcounts", "1.0", "Maximum times a user can get kicked before getting banned", 0, true, 0.0, true, 25.0);

    /* Create the convar for how long a user gets banned for breaking the max ping */
    g_cVarKickCountLimitBanTime = CreateConVar ("yghpr_kickcountlimitbantime", "120.0", "Set the ban time a user gets for breaking the kick count limit", 0, true, 0.0, true, 1440.0);

    /* Create the convar for the timer to clear the kick counts array */
    g_cVarKickCountClearTime = CreateConVar ("yghpr_kickcountcleartime", "120.0", "How often to clear the kick counts array, 1 = minute", 0, true, 0.0, true, 99999.0);

    /* Create the convar for the extra immunity admin flag */
    g_cVarImmunityExtraFlag = CreateConVar ("yghpr_extraimmunityflag", "1.0", "Extra immunity flag to stop clients getting checked for a high ping", 0, true, 0.0, true, Float:AdminFlags_TOTAL);

    if ((g_cVarEnable == INVALID_HANDLE) ||
        (g_cVarMaxPing == INVALID_HANDLE) ||
        (g_cVarMaxPingPoints == INVALID_HANDLE) ||
//        (g_cVarMaxChoke == INVALID_HANDLE) ||
//        (g_cVarMaxChokePoints == INVALID_HANDLE) ||
//        (g_cVarMaxLoss == INVALID_HANDLE) ||
//        (g_cVarMaxLossPoints == INVALID_HANDLE) ||
        (g_cVarAdminsImmune == INVALID_HANDLE) ||
        (g_cVarConnectionBreakWarn == INVALID_HANDLE) ||
        (g_cVarMaxKickCounts == INVALID_HANDLE) ||
		(g_cVarKickCountLimitBanTime == INVALID_HANDLE) ||
		(g_cVarKickCountClearTime == INVALID_HANDLE) ||
        (g_cVarImmunityExtraFlag == INVALID_HANDLE))
    {
        SetFailState ("[YGHPR] Plugin Disabled. Unable to create a console var");
        return;
    }

    if ((g_hArrayClientKickCounts = CreateArray (10, 0)) == INVALID_HANDLE)
    {
        SetFailState ("[YGHPR] Plugin Disabled. Unable to create the kick counts array");
    }

    LoadTranslations ("yghpr.phrases");

    /* Reset the client ping points array */
    for (new i = 0; i <= MAXPLAYERS; i++)
    {
        g_iPingPoints[i] = 0;
//        g_iChokePoints[i] = 0;
//        g_iLossPoints[i] = 0;
        g_iSteamIds[i] = 0;
        g_iKickCounts[i] = -1;
    }

    g_bPingCheckThreadRunning = false;

    /* Create the delayed plugin start hook thread */
    CreateTimer (3.0, OnPluginStart_Delayed);
}


public Action:OnPluginStart_Delayed (Handle:timer)
{
    /* Run delayed startup timer. Thanks to FlyingMongoose/sslice for the idea :) */
    HookConVarChange (g_cVarEnable, OnConvarChanged);

    /* Create the main ping check thread */
    CreateTimer (1.0, PingCheckThread, _, TIMER_REPEAT);
    g_bPingCheckThreadRunning = true;
}

public OnPluginEnd ()
{
    ClearArray (g_hArrayClientKickCounts);
    CloseHandle (g_hArrayClientKickCounts);
}

public OnConvarChanged (Handle:convar, const String:oldValue[], const String:newValue[])
{
    static iOldcVarValue = 0, iNewcVarValue = 0;

    if (convar == g_cVarEnable)
    {
        /* Check that the convar has changed from the old value */
        iOldcVarValue = StringToInt (oldValue);
        iNewcVarValue = StringToInt (newValue);

        if (iOldcVarValue != iNewcVarValue)
        {
            if (iNewcVarValue > 0)
            {
                if (!g_bPingCheckThreadRunning)
                {
                    CreateTimer (1.0, PingCheckThread, _, TIMER_REPEAT);
                    g_bPingCheckThreadRunning = true;
                }
            }
            else
            {
                g_bPingCheckThreadRunning = false;
            }
        }
    }
}

public OnMapStart ()
{
    /* Reset the client ping points array */
    for (new i = 0; i <= MAXPLAYERS; i++)
    {
        g_iPingPoints[i] = 0;
//        g_iChokePoints[i] = 0;
//        g_iLossPoints[i] = 0;
        g_iKickCounts[i] = -1;
        g_iSteamIds[i] = 0;
    }
}

public OnConfigsExecuted ()
{
    AutoExecConfig (false, "plugin.yghpr", "sourcemod");
    AutoExecConfig (false, "plugin.yghpr", "");
}

public bool:OnClientConnect (client, String:rejectmsg[], maxlen)
{
    g_iPingPoints[client] = 0;
//    g_iChokePoints[client] = 0;
//    g_iLossPoints[client] = 0;
    g_iKickCounts[client] = -1;
    g_iSteamIds[client] = 0;
    return true;
}

public OnClientAuthorized (client)
{
    if ((client != 0) && !IsFakeClient (client) && (GetConVarInt (g_cVarMaxKickCounts) > 0))
    {
        g_iSteamIds[client] = GetSteamID (client);
        g_iKickCounts[client] = GetClientKickCounts (client);
    }
}

GetSteamID (client)
{
    decl String:szSteamId[32];
    GetClientAuthString (client, szSteamId, sizeof (szSteamId));
    ReplaceString (szSteamId, sizeof (szSteamId), "STEAM_0", "");
    ReplaceString (szSteamId, sizeof (szSteamId), ":", "");
    return StringToInt (szSteamId);
}

public OnClientDisconnect (client)
{
    /* Set the clients location in the ping points array to 0, because they have disconnected from the server */
    g_iPingPoints[client] = 0;
//    g_iChokePoints[client] = 0;
//    g_iLossPoints[client] = 0;
    g_iKickCounts[client] = -1;
    g_iSteamIds[client] = 0;
}

public Action:PingCheckThread (Handle:timer)
{
    static iMaxClients = 0, i = 0, iSeconds = 0;

    if (GetConVarInt (g_cVarEnable))
    {
        iMaxClients = GetMaxClients ();
        g_bPingCheckThreadRunning = true;

        for (i = 1; i <= iMaxClients; i++)
        {
            if (IsClientConnected (i) && IsClientInGame (i) && !IsFakeClient (i) && !IsProtectedAdmin (i))
            {
                if ((g_fMaxPing = GetConVarFloat (g_cVarMaxPing)) > 0.0)
                {
                    g_iMaxPingPoints = GetConVarInt (g_cVarMaxPingPoints);
                    RunLatencyChecks (i);
                }
/*
                if ((g_fMaxChoke = GetConVarFloat (g_cVarMaxChoke)) > 0.0)
                {
                    g_iMaxChokePoints = GetConVarInt (g_cVarMaxChokePoints);
                    RunChokeChecks (i);
                }

                if ((g_fMaxLoss = GetConVarFloat (g_cVarMaxLoss)) > 0.0)
                {
                    g_iMaxLossPoints = GetConVarInt (g_cVarMaxLossPoints);
                    RunLossChecks (i);
                }
*/
            }
        }

        if ((GetConVarInt (g_cVarMaxKickCounts) > 0) && (iSeconds++ >= (GetConVarInt (g_cVarKickCountClearTime) * 60)))
        {
            ClearArray (g_hArrayClientKickCounts);
            iSeconds = 0;
		}

        return Plugin_Continue;
    }

    ClearArray (g_hArrayClientKickCounts);
    g_bPingCheckThreadRunning = false;
    iSeconds = 0;
    return Plugin_Stop;
}

RunLatencyChecks (client)
{
    static Float:fClientLatency = 0.0;

    if (IsClientConnected (client))
    {
        fClientLatency = GetClientLatency (client, NetFlow_Outgoing) * 500.0;

        if (fClientLatency > g_fMaxPing)
            g_iPingPoints[client]++;
        else if (g_iPingPoints[client] > 0)
            g_iPingPoints[client]--;

        if (GetConVarBool (g_cVarConnectionBreakWarn) && ((g_iMaxPingPoints - g_iPingPoints[client]) <= 10))
            PrintToChat (client, "\x01\x03 %t", "High Ping Violation", g_iMaxPingPoints - g_iPingPoints[client]);

        if (g_iMaxPingPoints <= g_iPingPoints[client])
            KickClientWithReason (client);
    }
}
/*
RunChokeChecks (client)
{
    static Float:fClientChoke = 0.0;

    if (IsClientConnected (client))
    {
        fClientChoke = GetClientAvgChoke (client, NetFlow_Outgoing) * 100.0;
        if (fClientChoke > g_fMaxChoke)
            g_iChokePoints[client]++;
        else if (g_iChokePoints[client] > 0)
            g_iChokePoints[client]--;

        if (GetConVarBool (g_cVarConnectionBreakWarn) && ((g_iMaxChokePoints - g_iChokePoints[client]) <= 10))
            PrintToChat (client, "\x01\x03 %t", "High Choke Violation", g_iMaxChokePoints - g_iChokePoints[client]);

        if (g_iMaxChokePoints <= g_iChokePoints[client])
            KickClientWithReason (client);
    }
}

RunLossChecks (client)
{
    static Float:fClientLoss = 0.0;

    if (IsClientConnected (client))
    {
        fClientLoss = GetClientAvgLoss (client, NetFlow_Outgoing) * 100.0;
        if (fClientLoss > g_fMaxLoss)
            g_iLossPoints[client]++;
        else if (g_iLossPoints[client] > 0)
            g_iLossPoints[client]--;

        if (GetConVarBool (g_cVarConnectionBreakWarn) && ((g_iMaxLossPoints - g_iLossPoints[client]) <= 10))
            PrintToChat (client, "\x01\x03 %t", "High Loss Violation", g_iMaxLossPoints - g_iLossPoints[client]);

        if (g_iMaxLossPoints <= g_iLossPoints[client])
            KickClientWithReason (client);
    }
}
*/

GetClientKickCounts (client)
{
    static iArraySize = 0, i = 0;

    iArraySize = GetArraySize (g_hArrayClientKickCounts);

    /* Does the client currently exist in the Kick Counts Array */
    for (i = 0; i < iArraySize; i += 2)
    {
        if (GetArrayCell (g_hArrayClientKickCounts, i) == g_iSteamIds[client])
        {
            /* Client exists so return the kick counts */
            return GetArrayCell (g_hArrayClientKickCounts, i + 1);
        }
    }

    return -1;
}

UpdateClientKickCounts (client)
{
    static iArraySize = 0, i = 0;

    if (g_iKickCounts[client] == -1)
        g_iKickCounts[client] = 1;
    else
        g_iKickCounts[client]++;

    if (g_iSteamIds[client] == 0)
        g_iSteamIds[client] = GetSteamID (client);

    iArraySize = GetArraySize (g_hArrayClientKickCounts);

    /* Does the client exist in the Kick Counts Array */
    for (i = 0; i < iArraySize; i += 2)
    {
        if (GetArrayCell (g_hArrayClientKickCounts, i) == g_iSteamIds[client])
        {
            /* Client exists so set the kick counts */
            SetArrayCell (g_hArrayClientKickCounts, i + 1, g_iKickCounts[client]);

            if (g_iKickCounts[client] >= GetConVarInt (g_cVarMaxKickCounts))
            {
                PrintToConsole (client, "%t" ,"Hit Connection Violations", g_iKickCounts[client], GetConVarInt (g_cVarKickCountLimitBanTime));
                ServerCommand ("banid %d %d kick", GetConVarInt (g_cVarKickCountLimitBanTime), GetClientUserId (client));
                RemoveFromArray (g_hArrayClientKickCounts, i + 1);
                RemoveFromArray (g_hArrayClientKickCounts, i);
            }

            return;
        }
    }

    /* Client doesn't exist so we need to create a new entry */
    PushArrayCell (g_hArrayClientKickCounts, g_iSteamIds[client]);
    PushArrayCell (g_hArrayClientKickCounts, 1);
    return;
}

KickClientWithReason (client)
{
    decl String:szBuffer[128] = "";

    if (GetConVarInt (g_cVarMaxKickCounts) > 0)
        UpdateClientKickCounts (client);

    if (IsClientConnected (client))
    {
        //if (g_iMaxPingPoints <= g_iPingPoints[client])
        //{
            Format (szBuffer, sizeof (szBuffer), "%T", "Ping Too High", LANG_SERVER, g_fMaxPing);
            KickClient (client, szBuffer);
        //}
/*
        else if (g_iMaxChokePoints <= g_iChokePoints[client])
        {
            Format (szBuffer, sizeof (szBuffer), "%T", "Choke Too High", LANG_SERVER, g_fMaxChoke);
            KickClient (client, szBuffer);
        }
        else if (g_iMaxLossPoints <= g_iLossPoints[client])
        {
            Format (szBuffer, sizeof (szBuffer), "%T", "Loss Too High", LANG_SERVER, g_fMaxLoss);
            KickClient (client, szBuffer);
        }
*/
    }
}

bool:IsProtectedAdmin (client)
{
    new AdminId:aidUserAdmin = INVALID_ADMIN_ID;

    if (GetConVarInt (g_cVarAdminsImmune) && ((aidUserAdmin = GetUserAdmin (client)) != INVALID_ADMIN_ID))
    {
        if (GetAdminFlag (aidUserAdmin, Admin_Generic, Access_Effective) || GetAdminFlag (aidUserAdmin, any:GetConVarInt (g_cVarImmunityExtraFlag), Access_Effective))
            return true;
    }

    return false;
}
