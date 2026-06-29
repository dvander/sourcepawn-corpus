#include <sourcemod>
#include <sdkhooks>

new bool:g_IsGhostMode[MAXPLAYERS + 1]; // Zustand des Geist-Modus
new float:g_LastOrigin[MAXPLAYERS + 1][3]; // Speicherung der letzten Position

const float MOVEMENT_THRESHOLD = 20.0; // Bewegungsschwelle für echtes Laufen

public Plugin:myinfo = {
    name = "GhostGuard",
    author = "Programmiert von FeritGang",
    description = "Geist-Modus: Spieler/Bots bleiben unverwundbar nur bei Respawn",
    version = "1.5",
    url = ""
};

public void OnPluginStart() {
    HookEvent("player_spawn", OnPlayerSpawnEvent, EventHookMode_Post);
    HookEvent("player_hurt", OnPlayerHurtEvent);   // Jeglichen Schaden blockieren
    HookEvent("player_death", OnPlayerDeathEvent); // Verhindere Kills im Geist-Modus
    CreateTimer(0.1, CheckPlayerMovement, _, TIMER_REPEAT); // Bewegung regelmäßig prüfen
}

public Action OnPlayerSpawnEvent(Handle:event, const String:name[], bool:dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsValidClient(client)) {
        ActivateGhostMode(client); // Geist-Modus nur beim Spawn aktivieren
        GetClientAbsOrigin(client, g_LastOrigin[client]); // Position initialisieren
    }

    return Plugin_Continue;
}

public Action OnPlayerHurtEvent(Handle:event, const String:name[], bool:dontBroadcast) {
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsValidClient(victim) && g_IsGhostMode[victim]) {
        // Blockiere jeglichen Schaden vollständig
        SetEventInt(event, "damage", 0); // Schaden auf null setzen
        SetEntProp(victim, Prop_Data, "m_iHealth", 100); // Gesundheit fest auf 100 setzen
        return Plugin_Handled; // Keine weitere Verarbeitung erlauben
    }

    return Plugin_Continue;
}

public Action OnPlayerDeathEvent(Handle:event, const String:name[], bool:dontBroadcast) {
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));

    if (IsValidClient(victim) && g_IsGhostMode[victim]) {
        // Verhindere den Tod vollständig, solange der Geist-Modus aktiv ist
        return Plugin_Handled;
    }

    return Plugin_Continue;
}

public Action CheckPlayerMovement(Handle:timer, any:data) {
    for (int client = 1; client <= MaxClients; client++) {
        if (IsValidClient(client) && g_IsGhostMode[client]) {
            float currentOrigin[3];
            GetClientAbsOrigin(client, currentOrigin);

            // Berechnung der zurückgelegten Distanz
            float distance = SquareRoot(
                Pow(currentOrigin[0] - g_LastOrigin[client][0], 2.0) +
                Pow(currentOrigin[1] - g_LastOrigin[client][1], 2.0) +
                Pow(currentOrigin[2] - g_LastOrigin[client][2], 2.0)
            );

            if (distance > MOVEMENT_THRESHOLD) {
                DeactivateGhostMode(client); // Modus deaktivieren bei echter Bewegung
            }

            // Position aktualisieren
            g_LastOrigin[client][0] = currentOrigin[0];
            g_LastOrigin[client][1] = currentOrigin[1];
            g_LastOrigin[client][2] = currentOrigin[2];
        }
    }

    return Plugin_Continue;
}

void ActivateGhostMode(int client) {
    g_IsGhostMode[client] = true; // Geist-Modus aktivieren
    SetEntityRenderMode(client, RENDER_TRANSCOLOR); // Spieler transparent machen
    SetEntProp(client, Prop_Send, "m_clrRender", 100 << 24 | 255 << 16 | 255 << 8 | 255); // Transparenz setzen
}

void DeactivateGhostMode(int client) {
    if (IsValidClient(client) && g_IsGhostMode[client]) {
        g_IsGhostMode[client] = false; // Geist-Modus deaktivieren
        SetEntityRenderMode(client, RENDER_NORMAL); // Normaler Modus
        SetEntProp(client, Prop_Send, "m_clrRender", 255 << 24 | 255 << 16 | 255 << 8 | 255); // Sichtbarkeit setzen
    }
}

bool:IsValidClient(int client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client);
}