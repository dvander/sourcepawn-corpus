#pragma semicolon 1
#include <cstrike>
#include <sdktools>
#include <sourcemod>
#include <string>

// SPECTATOR MODES
#define SPECMODE_NONE 0
#define SPECMODE_FIRSTPERSON 4
#define SPECMODE_THIRDPERSON 5
#define SPECMODE_FREELOOK 6

// PLUGIN-INFORMATIONEN
#define PLUGIN_NAME "CS:S Bot Control"
#define PLUGIN_AUTHOR "Programmiert von FeritGang"
#define PLUGIN_DESCRIPTION "Bot Control wie bei CS:GO"
#define PLUGIN_VERSION "1.3.1"
#define PLUGIN_URL "http://5.189.131.115/ctrike"

#define ADMIN_FILE_PATH "addons/sourcemod/configs/admins_simple.ini"

public Plugin:myinfo = {
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version = PLUGIN_VERSION,
    url = PLUGIN_URL
}

bool warnedClients[MAXPLAYERS + 1];

public void OnPluginStart() {
    HookEvent("player_death", Event_PlayerDeath);
    // Registriere den Konsolenbefehl zum Übernehmen eines Bots
    RegConsoleCmd("sm_takeoverbot", Command_TakeOverBot);
    // Initialisiere gewarnte Clients
    for (int i = 0; i <= MAXPLAYERS; i++) {
        warnedClients[i] = false;
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IsClientAdmin(client)) {
        PrintToChat(client, "\x04Du kannst einen Bot übernehmen, indem du während des Zuschauens die E-Taste drückst!");
    }
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
    int iTarget, iSpecMode, iFrags, iDeaths;
    float teleportDestination[3];
    float anglesDestination[3];
    float velocityDestination[3];

    // Wenn der Spieler die Verwendungstaste drückt
    if ((buttons & IN_USE)) {
        // Stellen Sie sicher, dass der Spieler tot ist
        if (!IsPlayerAlive(client)) {
            iSpecMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
            // Wenn der Client niemanden beobachtet, ignorieren
            if (iSpecMode != SPECMODE_FIRSTPERSON && iSpecMode != SPECMODE_THIRDPERSON)
                return Plugin_Continue;

            // Ziel erhalten
            iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
            // Stellen Sie sicher, dass der Spieler ein Bot ist
            if (!IsFakeClient(iTarget))
                return Plugin_Continue;

            // Stellen Sie sicher, dass das Ziel lebt
            if (!IsPlayerAlive(iTarget))
                return Plugin_Continue;

            // Stellen Sie sicher, dass sie im selben Team sind
            if (GetClientTeam(iTarget) != GetClientTeam(client))
                return Plugin_Continue;

            // Überprüfen Sie, ob der Client ein Admin ist
            if (!IsClientAdmin(client)) {
                if (!warnedClients[client]) {
                    PrintToChat(client, "\x04[Fehler] Du hast keine Berechtigung, einen Bot zu übernehmen.");
                    warnedClients[client] = true;
                }
                return Plugin_Handled;
            }

            CS_RespawnPlayer(client);
            GetClientAbsOrigin(iTarget, teleportDestination);
            teleportDestination[2] = teleportDestination[2] + 16;
            GetClientAbsAngles(iTarget, anglesDestination);
            GetEntPropVector(iTarget, Prop_Data, "m_vecVelocity", velocityDestination);
            TeleportEntity(client, teleportDestination, anglesDestination, velocityDestination);

            // Bot töten und aufräumen
            iFrags = GetClientFrags(iTarget);
            iDeaths = GetClientDeaths(iTarget);
            ForcePlayerSuicide(iTarget);
            RemoveBody(iTarget);
            SetEntProp(iTarget, Prop_Data, "m_iFrags", iFrags);
            SetEntProp(iTarget, Prop_Data, "m_iDeaths", iDeaths);
        }
    }
    return Plugin_Continue;
}

// Befehl zum Übernehmen des Bots
public Action Command_TakeOverBot(int client, int args) {
    // Überprüfen, ob der Benutzer Admin ist
    if (!IsClientAdmin(client)) {
        // Nachricht anzeigen, wenn der Benutzer kein Admin ist
        if (!warnedClients[client]) {
            PrintToChat(client, "\x04[Fehler] Du hast keine Berechtigung, diesen Befehl zu verwenden.");
            warnedClients[client] = true;
        }
        return Plugin_Handled;
    }

    // Benachrichtige den Spieler, die Verwendungstaste zu drücken
    PrintToChat(client, "\x04Drücke deine E-Taste, während du einen Bot beobachtest, um den Bot zu übernehmen.");
    return Plugin_Handled;
}

// Funktion zur Überprüfung, ob der Client Admin ist
stock bool:IsClientAdmin(int client) {
    char authId[32];
    GetClientAuthId(client, AuthId_Steam2, authId, sizeof(authId));
    
    File adminFile = OpenFile(ADMIN_FILE_PATH, "r");
    if (adminFile == null) {
        PrintToServer("[Fehler] Konnte die Datei admins_simple.ini nicht öffnen.");
        return false;
    }

    bool isAdmin = false;
    char line[256];
    while (ReadFileLine(adminFile, line, sizeof(line))) {
        if (StrContains(line, authId, false) != -1) {
            isAdmin = true;
            break;
        }
    }

    CloseHandle(adminFile);
    return isAdmin;
}

// Entfernen des Körpers
stock RemoveBody(int client) {
    // Deklaration
    int BodyRagdoll;
    char Classname[64];

    // Initialisierung
    BodyRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
    if (IsValidEdict(BodyRagdoll)) {
        // Klasse finden
        GetEdictClassname(BodyRagdoll, Classname, sizeof(Classname));
        // Entfernen
        if (StrEqual(Classname, "cs_ragdoll", false))
            RemoveEdict(BodyRagdoll);
    }
}
