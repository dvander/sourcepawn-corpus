#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

new Handle:cvar_FireMilkDuration;

public Plugin:myinfo = 
{
	name = "Fire Milk",
	author = "psychonic, TheSpyHunter, L.Duke, xCoderx, hotgrits",
	description = "Sun-on-a-Stick ignites Mad Milk",
	version = "0.1",
	url = ""
};

public OnPluginStart()
{
	cvar_FireMilkDuration = CreateConVar("sm_firemilkduration", "5.0", "Duration of fire for Mad Milk ignited by the Sun-on-a-Stick.");
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (inflictor > 0 && inflictor <= MaxClients
	&& IsClientInGame(inflictor) && IsClientInGame(victim)
	&& GetClientHealth(victim) > 0)
	{
		if (IsClientInGame(victim) && TF2_IsPlayerInCondition(victim, TFCond_Milked) && GetActiveIndex(attacker) == 349)
		{
			TF2_IgnitePlayer(victim, attacker, GetConVarFloat(cvar_FireMilkDuration));
		}
	}
}
stock bool:IsValidClient(client)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}

stock GetIndexOfWeaponSlot(iClient, iSlot)
{
    return GetWeaponIndex(GetPlayerWeaponSlot(iClient, iSlot));
}

stock GetClientCloakIndex(iClient)
{
    return GetWeaponIndex(GetPlayerWeaponSlot(iClient, TFWeaponSlot_Watch));
}

stock GetWeaponIndex(iWeapon)
{
    return IsValidEntity(iWeapon) ? GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"):-1;
}

stock GetWeaponIndex2(iWeapon) // UNTESTED
{
    if (GetEntSendPropOffs(iWeapon, "m_iItemDefinitionIndex") <= 0)
    {
        return -1;
    }
    return GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");
}

stock GetActiveIndex(iClient)
{
    return GetWeaponIndex(GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"));
}

stock bool:IsWeaponSlotActive(iClient, iSlot)
{
    return GetPlayerWeaponSlot(iClient, iSlot) == GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
}

stock bool:IsIndexActive(iClient, iIndex)
{
    return iIndex == GetWeaponIndex(GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon"));
}

stock bool:IsSlotIndex(iClient, iSlot, iIndex)
{
    return iIndex == GetIndexOfWeaponSlot(iClient, iSlot);
}

stock bool:IsSlotReloading(iClient, iSlot)
{
    new iWep = GetPlayerWeaponSlot(iClient, iSlot);
    if (!IsValidEntity(iWep))
    {
        return false;
    }
    return GetEntProp(iWeapon, Prop_Send, "m_iReloadMode");
}

stock bool:IsSlotWeapon(iClient, iSlot, iWeapon)
{
    return iWeapon == GetPlayerWeaponSlot(iClient, iSlot);
}

stock bool:IsReloading(iWeapon)
{
    return GetEntProp(iWeapon, Prop_Send, "m_iReloadMode");
}

stock bool:IsValidWeapon(iWeapon)
{
    decl String:szClassname[7];

    if (!IsValidEntity(iWeapon) || !GetEdictClassname(iWeapon, szClassname, sizeof(szClassname)))
    {
        return false;
    }

    return (StrStarts(szClassname, "tf_wea", false) || StrStarts(szClassname, "saxxy", false));
} 	