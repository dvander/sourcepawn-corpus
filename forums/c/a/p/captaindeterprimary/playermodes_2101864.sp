#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "[TF2] Player modes",
	author = "vman315",
	description = "Witty words here.",
	version = "1.1",
	url = "http://vman315.com"
}

new Handle:sm_playermode;
 
public OnPluginStart()
{
	sm_playermode = CreateConVar( "sm_playermode", "0", "1 - Fat Scouts, 2 - Pew pew Spies, 3 - Heavy boxing, 4 - Chargen Demoknights", FCVAR_NOTIFY, true, 0.0, true, 4.0 );
	HookEvent("player_spawn", event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_PlayerResupply, EventHookMode_Post);
}
public event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
//	new iWeaponIndex = GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex");//
	switch(GetConVarInt(sm_playermode)) 
	{
		case 1:
		//Fat Scout//
		{			
			if (TF2_GetPlayerClass(client) != TFClass_Heavy)
			{
				TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
			}
			TF2_RegeneratePlayer(client);
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 2);
			PrintToChat(client, "Its Fat Scout time!");
		}
		case 2:
		//PewPewSpy//
		{			
			if (TF2_GetPlayerClass(client) != TFClass_Spy)
			{
				TF2_SetPlayerClass(client, TFClass_Spy, false, true);
			}
			TF2_RegeneratePlayer(client);
			TF2_RemoveWeaponSlot(client, 1);
			TF2_RemoveWeaponSlot(client, 2);
			TF2_RemoveWeaponSlot(client, 3);
			TF2_RemoveWeaponSlot(client, 4);
			TF2_RemoveWeaponSlot(client, 5);

            PrintToChat(client, "Its Pew Pew Spy time!");
		}
		case 3:
		//Heavy Boxing//
		{
			if (TF2_GetPlayerClass(client) != TFClass_Heavy)
			{
				TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
			}
			TF2_RegeneratePlayer(client);
			TF2_RemoveWeaponSlot(client, 0);
			if(GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") != (42 || 159 || 311 || 433 || 863 || 1002) )
			//Can you eat it? If not get rid of it//
			{
			    TF2_RemoveWeaponSlot(client, 1);
			}
            PrintToChat(client, "Its Heavy boxing time!");
		}
		case 4:
        //Charge'n Demoknight//
		{
			if (TF2_GetPlayerClass(client) != TFClass_DemoMan)
			{
				TF2_SetPlayerClass(client, TFClass_DemoMan, false, true);
			}
			TF2_RegeneratePlayer(client);
			if(GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iItemDefinitionIndex") != (608 || 405) )
			{
			    TF2_RemoveWeaponSlot(client, 0);
			}
			if(GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") != (131 || 406) )
			{
			    TF2_RemoveWeaponSlot(client, 1);
			    PrintToChat(client, "If you have a Chargin' Targe or a Splendid Screen, you need to equip them to move.");
			}
			PrintToChat(client, "Charge'n Demoknight time!");
		}
	}
}
public Event_PlayerResupply(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	switch(GetConVarInt(sm_playermode)) 
	{
		case 1:
		//Fat Scout//
		{			
			if (TF2_GetPlayerClass(client) != TFClass_Heavy)
			{
				TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
			}
			TF2_RemoveWeaponSlot(client, 0);
			TF2_RemoveWeaponSlot(client, 2);
			PrintToChat(client, "Its Fat Scout time!");
		}
		case 2:
		//PewPewSpy//
		{			
			if (TF2_GetPlayerClass(client) != TFClass_Spy)
			{
				TF2_SetPlayerClass(client, TFClass_Spy, false, true);
			}
			TF2_RemoveWeaponSlot(client, 1);
			TF2_RemoveWeaponSlot(client, 2);
			TF2_RemoveWeaponSlot(client, 3);
			TF2_RemoveWeaponSlot(client, 4);
			TF2_RemoveWeaponSlot(client, 5);
            PrintToChat(client, "Its Pew Pew Spy time!");
		}
		case 3:
		//Heavy Boxing//
		{
			if (TF2_GetPlayerClass(client) != TFClass_Heavy)
			{
				TF2_SetPlayerClass(client, TFClass_Heavy, false, true);
			}
			TF2_RemoveWeaponSlot(client, 0);
			if(GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") != (42 || 159 || 311 || 433 || 863 || 1002) )
			//Can you eat it? If not get rid of it//
			{
			    TF2_RemoveWeaponSlot(client, 1);
			}
            PrintToChat(client, "Its Heavy boxing time!");
		}
		case 4:
        //Charge'n Demoknight//
		{
			if (TF2_GetPlayerClass(client) != TFClass_DemoMan)
			{
				TF2_SetPlayerClass(client, TFClass_DemoMan, false, true);
			}
			if(GetEntProp(GetPlayerWeaponSlot(client, 0), Prop_Send, "m_iItemDefinitionIndex") != (608 || 405) )
			{
			    TF2_RemoveWeaponSlot(client, 0);
			}
			if(GetEntProp(GetPlayerWeaponSlot(client, 1), Prop_Send, "m_iItemDefinitionIndex") != (131 || 406) )
			{
			    TF2_RemoveWeaponSlot(client, 1);
			    PrintToChat(client, "If you have a Chargin' Targe or a Splendid Screen, you need to equip them to move.");
			}
			PrintToChat(client, "Charge'n Demoknight time!");
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(GetConVarBool(sm_playermode) == 4 && condition == TFCond_Charging)
	{
		SetChargeMeter(client);
	}
}

stock SetChargeMeter(client, Float:flChargeMeter = 100.0)
{
	SetEntPropFloat(client, Prop_Send, "m_flChargeMeter", flChargeMeter);
}