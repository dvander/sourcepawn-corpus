#include <sourcemod>

#define FLASH_ID 2

int isClientFlashed[MAXPLAYERS];

public Plugin myinfo = {
	name = "[MAGA] Teamflash",
	description = "Prints the name of any teamflasher to team chat",
	author = "Apple3.14159",
	version = "1.0.0",
	url = "https://discord.gg/H492wRM"
};

//https://www.sourcemod.net/newstats.php?go=faq

public void OnPluginStart(){
	HookEvent("grenade_detonate", getTeamflasher);
	HookEvent("player_blind", getBlindedPlayer);
}

public void getTeamflasher(Event event, const char[] name, bool dontBroadcast){
	int id = event.GetInt("id");
	
	if(id == FLASH_ID){
		int thrower = GetClientOfUserId(event.GetInt("userid"));
		
		CreateTimer(0.1, getFlashedTeammates, thrower);
	}
}

public Action getFlashedTeammates(Handle timer, int thrower){
	if(!thrower){
		return;
	}
	int throwerTeam = GetClientTeam(thrower);
	
	char flasherName[MAX_NAME_LENGTH];

	if(GetClientName(thrower, flasherName, MAX_NAME_LENGTH)){
		int numFlashed = 0;
		for(int i = 1; i <= MaxClients; i++){
			if(IsClientInGame(i) && IsPlayerAlive(i) && isClientFlashed[i] && throwerTeam == GetClientTeam(i) && i != thrower){
				numFlashed++;
				isClientFlashed[i] = 0;
			}
		}
		
		if(numFlashed){
			for(int i = 1; i <= MaxClients; i++){
				if(IsClientInGame(i) && throwerTeam == GetClientTeam(i)){
					PrintToChat(i, "%s flashed %d teammate(s)", flasherName, numFlashed);
				}
			}
		}

	}

}

public void getBlindedPlayer(Event event, const char[] name, bool dontBroadcast){
	int userid = event.GetInt("userid");
	isClientFlashed[GetClientOfUserId(userid)] = 1;
}