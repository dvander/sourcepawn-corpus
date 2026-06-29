#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

bool g_NoDamage[MAXPLAYERS + 1] = { false, ... };
//native bool Godmode_GetStatus(int client);

public Plugin myinfo = {
    name = "[TF2] Anti Donor Abuse",
    description = "Prevents resized and kartified players from damaging others",
    author = "Banshee",
    version = "1.1.0",
    url = "https://FirePowered.org"
};

public void OnPluginStart() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            g_NoDamage[i] = false;
            SDKHook(i, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client) {
    g_NoDamage[client] = false;
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public void TF2_OnConditionAdded(int client, TFCond condition) {
    if (condition == TFCond_HalloweenKart) {
        g_NoDamage[client] = true;
    }

    // Check for healing in god mode
    if (condition != TFCond_Healing && condition != TFCond_Overhealed) {
        return;
    }
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            if (TF2_GetPlayerClass(i) != TFClass_Medic) {
                continue;
            }
            int weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
            if (weapon == -1 || GetPlayerWeaponSlot(i, 1) != weapon) {
                continue;
            }
            int healingTarget = GetEntPropEnt(weapon, Prop_Send, "m_hHealingTarget");
            if (healingTarget == client && (GetEntProp(i, Prop_Data, "m_takedamage") == 1 || GetEntProp(i, Prop_Data, "m_takedamage") == 0 ))
            {
                LogDebug("%N prevented from healing %N", i, healingTarget);
                TF2_RemoveCondition(client, TFCond_Healing);
            }
        }
    }
}

public void TF2_OnConditionRemoved(int client, TFCond condition) {
    if (condition == TFCond_HalloweenKart) {
        g_NoDamage[client] = false;
    }
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
    if (victim == attacker) {
        return Plugin_Continue;
    }
    if (attacker > 0 && attacker <= MaxClients && !CheckCommandAccess(attacker, "sm_admin", ADMFLAG_GENERIC)) {
        float scale = GetEntPropFloat(attacker, Prop_Send, "m_flModelScale");
        if (g_NoDamage[attacker]) {
            LogDebug("%N was prevented from doing damage in kart", attacker);
            PrintToChat(attacker, "\x04[SM] \x01You cannot do damage while in a kart.");
            return Plugin_Handled;
        }
        if (scale != 1.0) {
            LogDebug("%N was prevented from doing damage while resized", attacker);
            PrintToChat(attacker, "\x04[SM] \x01You cannot do damage while resized.");
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

void LogDebug(const char[] format, any ...) {
    #if defined DEBUG
        char buffer[128];
        VFormat(buffer, sizeof(buffer), format, 2);
        LogError("[ANTI DONOR ABUSE] %s", buffer);
    #endif
}