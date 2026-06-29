#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION "1.0.05"

new const String:WeaponNames[][] =
{
"weapon_ak74",    
"weapon_akm",      
"weapon_aks74u",  
"weapon_fal",  
"weapon_m14",
"weapon_m16a4",
"weapon_m18",
"weapon_m1a1",
"weapon_m249",
"weapon_m40a1",
"weapon_m4a1",
"weapon_m590",
"weapon_mini14",
"weapon_mk18",
"weapon_mosin",
"weapon_mp40",
"weapon_mp5",
"weapon_rpk", 
"weapon_sks",
"weapon_toz",
"weapon_l1a1",
"weapon_sterling",
"weapon_galil",
"weapon_galil_sar",
"weapon_ump45", //0-24
"weapon_m1911",  
"weapon_m9",
"weapon_m45",   
"weapon_makarov",
"weapon_model10" //25-29
}

public Plugin:myinfo = 
{
	name = "Insurgency Drop Weapon",
	author = "Artos",
	description = "Drop Weapon plugin for Insurgency",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/groups/BeFriendTeam"
}

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post)
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
		new client     = GetClientOfUserId(GetEventInt(event, "userid"))
		//new attacker   = GetClientOfUserId(GetEventInt(event, "attacker"))
		new hitgroup = GetEventInt(event, "hitgroup")
		new damage   = GetEventInt(event, "dmg_health")
		new health = GetClientHealth(client)
		new slot
		decl String:weapon[32]
		//GetClientWeapon(attacker, weapon, sizeof(weapon))
		GetClientWeapon(client, weapon, sizeof(weapon))
		if ((((hitgroup == 0) && (damage > 70)) && (health >0)) || (((hitgroup == 4) || (hitgroup == 5)) && (health >0)))
		{
			for (new count=0; count<=29; count++)
			{
				switch(count)
				{
				case 25: slot = 1
				case 30: break
				}
				if (StrEqual(weapon, WeaponNames[count]))
				{
					if (GetPlayerWeaponSlot(client, slot) > 0)
					{
						PrintToServer("Player %N lost gun %s", client, weapon)
						new weapon_id = GetPlayerWeaponSlot(client, slot)
						SDKHooks_DropWeapon(client, weapon_id, NULL_VECTOR, NULL_VECTOR)
						PrintHintText(client, "Wounded to the arm! You lost your weapon!")
					}
				}
			}
		}
}

