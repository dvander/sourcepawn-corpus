#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo = {
    name = "[DODS] Damage Modifier",
    author = "drixevel",
    description = "Modifies damage for certain weapons.",
    version = "1.0.0",
    url = "https://drixevel.dev/"
};

public void OnPluginStart() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i)) {
            OnClientPutInServer(i);
        }
    }
}

public void OnClientPutInServer(int client) {
    SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

public Action OnTraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup) {
    int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");

    if (!IsValidEntity(weapon)) {
        return Plugin_Continue;
    }

    char class[32];
    GetEntityClassname(weapon, class, sizeof(class));

    if (StrEqual(class, "weapon_spring", false) || StrEqual(class, "weapon_k98", false)) {
        //1 = Headshot?
        if (hitgroup == 1) {
            damage = 300.0;
        } else {
            damage = 120.0;
        }
        return Plugin_Changed;
    }

    return Plugin_Continue;
}