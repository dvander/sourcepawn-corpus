// == OVERTIME PLUGIN FOR CS:S/CS:GO ==
// Description: Implements CS2 style overtime with cvar to adjust regulation rounds.

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define TEAM_T 2
#define TEAM_CT 3

new Handle:gCvarRegRounds;
new bool:g_bOvertimeActive = false;
new g_iOTScoreT = 0;
new g_iOTScoreCT = 0;
new g_iOTRoundsPlayed = 0;

public Plugin:myinfo = 
{
    name = "Overtime Mod (CS2 Style)",
    author = "Kael",
    description = "Implements CS2 style overtime with customizable regulation rounds",
    version = "1.1"
};

public void OnPluginStart()
{
    HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

    gCvarRegRounds = CreateConVar("cs_ot_reg_rounds", "24", "Number of total rounds to trigger overtime (default 24 = MR12 tie).", FCVAR_PLUGIN, true, 2.0, true, 60.0);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bOvertimeActive)
    {
        int winner = event.GetInt("winner");
        if (winner == TEAM_T)
            g_iOTScoreT++;
        else if (winner == TEAM_CT)
            g_iOTScoreCT++;

        g_iOTRoundsPlayed++;

        // Check win condition: first to 4 with 2 round lead
        if ((g_iOTScoreT >= 4 || g_iOTScoreCT >= 4) && Abs(g_iOTScoreT - g_iOTScoreCT) >= 2)
        {
            if (g_iOTScoreT > g_iOTScoreCT)
                PrintToChatAll("[Overtime] Terrorists win the overtime!");
            else
                PrintToChatAll("[Overtime] Counter-Terrorists win the overtime!");

            g_bOvertimeActive = false;
            return;
        }

        // After 6 OT rounds with no winner -> swap sides
        if (g_iOTRoundsPlayed >= 6)
        {
            g_iOTRoundsPlayed = 0;
            SwapTeams();
            PrintToChatAll("[Overtime] No winner after 6 rounds, swapping teams!");
        }
    }
    else
    {
        int scoreT = GetTeamScore(TEAM_T);
        int scoreCT = GetTeamScore(TEAM_CT);
        int regRounds = GetConVarInt(gCvarRegRounds);

        if (scoreT + scoreCT >= regRounds && scoreT == scoreCT)
        {
            ActivateOvertime();
        }
    }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (g_bOvertimeActive)
    {
        // Give all players 16000 at round start
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && IsPlayerAlive(i))
            {
                SetEntProp(i, Prop_Send, "m_iAccount", 16000);
            }
        }
    }
}

void ActivateOvertime()
{
    g_bOvertimeActive = true;
    g_iOTScoreT = 0;
    g_iOTScoreCT = 0;
    g_iOTRoundsPlayed = 0;

    PrintToChatAll("[Overtime] Match tied! Entering overtime mode. All players get $16000.");
}

void SwapTeams()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            int team = GetClientTeam(i);
            if (team == TEAM_T)
                CS_SwitchTeam(i, TEAM_CT);
            else if (team == TEAM_CT)
                CS_SwitchTeam(i, TEAM_T);
        }
    }
}

int Abs(int value)
{
    return (value < 0) ? -value : value;
}
