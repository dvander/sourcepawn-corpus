#include <sourcemod>
#include <sdktools>
#include <cstrike>
public Plugin:myinfo = {
	name = "Warmup Pistols Only",
	author = "sharkdeed",
	description = "Requested by whompmaster.",
	url = ""
}

public OnPluginStart()
{
	HookEvent("item_pickup", onItemPickup);
}

public onItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GameRules_GetProp("m_bWarmupPeriod"))
	{
		new primary_slot = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
		if(primary_slot != -1)
		{
			stripPlayer(client, primary_slot);
			PrintToChat(client, "Only pistols are allowed in warmup rounds.");
		}
	}
	else 
		UnhookEvent("item_pickup",onItemPickup);
}

public stripPlayer(client, slot)
{
	if(!IsClientConnected(client) || !IsClientInGame(client))
		return;
	RemovePlayerItem(client, slot);
}