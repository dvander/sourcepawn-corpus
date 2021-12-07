#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <sdkhooks>

#define PLUGIN_VERSION "1.3.2"

new bool:g_bUseSDKHooks;

public Plugin:myinfo = {
    name = "Civilian Class Fixer",
    author = "bl4nk",
    description = "Fixes any current known civilian bugs",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/"
};

enum {
    WEAPONSLOT_PRIMARY = 0,
    WEAPONSLOT_SECONDARY,
    WEAPONSLOT_MELEE,
    WEAPONSLOT_OTHER1,
    WEAPONSLOT_OTHER2
};

public OnPluginStart() {
    CreateConVar("sm_ccfixer_version", PLUGIN_VERSION, "Civilian Class Fixer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    
    if (LibraryExists("sdkhooks")) {
        g_bUseSDKHooks = true;
        
        for (new i = 1; i <= MaxClients; i++) {
            if (IsClientConnected(i) && IsClientInGame(i)) {
                SDKHook(i, SDKHook_PostThink, Hook_PostThink);
            }
        }
    }
}

public OnLibraryAdded(const String:szName[]) {
    if (strcmp(szName, "sdkhooks", false) == 0) {
        g_bUseSDKHooks = true;
    }
}

public OnLibraryRemoved(const String:szName[]) {
    if (strcmp(szName, "sdkhooks", false) == 0) {
        g_bUseSDKHooks = false;
    }
}

public OnClientPutInServer(iClient) {
    if (g_bUseSDKHooks) {
        SDKHook(iClient, SDKHook_PostThink, Hook_PostThink);
    }
}

public Hook_PostThink(iClient) {
    if (GetPlayerWeapon(iClient) == -1) {
        LogAction(iClient, -1, "%L attempted to go civilian", iClient);
        ChangePlayerWeaponSlot(iClient, WEAPONSLOT_PRIMARY);
    }
}

public OnGameFrame() {
    if (!g_bUseSDKHooks) {
        for (new i = 1; i <= MaxClients; i++) {
            if (IsClientConnected(i) && IsClientInGame(i) && IsPlayerAlive(i)) {
                if (GetPlayerWeapon(i) == -1) {
                    LogAction(i, -1, "%L attempted to go civilian", i);
                    ChangePlayerWeaponSlot(i, WEAPONSLOT_PRIMARY);
                }
            }
        }
    }
}

stock GetPlayerWeapon(iClient) {
    return GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock bool:ChangePlayerWeaponSlot(iClient, iSlot) {
    new iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
    if (iWeapon > MaxClients) {
        SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iWeapon);
        return true;
    }

    return false;
}