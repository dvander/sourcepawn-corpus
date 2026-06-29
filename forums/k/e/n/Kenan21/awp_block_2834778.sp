#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
    name = "AWP Block",
    author = "Programmiert von FeritGang",
    description = "Beschränkt die Nutzung bestimmter Waffen auf KILL3R-B3AN VIP und verbietet sie Bots",
    version = "4.4",
    url = "http://5.189.131.115/cstrike/"
};

new String:g_AdminList[64][32];
new g_AdminCount;

public OnPluginStart() {
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_connect", OnPlayerConnect, EventHookMode_Post);
    LoadAdminList();
}

public OnPlayerConnect(Handle:event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client > 0 && IsClientInGame(client)) {
        SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
    }
}

public OnPlayerSpawn(Handle:event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (client > 0 && IsClientInGame(client)) {
        CreateTimer(0.1, Timer_CheckWeapons, client, TIMER_FLAG_NO_MAPCHANGE);
        SDKHook(client, SDKHook_WeaponSwitch, OnWeaponSwitch);
    }
}

public Action OnWeaponSwitch(int client, int weapon) {
    if (!IsValidEntity(weapon)) return Plugin_Continue;

    char classname[64];
    GetEdictClassname(weapon, classname, sizeof(classname));

    if (IsWeaponForbidden(classname)) {
        if (IsClientAdmin(client)) {
            PrintToChat(client, "[Waffen Block] Sie sind Admin, daher dürfen Sie diese Waffe benutzen.");
        } else {
            CreateTimer(0.1, Timer_RemoveWeapon, weapon, TIMER_FLAG_NO_MAPCHANGE);
            PrintToChat(client, "[Waffen Block] Diese verbotene Waffe wurde entfernt!");
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

public Action Timer_CheckWeapons(Handle timer, any client) {
    if (client > 0 && IsClientInGame(client)) {
        for (int i = 0; i < 6; i++) {
            int weapon = GetPlayerWeaponSlot(client, i);
            if (weapon != -1 && IsValidEntity(weapon)) {
                char classname[64];
                GetEdictClassname(weapon, classname, sizeof(classname));

                if (IsWeaponForbidden(classname) && !IsClientAdmin(client)) {
                    CreateTimer(0.1, Timer_RemoveWeapon, weapon, TIMER_FLAG_NO_MAPCHANGE);
                }
            }
        }
    }
    return Plugin_Stop;
}

public Action Timer_RemoveWeapon(Handle timer, any weapon) {
    if (IsValidEntity(weapon)) {
        AcceptEntityInput(weapon, "Kill");
    }
    return Plugin_Stop;
}

public bool IsWeaponForbidden(const char[] classname) {
    return StrEqual(classname, "weapon_awp", false) ||
           StrEqual(classname, "weapon_scout", false) ||
           StrEqual(classname, "weapon_g3sg1", false) ||
           StrEqual(classname, "weapon_sg552", false);
}

public bool IsClientAdmin(int client) {
    char authId[64];
    GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
    return IsAdminInList(authId);
}

public bool IsAdminInList(const char[] authId) {
    for (int i = 0; i < g_AdminCount; i++) {
        if (StrEqual(g_AdminList[i], authId, false)) {
            return true;
        }
    }
    return false;
}

public void LoadAdminList() {
    Handle file = OpenFile("addons/sourcemod/configs/admins_simple.ini", "r");
    if (file == null) return;

    char line[256];
    while (!IsEndOfFile(file) && g_AdminCount < sizeof(g_AdminList)) {
        ReadFileLine(file, line, sizeof(line));
        TrimString(line);

        if (StrContains(line, "STEAM_", false) != -1) {
            char steamId[32];
            int startIdx = 0, endIdx = 0;

            for (int i = 0; i < strlen(line); i++) {
                if (line[i] == '"') {
                    if (startIdx == 0) {
                        startIdx = i + 1;
                    } else {
                        endIdx = i;
                        break;
                    }
                }
            }

            if (startIdx < endIdx && endIdx - startIdx < sizeof(steamId)) {
                int length = endIdx - startIdx;
                strcopy(steamId, sizeof(steamId), line[startIdx]);
                steamId[length] = '\0';
                strcopy(g_AdminList[g_AdminCount], sizeof(g_AdminList[]), steamId);
                g_AdminCount++;
            }
        }
    }

    CloseHandle(file);
}
