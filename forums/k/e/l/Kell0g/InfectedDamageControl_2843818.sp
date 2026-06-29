#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "8.5"

public Plugin myinfo =
{
    name = "Infected Damage Control",
    author = "Kell0g",
    version = PLUGIN_VERSION
};

ConVar g_hDifficulty;
ConVar g_hIncapHealth;

enum
{
    ATTACK_COMMON = 0,
    ATTACK_HUNTER_CLAW,
    ATTACK_HUNTER_POUNCE,
    ATTACK_JOCKEY_CLAW,
    ATTACK_JOCKEY_RIDE,
    ATTACK_CHARGER_PUNCH,
    ATTACK_CHARGER_SMASH,
    ATTACK_CHARGER_STUMBLE,
    ATTACK_CHARGER_POUND,
    ATTACK_SMOKER_TONGUE,
    ATTACK_SMOKER_DRAG,
    ATTACK_SPITTER_CLAW,    // Added missing claw
    ATTACK_SPITTER_ACID,
    ATTACK_TANK_ROCK,
    ATTACK_TANK_PUNCH,
    ATTACK_WITCH_BASE,
    NUM_ATTACKS
};

ConVar g_cvBaseDamage[NUM_ATTACKS][4]; 
ConVar g_cvIncapMult[NUM_ATTACKS][4];
ConVar g_cvNonIncapMult[NUM_ATTACKS][4];

public void OnPluginStart()
{
    g_hDifficulty = FindConVar("z_difficulty");
    g_hIncapHealth = FindConVar("survivor_incap_health");

    // Initialize all attack types
    InitAttack(ATTACK_COMMON, "common", "3.0", "5.0", "10.0", "20.0");
    InitAttack(ATTACK_HUNTER_CLAW, "hunter_claw", "4.0", "6.0", "9.0", "15.0");
    InitAttack(ATTACK_HUNTER_POUNCE, "hunter_pounce", "15.0", "25.0", "35.0", "50.0");
    InitAttack(ATTACK_JOCKEY_CLAW, "jockey_claw", "3.0", "4.0", "6.0", "10.0");
    InitAttack(ATTACK_JOCKEY_RIDE, "jockey_ride", "4.0", "6.0", "8.0", "12.0");
    InitAttack(ATTACK_CHARGER_PUNCH, "charger_punch", "10.0", "15.0", "20.0", "30.0");
    InitAttack(ATTACK_CHARGER_SMASH, "charger_smash", "7.0", "10.0", "15.0", "25.0");
    InitAttack(ATTACK_CHARGER_STUMBLE, "charger_stumble", "2.0", "5.0", "10.0", "15.0");
    InitAttack(ATTACK_CHARGER_POUND, "charger_pound", "15.0", "25.0", "35.0", "50.0");
    InitAttack(ATTACK_SMOKER_TONGUE, "smoker_tongue", "3.0", "4.0", "6.0", "10.0");
    InitAttack(ATTACK_SMOKER_DRAG, "smoker_drag", "1.0", "1.0", "3.0", "5.0");
    InitAttack(ATTACK_SPITTER_CLAW, "spitter_claw", "2.0", "4.0", "6.0", "10.0");
    InitAttack(ATTACK_SPITTER_ACID, "spitter_acid", "2.0", "3.0", "4.0", "6.0");
    InitAttack(ATTACK_TANK_ROCK, "tank_rock", "50.0", "50.0", "100.0", "150.0");
    InitAttack(ATTACK_TANK_PUNCH, "tank_punch", "24.0", "24.0", "50.0", "75.0");
    InitAttack(ATTACK_WITCH_BASE, "witch_base", "50.0", "100.0", "100.0", "100.0");

    AutoExecConfig(true, "InfectedDamageControl");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!IsSurvivor(victim)) return Plugin_Continue;

    bool incapped = IsIncapped(victim);
    char cls[64] = "";
    if (inflictor > 0 && IsValidEntity(inflictor)) GetEntityClassname(inflictor, cls, sizeof(cls));

    int attackType = -1;

    // ATTACK IDENTIFICATION
    if (IsCommon(attacker)) attackType = ATTACK_COMMON;
    else if (IsWitch(attacker)) attackType = ATTACK_WITCH_BASE;
    else if (IsSpit(inflictor)) attackType = ATTACK_SPITTER_ACID;
    else if (IsInfected(attacker, 3)) attackType = (StrContains(cls, "claw") != -1) ? ATTACK_HUNTER_CLAW : ATTACK_HUNTER_POUNCE;
    else if (IsInfected(attacker, 5)) attackType = (StrContains(cls, "claw") != -1) ? ATTACK_JOCKEY_CLAW : ATTACK_JOCKEY_RIDE;
    else if (IsInfected(attacker, 1)) attackType = (damage <= 2.0) ? ATTACK_SMOKER_DRAG : ATTACK_SMOKER_TONGUE;
    else if (IsInfected(attacker, 8)) attackType = StrEqual(cls, "tank_rock") ? ATTACK_TANK_ROCK : ATTACK_TANK_PUNCH;
    else if (IsInfected(attacker, 4)) attackType = ATTACK_SPITTER_CLAW; // Identification for Spitter's hand attack
    else if (IsInfected(attacker, 6)) 
    {
        if (StrContains(cls, "claw") != -1) attackType = ATTACK_CHARGER_PUNCH;
        else if (damage >= 15.0) attackType = ATTACK_CHARGER_SMASH;
        else if (damage <= 5.0) attackType = ATTACK_CHARGER_STUMBLE;
        else attackType = ATTACK_CHARGER_POUND;
    }

    // APPLY CUSTOM DAMAGE
    if (attackType != -1)
    {
        damage = GetAttackDamage(attackType, incapped);
        
        // --- THE SPITTER FIX ---
        // If it's acid damage, we MUST change the damagetype to bypass the engine's 
        // hardcoded "1 damage to incapped" nerf.
        if (attackType == ATTACK_SPITTER_ACID)
        {
            damagetype = DMG_GENERIC; 
        }
    }

    // INSTA-KILL LOGIC
    if (!incapped)
    {
        float hp = float(GetClientHealth(victim));
        float buffer = GetEntPropFloat(victim, Prop_Send, "m_healthBuffer");
        float incapHealth = (g_hIncapHealth != null) ? g_hIncapHealth.FloatValue : 300.0;
        
        if (damage >= (hp + buffer + incapHealth))
        {
            SetEntProp(victim, Prop_Send, "m_currentReviveCount", 2);
            damage = hp + buffer + 100.0; 
        }
    }

    return Plugin_Changed;
}

void InitAttack(int type, const char[] name, const char[] easy, const char[] norm, const char[] hard, const char[] exp)
{
    char buffer[64];
    char diffNames[][] = {"easy", "normal", "hard", "expert"};

    for (int i = 0; i < 4; i++)
    {
        Format(buffer, sizeof(buffer), "mid_%s_%s", name, diffNames[i]);
        g_cvBaseDamage[type][i] = CreateConVar(buffer, (i == 0) ? easy : (i == 1) ? norm : (i == 2) ? hard : exp);

        Format(buffer, sizeof(buffer), "mid_%s_incap_mult_%s", name, diffNames[i]);
        g_cvIncapMult[type][i] = CreateConVar(buffer, "2.0");

        Format(buffer, sizeof(buffer), "mid_%s_nonincap_mult_%s", name, diffNames[i]);
        g_cvNonIncapMult[type][i] = CreateConVar(buffer, "1.0");
    }
}

float GetAttackDamage(int attackType, bool isIncapped)
{
    int diffIdx = 1; 
    char diffStr[16];
    
    if (g_hDifficulty != null)
    {
        g_hDifficulty.GetString(diffStr, sizeof(diffStr));
        if (StrEqual(diffStr, "Easy", false)) diffIdx = 0;
        else if (StrEqual(diffStr, "Hard", false)) diffIdx = 2;
        else if (StrEqual(diffStr, "Impossible", false)) diffIdx = 3;
    }

    float base = g_cvBaseDamage[attackType][diffIdx].FloatValue;
    float mult = isIncapped ? g_cvIncapMult[attackType][diffIdx].FloatValue : g_cvNonIncapMult[attackType][diffIdx].FloatValue;

    return base * mult;
}

// Helpers
bool IsSurvivor(int client) { return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2); }
bool IsIncapped(int client) { return !!GetEntProp(client, Prop_Send, "m_isIncapacitated"); }
bool IsInfected(int client, int cls) { return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == cls); }

bool IsCommon(int attacker) { 
    if (attacker > MaxClients && IsValidEntity(attacker)) {
        char cls[32]; 
        GetEntityClassname(attacker, cls, sizeof(cls));
        return StrEqual(cls, "infected");
    }
    return false;
}

bool IsSpit(int ent) {
    if (ent > MaxClients && IsValidEntity(ent)) {
        char cls[32]; 
        GetEntityClassname(ent, cls, sizeof(cls));
        return (StrEqual(cls, "insect_swarm") || StrEqual(cls, "spitter_projectile"));
    }
    return false;
}

bool IsWitch(int ent) {
    if (ent > MaxClients && IsValidEntity(ent)) {
        char cls[32]; 
        GetEntityClassname(ent, cls, sizeof(cls));
        return (StrContains(cls, "witch") != -1);
    }
    return false;
}