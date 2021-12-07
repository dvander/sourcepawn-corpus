#include <sourcemod>
#include <tf2_stocks>

public Plugin:myinfo =
{
	name = "[TF2] Remove Snipers Weapon slot 2",
	author = "Pelipoika",
	description = "Removes slots 2 for snipers",
	version = "1.0",
	url = ""
};
 
public OnPluginStart()
{
	HookEvent("post_inventory_application", OnPostInventoryApplicationAndPlayerSpawn);
	HookEvent("player_spawn", OnPostInventoryApplicationAndPlayerSpawn);
}

public OnPostInventoryApplicationAndPlayerSpawn(Handle:hEvent, const String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"))

	if (TF2_GetPlayerClass(iClient) == TFClass_Sniper && IsValidClient[iClient])
    {
        TF2_RemoveWeaponSlot(iClient, 2);
    }
}
 
stock bool:IsValidClient(client)
{
	if (client <= 0 || client > MaxClients) return false;
	return IsClientInGame(client);
}