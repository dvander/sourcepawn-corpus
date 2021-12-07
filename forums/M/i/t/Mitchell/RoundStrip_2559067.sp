#pragma semicolon 1
#include <sdktools>

public Plugin myinfo = {
    name = "Round Weapon Stripper",
    author = "Mitch",
    description = "Strips players at round_prestart.",
    version = "1.0.0",
    url = "mtch.tech"
}

public void OnPluginStart() {
    HookEvent("round_prestart", Event_RoundPrestart);
}

public Event_RoundPrestart(Event event, const char[] name, bool dontBroadcast) {
    int weapon = -1;
    for(int i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) > 1) {
            weapon = -1;
            for(int slot = 5; slot >= 0; slot--) {
                while((weapon = GetPlayerWeaponSlot(i, slot)) != -1) {
                    if(IsValidEntity(weapon)) {
                        RemovePlayerItem(i, weapon);
                    }
                }
            }
        }
    }
}
