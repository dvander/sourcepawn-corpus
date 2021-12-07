#include <sourcemod>
#include <tf2>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

bool g_NoDamage[MAXPLAYERS + 1] = { false, ... };

public Plugin myinfo = {
    name = "[TF2] Anti Donor Abuse",
    description = "Prevents resized and kartified players from damaging others",
    author = "Banshee",
    version = "1.0.0",
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
}

public void TF2_OnConditionRemoved(int client, TFCond condition) {
    if (condition == TFCond_HalloweenKart) {
        g_NoDamage[client] = false;
    }
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype) {
    if (attacker > 0 && attacker <= MaxClients && !CheckCommandAccess(attacker, "sm_admin", ADMFLAG_GENERIC)) {
        float scale = GetEntPropFloat(attacker, Prop_Send, "m_flModelScale");
        if (g_NoDamage[attacker]) {
            #if defined DEBUG
                LogDebug("%N was prevented from doing damage in kart", attacker);
            #endif
            PrintToChat(attacker, "\x04[SM] \x01You cannot do damage while in a kart.");
            return Plugin_Handled;
        }
        if (scale != 1.0) {
            #if defined DEBUG
                LogDebug("%N was prevented from doing damage while resized", attacker);
            #endif
            PrintToChat(attacker, "\x04[SM] \x01You cannot do damage while resized.");
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

#if defined DEBUG
void LogDebug(const char[] format, any ...) {
	char buffer[128];
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToServer("[ANTI DONOR ABUSE] %s", buffer);
}
#endif