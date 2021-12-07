#include <multicolors>
#pragma newdecls optional
#include <store>
#pragma newdecls required
#pragma semicolon 1

#define MSG_PREFIX "{grey}[{lime}Coinflip{grey}]"

#define PLUGIN_NAME "zephyrus-coinflip"
#define PLUGIN_VERSION "1.0.1"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "siimon",
	description = "Basic Coinflip System!",
	version = PLUGIN_VERSION,
	url = "siimon.org"
}

public void OnPluginStart() {
	CreateConVar("sm_coinflip_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	RegConsoleCmd("sm_coinflip", Command_CoinFlip, "Use this commanad to flip the magic coin!");
	RegConsoleCmd("sm_flip", Command_CoinFlip, "Use this commanad to flip the magic coin!");
}

public Action Command_CoinFlip(int client, int args) {
	if(client <= 0 && client > MaxClients && !IsClientInGame(client)) {
		return Plugin_Handled;
	}
	
	if(args < 2) {
		CPrintToChat(client, "%s Usage: {lime}sm_coinflip{grey} <{lime} T / CT {grey}> <{lime}amount{grey}>", MSG_PREFIX);
		return Plugin_Handled;
	}

	char arg1[3];
	GetCmdArg(1, arg1, sizeof(arg1));

	if(!StrEqual(arg1, "ct", false) && !StrEqual(arg1, "t", false)) {
		CPrintToChat(client, "%s Invalid team! ", MSG_PREFIX);
		CPrintToChat(client, "%s Usage: {lime}sm_coinflip{grey} <{lime} T / CT {grey}> <{lime}amount{grey}>", MSG_PREFIX);
		return Plugin_Handled;
	}

	char arg2[16];
	GetCmdArg(2, arg2, sizeof(arg2));
	int amount = StringToInt(arg2);
	int currentCredits = Store_GetClientCredits(client);
	if(currentCredits < amount) {
		CPrintToChat(client,"%s Not enough credits!", MSG_PREFIX);
		return Plugin_Handled;
	}
	bool won = (GetRandomInt(1, 2) == 1);
	CPrintToChat(client,"%s You choose {lime}%s{grey} and %s {lime}%d{grey} credits", MSG_PREFIX, arg1, won ? "won additional" : "lost your", won);
	Store_SetClientCredits(client, currentCredits + (won ? amount : -amount));
	return Plugin_Handled;
}