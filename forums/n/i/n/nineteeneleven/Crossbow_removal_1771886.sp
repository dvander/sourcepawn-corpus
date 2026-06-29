#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "No Crusader's Crossbow",
	author = "Tubaflub- original code, edited by NineteenEleven",
	description = "This plugin blocks the Crusader's Crossbow",
	version = "1.0.0",
	url = "www.sourcemod.net"
}

#define WEP_Crossbow 305

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
						
			if(TF2_GetPlayerClass(client) == TFClass_Medic)
			{
				if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_Crossbow)
				{
					TF2_RemoveWeaponSlot(client, 0);
					PrintToChat(client, "The Crossbow is not permitted here");
				}
			}
		}	
	}
}
