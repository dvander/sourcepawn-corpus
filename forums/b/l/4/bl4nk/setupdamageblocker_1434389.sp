#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

new bool:g_bInSetup;
new bool:g_bLateLoad;

public Plugin:myinfo = {
    name = "Setup Damage Blocker",
    author = "bl4nk",
    description = "Makes it so players can't hurt opposing players during setup",
    version = "1.0.0",
    url = "http://forums.alliedmods.net/"
};

public APLRes:AskPluginLoad2(Handle:hMyself, bool:bLateLoad, String:szError[], iErrLen) {
    g_bLateLoad = bLateLoad;
    return APLRes_Success;
}

public OnPluginStart() {
    HookEvent("teamplay_round_start", Event_RoundStart);
    HookEvent("teamplay_setup_end", Event_SetupEnd);
    
    if (g_bLateLoad) {
        for (new iClient = 1; iClient <= MaxClients; iClient++) {
            if (IsClientInGame(iClient)) {
                SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
            }
        }
    }
}

public OnClientPutInServer(iClient) {
    SDKHook(iClient, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Event_RoundStart(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast) {
    g_bInSetup = true;
}

public Event_SetupEnd(Handle:hEvent, const String:szEventName[], bool:bDontBroadcast) {
    g_bInSetup = false;
}

public Action:OnTakeDamage(iVictim, &iAttacker, &iInflictor, &Float:fDamage, &iDamageType) {
    if (g_bInSetup && iAttacker) {
        if (GetClientTeam(iVictim) != GetClientTeam(iAttacker)) {
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}