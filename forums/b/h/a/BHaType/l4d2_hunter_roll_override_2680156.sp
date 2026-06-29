#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#include <left4dhooks>

public Plugin myinfo =
{
    name = "[L4D2] Hunter Roll Anim",
    author = "BHaType",
    description = "Overrides hunter animation (now with chance)",
    version = "0.2",
    url = ""
}

enum
{
    STATE_NONE,
    STATE_SHOVED,
    STATE_ROLL,
    STATE_DEFAULT
};

static const char g_SequenceMatch[][] =
{
    "ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_L",
    "ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_BACKWARD",
    "ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_FORWARD",
    "ACT_TERROR_SHOVED_FORWARD",
    "ACT_TERROR_SHOVED_BACKWARD",
    "ACT_TERROR_SHOVED_LEFTWARD",
    "ACT_TERROR_SHOVED_RIGHTWARD"
};

ConVar sm_hunter_roll_animation_chance;

public void OnPluginStart()
{
    sm_hunter_roll_animation_chance = CreateConVar("sm_hunter_roll_animation_chance", "50.0", "Chance of roll animation");
}

public void OnClientPutInServer(int client)
{
    AnimHookEnable(client, AnimHook);
}
 
public void OnAllPluginsLoaded()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            OnClientPutInServer(i);
        }
    }
}

Action AnimHook(int client, int &sequence)
{
    if (!ShouldOverrideAnimtion(client, sequence))
        return Plugin_Continue;

    sequence = AnimGetFromActivity("ACT_TERROR_HUNTER_POUNCE_KNOCKOFF_R");
    return Plugin_Changed;
}

bool ShouldOverrideAnimtion(int client, int sequence)
{
    static int state[MAXPLAYERS + 1];

    if (GetClientTeam(client) != 3)
        return false;

    if (L4D2_GetPlayerZombieClass(client) != L4D2ZombieClass_Hunter)
        return false;

    if (state[client] == STATE_NONE && IsMatchedSequence(sequence))
        state[client] = STATE_SHOVED;

    if (state[client] == STATE_SHOVED)
    {
        if (sm_hunter_roll_animation_chance.FloatValue >= GetRandomFloat(1.0, 100.0))
        {
            state[client] = STATE_ROLL;
        }
        else
        {
            state[client] = STATE_DEFAULT;
        }
    }

    if (state[client] != STATE_NONE && !L4D_IsPlayerStaggering(client))
        state[client] = STATE_NONE;
    
    return state[client] == STATE_ROLL;
}

bool IsMatchedSequence(int sequence)
{
    for(int i; i < sizeof g_SequenceMatch; i++)
    {
        if (AnimGetFromActivity(g_SequenceMatch[i]) == sequence)
        {
            return true;
        }
    }
    
    return false;
}