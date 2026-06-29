// Anti-Camping Plugin für CS:S

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = {
    name = "Anti-Camping",
    author = "Anti-Camp Programmiert von FeritGang",
    description = "Zeigt Warnmeldungen und zieht HP bei Camping ab",
    version = "1.0",
    url = "http://5.189.131.115/cstrike"
};

new Float:fCampTime[MAXPLAYERS + 1];
new Float:LastPosition[MAXPLAYERS + 1][3];
new bool:bWarned[MAXPLAYERS + 1];
new Float:fNextDamageTime[MAXPLAYERS + 1];
new Float:SpawnTime[MAXPLAYERS + 1];

public void OnPluginStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("round_start", Event_RoundStart);
    CreateTimer(1.0, Timer_AntiCamp, _, TIMER_REPEAT);
    for (int i = 1; i <= MaxClients; i++)
    {
        LastPosition[i][0] = 0.0;
        LastPosition[i][1] = 0.0;
        LastPosition[i][2] = 0.0;
        fNextDamageTime[i] = 0.0;
        SpawnTime[i] = 0.0;
    }
}

public void Event_PlayerSpawn(Event ev, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(ev.GetInt("userid"));
    fCampTime[client] = 0.0;
    bWarned[client] = false;
    fNextDamageTime[client] = 0.0;
    SpawnTime[client] = GetEngineTime();
}

public void Event_PlayerDeath(Event ev, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(ev.GetInt("userid"));
    fCampTime[client] = 0.0;
    bWarned[client] = false;
    fNextDamageTime[client] = 0.0;
}

public void Event_RoundStart(Event ev, const char[] name, bool dontBroadcast)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            fCampTime[i] = 0.0;
            bWarned[i] = false;
            LastPosition[i][0] = 0.0;
            LastPosition[i][1] = 0.0;
            LastPosition[i][2] = 0.0;
            fNextDamageTime[i] = 0.0;
            SpawnTime[i] = 0.0;
        }
    }
}

public Action Timer_AntiCamp(Handle timer, any data)
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            float fCurrentTime = GetEngineTime();
            float currentPos[3];
            GetClientAbsOrigin(i, currentPos);

            // Überprüfen, ob der Spieler sich in der Kaufzone befindet (Beispielkoordinaten)
            bool isInBuyZone = (currentPos[0] >= -1000 && currentPos[0] <= 1000 && currentPos[1] >= -1000 && currentPos[1] <= 1000);

            float distance = GetVectorDistanceFixed(currentPos, LastPosition[i]);

            if (distance > 100.0 || (fCurrentTime - SpawnTime[i]) <= 15.0 || isInBuyZone) // Ignorieren beim Bewegen, Spawnen oder in der Kaufzone
            {
                fCampTime[i] = fCurrentTime;
                bWarned[i] = false;
                fNextDamageTime[i] = 0.0;
                LastPosition[i][0] = currentPos[0];
                LastPosition[i][1] = currentPos[1];
                LastPosition[i][2] = currentPos[2];
            }
            else if (fCurrentTime - fCampTime[i] >= 15.0) // 15 Sekunden für die Überprüfung der Position
            {
                if (!bWarned[i])
                {
                    PrintToChat(i, "\x04[Anti-Camp] \x01Bitte bewege dich! Wenn du weiter campst, wirst du Schaden erleiden.");
                    PrintToChat(i, "\x04[Anti-Camp] \x01Please move! If you continue to camp, you will take damage.");
                    bWarned[i] = true;
                }
                else if (fNextDamageTime[i] == 0.0 || fCurrentTime >= fNextDamageTime[i])
                {
                    int health = GetClientHealth(i);
                    SetEntityHealth(i, health - 25);

                    if (health - 25 <= 0)
                    {
                        ForcePlayerSuicide(i);
                        PrintToChat(i, "\x04[Anti-Camp] \x01Du bist gestorben, weil du gecampt hast.");
                        PrintToChat(i, "\x04[Anti-Camp] \x01You have died for camping.");
                    }
                    else
                    {
                        PrintToChat(i, "\x04[Anti-Camp] \x01Du hast 25 HP verloren, weil du gecampt hast.");
                        PrintToChat(i, "\x04[Anti-Camp] \x01You have lost 25 HP for camping.");
                        fNextDamageTime[i] = fCurrentTime + 10.0; // Warte 10 Sekunden, bevor erneut HP abgezogen werden
                    }
                }
            }
        }
    }
    return Plugin_Continue;
}

float GetVectorDistanceFixed(float vec1[3], float vec2[3])
{
    return SquareRoot(Pow(vec1[0] - vec2[0], 2.0) + Pow(vec1[1] - vec2[1], 2.0) + Pow(vec1[2] - vec2[2], 2.0));
}
