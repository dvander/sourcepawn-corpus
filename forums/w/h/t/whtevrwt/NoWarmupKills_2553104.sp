#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "Warmup: No Killing!",
	author = "shanapu",
	description = "Disables killing each other during a warmup.",
	version = "1.1",
	url = "https://forums.alliedmods.net/showthread.php?t=301871"
};

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_TraceAttack, OnTraceAttackOnTakeDamage);
    SDKHook(client, SDKHook_OnTakeDamage, OnTraceAttackOnTakeDamage);
}

public Action OnTraceAttackOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
    if (GameRules_GetProp("m_bWarmupPeriod") != 1)
    {
        return Plugin_Continue;
    }

    if (!IsValidClient(victim) || attacker == victim || !IsValidClient(attacker))
    {
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

bool IsValidClient(int client)
{
    if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client))
    {
        return false;
    }
    return true;
}