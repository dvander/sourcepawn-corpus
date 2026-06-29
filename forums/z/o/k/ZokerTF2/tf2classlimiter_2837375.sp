#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_NAME       "TF2 Class Limiter"
#define PLUGIN_VERSION    "1.9"

#define MAX_CLASSES           10
#define MAX_CLASS_SELECTION   2

new Handle:h_AllowedClasses[2];
new g_RandomClasses[2][MAX_CLASS_SELECTION];
bool g_IsDead[MAXPLAYERS+1];

char g_ClassNames[MAX_CLASSES][32] =
{
    "Unknown", "Scout", "Sniper", "Soldier", "Demoman",
    "Medic", "Heavy", "Pyro", "Spy", "Engineer"
};

TFClassType g_ClassEnumMap[MAX_CLASSES] =
{
    TFClass_Scout, TFClass_Scout, TFClass_Sniper, TFClass_Soldier,
    TFClass_DemoMan, TFClass_Medic, TFClass_Heavy, TFClass_Pyro,
    TFClass_Spy, TFClass_Engineer
};

public void OnPluginStart()
{
    HookEvent("teamplay_round_start", OnRoundStart);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", OnPlayerDeath);
    HookEvent("player_changeclass", OnPlayerChangeClass, EventHookMode_Pre);

    for (int i = 0; i < 2; i++)
    {
        h_AllowedClasses[i] = CreateArray(MAX_CLASS_SELECTION);
    }

    ResetAllDeadFlags();
}

void PickRandomClasses()
{
    ClearArray(h_AllowedClasses[0]);
    ClearArray(h_AllowedClasses[1]);

    int classPool[] = {1,2,3,4,5,6,7,8,9};

    // RED team
    ShuffleArray(classPool, sizeof(classPool));
    for (int i = 0; i < MAX_CLASS_SELECTION; i++)
    {
        PushArrayCell(h_AllowedClasses[0], classPool[i]);
        g_RandomClasses[0][i] = classPool[i];
    }

    // BLU team
    ShuffleArray(classPool, sizeof(classPool));
    for (int i = 0; i < MAX_CLASS_SELECTION; i++)
    {
        PushArrayCell(h_AllowedClasses[1], classPool[i]);
        g_RandomClasses[1][i] = classPool[i];
    }
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    PickRandomClasses();
    ResetAllDeadFlags();

    // Orange header, no prefix
    PrintToChatAll("\x07FFA500Class restrictions this round:");

    PrintToChatAll("Red Classes");
    for (int i = 0; i < MAX_CLASS_SELECTION; i++)
    {
        PrintToChatAll("\x07FF0000%s", g_ClassNames[g_RandomClasses[0][i]]);
    }

    PrintToChatAll("Blu Classes");
    for (int i = 0; i < MAX_CLASS_SELECTION; i++)
    {
        PrintToChatAll("\x07007FFF%s", g_ClassNames[g_RandomClasses[1][i]]);
    }

    // Enforce immediately on all alive players
    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientInGame(client) && IsPlayerAlive(client))
        {
            int team = GetClientTeam(client);
            int teamIndex = (team == 2) ? 0 : (team == 3) ? 1 : -1;
            if (teamIndex >= 0)
            {
                int playerClass = TF2_GetPlayerClass(client);
                if (!IsClassAllowedForTeam(playerClass, teamIndex))
                {
                    int forcedClass = g_RandomClasses[teamIndex][GetRandomInt(0, MAX_CLASS_SELECTION - 1)];
                    ForcePlayerClass(client, forcedClass);
                }
            }
        }
    }
}

void ResetAllDeadFlags()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            g_IsDead[i] = false;
        }
    }
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client)) return;

    g_IsDead[client] = false;

    int team = GetClientTeam(client);
    int teamIndex = (team == 2) ? 0 : (team == 3) ? 1 : -1;
    if (teamIndex < 0) return;

    int playerClass = TF2_GetPlayerClass(client);
    if (!IsClassAllowedForTeam(playerClass, teamIndex))
    {
        int forcedClass = g_RandomClasses[teamIndex][GetRandomInt(0, MAX_CLASS_SELECTION - 1)];
        ForcePlayerClass(client, forcedClass);
    }
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (IsClientInGame(client))
    {
        g_IsDead[client] = true;
    }
}

bool IsClassAllowedForTeam(int classIndex, int teamIndex)
{
    int size = GetArraySize(h_AllowedClasses[teamIndex]);
    for (int i = 0; i < size; i++)
    {
        if (classIndex == GetArrayCell(h_AllowedClasses[teamIndex], i))
        {
            return true;
        }
    }
    return false;
}

void ForcePlayerClass(int client, int classIndex)
{
    if (classIndex >= 1 && classIndex < MAX_CLASSES)
    {
        TF2_SetPlayerClass(client, g_ClassEnumMap[classIndex]);
        TF2_RespawnPlayer(client);
    }
}

public Action OnPlayerChangeClass(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!IsClientInGame(client)) return Plugin_Continue;

    if (g_IsDead[client])
        return Plugin_Handled;

    int team = GetClientTeam(client);
    int teamIndex = (team == 2) ? 0 : (team == 3) ? 1 : -1;
    if (teamIndex < 0) return Plugin_Continue;

    int newClass = event.GetInt("class");
    if (!IsClassAllowedForTeam(newClass, teamIndex))
        return Plugin_Handled;

    return Plugin_Continue;
}

void ShuffleArray(int[] array, int length)
{
    for (int i = length - 1; i > 0; i--)
    {
        int j = GetRandomInt(0, i);
        int temp = array[i];
        array[i] = array[j];
        array[j] = temp;
    }
}