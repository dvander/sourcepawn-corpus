#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "Remove Weapons for GG",
	author = "Tubaflub- original code, edited by NineteenEleven",
	description = "Removed Demoshields and Razorback",
	version = "1.0.0",
	url = "www.sourcemod.net"
}

#define WEP_Targe 131
#define WEP_Screen 406
#define WEP_Razorback 57

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
				if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_Razorback)
				{
					TF2_RemoveWeaponSlot(client, 0);
					
				}
			}
		}	
	}

	for(new client=1; client <= MaxClients; client++)
	{		
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{		
			new slot0 = GetPlayerWeaponSlot(client, 0);
						
			if(TF2_GetPlayerClass(client) == TFClass_DemoMan)
			{
				if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_Screen)
				{
					TF2_RemoveWeaponSlot(client, 0);
					
				}
				else if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_Targe)
				{
					TF2_RemoveWeaponSlot(client, 0);
					
				}
			}
		}	
	}
}
