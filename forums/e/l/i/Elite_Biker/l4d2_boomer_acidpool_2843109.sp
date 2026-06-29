#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define PLUGIN_AUTHOR "EliteBiker"
#define PLUGIN_VERSION "1.02"
#define PARTICLE_SPIT "spitter_projectile_explode"

public Plugin myinfo = 
{
    name = "[L4D2] Boomer Vomit - Acid Pools",
    author = PLUGIN_AUTHOR,
    description = "Drops a standalone Spitter acid pool under survivors who are vomited on.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2843109"
};

// ====================================================================================================
// Cvars & Globals
// ====================================================================================================

ConVar g_hCvarEnable;
ConVar g_hCvarDamage;
ConVar g_hCvarMPGameMode;
ConVar g_hCvarModesTog;
ConVar g_hCvarModes;
ConVar g_hCvarModesOff;

bool g_bEnabled;
int g_iCurrentMode;

bool g_bSpawningBoomerAcid = false;
int g_iSpawningBoomerClient = 0; // Tracks the boomer currently dropping acid
bool g_bIsBoomerAcid[2049];
int g_iBoomerAcidOwner[2049];    // Stores which boomer owns which acid pool
float g_fLastParticle[MAXPLAYERS + 1];

// ====================================================================================================
// Plugin Start & Configs
// ====================================================================================================

public void OnPluginStart()
{
    g_hCvarMPGameMode = FindConVar("mp_gamemode");
    
    CreateConVar("l4d2_boomer_acid_version", PLUGIN_VERSION, "Boomer Acid Pools plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    
    g_hCvarEnable = CreateConVar("l4d2_boomer_acid_enable", "1", "Enable/Disable the plugin.", FCVAR_NOTIFY);
    g_hCvarDamage = CreateConVar("l4d2_boomer_acid_damage", "2.0", "Custom damage per tick dealt by the Boomer's standalone acid pool.", FCVAR_NOTIFY);
    g_hCvarModesTog = CreateConVar("l4d2_boomer_acid_modes_tog", "0", "Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", FCVAR_NOTIFY);
    g_hCvarModes = CreateConVar("l4d2_boomer_acid_modes", "", "Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", FCVAR_NOTIFY);
    g_hCvarModesOff = CreateConVar("l4d2_boomer_acid_modes_off", "", "Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", FCVAR_NOTIFY);

    g_hCvarEnable.AddChangeHook(Event_ConVarChanged);
    g_hCvarModesTog.AddChangeHook(Event_ConVarChanged);
    g_hCvarModes.AddChangeHook(Event_ConVarChanged);
    g_hCvarModesOff.AddChangeHook(Event_ConVarChanged);

    HookEvent("player_now_it", Event_PlayerNowIt);
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i)) OnClientPutInServer(i);
    }
    
    AutoExecConfig(true, "l4d2_boomer_acidpool"); 
}

public void OnMapStart()
{
    if (!IsModelPrecached("models/infected/spitter_projectile.mdl"))
    {
        PrecacheModel("models/infected/spitter_projectile.mdl", true);
    }
    PrecacheParticle(PARTICLE_SPIT);
    UpdatePluginState();
}

public void OnConfigsExecuted()
{
    UpdatePluginState();
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

// ====================================================================================================
// Game Mode Validation
// ====================================================================================================

public void L4D_OnGameModeChange(int gamemode)
{
    g_iCurrentMode = gamemode;
    UpdatePluginState();
}

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    UpdatePluginState();
}

void UpdatePluginState()
{
    g_bEnabled = (g_hCvarEnable.BoolValue && IsAllowedGameMode());
}

bool IsAllowedGameMode()
{
    if(g_hCvarMPGameMode == null) return false;

    int iCvarModesTog = g_hCvarModesTog.IntValue;
    if(iCvarModesTog != 0)
    {
        g_iCurrentMode = L4D_GetGameModeType();
        if(g_iCurrentMode == 0) return false;

        switch(g_iCurrentMode)
        {
            case 2: g_iCurrentMode = 4;
            case 4: g_iCurrentMode = 2;
        }
        if(!(iCvarModesTog & g_iCurrentMode)) return false;
    }

    char sGameModes[64], sGameMode[64];
    g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
    Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

    g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
    if(sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if(StrContains(sGameModes, sGameMode, false) == -1) return false;
    }

    g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
    if(sGameModes[0])
    {
        Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
        if(StrContains(sGameModes, sGameMode, false) != -1) return false;
    }

    return true;
}

// ====================================================================================================
// Core Logic & Acid Spawning
// ====================================================================================================

public void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bEnabled) return;

    int survivorId = event.GetInt("userid");
    int attackerId = event.GetInt("attacker");
    
    // Passing both UserIDs via DataPack to be safe and accurate
    DataPack pack;
    CreateDataTimer(0.1, Timer_CreateSpit, pack, TIMER_FLAG_NO_MAPCHANGE);
    pack.WriteCell(survivorId);
    pack.WriteCell(attackerId);
}

public Action Timer_CreateSpit(Handle timer, DataPack pack)
{
    pack.Reset();
    int survivorId = pack.ReadCell();
    int attackerId = pack.ReadCell();

    int survivor = GetClientOfUserId(survivorId);
    int attacker = GetClientOfUserId(attackerId);
    
    if (IsValidSurvivor(survivor) && IsPlayerAlive(survivor))
    {
        DropAcidOnSurvivor(survivor, attacker);
    }
    
    return Plugin_Stop;
}

void DropAcidOnSurvivor(int survivor, int attacker)
{
    float vPos[3], vDir[3] = {90.0, 0.0, 0.0}; 
    GetClientAbsOrigin(survivor, vPos);
    vPos[2] += 40.0; 
    
    g_bSpawningBoomerAcid = true;
    g_iSpawningBoomerClient = attacker; 
    
    // Pass the Boomer index to native. If they disconnected, default back to 0.
    int clientParam = (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker)) ? attacker : 0;
    int spit = L4D2_SpitterPrj(clientParam, vPos, vDir);
    
    if (spit > MaxClients && IsValidEntity(spit))
    {
        L4D_DetonateProjectile(spit);
    }
    
    g_bSpawningBoomerAcid = false;
    g_iSpawningBoomerClient = 0;
}

// ====================================================================================================
// Entity Tracking (Isolating Boomer Acid)
// ====================================================================================================

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity > MaxClients && entity <= 2048)
    {
        if (g_bSpawningBoomerAcid && StrEqual(classname, "insect_swarm"))
        {
            g_bIsBoomerAcid[entity] = true;
            g_iBoomerAcidOwner[entity] = g_iSpawningBoomerClient; // Record the Boomer
        }
    }
}

public void OnEntityDestroyed(int entity)
{
    if (entity > MaxClients && entity <= 2048)
    {
        g_bIsBoomerAcid[entity] = false; 
        g_iBoomerAcidOwner[entity] = 0; 
    }
}

// ====================================================================================================
// Damage, Credit & Modular Effects
// ====================================================================================================

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bEnabled || !IsValidSurvivor(victim)) return Plugin_Continue;

    if (inflictor > MaxClients && inflictor <= 2048)
    {
        if (g_bIsBoomerAcid[inflictor])
        {
            int boomer = g_iBoomerAcidOwner[inflictor];

            // If the Boomer is still in the game.
            if (boomer > 0 && boomer <= MaxClients && IsClientInGame(boomer))
            {
                attacker = boomer; 
            }
            else
            {
                attacker = inflictor; // Fallback if the boomer disconnected
            }

            damage = g_hCvarDamage.FloatValue;
            damagetype = (262144 | 2048); 

            if (GetGameTime() - g_fLastParticle[victim] >= 0.2)
            {
                g_fLastParticle[victim] = GetGameTime();
                TriggerSilverShotEffects(victim);
            }

            return Plugin_Changed;
        }
    }
    
    return Plugin_Continue; 
}

void TriggerSilverShotEffects(int target)
{
    ConVar hSilverEffects = FindConVar("l4d2_spitter_acid_effects");
    if (hSilverEffects != null)
    {
        if (hSilverEffects.IntValue & 2)
        {
            DisplayParticle(target, PARTICLE_SPIT);
        }
    }
}

void DisplayParticle(int target, const char[] sParticle)
{
    int entity = CreateEntityByName("info_particle_system");
    if(entity == -1) return;

    DispatchKeyValue(entity, "effect_name", sParticle);
    DispatchSpawn(entity);
    ActivateEntity(entity);
    AcceptEntityInput(entity, "start");

    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", target);

    float vPos[3];
    vPos[2] += 10.0;
    TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

    SetVariantString("OnUser4 !self:Kill::0.8:-1");
    AcceptEntityInput(entity, "AddOutput");
    AcceptEntityInput(entity, "FireUser4");
}

void PrecacheParticle(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;
    if(table == INVALID_STRING_TABLE) table = FindStringTable("ParticleEffectNames");

    if(FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX)
    {
        bool save = LockStringTables(false);
        AddToStringTable(table, sEffectName);
        LockStringTables(save);
    }
}

// ====================================================================================================
// Helpers
// ====================================================================================================

bool IsValidSurvivor(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}