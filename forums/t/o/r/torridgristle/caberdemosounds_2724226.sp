#include <sourcemod>
#include <sdktools>
#include <tf2>

#pragma semicolon 1

public Plugin myinfo = 
{
    name = "Caberdemo Scream",
    author = "hotgrits",
    description = "Caberdemo Scream",
    version = "0.2",
    url = ""    
}

public OnPluginStart()
{
	AddFileToDownloadsTable("sound/skibidibopmmdada.wav");
	PrecacheSound("skibidibopmmdada.wav");
}

public OnMapStart()
{
	PrecacheSound("skibidibopmmdada.wav");
}

public void TF2_OnConditionAdded(client, TFCond:cond)
{
	if (cond == TFCond_Charging)
	{
	if (GetActiveIndex(client) == 307)
	{
	EmitSoundToAll("skibidibopmmdada.wav", client);
	}
	}
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