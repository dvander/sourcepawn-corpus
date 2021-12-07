#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombiereloaded>

#define MELEE_WEAPON_SLOT	2

public Plugin:myinfo = 
{
    name = "Karambit for Zombie Escape",
    author = "ceLoFaN",
    version = "1.0"
}

public OnPluginStart()
{
	HookEvent("item_pickup", OnItemPickup);
}

public Action:OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	if(!IsValidClient(client, true) || !ZR_IsClientZombie(client))
	{
		return Plugin_Continue;
	}
	
	new String:item[32];
	GetEventString(event, "item", item, sizeof(item));
	
	// Replace any knife weapon with a Karambit knife, if not equipped already.
	if(IsKnifeWeapon(item) && !IsKarambitWeapon(item))
	{
		RemoveMeleeWeaponIfExists(client);
		
		new knife = GivePlayerItem(client, "weapon_knife_karambit");
		EquipPlayerWeapon(client, knife);
	}
    
	return Plugin_Continue;
}

// Stocks
stock bool:IsValidClient(client, bool:mustBeAlive = false)
{
	if (client <= 0 || client > MaxClients)
	{
		return false;
	}
	
	if (!IsClientConnected(client))
	{
		return false;
	}
	
	if (!IsClientInGame(client))
	{
		return false;
	}
	
	if (mustBeAlive && !IsPlayerAlive(client))
	{
		return false;
	}
	
	return true;
}

stock bool:IsKnifeWeapon(const String:weapon[])
{
	return StrContains(weapon, "knife", false) =! -1;
}

stock bool:IsKarambitWeapon(const String:weapon[])
{
	return StrContains(weapon, "karambit", false) == -1;
}

stock GetPlayerMeleeWeapon(client)
{
	return GetPlayerWeaponSlot(client, MELEE_WEAPON_SLOT);
}

stock RemoveWeaponIfExists(client, weapon)
{
	if(weapon != INVALID_ENT_REFERENCE)
	{
		RemovePlayerItem(client, weapon);
		AcceptEntityInput(weapon, "Kill");
	}
}

stock RemoveMeleeWeaponIfExists(client)
{
	new meleeWeapon = GetPlayerMeleeWeapon(client);
	RemoveWeaponIfExists(client, meleeWeapon);
}
