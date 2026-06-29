#include <sourcemod>
#include <sdktools>

int kills_T = 0;
int kills_CT = 0;

#define TEAM_T 2
#define TEAM_CT 3

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("player_death", Event_PlayerDeath);
}

public Action Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    kills_T = 0;
    kills_CT = 0;
    PrintToServer("Round Start: Kills reset. T %d, CT %d", kills_T, kills_CT);
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    int victim = GetEventInt(event, "userid");
    int victim_index = GetClientOfUserId(victim);
    int team = GetClientTeam(victim_index);
    
    if (team == TEAM_CT)
    {
        kills_T++;
    }
    else if (team == TEAM_T)
    {
        kills_CT++;
    }

    PrintToServer("Event_PlayerDeath: Killer %d, Victim %d", GetEventInt(event, "attacker"), victim_index);
    return Plugin_Continue;
}

public Action Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    int winningTeam = TEAM_CT;

    if (kills_T > kills_CT)
    {
        winningTeam = TEAM_T;
        PrintToChatAll("\x04[T] Terrorists Win!");
    }
    else if (kills_CT > kills_T)
    {
        PrintToChatAll("\x04[CT] Counter-Terrorists Win!");
    }
    else
    {
        PrintToChatAll("\x03[DRAW] The round is a draw!");
    }

    PrintToServer("Round End: Final Kills: T %d, CT %d", kills_T, kills_CT);

    // Suppress the default win sounds and messages
    if (winningTeam == TEAM_CT || winningTeam == TEAM_T)
    {
        // Use EmitSoundAny to play a custom win sound or suppress the sound entirely
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                // Optionally, stop the default win sound (if one is playing)
                // or play a different sound using EmitSoundAny

                // Example to stop a sound (ensure it's the correct sound):
                // EmitSoundAny(i, "common/null.wav");
                
                // Suppress the event broadcast to stop the default message
                SetEventBroadcast(event, false);
            }
        }
    }

    return Plugin_Continue;
}