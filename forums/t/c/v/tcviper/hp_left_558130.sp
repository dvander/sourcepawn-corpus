#include <sourcemod>

//0=attacker name, 1=attacker weapon
new String:deathInfo[MAXPLAYERS+1][2][32];
new hpleft[MAXPLAYERS+1];
new distances[MAXPLAYERS+1];
new bool:headshots[MAXPLAYERS+1];
new Handle:weaponNames;

#define PLUGIN_VERSION "1.2.1"

public Plugin:myinfo = {
	name = "HP Left",
	author = "InterWave Studios team",
	description = "Shows how many hp an attacker has left",
	version = PLUGIN_VERSION,
	url = "http://www.interwavestudios.com/"
};

public OnPluginStart()
{
	HookEvent("player_death", playerDeath)
	CreateConVar("sm_hpl_version", PLUGIN_VERSION, "HP left version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	RegConsoleCmd("say", printInfoChat);
	RegConsoleCmd("say_team", printInfoChat);
	LoadTranslations("hp_left.phrases");
	weaponNames = CreateKeyValues("Weapons");
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
			PrintToChat(client,"%t", "Notdied")
		}else{
			printInfo(client)
		}
	}
	
	return Plugin_Continue
}

public printInfo(client){
	if(headshots[client]){	
		PrintToChat(client,"%t", "Killedhs", 3,deathInfo[client][0],1,deathInfo[client][1],hpleft[client])
	}else{
		PrintToChat(client,"%t", "Killed", 3,deathInfo[client][0],1,deathInfo[client][1],hpleft[client])
	}
}


public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	new victim = GetClientOfUserId(GetEventInt(event, "userid"))
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"))
	
	//Suicide of some form, not paying attention
	if(attacker == victim || attacker == 0){
		return Plugin_Continue
	}
		
	new String:attackerName[32]
	GetClientName(attacker,attackerName,32)
	new String:weapon[32]
	GetEventString(event, "weapon", weapon, 32)
	
	if(strlen(weapon) == 0)
		return Plugin_Continue

	KvGetString(weaponNames, weapon, weapon, sizeof(weapon), weapon);
	ReplaceString(weapon, 32, "WEAPON_", "")

	//Store the info in the arrays
	strcopy(deathInfo[victim][0],sizeof(deathInfo[][]),attackerName)
	strcopy(deathInfo[victim][1],sizeof(deathInfo[][]),weapon)
	if(attacker != 0){
		if(IsClientConnected(attacker)) {
			hpleft[victim] = GetClientHealth(attacker)	
		}
	}
	printInfo(victim)
	
	return Plugin_Continue
}

public OnMapStart() {
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/hp_left_weapons.txt");
	FileToKeyValues(weaponNames, sPath);
}