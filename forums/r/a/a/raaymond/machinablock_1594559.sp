#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "MachinaBlock",
	author = "raaymond",
	description = "this plugin can blocks the machina ,use it can without noisy sounds",
	version = "1.0.0",
	url = "www.raaymond.com"
}

#define WEP_DEX_Rifle 526

public OnPluginStart()
{
	//HookEvent("player_spawn", Event_player_spawn);
	CreateTimer(0.1, Timer_DoEquip, 0, TIMER_REPEAT);
}


public Action:Timer_DoEquip(Handle:timer, any:derp)
{
	for(new client=1; client <= MaxClients; client++)
	{		
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{		
			new slot0 = GetPlayerWeaponSlot(client, 0);
						
			if(TF2_GetPlayerClass(client) == TFClass_Sniper)
			{
				if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_DEX_Rifle)
				{
					TF2_RemoveWeaponSlot(client, 0);
					PrintToChat(client, "The Machina is not permitted here currently due Headshot sounds are too noisy");
				}
			}
		}	
	}
}