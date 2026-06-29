/*
 * Deathmatch Team Balancer for SourceMod - www.sourcemod.net
 *
 * Plugin licensed under the GPLv3
 * 
 * Coded by dubbeh - www.yegods.net  
 *
 */


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#define PLUGIN_VERSION	"1.0.0.4"
#define TEAM_T					2
#define TEAM_CT					3

public Plugin:myinfo =
{
    name = "Deathmatch Team Balancer",
    author = "dubbeh",
    description = "Keep the teams balanced in CS:S Deathmatch - thanks to Oxymoron for the idea",
    version = PLUGIN_VERSION,
    url = "http://www.yegods.net/"
};

new Handle:g_cVarEnable = INVALID_HANDLE;
new Handle:g_cVarCheckTime = INVALID_HANDLE;
new Handle:g_cVarPlayerLimit = INVALID_HANDLE;
new Handle:g_cVarAdminsImmune = INVALID_HANDLE;
new bool:g_bTeamBalanceThreadRunning = false;
new Float:g_fBalanceCheckTime = 0.0;

public OnPluginStart ()
{
    /* register all the plugin console vars */
    CreateConVar ("dmtb_version", PLUGIN_VERSION, "Deathmatch Team Balancer version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    g_cVarEnable = CreateConVar ("dmtb_enable", "1", "Enable the Deathmatch Team Balancer", 0, true, 0.0, true, 1.0);
    g_cVarCheckTime = CreateConVar ("dmtb_checktime", "30.0", "How often to check if the teams are balanced", 0, true, 30.0, true, 600.0);
    g_cVarPlayerLimit = CreateConVar ("dmtb_playerlimit", "2", "How uneven the teams can get before getting balanced", 0, true, 1.0, true, 32.0);
    g_cVarAdminsImmune = CreateConVar ("dmtb_adminsimmune", "1", "Enable admins immunity from getting switched", 0, true, 0.0, true, 1.0);

    if ((g_cVarEnable == INVALID_HANDLE) ||
        (g_cVarCheckTime == INVALID_HANDLE) ||
        (g_cVarPlayerLimit == INVALID_HANDLE) ||
        (g_cVarAdminsImmune == INVALID_HANDLE))
    {
        SetFailState ("[DMTB] Error - Unable to create a console var. Exiting...");
        return;
    }

    /* set the global Balance thread running boolean to false */
    g_bTeamBalanceThreadRunning = false;

    /* Create the delayed plugin start hook thread */
    CreateTimer (4.0, OnPluginStart_Delayed);
}

public Action:OnPluginStart_Delayed (Handle:timer)
{
    /* Run delayed startup timer. Thanks to FlyingMongoose/sslice for the idea :) */
    HookConVarChange (g_cVarEnable, OnEnableChanged);

    /* Create the main team balancing thread */
    CreateTimer (5.0, TeamBalanceThread, _, TIMER_REPEAT);
}

public OnConfigsExecuted ()
{
    AutoExecConfig ();
}

public OnEnableChanged (Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (convar == g_cVarEnable)
    {
        /* Check that the convar has changed from the old value */
        new iOldcVarValue = StringToInt (oldValue);
        new iNewcVarValue = StringToInt (newValue);

        if (iOldcVarValue != iNewcVarValue)
        {
            if (iNewcVarValue > 0)
            {
                if (!g_bTeamBalanceThreadRunning)
                {
                    CreateTimer (5.0, TeamBalanceThread, _, TIMER_REPEAT);
                    g_bTeamBalanceThreadRunning = true;
                }
            }
            else
            {
                g_bTeamBalanceThreadRunning = false;
            }
        }
    }
}

public Action:TeamBalanceThread (Handle:timer)
{
    if (GetConVarInt (g_cVarEnable))
    {
        static Float:fTime = 0.0;

        fTime = GetGameTime ();

        if (g_fBalanceCheckTime <= fTime)
        {
            static i = 0, iMaxClients = 0, iTeam = 0, iTeamT = 0, iTeamCT = 0, iDeadT = 0, iDeadCT = 0,  iPlayerLimit = 0;

            /* here we count the number of players on each team */
            iTeamT = 0;
            iTeamCT = 0;
            iDeadT = 0;
            iDeadCT = 0;
            iMaxClients = GetMaxClients ();
            
            for (i = 1; i <= iMaxClients; i++)
            {
                if (IsClientConnected (i) && IsClientInGame (i) && !IsClientObserver (i))
                {
                    iTeam = GetClientTeam (i);

                    if (iTeam == TEAM_T)
                    {
                        iTeamT++;
                        if (!IsPlayerAlive (i) && !IsProtectedAdmin (i))
                        {
                            iDeadT++;
                        }
                    }
                    else if (iTeam == TEAM_CT)
                    {
                        iTeamCT++;
                        if (!IsPlayerAlive (i) && !IsProtectedAdmin (i))
                        {
										        iDeadCT++;
                        }
                    }
                }
            }

            /* now we have the number of players on each team
             * check the team player limit & balance as requested */
            iPlayerLimit = GetConVarInt (g_cVarPlayerLimit);

            /* is there currently more Ts then CTs */
            /* also is the player limit less than the Ts count minus the CTs count */
            if ((iTeamT > iTeamCT) && ((iTeamT - iTeamCT) >= iPlayerLimit))
            {
                i = 1;
                while ((i <= iMaxClients) && (iPlayerLimit > 1))
                {
                    if (IsClientConnected (i) && IsClientInGame (i) && !IsProtectedAdmin (i) && (GetClientTeam (i) == TEAM_T))
                    {
                        if (iDeadT > 0)
                        {
                            if (!IsPlayerAlive (i))
                            {
                                ChangeClientTeam (i, TEAM_CT);
                                iPlayerLimit--;
                                iDeadT--;
                            }
												}
												else
												{
												    ChangeClientTeam (i, TEAM_CT);
												    iPlayerLimit--;
												}

                        iPlayerLimit--;
                    }

                    i++;
                }
            }
            /* else is there currently more CTs then Ts*/
            /* also is the player limit less than the CTs count minus the Ts count */
            else if ((iTeamCT > iTeamT) && ((iTeamCT - iTeamT) >= iPlayerLimit))
            {
                i = 1;
                while ((i <= iMaxClients) && (iPlayerLimit > 1))
                {
                    if (IsClientConnected (i) && IsClientInGame (i) && !IsProtectedAdmin (i) && (GetClientTeam (i) == TEAM_CT))
                    {
                        if (iDeadCT > 0)
                        {
                            if (!IsPlayerAlive (i))
                            {
                                ChangeClientTeam (i, TEAM_T);
                                iPlayerLimit--;
                                iDeadCT--;
                            }
												}
												else
												{
												    ChangeClientTeam (i, TEAM_T);
												    iPlayerLimit--;
												}

                        iPlayerLimit--;
                    }

                    i++;
                }
            }

            /* update the next balance check timer */
            g_fBalanceCheckTime = fTime + GetConVarFloat (g_cVarCheckTime);
        }
        
        g_bTeamBalanceThreadRunning = true;
        return Plugin_Continue;
    }

    g_bTeamBalanceThreadRunning = false;
    return Plugin_Stop;
}

stock bool:IsProtectedAdmin (client)
{
    return (GetConVarBool (g_cVarAdminsImmune) && (GetUserAdmin (client) != INVALID_ADMIN_ID));
}

