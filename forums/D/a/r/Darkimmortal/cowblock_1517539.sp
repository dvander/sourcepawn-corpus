
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "CowBlock",
	author = "Darkimmortal",
	description = "Blocks new weapons due to instability on Linux",
	version = "0.0.1",
	url = ""
}

#define WEP_COWMANGLER 441
#define WEP_BISON 442

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
			new slot1 = GetPlayerWeaponSlot(client, 1);
			
			if(TF2_GetPlayerClass(client) == TFClass_Soldier)
			{
				if(slot0 > MaxClients && IsValidEntity(slot0) && GetEntProp(slot0, Prop_Send, "m_iItemDefinitionIndex") == WEP_COWMANGLER)
				{
					TF2_RemoveWeaponSlot(client, 0);
					PrintToChat(client, "Cow Mangler 5000 is not permitted here currently due to server instability (blame Valve)");
				}
				if(slot1 > MaxClients && IsValidEntity(slot1) && GetEntProp(slot1, Prop_Send, "m_iItemDefinitionIndex") == WEP_BISON)
				{
					TF2_RemoveWeaponSlot(client, 1);
					PrintToChat(client, "Righteous Bison is not permitted here currently due to server instability (blame Valve)");
				}
			}
		}	
	}
}