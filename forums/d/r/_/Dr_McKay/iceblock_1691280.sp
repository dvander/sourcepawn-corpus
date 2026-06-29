
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "IceBlock (adapted from CowBlock)",
	author = "Dr. McKay (adapted from Darkimmortal's plugin)",
	description = "Blocks the Spy-Cicle",
	version = "1.0.0",
	url = "http://www.doctormckay.com"
}

#define WEP_SPYCICLE 649

public OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}


public Event_PostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	new slot2 = GetPlayerWeaponSlot(client, 2);		
	if(TF2_GetPlayerClass(client) == TFClass_Spy)
	{
		if(slot2 > MaxClients && IsValidEntity(slot2) && GetEntProp(slot2, Prop_Send, "m_iItemDefinitionIndex") == WEP_SPYCICLE)
		{
			TF2_RemoveWeaponSlot(client, 2);
			PrintToChat(client, "The spy-cicle is disabled on this server.");
		}
	}
}