#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>


new player_use[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "[l4d2]Melee weapons ignite infection",
	author = "AK978",
	version = "1.0"
}

public OnPluginStart(){
	RegConsoleCmd("sm_smf", sm_Start_melee_fire);
}

public OnClientDisconnect(Client){
	if (player_use[Client] == 1){
		player_use[Client] = 0; 
	}
}

public Action:sm_Start_melee_fire(Client, args){
	player_use[Client] = 1;	
	PrintToChat(Client, "Melee weapons ignite infection");
}


public OnEntityCreated(entity, const String:classname[]){
	SDKHook(entity, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype){	
	if (IsSurvivor(attacker)){
		if (IsCommonInfected(victim) || IsInfected(victim)){
			if (CheckWeapon(attacker)){
				IgniteEntity(victim, 0.1);
			}
		}
	}
}

bool CheckWeapon(int client){
	if(player_use[client] == 1 && IsSurvivor(client) && IsPlayerAlive(client)){
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( weapon > 0 && IsValidEntity(weapon)){
			char sTemp[32];
			GetEntityClassname(weapon, sTemp, sizeof(sTemp));
			if(strcmp(sTemp, "weapon_melee") == 0)
				return true;
		}
	}
	return false;
}

bool:IsSurvivor(client){
	if (IsValidClient(client)){
		if (GetClientTeam(client) == 2){
			return true;
		}
	}
	return false;
}

bool:IsInfected(client){
	if (IsValidClient(client)){
		if (GetClientTeam(client) == 3){
			return true;
		}
	}
	return false;
}

stock bool:IsCommonInfected(iEntity){
    if(iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity)){
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        return StrEqual(strClassName, "infected");
    }
    return false;
}

bool:IsValidClient(client){
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) return false;      
    return true; 
}