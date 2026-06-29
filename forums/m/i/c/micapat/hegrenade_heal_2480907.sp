// =========================================================================
// HeGrenade Heal -- Modify the HeGrenade to heal teammates
// =========================================================================

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls  required

// =========================================================================

public Plugin myinfo =
{
    name        = "HeGrenade Heal",
    author      = "Nyuu",
    description = "Modify the HeGrenade to heal teammates",
    version     = "1.0.0",
    url         = "https://forums.alliedmods.net/showthread.php?t=291969"
}

// =========================================================================

public void OnClientPutInServer(int iClient)
{
    SDKHook(iClient, SDKHook_OnTakeDamage, OnPlayerTakeDamage);
}

public Action OnPlayerTakeDamage(int iPlayer, int &iAttacker, int &iInflictor, float &flDamage, int &iDamageType)
{
    if ((1 <= iAttacker <= MaxClients) && (iAttacker != iInflictor) && (GetClientTeam(iPlayer) == GetClientTeam(iAttacker)))
    {
        static char szClassname[32];
        GetEdictClassname(iInflictor, szClassname, sizeof(szClassname));
        
        if (StrEqual(szClassname, "hegrenade_projectile"))
        {
            int iMaxHealth = GetEntProp(iPlayer, Prop_Data, "m_iMaxHealth");
            int iHealth    = GetEntProp(iPlayer, Prop_Send, "m_iHealth");
            
            if (iHealth < iMaxHealth)
            {
                iHealth = iHealth + RoundFloat(flDamage);
                
                if (iHealth > iMaxHealth)
                {
                    SetEntProp(iPlayer, Prop_Send, "m_iHealth", iMaxHealth);
                }
                else
                {
                    SetEntProp(iPlayer, Prop_Send, "m_iHealth", iHealth);
                }
            }
            
            return Plugin_Handled;
        }
    }
    
    return Plugin_Continue;
}

// =========================================================================
