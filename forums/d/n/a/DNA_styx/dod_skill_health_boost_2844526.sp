#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <timers>

#undef REQUIRE_PLUGIN
#include <hlstatsx_api>
#define REQUIRE_PLUGIN

#define PLUGIN_VERSION "1.9.0"

bool g_bHLStatsApi = false;

int  g_iSkill[MAXPLAYERS + 1];
bool g_bStatsReady[MAXPLAYERS + 1];

ConVar g_cvBoostHP;
ConVar g_cvSkillMax;
ConVar g_cvDebug;

char g_sLogFilePath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
    name        = "DoD Skill Based Health Boost",
    author      = "By ChatGPT, guided by DNA.styx",
    description = "Boost new player's health based on HLStatsX skill",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/DNA-styx/DoD_Skill_Based_Health_Boost"
};

public void OnPluginStart()
{
    // Auto-generate config file
    AutoExecConfig(true, "dod_skill_health_boost");

    // ConVars
    g_cvBoostHP  = CreateConVar("dod_skill_hp", "200",
        "Health to give players below the skill threshold",
        FCVAR_PLUGIN, true, 1.0, true, 500.0);

    g_cvSkillMax = CreateConVar("dod_skill_max", "1000",
        "Maximum HLStatsX skill to receive health boost",
        FCVAR_PLUGIN, true, 0.0, true, 1000000.0);

    g_cvDebug    = CreateConVar("dod_skill_debug", "1",
        "Enable debug logging (1 = on, 0 = off)",
        FCVAR_PLUGIN, true, 0.0, true, 1.0);

    // Log file
    BuildPath(Path_SM, g_sLogFilePath, sizeof(g_sLogFilePath),
        "logs/dod_skill_health_boost.log");

    if (g_cvDebug.BoolValue)
    {
        LogToFile(g_sLogFilePath,
            "[PLUGIN START] DoD Skill Based Health Boost loaded.");
    }

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    for (int i = 1; i <= MaxClients; i++)
    {
        g_bStatsReady[i] = false;
        g_iSkill[i] = 0;
    }
}

public void OnAllPluginsLoaded()
{
    g_bHLStatsApi = LibraryExists("hlstatsx_api");
}

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "hlstatsx_api"))
        g_bHLStatsApi = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if (StrEqual(name, "hlstatsx_api"))
        g_bHLStatsApi = false;
}

public void OnClientDisconnect(int client)
{
    g_bStatsReady[client] = false;
    g_iSkill[client] = 0;
}

//---------------------------------------------------------
// Player spawn
//---------------------------------------------------------
public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (!IsValidClient(client, false, false))
        return Plugin_Continue;

    // Request HLStats only once
    if (!g_bStatsReady[client])
    {
        RequestHLStats(client);
    }

    // Apply boost if stats are ready
    if (g_bStatsReady[client])
    {
        ApplySkillHealthBoost(client);
    }

    return Plugin_Continue;
}

//---------------------------------------------------------
// HLStats request
//---------------------------------------------------------
void RequestHLStats(int client)
{
    if (!g_bHLStatsApi || !IsValidClient(client, true, false))
        return;

    char nameBuf[64];
    GetClientName(client, nameBuf, sizeof(nameBuf));

    bool ok = HLStatsX_Api_GetStats("playerinfo",
                                   client,
                                   HLStats_Response,
                                   0);

    if (g_cvDebug.BoolValue)
    {
        LogToFile(g_sLogFilePath,
            "[REQUEST] HLStats query for %s (%d) returned %d",
            nameBuf, client, ok ? 1 : 0);
    }

    if (!ok)
    {
        CreateTimer(3.0, Timer_HLStatsRetry, client);
    }
}

//---------------------------------------------------------
// Timer callback for retry
//---------------------------------------------------------
public Action Timer_HLStatsRetry(Handle timer, any client)
{
    if (IsValidClient(client, true, false))
    {
        if (g_cvDebug.BoolValue)
        {
            char nameBuf[64];
            GetClientName(client, nameBuf, sizeof(nameBuf));

            LogToFile(g_sLogFilePath,
                "[RETRY] Retrying HLStats query for %s (%d)",
                nameBuf, client);
        }

        RequestHLStats(client);
    }

    return Plugin_Stop;
}

//---------------------------------------------------------
// HLStats callback
//---------------------------------------------------------
public void HLStats_Response(int command, int payload, int client, DataPack &datapack)
{
    if (!IsValidClient(client, true, false))
    {
        delete datapack;
        return;
    }

    DataPack pack = view_as<DataPack>(CloneHandle(datapack));

    pack.ReadCell();            // rank (ignored)
    int skill = pack.ReadCell();
    pack.ReadCell();            // kills
    pack.ReadCell();            // deaths
    pack.ReadFloat();           // kd

    g_iSkill[client] = skill;
    g_bStatsReady[client] = true;

    if (g_cvDebug.BoolValue)
    {
        char nameBuf[64];
        GetClientName(client, nameBuf, sizeof(nameBuf));

        LogToFile(g_sLogFilePath,
            "[RESPONSE] HLStats skill for %s (%d): %d",
            nameBuf, client, skill);
    }

    // --- IMMEDIATE BOOST if player alive ---
    if (IsPlayerAlive(client) && GetClientTeam(client) > 1)
    {
        ApplySkillHealthBoost(client);
    }

    delete datapack;
    delete pack;
}

//---------------------------------------------------------
// Apply the boost (centralized)
//---------------------------------------------------------
void ApplySkillHealthBoost(int client)
{
    int skillThreshold = g_cvSkillMax.IntValue;
    int boostHp = g_cvBoostHP.IntValue;

    if (g_iSkill[client] <= skillThreshold)
    {
        SetEntityHealth(client, boostHp);

        if (g_cvDebug.BoolValue)
        {
            char nameBuf[64];
            GetClientName(client, nameBuf, sizeof(nameBuf));

            LogToFile(g_sLogFilePath,
                "[BOOST] %s (%d) | skill=%d <= %d | health=%d",
                nameBuf, client, g_iSkill[client], skillThreshold, boostHp);
        }
    }
}

//---------------------------------------------------------
// Client validation
//---------------------------------------------------------
bool IsValidClient(int client, bool allowDead = true, bool allowBots = false)
{
    if (client < 1 || client > MaxClients) return false;
    if (!IsClientInGame(client)) return false;
    if (IsClientSourceTV(client) || IsClientReplay(client)) return false;
    if (IsFakeClient(client) && !allowBots) return false;
    if (!allowDead && !IsPlayerAlive(client)) return false;
    if (GetClientTeam(client) <= 1) return false;
    return true;
}
