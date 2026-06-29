#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PLUGIN_VERSION "1"
#define PREFIX "\x04[BS]\x01 "
#define MAX_PLAYERS 25
#define NAME_LENGTH 32
#define MAX_FILE_LEN 80


public Plugin:myinfo = {
	name = "Ultimate butter knife",
	author = "Cerisier",
	description = "Butter knifes one shot people",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart() {
	
	CreateConVar("sm_bs_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	HookEvent("player_hurt", Event_Ouch, EventHookMode_Pre);
	
}


 
public Event_Ouch(Handle:event, const String:name[], bool:dontBroadcast) {	
    	int attacker_id = GetEventInt(event, "attacker");
    	int ouch_id = GetEventInt(event, "userid");
    	new client = GetClientOfUserId(attacker_id);
    	new clientouch = GetClientOfUserId(ouch_id);
		 if (client != 0 && IsValidEntity(attacker_id) && IsValidEntity(ouch_id) && TF2_GetPlayerClass(client) == TFClass_Spy) {
			new primary = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
         if (primary > -1 && primary == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
       {
             SetEntityHealth(clientouch, 0);
        } 		
		}
}