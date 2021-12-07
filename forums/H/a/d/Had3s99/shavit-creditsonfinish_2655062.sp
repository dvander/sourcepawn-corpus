#include <sourcemod>
#include <sdktools>
#include <shavit>
#include <store>

Handle hCvar_MinCredits;
Handle hCvar_MaxCredits;
Handle hCvar_Enable;

public Plugin myinfo = {
	name = "[shavit] Credits On Finish for Zephyrus Store",
	author = "Had3s99",
	description = "When player finish he some credits for Zephyrus Store.",
	version = "1.0",
	url = "https://lastfate.fr"
};

public void OnPluginStart() {
	hCvar_Enable = CreateConVar("sm_creditsonfinish_enable", "1", "Enable plugin (1 = Yes, 0 = No)", _, true, 0.0, true, 1.0);
	hCvar_MinCredits = CreateConVar("sm_creditsonfinish_minimum_number", "1", "Minimum amount for end of map");
	hCvar_MaxCredits = CreateConVar("sm_creditsonfinish_maximum_number", "100", "Maximum amount for end of map");
	
	AutoExecConfig(true, "plugin.shavit-creditsonfinish");
}

public void Shavit_OnFinish(int client, int style, float time, int jumps) {
	if(GetConVarBool(hCvar_Enable) == false)
		return;
	
	int random = GetRandomInt(GetConVarInt(hCvar_MinCredits), GetConVarInt(hCvar_MaxCredits));
	Store_SetClientCredits(client, Store_GetClientCredits(client) + random);
}