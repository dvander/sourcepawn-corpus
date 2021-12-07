#include <sourcemod>
#include <tf2_stocks>
#include <tf2>

#pragma semicolon 1

//////////////////////////////////////////////////////
// ABOUT
//
//This plugin specifically targets the heavy glitch.
//The Heavy glitch allows him to move at faster than normal
//speeds while having the minigun revved up.
//
//How To Reproduce Glitch:
// 1. Go Heavy
// 2. Spin up MiniGun (do not release Mouse2)
// 3. Change Secondary or Melee weapon in spawn (do NOT release Mouse2)
// 4. You can now move walking speed while having MiniGun revved up
//
// Glitch resets once Mouse2 is released
//
///////////////////////////////////////////////////////
#define PLUGIN_VERSION "1.1"

new Handle:c_Enabled   = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "[TF2] Heavy Glitch Fix",
	author = "Kevin_b_er & Fox",
	description = "Prevents fast Heavy glitch",
	version = PLUGIN_VERSION,
	url = "http://www.brothersofchaos.com.com"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_Respawn, EventHookMode_Post);
	HookEvent("post_inventory_application", Event_Respawn, EventHookMode_Post); 
	
	CreateConVar("sm_heavyrunningminigunfix_version", PLUGIN_VERSION, "[TF2] Prevents fast Heavy glitch", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	c_Enabled   = CreateConVar("sm_heavyglitchfix_enable",    "1",        "<0/1> Enable Heavy Glitch Fix");
	
	HookConVarChange(c_Enabled,	ConVarChange);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(convar == c_Enabled)
	{
		if(GetConVarInt(c_Enabled))
		{
			PrintCenterTextAll("Heavy Glitch Fix: ENABLED");
		}else{
			PrintCenterTextAll("Heavy Glitch Fix: DISABLED");
		}
	}
}

public Action:Event_Respawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarInt(c_Enabled))
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client)
		return;

	//is player heavy?
	if(TF2_GetPlayerClass(client) == TFClass_Heavy)
	{
		//wait a little bit and check
		CreateTimer(0.2, Timer_CheckState, client);
	}
}


public Action:Timer_CheckState(Handle:Timer, any:client)
{
	if(!IsClientInGame(client))
		return Plugin_Stop;
	
	if(TF2_GetPlayerClass(client) != TFClass_Heavy)
		return Plugin_Stop;
	
	decl String:sWeaponCurrent[64];
	GetClientWeapon(client, sWeaponCurrent, sizeof(sWeaponCurrent));
	if (StrEqual(sWeaponCurrent, "tf_weapon_minigun", false))
	{
		new iWeapon = GetPlayerWeaponSlot(client, 0);
		new iCondFlags = TF2_GetPlayerConditionFlags( client );
		new iWeaponState = GetEntProp(iWeapon, Prop_Send, "m_iWeaponState");

		if(  ( (iCondFlags   & TF_CONDFLAG_SLOWED) == 0) 
		  && ( (iWeaponState & 3)                  != 0) )
		{
			/*  MiniGun State from m_iWeaponState:
			 * 		Revving up: 1
			 *		Firing:		2
			 *		Spin Only:	3
			 *		
			 *		States are strange and we technically don't care about 
			 *		  0b01, but 0b10 and 0b11 are valid states in the glitch
			 */
			/* However during the exploit the heavy is missing the slow flag */
			/* If they are revving but lack a slow condition, they are cheating */
			//PrintToChatAll("Strange Mini-Gun State!");
			
			// Force the minigun to stop revving.
			// If client is holding down alt fire they will re-rev their minigun,
			//  but the correct speed will be applied.
			SetEntProp(iWeapon, Prop_Send, "m_iWeaponState", 0);
		}
	}
	
	return Plugin_Stop;
}