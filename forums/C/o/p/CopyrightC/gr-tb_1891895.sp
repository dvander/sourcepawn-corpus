#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.1.1.82"
#define PLUGIN_VERSION_CVAR "grtb_version"
#define FADE_IN 0x0001
#define SPEC 1
#define TS 2
#define CTS 3

new Handle:g_Cvar_round_restart_delay;
new Handle:g_adtClientlist;
new Handle:g_adtPlayers;
new Handle:g_cVarAdminsImmune = INVALID_HANDLE;
new g_teamT;
new g_teamCT;
new g_diff;

public Plugin:myinfo =
{
    name = "GERMANY RELOADED | Team Balance",
    author = "Razor2142, Copyright(c)",
    version = PLUGIN_VERSION,
    description = "Germany Reloaded Team Balancer",
    url = "5.9.158.136"
};

public OnPluginStart()
{
	new Handle:version_cvar = CreateConVar(PLUGIN_VERSION_CVAR, PLUGIN_VERSION);
    g_cVarAdminsImmune = CreateConVar ("grtb_admin_immun", "1", "Enable admins immunity from getting switched", 0, true, 0.0, true, 1.0);
    g_Cvar_round_restart_delay = FindConVar("mp_round_restart_delay");
    PrintToChatAll("\x05[SM]\x01 Team-Balancer is loading...")

    if ((g_cVarAdminsImmune == INVALID_HANDLE))
    {
        SetFailState ("\x05[SM]\x01 Error - Unable to create a console var. Exiting...");
        return;
    }

    HookEvent("round_end", Event_RoundEnd)
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    new Float:restart_delay = GetConVarFloat(g_Cvar_round_restart_delay);

    CreateTimer((restart_delay - 0.1), Balance);
}

public Action:Balance(Handle:timer)
{
    g_teamT = GetTeamClientCount(TS);
    g_teamCT = GetTeamClientCount(CTS);
    g_diff = g_teamT - g_teamCT;

    if (g_diff < 0)
    {
        g_diff = -g_diff;
    }

    g_diff = RoundToFloor(Float:(g_diff / 2.0) + 1);

    g_adtClientlist = CreateArray(3);
    g_adtPlayers = CreateArray(3);

    if (g_teamT > (g_teamCT + 1))
    {
        if (GetTeamClientCount(TS) > 0)
        {
            for (new i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == TS) && !IsProtectedAdmin(i))
                {
                    PushArrayCell(g_adtClientlist, i);
                }
            }
            clientuebergeber();
        }
        switcher(0, 0, 255, 255, FADE_IN, CTS);
    }

    if (g_teamCT > (g_teamT + 1))
    {
        if (GetTeamClientCount(CTS) > 0)
        {
            for (new i = 1; i <= MaxClients; i++)
            {
                if (IsClientInGame(i) && IsClientConnected(i) && (GetClientTeam(i) == CTS) && !IsProtectedAdmin(i))
                {
                    PushArrayCell(g_adtClientlist, i);
                }
            }
            clientuebergeber();
        }
        switcher(255, 0, 0, 255, FADE_IN, TS);
    }
}

public Action:clientuebergeber()
{
    new randomnumber;

    if (GetArraySize(g_adtClientlist) + 1 < g_diff)
    {
        g_diff = GetArraySize(g_adtClientlist)+1;
    }

    for (new j = 1; j < g_diff; j++)
    {
        randomnumber = GetRandomInt(0, GetArraySize(g_adtClientlist)-1);
        PushArrayCell(g_adtPlayers, GetArrayCell(g_adtClientlist, randomnumber));
        RemoveFromArray(g_adtClientlist, randomnumber);
    }
}

public Action:switcher(red, green, blue, alpha, type, newteam)
{
    new Handle:msg;
    new duration;

    duration = 0;

    for (new i = 1; i < g_diff; i++)
    {
        CS_SwitchTeam(GetArrayCell(g_adtPlayers, i - 1), newteam);

        msg = StartMessageOne("Fade", GetArrayCell(g_adtPlayers, i - 1));
        BfWriteShort(msg, 500);
        BfWriteShort(msg, duration);
        BfWriteShort(msg, type);
        BfWriteByte(msg, red);
        BfWriteByte(msg, green);
        BfWriteByte(msg, blue);
        BfWriteByte(msg, alpha);
        EndMessage();
    }

    PrintToChatAll("\x05[SM]\x01 Teams are balanced!")

    ClearArray(g_adtClientlist);
    ClearArray(g_adtPlayers);
}

stock bool:IsProtectedAdmin(client)
{
    return (GetConVarBool(g_cVarAdminsImmune) && (GetUserAdmin(client) != INVALID_ADMIN_ID));
}
