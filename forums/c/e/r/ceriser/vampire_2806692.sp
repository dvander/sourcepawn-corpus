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
 new Handle:healrate;


public Plugin:myinfo = {
	name = "Vampirism",
	author = "Cerisier",
	description = "Heals you when you hit an enemy.",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart() {
	
	CreateConVar("sm_bs_version", PLUGIN_VERSION, "", FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY);
	healrate = CreateConVar("sm_vampirismrate", "50", "Sets how much health (in %) you should drain. (100 is you getting exactly the amount of damage that you dealt).");
	AutoExecConfig(true, "vamprismmod");
	HookEvent("player_hurt", Event_Ouch);
	
}


 
public Event_Ouch(Handle:event, const String:name[], bool:dontBroadcast) {	
	new maxHealth[10] = {0, 125, 125, 200, 175, 150, 300, 175, 125, 125};
    	int attacker_id = GetEventInt(event, "attacker");
    	int ouch_id = GetEventInt(event, "userid");
    	new client = GetClientOfUserId(attacker_id);
    	int damagere = GetEventInt(event, "damageamount");
    	int ouchie = RoundToCeil(float(damagere) * float(GetConVarInt(healrate)) / 100);
    	int target = client;
		if (client != 0 && attacker_id != ouch_id) {
			new class = GetEntProp(target, Prop_Send, "m_iClass");
    	    int heal = GetClientHealth(client);
			if (ouchie == 0)
				FakeClientCommand(target, "explode");
			else if (ouchie > maxHealth[class]) {
				SetEntProp(target, Prop_Data, "m_iMaxHealth", ouchie + heal);
				SetEntityHealth(target, ouchie + heal);
			}
		

		else {
			if (ouchie == 0)
				SetEntityHealth(target, 1);
			else
				SetEntityHealth(target, ouchie + heal);
		}
		}
			

    	// decl String:nameattack[MAX_NAME_LENGTH];
    	// decl String:nameouch[MAX_NAME_LENGTH];
    	// GetClientName(client, nameattack, sizeof(nameattack));
    	// GetClientName(clientouch, nameouch, sizeof(nameouch));
    	

}