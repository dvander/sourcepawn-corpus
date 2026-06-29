#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION      "1.8"
#define FALLBACK_THRESHOLD  30

// Medic command modes
#define MEDIC_MODE_VOICE    0   // voice_medic (default)
#define MEDIC_MODE_SAY      1   // say !medic
#define MEDIC_MODE_SAY_WORD 2   // say medic

bool    g_bSaidMedic[MAXPLAYERS + 1];
ConVar  g_cvThreshold;
ConVar  g_cvMedicMode;
ConVar  g_cvFallbackThreshold;

public Plugin myinfo =
{
    name        = "Bot Auto-Medic",
    author      = "Claude.ai guided by DNA.styx",
    description = "Makes bots use the medic command when health drops below a threshold",
    version     = PLUGIN_VERSION,
    url         = "https://github.com/DNA-styx/DoDS-Bot-Helper-Plugins"
};

public void OnPluginStart()
{
    CreateConVar("dod_bot_medic_version", PLUGIN_VERSION, "Bot Auto-Medic version", FCVAR_NOTIFY);

    g_cvMedicMode = CreateConVar(
        "dod_bot_medic_mode",
        "0",
        "Medic command mode. 0 = voice_medic, 1 = say !medic, 2 = say medic",
        FCVAR_NONE,
        true, 0.0,
        true, 2.0
    );

    g_cvFallbackThreshold = CreateConVar(
        "dod_bot_medic_threshold",
        "30",
        "HP threshold at which bots call for medic. Used if no external medic plugin ConVar is found.",
        FCVAR_NONE,
        true, 1.0,
        true, 100.0
    );

    AutoExecConfig(true, "dod_bot_medic");

    HookEvent("player_spawn", Event_PlayerSpawn);

    // Cache external health ConVars in priority order
    // First found wins; falls back to dod_bot_medic_threshold if none present
    g_cvThreshold = FindConVar("sm_dodmedic_maximum");
    if (g_cvThreshold == null)
        g_cvThreshold = FindConVar("sm_medic_health");
    if (g_cvThreshold == null)
        g_cvThreshold = FindConVar("dod_medic_health_maximum");

    // Hook bots already in-game when the plugin loads mid-map
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i))
            SDKHook(i, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
    }
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        SDKHook(client, SDKHook_OnTakeDamagePost, Hook_OnTakeDamagePost);
}

public void OnClientDisconnect(int client)
{
    g_bSaidMedic[client] = false;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0)
        g_bSaidMedic[client] = false;
}

public void Hook_OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if (!IsClientInGame(victim) || !IsPlayerAlive(victim))
        return;

    if (g_bSaidMedic[victim])
        return;

    // Use external plugin ConVar if found, otherwise use our own threshold
    int threshold = (g_cvThreshold != null) ? g_cvThreshold.IntValue : g_cvFallbackThreshold.IntValue;

    if (GetClientHealth(victim) <= threshold)
    {
        g_bSaidMedic[victim] = true;
        float delay = 2.0 + GetRandomFloat(0.0, 5.0);
        CreateTimer(delay, Timer_SayMedic, GetClientUserId(victim));
    }
}

public Action Timer_SayMedic(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if (client == 0 || !IsClientInGame(client))
        return Plugin_Stop;

    if (!IsPlayerAlive(client))
        return Plugin_Stop;

    switch (g_cvMedicMode.IntValue)
    {
        case MEDIC_MODE_VOICE:    FakeClientCommand(client, "voice_medic");
        case MEDIC_MODE_SAY:      FakeClientCommand(client, "say !medic");
        case MEDIC_MODE_SAY_WORD: FakeClientCommand(client, "say medic");
    }

    return Plugin_Stop;
}
