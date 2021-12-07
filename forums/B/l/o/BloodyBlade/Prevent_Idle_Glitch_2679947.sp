#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
    name = "Prevent IDLE glitch",
    author = "khan",
    description = "Stop players from using idle to cheat",
    version = "1.0"
};

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define ZC_TANK         8

enum ISSUE
{
    TankHit, 
    Defib
};

int iNextValidIDLE[MAXPLAYERS];           // Next game instant to allow player to go idle
ISSUE iReason[MAXPLAYERS];                // Reason for not allow idle

public void OnPluginStart()
{
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
    HookEvent("defibrillator_used", Event_DefibUsed, EventHookMode_Pre);

    AddCommandListener(GoAwayFromKeyboard, "go_away_from_keyboard"); 
}

public Action GoAwayFromKeyboard(int client, const char[] command, int argc) 
{
    if (!AllowIDLE(client))
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action Event_DefibUsed(Event hEvent, const char[] name, bool dontBroadcast) 
{
    int subject = GetClientOfUserId(GetEventInt(hEvent, "subject"));
    iNextValidIDLE[subject] = GetTime() + 5; // Disable IDLE for 5 seconds when defibbed
    iReason[subject] = view_as<ISSUE>(Defib);
}

public Action Event_PlayerHurt(Event hEvent, const char[] name, bool dontBroadcast) 
{
    int player = GetClientOfUserId(GetEventInt(hEvent, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));

    if (!IS_VALID_INFECTED(attacker)) return Plugin_Continue;

    int zClass = GetEntProp(attacker, Prop_Send, "m_zombieClass"); 
    switch (zClass) 
    {
        case ZC_TANK:
        {
            iNextValidIDLE[player] = GetTime() + 3;  // Disable idle for 3 seconds if hit by tank
            iReason[player] = view_as<ISSUE>(TankHit);
        }
    }
    return Plugin_Continue; 
} 

bool AllowIDLE(int client) 
{
    // Are they boomed? Don't allow player to go idle for 13 seconds after boomed - about the time when they can see clearly again
    float vomitStart = GetEntPropFloat(client, Prop_Send, "m_vomitStart");
    if ((vomitStart + 13) > GetGameTime())
    {
        PrintToChat(client, "\x05Not allowed to go idle when boomed");
        return false;
    }

    // Are they reloading?
    int weapon = GetPlayerWeaponSlot(client, 0);
    if (weapon != -1)
    {
        if(GetEntProp(weapon, Prop_Data, "m_bInReload"))
        {
            PrintToChat(client, "\x05Not allowed to go idle when reloading");
            return false;
        }
    }

    // Are they being charged?
    int m_pummelAttacker = GetEntPropEnt(client, Prop_Send, "m_pummelAttacker");
    if (m_pummelAttacker != -1)
    {
        PrintToChat(client, "\x05Not allowed to go idle when being charged");
        return false;
    }

    // Are they stumbling?
    float vec[3];
    GetEntPropVector(client, Prop_Send, "m_staggerStart", vec);
    if (vec[0] != 0.000000 || vec[1] != 0.000000 || vec[2] != 0.000000)
    {
        PrintToChat(client, "\x05Not allowed to go idle when stumbled");
        return false;
    }

    // Verify that they didn't just get hit by a tank or defibbed
    if (iNextValidIDLE[client] > GetTime())
    {
        if (iReason[client] == view_as<ISSUE>(TankHit))
        {
            PrintToChat(client, "\x05Not allowed to go idle after tank hit");
        }
        else if (iReason[client] == view_as<ISSUE>(Defib))
        {
            PrintToChat(client, "\x05Not allowed to go idle after being defibbed");
        }
        else
        {
            PrintToChat(client, "\x05Not allowed to go idle");
        }
        return false;
    }

    // Allow idle
    return true;
}