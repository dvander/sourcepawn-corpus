#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <zombiereloaded>

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

public Action:OnItemPickup(Handle:event, const String:name[], bool:dB) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 
	if(!IsValidClient(client) || !ZR_IsClientZombie(client))
	{
		return Plugin_Continue;
	}
	new String:weapon[32];
	GetEventString(event, "item", weapon, sizeof(weapon));

	if(StrContains(weapon, "knife", false) != -1 && StrContains(weapon, "karambit", false) == -1)
	{
		new currentknife = GetPlayerWeaponSlot(client, 2);
		if(currentknife != INVALID_ENT_REFERENCE)
		{
			RemovePlayerItem(client, currentknife);
			AcceptEntityInput(currentknife, "Kill");
		}
		new knife = GivePlayerItem(client, "weapon_knife_karambit");
		EquipPlayerWeapon(client, knife);
	}
    
	return Plugin_Continue;
}

// Stocks
stock bool:IsValidClient(client, bool:alive = false)
{
	return (client >= 1 && client <= MaxClients &&  IsClientConnected(client) && IsClientInGame(client) &&  (alive == false || IsPlayerAlive(client)));
}