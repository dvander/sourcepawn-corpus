#include <sourcemod>

//0=attacker name, 1=attacker weapon
new String:deathInfo[MAXPLAYERS+1][2][32];
new hpleft[MAXPLAYERS+1];
new distances[MAXPLAYERS+1];
new bool:headshots[MAXPLAYERS+1];

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo = {
	name = "HP left",
	author = "vIr-Dan",
	description = "Shows how many hp an attacker has left",
	version = PLUGIN_VERSION,
	url = "http://dansbasement.us/"
};

public OnPluginStart()
{
	HookEvent("player_death", playerDeath)
	CreateConVar("sm_hpl_version", PLUGIN_VERSION, "HP left version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegConsoleCmd("say", printInfoChat);
	RegConsoleCmd("say_team", printInfoChat);
}

public Action:printInfoChat(client, args){
	//Make sure it's not console
	if(client == 0){
		return Plugin_Continue
	}
	
	
	
	//Get the user's command
	new String:user_command[192];
	GetCmdArgString(user_command, 192);
	new start_index = 0
	new command_length = strlen(user_command);
	if (command_length > 0) {
		//Get rid of quotes
		if (user_command[0] == 34)	{
			start_index = 1;
			if (user_command[command_length - 1] == 34)	{
				user_command[command_length - 1] = 0;
			}
		}
		
		if (user_command[start_index] == 47)	{
			start_index++;
		}
	}
	
	if(strcmp(user_command[start_index],"hp",false)==0 || strcmp(user_command[start_index],"/hp",false)==0){
		//Make sure they've died already
		if(distances[client] == 0){
			PrintToChat(client,"\x04You have not died yet")
		}else{
			printInfo(client)
		}
	}
	
	return Plugin_Continue
}

public printInfo(client){
	if(headshots[client]){	
		PrintToChat(client,"\x04%s killed you with %s (headshot) from %i feet and has %i hp left",deathInfo[client][0],deathInfo[client][1],distances[client],hpleft[client])
	}else{
		PrintToChat(client,"\x04%s killed you with %s from %i feet and has %i hp left",deathInfo[client][0],deathInfo[client][1],distances[client],hpleft[client])
	}
}


public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new bool:headshot = GetEventBool(event, "headshot")
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	//Suicide of some form, not paying attention
	if(attacker == victim){
		return Plugin_Continue
	}
		
	new String:attackerName[32]
	GetClientName(attacker,attackerName,32)
	new String:weapon[32]
	GetEventString(event, "weapon", weapon, 32)
	ReplaceString(weapon, 32, "WEAPON_", "")
	
	//Get the distance
	new Float:victimLoc[3];
	new Float:attackerLoc[3];
	GetClientAbsOrigin(victim,victimLoc)
	GetClientAbsOrigin(attacker,attackerLoc)
	new distance = RoundToNearest(FloatDiv(calcDistance(victimLoc[0],attackerLoc[0], victimLoc[1],attackerLoc[1], victimLoc[2],attackerLoc[2]),12.0))
	
	//Store the info in the arrays
	strcopy(deathInfo[victim][0],sizeof(deathInfo[][]),attackerName)
	strcopy(deathInfo[victim][1],sizeof(deathInfo[][]),weapon)
	hpleft[victim] = GetClientHealth(attacker)
	distances[victim] = distance
	headshots[victim] = headshot
	
	printInfo(victim)
	
	return Plugin_Continue
}

public Float:calcDistance(Float:x1,Float:x2,Float:y1,Float:y2,Float:z1,Float:z2){ 
	//Distance between two 3d points
	new Float:dx = x1-x2 
	new Float:dy = y1-y2 
	new Float:dz = z1-z2 

	return(SquareRoot(dx*dx + dy*dy + dz*dz))
}