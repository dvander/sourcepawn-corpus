// awardban.inc
native void Give_Award(int client, int awardId);
//---

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// --- My Custom Award IDs ( must be unique and not used by the game)---
#define AWARD_CARELESS      3
#define AWARD_SUICIDE       4
#define AWARD_RUSH          5
#define AWARD_FALL_TROLL    6

// --- Knockback inflicted by Tank or SI (may result in survivor falls) ---
#define DMG_LEGIT_KNOCKBACK  (DMG_CLUB | (1 << 20))

int JoinTime[MAXPLAYERS + 1];
int TrollDeathTime[MAXPLAYERS + 1];
int SafeSpawnTime[MAXPLAYERS + 1];
int KnockBackTime[MAXPLAYERS + 1];


public void OnPluginStart()
{
    HookEvent("player_spawn", Event_Spawn);
    HookEvent("bot_player_replace", Event_BotPlayerReplace);
    HookEvent("player_death", Event_Death);
    HookEvent("boomer_exploded", Event_BoomerExplode);
    HookEvent("player_disconnect", Event_Disconnect);
    if (GetEngineVersion() == Engine_Left4Dead2)
        HookEvent("charger_carry_start", Event_CarryStart);
}

public void OnClientPutInServer(int client)
{
    JoinTime[client] = GetTime();
    TrollDeathTime[client] = 0;
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

// --- Damage Hook (tracks knockback for fall troll) ---
public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ( damagetype & DMG_LEGIT_KNOCKBACK )
    {
        if (attacker < MAXPLAYERS)
            KnockBackTime[victim] = GetTime();
    }
    return Plugin_Continue;
}

public void Event_Spawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client)
        CreateTimer(1.0, Timer_Check, client, TIMER_REPEAT); // check for dangerous situation
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
    int player = GetClientOfUserId(event.GetInt("player"));
    int bot = GetClientOfUserId(event.GetInt("bot"));

    KnockBackTime[player] = KnockBackTime[bot];
}

public Action Timer_Check(Handle timer, any client)
{
    // Rarely repeats (typically executes once)

    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Stop;
    
    if (GetTime() - KnockBackTime[client] < 3 || Is_Incap(client))
        return Plugin_Continue;

    if (GetClientHealth(client) < 50)
        SetEntityHealth(client , 50);

    SafeSpawnTime[client] = GetTime();
    return Plugin_Stop; 
}

// --- Add knockback (this damage is not triggered by SDKHook_OnTakeDamage)
public void Event_BoomerExplode(Event event, const char[] name, bool dontBroadcast)
{
    int exploder = GetClientOfUserId(event.GetInt("attacker"));
    KnockBackTime[exploder] = GetTime();
}

// --- Add knockback (this damage is not triggered by SDKHook_OnTakeDamage)
public void Event_CarryStart(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(GetEventInt(event, "victim"));
    KnockBackTime[victim] = GetTime();
}

// --- Check for  (Suicide + Rush + Fall Troll) ---
public void Event_Death(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client || IsFakeClient(client)) return;

    int damagetype = event.GetInt("type");
    int currenttime = GetTime();
    bool trolling = false;

    // Rush (early death)
    if (currenttime - SafeSpawnTime[client] < 60)
    {
        trolling = true;
        ServerCommand("sm_chat \"[TrollDetect] Player %N died too soon after spawn (Rush)\"", client);
        Give_Award(client, AWARD_RUSH);
    }

    // Suicide by fire
    if (damagetype & DMG_BURN)
    {
        int attacker = GetClientOfUserId(event.GetInt("attacker"));
        if (attacker == client || !attacker)
        {
            trolling = true;
            ServerCommand("sm_chat \"[TrollDetect] Player %N committed suicide by fire\"", client);
            Give_Award(client, AWARD_SUICIDE);
        }
    }

    // Fall Troll
    if (damagetype & DMG_FALL)
    {
        if (currenttime - KnockBackTime[client] > 5)
        {
            trolling = true;
            ServerCommand("sm_chat \"[TrollDetect] Player %N died from a fall\"", client);
            Give_Award(client, AWARD_FALL_TROLL);
        }
    }

    TrollDeathTime[client] = trolling ? currenttime : 0;
}


// AWARD_CARELESS
public void Event_Disconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!client || IsFakeClient(client) || !IsClientInGame(client))
        return;

    int timeSinceJoin = GetTime() - JoinTime[client];
    int timeSinceDeath = GetTime() - TrollDeathTime[client];

    if (timeSinceJoin <= 60 && timeSinceDeath <= 5)
    {
        char steamID[32];
        GetClientAuthId(client, AuthId_Steam2, steamID, sizeof(steamID));
        
        ServerCommand("sm_chat \"[TrollDetect] %N (SteamID: %s) died and disconnected shortly after\"", client, steamID);
        Give_Award(client, AWARD_CARELESS);
    }
}

stock bool Is_Incap(int client)
{
    return (GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0);
}