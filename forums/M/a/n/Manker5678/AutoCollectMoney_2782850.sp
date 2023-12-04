#include <sdkhooks>
#include <tf2_stocks>

#define REDTEAMNUM 2

public Plugin myinfo = 
{
	name = "Auto Collect Money",
	author = "Manker5678",
	description = "Collects money automatically in MVM",
	version = "1.00",
	url = ""
};

public void OnPluginStart()
{
	//Not Necessary, but online compiler wants it
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "item_currencypack_custom"))
	{
		SDKHook(entity, SDKHook_SpawnPost, MoneyCreated);
	}
}

public Action MoneyCreated(int entity)
{
	//Players index are always 1-6
	new Float:origin[3]; //vector value
	
	//Find Alive Player
	int alivePlayerIndex = 1;
	int humanCount = GetTeamClientCount(REDTEAMNUM); //Make sure it's not 6 when entity doesn't exist
	//Prioritize Scouts
	//bool scoutFound = false;
	for (new i = 1; i <= humanCount; i++) {
		if(TF2_GetPlayerClass(i) == TFClass_Scout){
			alivePlayerIndex = i;
		}
	}
	while( (IsPlayerAlive(alivePlayerIndex) == false) && 
	(alivePlayerIndex < humanCount)){ //worst case scenario: spawn at most recent dead
		alivePlayerIndex++; //if not alive, move up to next player
	}
	GetClientAbsOrigin(alivePlayerIndex,origin); //Gets player Location
	TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR) //teleports to player
	return Plugin_Handled;
	
}