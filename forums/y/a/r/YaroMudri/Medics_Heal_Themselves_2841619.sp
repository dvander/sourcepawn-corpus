#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
    name = "Medic Self-Healing",
    author = "",
    description = "Allows Medics to heal themselves with their Medigun",
    version = PLUGIN_VERSION,
    url = "
};

// ConVar handles
ConVar g_cvEnabled;
ConVar g_cvHealRate;
ConVar g_cvUberRate;
ConVar g_cvAllowOverheal;

// Healing states
bool g_bIsHealingSelf[MAXPLAYERS + 1];
float g_fNextHealTick[MAXPLAYERS + 1];
float g_fNextBeamTick[MAXPLAYERS + 1];

public void OnPluginStart()
{
    // Create convars
    CreateConVar("sm_medicselfheal_version", PLUGIN_VERSION, "Medic Self-Heal Version", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
    g_cvEnabled = CreateConVar("sm_medicselfheal_enabled", "1", "Enable/disable medic self-healing", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    g_cvHealRate = CreateConVar("sm_medicselfheal_rate", "24.0", "Healing rate per second (default matches medigun)", FCVAR_NOTIFY, true, 1.0, true, 100.0);
    g_cvUberRate = CreateConVar("sm_medicselfheal_uberrate", "1.0", "Ubercharge build rate multiplier when self-healing", FCVAR_NOTIFY, true, 0.0, true, 2.0);
    g_cvAllowOverheal = CreateConVar("sm_medicselfheal_overheal", "1", "Allow overheal when self-healing", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // Hook events
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("player_changeclass", Event_PlayerChangeClass);
    HookEvent("post_inventory_application", Event_InventoryUpdate);
    
    // Initialize arrays
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsValidClient(i))
        {
            OnClientPutInServer(i);
        }
    }
    
    // Create timers
    CreateTimer(0.1, Timer_ProcessHealing, _, TIMER_REPEAT);
    
    // Late load support
    if (LibraryExists("clientprefs"))
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i))
            {
                OnClientPutInServer(i);
            }
        }
    }
}

public void OnClientPutInServer(int client)
{
    g_bIsHealingSelf[client] = false;
    g_fNextHealTick[client] = 0.0;
    g_fNextBeamTick[client] = 0.0;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(client))
    {
        g_bIsHealingSelf[client] = false;
        g_fNextHealTick[client] = 0.0;
        g_fNextBeamTick[client] = 0.0;
    }
    
    return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(client))
    {
        g_bIsHealingSelf[client] = false;
    }
    
    return Plugin_Continue;
}

public Action Event_PlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(client))
    {
        g_bIsHealingSelf[client] = false;
    }
    
    return Plugin_Continue;
}

public Action Event_InventoryUpdate(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (IsValidClient(client))
    {
        // Stop healing if inventory changes
        g_bIsHealingSelf[client] = false;
    }
    
    return Plugin_Continue;
}

public Action Timer_ProcessHealing(Handle timer)
{
    if (!g_cvEnabled.BoolValue)
    {
        return Plugin_Continue;
    }
    
    float healRate = g_cvHealRate.FloatValue;
    float uberMultiplier = g_cvUberRate.FloatValue;
    bool allowOverheal = g_cvAllowOverheal.BoolValue;
    
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsValidClient(client) || !IsPlayerAlive(client))
        {
            continue;
        }
        
        // Only process medics
        if (TF2_GetPlayerClass(client) != TFClass_Medic)
        {
            continue;
        }
        
        // Check if player is trying to heal themselves
        int medigun = GetPlayerWeaponSlot(client, 1); // Secondary weapon slot
        
        if (!IsValidEntity(medigun))
        {
            continue;
        }
        
        char classname[64];
        GetEntityClassname(medigun, classname, sizeof(classname));
        
        if (!StrEqual(classname, "tf_weapon_medigun"))
        {
            continue;
        }
        
        // Check if medigun is active
        int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        
        if (activeWeapon != medigun)
        {
            g_bIsHealingSelf[client] = false;
            continue;
        }
        
        // Check if player is attacking (holding primary fire)
        if (GetEntProp(medigun, Prop_Send, "m_bHealing") || GetEntProp(medigun, Prop_Send, "m_bAttacking"))
        {
            // Player is holding fire button - check if they're trying to heal themselves
            int healTarget = GetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget");
            
            if (!IsValidClient(healTarget) || healTarget == client)
            {
                // No valid target or targeting self - enable self-healing
                g_bIsHealingSelf[client] = true;
                
                // Apply healing
                float gameTime = GetGameTime();
                
                if (gameTime >= g_fNextHealTick[client])
                {
                    PerformSelfHealing(client, medigun, healRate, uberMultiplier, allowOverheal);
                    g_fNextHealTick[client] = gameTime + 0.1; // Heal every 0.1 seconds
                }
                
                // Update medigun state to show healing
                SetEntProp(medigun, Prop_Send, "m_bHealing", 1);
                SetEntProp(medigun, Prop_Send, "m_bAttacking", 1);
                
                // Set healing target to self
                SetEntPropEnt(medigun, Prop_Send, "m_hHealingTarget", client);
            }
            else
            {
                // Healing another player - disable self-healing
                g_bIsHealingSelf[client] = false;
            }
        }
        else
        {
            // Not attacking - disable self-healing
            g_bIsHealingSelf[client] = false;
        }
    }
    
    return Plugin_Continue;
}

void PerformSelfHealing(int client, int medigun, float healRate, float uberMultiplier, bool allowOverheal)
{
    // Get current health
    int currentHealth = GetClientHealth(client);
    int maxHealth = GetEntProp(client, Prop_Data, "m_iMaxHealth");
    
    // Check if healing is needed
    if (currentHealth >= maxHealth && !allowOverheal)
    {
        // At full health, no overheal allowed
        return;
    }
    
    // Calculate healing amount (healRate is per second, called every 0.1 seconds)
    float healAmount = healRate * 0.1;
    
    // Apply healing
    int newHealth = currentHealth + RoundFloat(healAmount);
    
    // Cap at max health if overheal not allowed
    if (!allowOverheal && newHealth > maxHealth)
    {
        newHealth = maxHealth;
    }
    
    // Cap at maximum possible overheal (3x base health for medic)
    int maxOverheal = maxHealth * 3;
    if (newHealth > maxOverheal)
    {
        newHealth = maxOverheal;
    }
    
    // Only set health if it actually changed
    if (newHealth != currentHealth)
    {
        SetEntityHealth(client, newHealth);
        
        // Play healing sound occasionally
        if (GetRandomInt(1, 10) <= 3) // 30% chance per tick
        {
            EmitSoundToAll("weapons/medigun_heal.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.5);
        }
    }
    
    // Build ubercharge
    float uber = GetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel");
    uber += (uberMultiplier * 0.00125); // ~1.25% per second
    if (uber > 1.0) uber = 1.0;
    SetEntPropFloat(medigun, Prop_Send, "m_flChargeLevel", uber);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if (!g_cvEnabled.BoolValue || !IsValidClient(client) || !IsPlayerAlive(client))
    {
        return Plugin_Continue;
    }
    
    // Only process medics
    if (TF2_GetPlayerClass(client) != TFClass_Medic)
    {
        return Plugin_Continue;
    }
    
    int medigun = GetPlayerWeaponSlot(client, 1); // Secondary weapon slot
    
    if (!IsValidEntity(medigun))
    {
        return Plugin_Continue;
    }
    
    char classname[64];
    GetEntityClassname(medigun, classname, sizeof(classname));
    
    if (!StrEqual(classname, "tf_weapon_medigun"))
    {
        return Plugin_Continue;
    }
    
    // Check if medigun is active
    int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    
    if (activeWeapon != medigun)
    {
        return Plugin_Continue;
    }
    
    return Plugin_Continue;
}

// Helper function to check if client is valid
stock bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}