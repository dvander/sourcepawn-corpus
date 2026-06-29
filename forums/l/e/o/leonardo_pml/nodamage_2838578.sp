#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo = 
{
    name = "NoDamage",
    author = "SERASA & EV",
    description = "Desabilita o dano entre jogadores de times diferentes",
    version = "1.1.0",
    url = "https://www.gametracker.com/server_info/191.209.110.83:27015/"
};

bool g_NoDamageEnabled = true;

public void OnPluginStart()
{
    LoadTranslations("nodamage.phrases");
    RegAdminCmd("sm_nodamage", Command_ToggleNoDamage, ADMFLAG_GENERIC, "Ativa ou desativa a proteção contra dano entre jogadores (exceto auto-dano).");

    // Hook de dano
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_NoDamageEnabled)
    {
        return Plugin_Continue;
    }

    if (victim == attacker)
    {
        return Plugin_Continue; // Auto-dano permitido
    }

    if (IsValidClient(attacker))
    {
        return Plugin_Handled; // Bloqueia dano de outros jogadores
    }

    return Plugin_Continue;
}

public Action Command_ToggleNoDamage(int client, int args)
{
    g_NoDamageEnabled = !g_NoDamageEnabled;

    char statusKey[32];
    if (g_NoDamageEnabled)
    {
        strcopy(statusKey, sizeof(statusKey), "status_enabled");
    }
    else
    {
        strcopy(statusKey, sizeof(statusKey), "status_disabled");
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            char translatedStatus[64];
            Format(translatedStatus, sizeof(translatedStatus), "%T", statusKey, i);

            PrintToChat(i, "%T", "status_changed", i, translatedStatus);
        }
    }

    return Plugin_Handled;
}
bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}
