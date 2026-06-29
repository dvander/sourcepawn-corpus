#include <sdkhooks>
#include <sourcemod>
#include <cfgmap>
#include <ff2r>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

float g_NormalDamage[MAXPLAYERS + 1] = {0.0, ...};
float g_RJDamage[MAXPLAYERS + 1] = {0.0, ...};
bool  g_Active[MAXPLAYERS + 1];

public Plugin myinfo =
{
    name    = "[FF2R] Market Gardener",
    author  = "Emir42502, Gaming.",
    version = "1.1"
};

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
    PrintToChatAll("[FF2R Market Gardener] Plugin started");
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_Active[client] = false;
	g_NormalDamage[client] = 0.0;
	g_RJDamage[client] = 0.0;
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	g_Active[client] = false;
}

public void FF2R_OnAbility(int client, const char[] ability, AbilityData cfg)
{
    PrintToChatAll("[FF2R Market Gardener] OnAbility called for %N ability: %s", client, ability);

    if (StrContains(ability, "special_market", false) != -1)
    {
        g_NormalDamage[client] = cfg.GetFloat("normal_damage", 60.0);
		g_RJDamage[client] = cfg.GetFloat("rj_damage", 500.0);
		PrintToChatAll("[FF2R Market Gardener] Ability does NOT belong to this plugin");
        return;
    }
	else
	{
		PrintToChatAll("[FF2R Market Gardener] Ability match confirmed");
	}

    PrintToChatAll("[FF2R Market Gardener] Ability activated for %N! Normal=%.1f RJ=%.1f", client, g_NormalDamage[client], g_RJDamage[client]);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (attacker <= 0 || attacker > MaxClients || !IsClientInGame(attacker))
        return Plugin_Continue;
	
	if (g_RJDamage[attacker] <= 0.0)
        return Plugin_Continue;

    if (!g_Active[attacker])
        return Plugin_Continue;

    int weapon = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
    if (weapon <= 0)
        return Plugin_Continue;

    int weaponIndex = -1;
    if (IsValidEntity(weapon))
    {
        weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
    }
    else 
    {
        // Fallback: check active weapon
        int activeWep = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
        if (IsValidEntity(activeWep))
            weaponIndex = GetEntProp(activeWep, Prop_Send, "m_iItemDefinitionIndex");
    }

    if (weaponIndex != 416)
        return Plugin_Continue;

    // 4. Apply custom damage logic
    if (TF2_IsPlayerInCondition(attacker, TFCond_BlastJumping))
    {
        damage = g_RJDamage[attacker];
        // Strip Crit/Mini-Crit flags to force our exact number
        damagetype &= ~DMG_CRIT;
        damagetype |= DMG_GENERIC; 
    }
    else
    {
        damage = g_NormalDamage[attacker];
    }

    // DEBUG: This will tell us if the code actually reached the "Apply" stage
    PrintToConsoleAll("[FF2R] DEBUG: Forcing %N damage to %.1f", attacker, damage);

    return Plugin_Changed;
}
