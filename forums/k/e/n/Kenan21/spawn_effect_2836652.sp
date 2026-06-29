#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = {
    name = "Sky Beam & Spawn Effect",
    author = "Kenan",
    description = "Erzeugt Spawn-Effekte und Lichtstrahlen vom Himmel",
    version = "1.9",
    url = "https://example.com"
};

public void OnPluginStart() {
    PrintToServer("Sky Beam & Spawn Effect Plugin gestartet!");

    // Dateien vorladen und zum Download bereitstellen
    PrecacheEffectFiles();

    // Events hooken
    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
    HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
}

// Effekt-Dateien vorladen und bereitstellen
void PrecacheEffectFiles() {
    char vmtPath[PLATFORM_MAX_PATH];
    char vtfPath[PLATFORM_MAX_PATH];

    // Setze die Dateipfade
    Format(vmtPath, sizeof(vmtPath), "materials/sprites/spawn_effect.vmt");
    Format(vtfPath, sizeof(vtfPath), "materials/sprites/spawn_effect.vtf");

    // Überprüfen, ob Dateien existieren und sie zum Download hinzufügen
    if (FileExists(vmtPath, true)) {
        AddFileToDownloadsTable(vmtPath);
        PrintToServer("Datei zum Download hinzugefügt: %s", vmtPath);
    } else {
        PrintToServer("WARNUNG: %s nicht gefunden!", vmtPath);
    }

    if (FileExists(vtfPath, true)) {
        AddFileToDownloadsTable(vtfPath);
        PrintToServer("Datei zum Download hinzugefügt: %s", vtfPath);
    } else {
        PrintToServer("WARNUNG: %s nicht gefunden!", vtfPath);
    }
}

// Event: Spieler-Spawn (inkl. Bots)
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (client > 0 && client <= MaxClients && IsClientInGame(client)) {
        CreateSpawnEffect(client); // Spawn-Effekt erzeugen
        CreateSkyBeamEffect(client); // Himmelstrahl erzeugen
    }
}

// Event: Rundenbeginn (inkl. Bots)
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    for (int client = 1; client <= MaxClients; client++) {
        if (IsClientInGame(client)) {
            CreateSpawnEffect(client); // Spawn-Effekt erzeugen
            CreateSkyBeamEffect(client); // Himmelstrahl erzeugen
        }
    }
}

// **1. Spawn-Effekt erstellen**
void CreateSpawnEffect(int client) {
    float origin[3];
    GetClientAbsOrigin(client, origin); // Spielerposition abrufen

    // Höhe des Effekts anpassen, um ihn über dem Spieler sichtbar zu machen
    origin[2] += 75.0;

    PrintToServer("Spawn Effekt erstellen an Position: X=%.2f Y=%.2f Z=%.2f", origin[0], origin[1], origin[2]);

    int entity = CreateEntityByName("env_sprite");
    if (entity == -1) {
        PrintToServer("Fehler: Entität 'env_sprite' konnte nicht erstellt werden!");
        return;
    }

    // Sprite-Eigenschaften setzen
    DispatchKeyValue(entity, "model", "materials/sprites/spawn_effect.vmt");
    DispatchKeyValue(entity, "scale", "3.0"); // Größe des Sprites anpassen
    DispatchKeyValue(entity, "rendermode", "5"); // Glühen aktivieren
    DispatchKeyValue(entity, "renderfx", "14");  // Konstantes Leuchten
    DispatchSpawn(entity);
    TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR); // Position über dem Spieler
    PrintToServer("Spawn Effekt erfolgreich erstellt für Client %d", client);

    // Automatisches Entfernen des Spawn-Effekts nach 2 Sekunden
    CreateTimer(2.0, RemoveSpawnEffect, entity);
}

// Spawn-Effekt entfernen
public Action RemoveSpawnEffect(Handle timer, int entity) {
    if (IsValidEntity(entity)) {
        AcceptEntityInput(entity, "Kill"); // Entfernt die Entität
        PrintToServer("Spawn Effekt entfernt: Entity %d", entity);
    }
    return Plugin_Continue;
}

// **2. Himmelstrahl-Effekt erstellen**
void CreateSkyBeamEffect(int client) {
    float origin[3];
    GetClientAbsOrigin(client, origin); // Spielerposition abrufen

    // Deklariere das Ziel-Array für den Strahl
    float top[3];

    // Weise Werte nach der Deklaration zu
    top[0] = origin[0];
    top[1] = origin[1];
    top[2] = origin[2] + 1500.0; // 1500 Einheiten nach oben für den Strahl

    PrintToServer("Sky Beam Effekt erstellen an Position: X=%.2f Y=%.2f Z=%.2f", top[0], top[1], top[2]);

    int entity = CreateEntityByName("env_beam");
    if (entity == -1) {
        PrintToServer("Fehler: Entität 'env_beam' konnte nicht erstellt werden!");
        return;
    }

    // Effekt konfigurieren
    DispatchKeyValue(entity, "texture", "materials/sprites/spawn_effect.vmt");
    DispatchKeyValueVector(entity, "origin", origin); // Startpunkt des Strahls
    DispatchKeyValueVector(entity, "targetname", top); // Endpunkt des Strahls
    DispatchKeyValue(entity, "rendercolor", "255 255 255"); // Rein weißer Strahl
    DispatchKeyValue(entity, "renderamt", "200"); // Transparenz
    DispatchKeyValue(entity, "life", "2"); // 2 Sekunden Lebensdauer
    DispatchKeyValue(entity, "width", "15"); // Breite des Strahls
    DispatchKeyValue(entity, "HaloScale", "0.0"); // Keine Verfärbung durch Halo
    DispatchSpawn(entity);

    // Automatisches Entfernen des Himmelstrahls nach 2 Sekunden
    CreateTimer(2.0, RemoveSkyBeamEffect, entity);

    PrintToServer("Sky Beam Effekt erfolgreich erstellt für Client %d", client);
}

// Himmelstrahl-Effekt entfernen
public Action RemoveSkyBeamEffect(Handle timer, int entity) {
    if (IsValidEntity(entity)) {
        AcceptEntityInput(entity, "Kill"); // Entfernt die Entität
        PrintToServer("Sky Beam Effekt entfernt: Entity %d", entity);
    }
    return Plugin_Continue;
}