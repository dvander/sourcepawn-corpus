#include <sourcemod>
#include <sdktools>

#define TEAM_SPEC 1
#define TEAM_T 2

#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_THIRDPERSON 5
#define SPECMODE_FREELOOK 6

new g_iLast[MAXPLAYERS + 1];

public OnPluginStart()
{
    CreateTimer(0.1, Timer_CheckSpec, _, TIMER_REPEAT);
}

public Action:Timer_CheckSpec(Handle:timer, any:data)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsPlayerAlive(i))
            continue;

        new mode = GetEntProp(i, Prop_Data, "m_iObserverMode");

        if (mode == SPECMODE_FIRSTPERSON && g_iLast[i] == SPECMODE_THIRDPERSON)
        {
            SetEntProp(i, Prop_Data, "m_iObserverMode", SPECMODE_FREELOOK);
            g_iLast[i] = SPECMODE_FREELOOK;
        }

        else if (g_iLast[i] == SPECMODE_FREELOOK && mode != SPECMODE_FREELOOK)
        {
            SetEntProp(i, Prop_Data, "m_iObserverMode", SPECMODE_FIRSTPERSON);
            g_iLast[i] = SPECMODE_FIRSTPERSON;
        }

        else
            g_iLast[i] = mode;
    }

    return Plugin_Continue;
}  