#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION 	"0.9"

new arr_RaffleNum[MAXPLAYERS + 1];
new rafflemax;

public Plugin:myinfo = {
	name = "Raffle",
	author = "NuclearWatermelon",
	description = "Raffle number generator",
	version = PLUGIN_VERSION,
	url = "http://www.critsandvich.com/"
}

public OnPluginStart() {
	SetConVarString(CreateConVar("sm_raffle_version", PLUGIN_VERSION, "Generates a random number for a raffle.", FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_REPLICATED), PLUGIN_VERSION);
	RegAdminCmd("sm_raffle", Generate_Raffle, ADMFLAG_CHAT, "Generates a random number for a raffle.");
	RegAdminCmd("sm_raffle_assign", Assign_Raffle, ADMFLAG_CHAT, "Assigns a raffle number to a player.");
	RegAdminCmd("sm_raffle_remove", Remove_Raffle, ADMFLAG_CHAT, "Removes a raffle number from a player.");
	RegAdminCmd("sm_raffle_cancel", Cancel_Raffle, ADMFLAG_CHAT, "Cancels a raffle.");
	RegConsoleCmd("sm_raffle_list", List_Raffle);
	LoadTranslations("common.phrases");
	rafflemax = 0;
}

public Action:List_Raffle(client, args) {
	if (args > 1) {
		PrintToConsole(client, "Usage: sm_raffle_list");
		return Plugin_Handled;
	}
	for (new i = 0; i <= MAXPLAYERS; i++) {
		if (arr_RaffleNum[i] != 0) {
			new String:rafflename[32];
			GetClientName(i, rafflename, sizeof(rafflename));			
			CPrintToChat(client, "{green}%s {default}has raffle number {green}%d", rafflename, arr_RaffleNum[i]);
		}
	}
	return Plugin_Handled;
}

public Action:Cancel_Raffle(client, args) {
	if (args > 1) {
		PrintToConsole(client, "Usage: sm_raffle_cancel");
		return Plugin_Handled;
	}
	for (new i = 0; i <= MAXPLAYERS; i++) {
		arr_RaffleNum[i] = 0;
	}
	PrintToChatAll("The raffle has been canceled.");
	rafflemax = 0;
	
	new String:clientname[32];
	GetClientName(client, clientname, sizeof(clientname));
	LogAction(client, -1, "%s canceled the raffle.", clientname);
	
	return Plugin_Handled;
}

public Action:Generate_Raffle(client, args) {
	if (args > 1) {
		PrintToConsole(client, "Usage: sm_raffle");
		return Plugin_Handled;
	}
	if (rafflemax == 0) {
		ReplyToCommand(client, "No persons in the raffle.");
		return Plugin_Handled;
	}
	if (rafflemax == 1) {
		ReplyToCommand(client, "Only one person in the raffle.");
		return Plugin_Handled;
	}
	new randnumber;
	randnumber = GetRandomInt(1, rafflemax);
	CPrintToChatAll("The winning raffle number is: {green}%d", randnumber);
	for (new i = 0; i <= MAXPLAYERS; i++) {
		if (arr_RaffleNum[i] == randnumber) {
			new String:winname[32];
			GetClientName(i, winname, sizeof(winname));
			CPrintToChatAll("The winner of the raffle is: {green}%s", winname);
			LogAction(client, -1, "%s won the raffle with raffle number %d", winname, randnumber);
			arr_RaffleNum[i] = 0;
		}
		else {
			arr_RaffleNum[i] = 0;
		}
	}
	rafflemax = 0;
	return Plugin_Handled;
}

public Action:Assign_Raffle(client, args) {
	if (args < 1) {
		PrintToConsole(client, "Usage: sm_raffle_assign <name> <name2> ...");
		return Plugin_Handled;
	}
	new argnum = 1;
	while (argnum <= args) {
		new String:argstr[32];
		GetCmdArg(argnum, argstr, sizeof(argstr));
		
		decl String:target_name[MAX_TARGET_LENGTH];
		decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

		if ((target_count = ProcessTargetString(
				argstr,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
			{
				ReplyToTargetError(client, target_count);
				argnum++;
				return Plugin_Handled;
			}
		for (new i = 0; i < target_count; i++) {
			new String:rafflename[32];
			GetClientName(target_list[i], rafflename, sizeof(rafflename));
			if (arr_RaffleNum[target_list[i]] > 0) {
				CPrintToChat(client, "{green}%s {default}is already in the raffle.", rafflename);
				return Plugin_Handled;
			}
			rafflemax++;	
			arr_RaffleNum[target_list[i]] = rafflemax;
			CPrintToChatAll("{green}%s {default}has raffle number {green}%d", rafflename, rafflemax);	
			LogAction(client, target_list[i], "%s given raffle number %d", rafflename, rafflemax);
			argnum++;
		}
		
		/*
		new target = FindTarget(client, argstr, true, false);
		if (target == -1) {
			argnum++;
		}
		else {
			new String:rafflename[32];
			GetClientName(target, rafflename, sizeof(rafflename));
			if (arr_RaffleNum[target] > 0) {
				CPrintToChat(client, "{green}%s {default}is already in the raffle.", rafflename);
				return Plugin_Handled;
			}
			rafflemax++;	
			arr_RaffleNum[target] = rafflemax;
			CPrintToChatAll("{green}%s {default}has raffle number {green}%d", rafflename, rafflemax);	
			LogAction(client, target, "%s given raffle number %d", rafflename, rafflemax);
			argnum++;
		}
		*/
	}
	return Plugin_Handled;
}

public Action:Remove_Raffle(client, args) {
	if (args < 1) {
		PrintToConsole(client, "Usage: sm_raffle_remove <name> <name2> ...");
		return Plugin_Handled;
	}
	new argnum = 1;
	while (argnum <= args) {
		new String:argstr[32];
		GetCmdArg(argnum, argstr, sizeof(argstr));
		new target = FindTarget(client, argstr, true, false);
		if  (target == -1) {
			argnum++;
		}
		else {
			new String:rafflename[32];
			GetClientName(target, rafflename, sizeof(rafflename));
			if (arr_RaffleNum[target] == 0) {
				CPrintToChat(client, "{green}%s {default}was not in the raffle to begin with!", rafflename);
				return Plugin_Handled;
			}
			new removenum = arr_RaffleNum[target];
			arr_RaffleNum[target] = 0;
			CPrintToChatAll("{green}%s {default}was removed from the raffle.", rafflename);
			LogAction(client, target, "%s was removed from the raffle", rafflename);
			
			if (removenum != 0) {
				for (new i = 0; i <= MAXPLAYERS; i++) {
					new String:iname[32];
					GetClientName(i, iname, sizeof(iname));
					if (arr_RaffleNum[i] > removenum) {
						arr_RaffleNum[i] = arr_RaffleNum[i] - 1;
						CPrintToChat(i, "Your raffle number has changed from {green}%d {default} to {green}%d{default}.", arr_RaffleNum[i] +1, arr_RaffleNum[i]);
						LogAction(client, target, "%s had raffle number changed from %d to %d", iname, arr_RaffleNum[i] +1, arr_RaffleNum[i]);
					}
				}
				rafflemax--;
			}
			argnum++;
		}
	}
	return Plugin_Handled;
}
