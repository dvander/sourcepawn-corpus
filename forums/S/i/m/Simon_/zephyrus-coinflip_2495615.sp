#include <multicolors>
#pragma newdecls optional
#include <store>
#pragma newdecls required
#pragma semicolon 1

#define msg_prefix "{grey}[{lime}Coinflip{grey}]"

#define PLUGIN_NAME "zephyrus-coinflip"
#define PLUGIN_VERSION "1.0.3"

ConVar g_hMincredits;
ConVar g_hMaxcredits;

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
    
	g_hMincredits = CreateConVar("sm_coinflip_min_credits", "10", "Minimum credits to bet!");
	g_hMaxcredits = CreateConVar("sm_coinflip_max_credits", "10000", "Maximum credits to bet!");
	AutoExecConfig(true, "zephyrus-coinflip");
}

public Action Command_CoinFlip(int client, int args) {
	if(client <= 0 && client > MaxClients && !IsClientInGame(client)) {
		return Plugin_Handled;
	}
	
	if(args < 2) {
		CPrintToChat(client, "%s Usage: {lime}sm_coinflip{grey} <{lime} T / CT {grey}> <{lime}amount{grey}>", msg_prefix);
		return Plugin_Handled;
	}

	char arg1[3];
	GetCmdArg(1, arg1, sizeof(arg1));

	if(!StrEqual(arg1, "ct", false) && !StrEqual(arg1, "t", false)) {
		CPrintToChat(client, "%s Invalid team! ", msg_prefix);
		CPrintToChat(client, "%s Usage: {lime}sm_coinflip{grey} <{lime} T / CT {grey}> <{lime}amount{grey}>", msg_prefix);
		return Plugin_Handled;
	}

	char arg2[16];
	GetCmdArg(2, arg2, sizeof(arg2));
	int amount = StringToInt(arg2);
	int currentCredits = Store_GetClientCredits(client);
	int minamount = g_hMincredits.IntValue;
	int maxamount = g_hMaxcredits.IntValue;
	
	if(currentCredits < amount) {
		CPrintToChat(client,"%s Not enough credits!", msg_prefix);
		return Plugin_Handled;
	}
	else if(amount < minamount) {
		CPrintToChat(client,"%s You have to spend at least {lime}%d{grey} credits!", msg_prefix, minamount);
		return Plugin_Handled;
	}
	else if(amount > maxamount) {
		CPrintToChat(client,"%s You can't spend that much credits (Max: {lime}%d{grey}).", msg_prefix, maxamount);
		return Plugin_Handled;
	}
	
	bool won = (GetRandomInt(1,100) > 50);
	CPrintToChat(client,"%s You choose {lime}%s{grey} and %s {lime}%d{grey} credits", msg_prefix, arg1, won ? "won additional" : "lost your", amount);
	Store_SetClientCredits(client, currentCredits + (won ? amount : -amount));
	return Plugin_Handled;
}