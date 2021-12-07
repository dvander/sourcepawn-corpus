#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "WeaponBlock",
	author = "xDerpyx",
	description = "This plugin blocks the cheap guns of TF2",
	version = "1.0.0",
	url = "www.derpygamers.com"
}

#define WEP_Enforcer 460

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
						
			if(TF2_GetPlayerClass(client) == TFClass_Spy)
			{
				if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_Enforcer)
				{
					TF2_RemoveWeaponSlot(client, 0);
					PrintToChat(client, "The Enforcer is not permitted here, because it's a cheap weapon");
					PrintToChat(client, "The Enforcer is not permitted here, because it's a cheap weapon");
					PrintToChat(client, "The Enforcer is not permitted here, because it's a cheap weapon");
					PrintToChat(client, "The Enforcer is not permitted here, because it's a cheap weapon");
				}
			}
		}	
	}
}