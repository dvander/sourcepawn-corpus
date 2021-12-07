/*

	1.0 : Release
	1.1 : Add sentence and credits for World Record

*/

#include <sourcemod>
#include <shavit>
#include <store>
#include <multicolors>

#pragma newdecls required
#pragma semicolon 1

ConVar hCvar_Enable = null;
ConVar hCvar_MinCredits = null;
ConVar hCvar_MaxCredits = null;
ConVar hCvar_WrCredits = null;

public Plugin myinfo = {
	name = "[shavit] Credits On Finish (Zephyrus)",
	author = "Had3s99",
	description = "When player finish he get some credits.",
	version = "1.1",
	url = "https://lastfate.fr"
};

public void OnPluginStart() {
	hCvar_Enable = CreateConVar("sm_creditsonfinish_enable", "1", "Enable plugin (1 = Yes, 0 = No)", _, true, 0.0, true, 1.0);
	hCvar_MinCredits = CreateConVar("sm_creditsonfinish_minimum_number", "1", "Minimum amount for end of map", _, true, 1.0); 
	hCvar_MaxCredits = CreateConVar("sm_creditsonfinish_maximum_number", "100", "Maximum amount for end of map", _, true, 0.0); 
	hCvar_WrCredits = CreateConVar("sm_creditsonfinish_wr_number", "200", "Amount when it's WR (0 = disable)", _, true, 0.0); 
	
	AutoExecConfig(true, "plugin.shavit-creditsonfinish");
}

public void Shavit_OnFinish(int client, int style, float time, int jumps) {
	if(!hCvar_Enable.BoolValue)
		return;
	
	int random = GetRandomInt(hCvar_MinCredits.IntValue, hCvar_MaxCredits.IntValue);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + random);
	CPrintToChat(client, "{purple}[Store] {default}You have received {green}%d {default}credits.", random); 
}

public void Shavit_OnWorldRecord(int client, int style, float time, int jumps, int strafes, float sync) { 
	if(!hCvar_Enable.BoolValue || hCvar_WrCredits.IntValue == 0)
		return;

	Store_SetClientCredits(client, Store_GetClientCredits(client) + hCvar_WrCredits.IntValue); 
	CPrintToChat(client, "{purple}[Store] {default}You have received {green}%d {default}credits for beating the world record.", hCvar_WrCredits.IntValue); 
} 