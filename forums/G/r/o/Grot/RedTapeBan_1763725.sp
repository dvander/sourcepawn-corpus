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

#define WEP_RedTape 810
#define WEP_GRedTape 831

public OnPluginStart()
{
	//HookEvent("player_spawn", Event_player_spawn);
	CreateTimer(0.1, Timer_DoEquip, 0, TIMER_REPEAT);
	CreateTimer(0.1, Timer_DoEquipaa, 0, TIMER_REPEAT);
}


public Action:Timer_DoEquip(Handle:timer, any:derp)
{
	for(new client=1; client <= MaxClients; client++)
	{		
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{		
			new slot1 = GetPlayerWeaponSlot(client, 1);
						
			if(TF2_GetPlayerClass(client) == TFClass_Spy)
			{
				if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_RedTape)
				{
					TF2_RemoveWeaponSlot(client, 1);
					PrintToChat(client, "The Red-Tape Recorder is temporarily banned as it causes server crashes.");
				}
			}
		}	
	}
}

public Action:Timer_DoEquipaa(Handle:timer, any:derp)
{
	for(new client=1; client <= MaxClients; client++)
	{		
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{		
			new slot1 = GetPlayerWeaponSlot(client, 1);
						
			if(TF2_GetPlayerClass(client) == TFClass_Spy)
			{
				if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_GRedTape)
				{
					TF2_RemoveWeaponSlot(client, 1);
					PrintToChat(client, "The Red-Tape Recorder is temporarily banned as it causes server crashes.");
				}
			}
		}	
	}
}