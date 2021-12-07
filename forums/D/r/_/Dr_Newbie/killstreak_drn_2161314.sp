#include <sourcemod>
#include <tf2_stocks>
#include <tf2attributes>

new Handle:GIVEKILLSTREAK_Enable;

float list_of_idleeffect_id[] = {1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0};
int list_of_idleeffect_id_size = sizeof(list_of_idleeffect_id) - 1;

float list_of_effect_id[] = {2002.0, 2003.0, 2004.0, 2005.0, 2006.0, 2007.0, 2008.0};
int list_of_effect_id_size = sizeof(list_of_effect_id) - 1;

public Plugin:myinfo =
{
	name = "Killstreak for everyone",
	author = "Dr_Newbie",
	description = " ",
	version = "10",
	url = "https://forums.alliedmods.net/showthread.php?t=243352"
};

public OnPluginStart()
{
	GIVEKILLSTREAK_Enable = CreateConVar("sm_ks_drn", "1", "Enable 'Killstreak for everyone'");
	HookEvent("post_inventory_application", Event_InventoryCheck_GiveKillStreak,  EventHookMode_Post); 
}

public Action:GiveKillStreakNow(Handle:timer, any:userid)
{
	new iClient = GetClientOfUserId(userid);
	if (iClient && iClient > 0 && IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		for (new iSlot = 0; iSlot < 8; iSlot++) 
		{ 
			new iWeapon = GetPlayerWeaponSlot(iClient, iSlot); 
			if (IsValidEntity(iWeapon)) 
			{
				if(TF2Attrib_GetByDefIndex(iWeapon, 2025) == Address_Null)
					TF2Attrib_SetByDefIndex(iWeapon, 2025, 1.0);
				if(TF2Attrib_GetByDefIndex(iWeapon, 2013) == Address_Null)
				{
					int grnd1 = GetRandomInt(0, list_of_effect_id_size);
					TF2Attrib_SetByDefIndex(iWeapon, 2013, list_of_effect_id[grnd1]);
				}
				if(TF2Attrib_GetByDefIndex(iWeapon, 2014) == Address_Null)
				{
					int grnd1 = GetRandomInt(0, list_of_idleeffect_id_size);
					TF2Attrib_SetByDefIndex(iWeapon, 2014, list_of_idleeffect_id[grnd1]);
				}
			}
		}
	}
}

public Event_InventoryCheck_GiveKillStreak(Handle:hEvent, String:strName[], bool:bDontBroadcast) 
{
	if (GetConVarBool(GIVEKILLSTREAK_Enable))
	{
		new userid = GetEventInt(hEvent, "userid");
		CreateTimer(4, GiveKillStreakNow, any:userid);
	}
}