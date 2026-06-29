#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo = 
{    
    name         = "SpectatorRank",    
    author       = "Programmiert von FeritGang",    
    description  = "Zeigt Statistiken für den beobachteten Spieler im Zuschauermodus an.",    
    version      = "1.2",
};

// Statistiken
new     g_PlayerKills[MAXPLAYERS + 1];    
new     g_PlayerShotsFired[MAXPLAYERS + 1];    
new     g_PlayerShotsHit[MAXPLAYERS + 1];    
new     g_PlayerPlayTime[MAXPLAYERS + 1]; // Minuten gespielt

public void OnPluginStart()
{    
    HookEvent(       "player_death", Event_PlayerDeath, EventHookMode_Pre    );    
    HookEvent(       "weapon_fire",  Event_WeaponFire,  EventHookMode_Pre    );    
    HookEvent(       "player_hurt",  Event_PlayerHurt,  EventHookMode_Pre    ); // Erfasst Treffer    
    CreateTimer(     1.0, UpdateSpectatorStats, _, TIMER_REPEAT             ); // Aktualisiert Statistiken jede Sekunde    
    CreateTimer(     60.0, TrackPlayerPlayTime, _, TIMER_REPEAT             ); // Spielzeit pro Minute aktualisieren    
    PrintToServer(   "[SpectatorRank] Plugin aktiviert!"                    );
}

// Funktion zur Berechnung des Rangs
int GetPlayerRank(int client)
{    
    return g_PlayerKills[client] / 100; // Einfacher Rang basierend auf Kills
}

// Funktion zur Berechnung der Genauigkeit
float GetPlayerAccuracy(int client)
{    
    int shotsFired = g_PlayerShotsFired[client];    
    int shotsHit   = g_PlayerShotsHit[client];

    if (shotsFired == 0)     
    {        
        return 0.0; // Verhindert Division durch null    
    }

    return (float(shotsHit) / float(shotsFired)) * 100.0;
}

// Funktion zur Anzeige der Statistiken im Zuschauermodus
void DisplayStatsForSpectator(int spectator, int target)
{    
    int rank         = GetPlayerRank(target);    
    int kills        = g_PlayerKills[target];    
    int deaths       = GetClientDeaths(target);    
    float kdr        = kills / (float)(deaths + 1);    
    int bonusPoints  = kills * 10;    
    int level        = bonusPoints / 1000;    
    float accuracy   = GetPlayerAccuracy(target);    
    float hours      = g_PlayerPlayTime[target] / 60.0;

    char stats[512];    
    Format(stats, sizeof(stats), 
           "Rank: %d\nKills: %d\nDeaths: %d\nK/D: %.4f\nBonus Points: %d (Level %d)\nAccuracy: %.2f%%\nHours: %.2f h",    
           rank, kills, deaths, kdr, bonusPoints, level, accuracy, hours);

    // Position weiter nach links verschoben
    SetHudTextParams(0.75, 0.30, 1.0, 255, 255, 255, 255);

    ShowHudText(spectator, 2, stats); 
}

// Benutzerdefinierte Funktion für GetClientObserverTarget
int GetClientObserverTarget(int client)
{    
    if (!IsClientInGame(client) || !IsClientObserver(client))    
    {        
        return -1; // Kein Ziel    
    }    
    return GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
}

// Timer, um die Statistiken für Zuschauer zu aktualisieren
public Action UpdateSpectatorStats(Handle timer)
{    
    for (int i = 1; i <= MaxClients; i++)    
    {        
        if (IsClientConnected(i) && IsClientInGame(i) && IsClientObserver(i))        
        {            
            int target = GetClientObserverTarget(i);            
            if (target > 0 && IsClientConnected(target) && IsClientInGame(target))            
            {                
                DisplayStatsForSpectator(i, target);            
            }        
        }    
    }    
    return Plugin_Continue;
}

// Events zur Verarbeitung der Statistiken
public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{    
    int killer       = GetEventInt(event, "attacker");    
    int killerIndex  = GetClientOfUserId(killer);    
    if (killerIndex > 0)    
    {        
        g_PlayerKills[killerIndex]++;    
    }    
    return Plugin_Continue;
}

public Action Event_WeaponFire(Handle event, const char[] name, bool dontBroadcast)
{    
    int client       = GetEventInt(event, "userid");    
    int clientIndex  = GetClientOfUserId(client);    
    if (clientIndex > 0)    
    {        
        g_PlayerShotsFired[clientIndex]++;    
    }    
    return Plugin_Continue;
}

// Neues Event: Treffer erfassen
public Action Event_PlayerHurt(Handle event, const char[] name, bool dontBroadcast)
{    
    int attacker       = GetEventInt(event, "attacker");    
    int attackerIndex  = GetClientOfUserId(attacker);    
    if (attackerIndex > 0)    
    {        
        g_PlayerShotsHit[attackerIndex]++;    
    }    
    return Plugin_Continue;
}

// Timer für die Spielzeitverfolgung
public Action TrackPlayerPlayTime(Handle timer)
{    
    for (int i = 1; i <= MaxClients; i++)    
    {        
        if (IsClientConnected(i) && IsClientInGame(i))        
        {            
            g_PlayerPlayTime[i]++;        
        }    
    }    
    return Plugin_Continue;
}