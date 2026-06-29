#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define DMG_FALL (1 << 5)

ConVar g_cvEnabled, g_cvJumpForce, g_cvVerticalBoost, g_cvFallThreshold, g_cvGameModes, g_cvSelfDamage, g_cvTeamLaunch, g_cvTeamDamage;
ConVar g_cvMPGameMode;

// Cached values for optimization
bool g_bIsAllowedMode;
bool g_bIsRocketJumping[MAXPLAYERS + 1]; 

public Plugin myinfo = {
    name = "[L4D2] RocketDude Universal",
    author = "Kell0g", 
    description = "Optimized rocket jumps with team-damage and team-launch controls.",
    version = "1.7",
    url = "https://forums.alliedmods.net/showthread.php?t=352555"
};

public void OnPluginStart() {
    g_cvEnabled = CreateConVar("l4d2_rocketdude_enabled", "1", "Enable RocketDude mechanics.");
    g_cvJumpForce = CreateConVar("l4d2_rocketdude_force", "300", "Launch power.");
    g_cvVerticalBoost = CreateConVar("l4d2_rocketdude_vertical", "200.0", "Upward boost.");
    g_cvFallThreshold = CreateConVar("l4d2_rocketdude_fall_damage", "40.0", "Damage cushion.");
    g_cvSelfDamage = CreateConVar("l4d2_rocketdude_self_damage", "12", "Damage you take from your own jump.");
    g_cvTeamDamage = CreateConVar("l4d2_rocketdude_teammate_damage", "0.0", "Damage teammates take from your rocket jump.");
    g_cvTeamLaunch = CreateConVar("l4d2_rocketdude_teammate_launch", "0", "Should your rocket jump launch teammates? (1 = Yes, 0 = No)");
    g_cvGameModes = CreateConVar("l4d2_rocketdude_modes", "", "Gamemodes to allow (Empty = all).");

    // Cache the gamemode ConVar handle once
    g_cvMPGameMode = FindConVar("mp_gamemode");
    
    // Hook changes to the gamemode or our config to re-cache logic
    g_cvGameModes.AddChangeHook(OnCVarChanged);
    if (g_cvMPGameMode != null) g_cvMPGameMode.AddChangeHook(OnCVarChanged);

    AutoExecConfig(true, "rocketdude_universal");

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}

public void OnConfigsExecuted() {
    CacheGamemodeAllowed();
}

public void OnCVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
    CacheGamemodeAllowed();
}

void CacheGamemodeAllowed() {
    char sAllow[256], sCurrent[64];
    g_cvGameModes.GetString(sAllow, sizeof(sAllow));
    
    if (sAllow[0] == '\0') {
        g_bIsAllowedMode = true;
        return;
    }

    if (g_cvMPGameMode != null) {
        g_cvMPGameMode.GetString(sCurrent, sizeof(sCurrent));
        g_bIsAllowedMode = (StrContains(sAllow, sCurrent, false) != -1);
    }
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    g_bIsRocketJumping[client] = false;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
    // 1. Bitwise and Boolean checks first (Extremely cheap)
    if (!g_cvEnabled.BoolValue || !g_bIsAllowedMode) return Plugin_Continue;
    
    // 2. Validate victim (Indices are cheap)
    if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim)) return Plugin_Continue;

    // 3. Fall Damage Logic (Optimized order)
    if (damagetype & DMG_FALL) {
        if (g_bIsRocketJumping[victim]) {
            float threshold = g_cvFallThreshold.FloatValue;
            damage = (damage <= threshold) ? 0.0 : damage - threshold;
            g_bIsRocketJumping[victim] = false; 
            return Plugin_Changed;
        }
        return Plugin_Continue;
    }

    // 4. Projectile Logic (Check inflictor index before string comparisons)
    if (inflictor > MaxClients && IsValidEntity(inflictor)) {
        char cls[32]; 
        GetEdictClassname(inflictor, cls, sizeof(cls));
        
        if (cls[0] == 'g' && StrEqual(cls, "grenade_launcher_projectile")) {
            if (GetClientTeam(victim) != 2) return Plugin_Continue;

            bool isSelf = (victim == attacker);
            
            if (isSelf || g_cvTeamLaunch.BoolValue) {
                float vExp[3], vPly[3], vVel[3], vDir[3];
                GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", vExp);
                GetClientAbsOrigin(victim, vPly);
                vPly[2] += 15.0;
                
                MakeVectorFromPoints(vExp, vPly, vDir);
                NormalizeVector(vDir, vDir);
                
                GetEntPropVector(victim, Prop_Data, "m_vecVelocity", vVel);
                float force = g_cvJumpForce.FloatValue;
                vVel[0] += vDir[0] * force;
                vVel[1] += vDir[1] * force;
                vVel[2] = (vDir[2] * force) + g_cvVerticalBoost.FloatValue;
                
                TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, vVel);
                
                // Set the flag; we clear it when they take fall damage or touch ground
                g_bIsRocketJumping[victim] = true;
            }

            damage = isSelf ? g_cvSelfDamage.FloatValue : g_cvTeamDamage.FloatValue;
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}

// Instead of OnGameFrame, we use the move post-think or touch to reset the flag
public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdrate, int tickcount, int seed, const int mouse[2]) {
    if (g_bIsRocketJumping[client] && (GetEntityFlags(client) & FL_ONGROUND)) {
        g_bIsRocketJumping[client] = false;
    }
}