#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>

#define DICE_VERSION "0.2.1"

public Plugin:myinfo =
{
	name = "Dice plugin",
	author = "MastAKK",
	description = "Now you can play dice in tf2!",
	version = DICE_VERSION,
	url = "http://youtube.com/user/MastAKK111"
};

new MaxToRand;

new Handle:g_RandHandle;
new Handle:g_DiceVersion;
new Handle:g_EchoMode;

new lobbyList[MAXPLAYERS][2];
new lobbyScores[MAXPLAYERS][2];

public OnPluginStart(){
	for(new i = 0; i < MAXPLAYERS; i++){
		lobbyList[i][0] = 0;
		lobbyList[i][1] = 0;
		lobbyScores[i][0] = 0;
		lobbyScores[i][1] = 0;
	}
	
	RegConsoleCmd("dice_wantplay", AddToLobby);
	RegConsoleCmd("dice_deleteme", ResetFromLobby);
	RegConsoleCmd("dice_start", StartDice);
	RegConsoleCmd("dice_getlobby", ShowClientLobbyAndOpponent);
	RegConsoleCmd("dice_movetolobby", MoveClientToLobby, "dice_movetolobby <#lobby>");
	RegConsoleCmd("dice_lobbiesstate", CmdPrintLobbies, "dice_lobbiesstate <#lobby|nothing (will be printed state of all lobbyies)>");
	
	RegAdminCmd("dice_getversion", PrintVersion, ADMFLAG_KICK);
	RegAdminCmd("dice_clean", CleanDiceLobbys, ADMFLAG_KICK);
	
	g_RandHandle = CreateConVar("dice_maxrand", "100", "Maximum number to generate random num", FCVAR_NOTIFY);
	g_DiceVersion = CreateConVar("dice_version", DICE_VERSION, "Plugin version", FCVAR_DONTRECORD);
	g_EchoMode = CreateConVar("dice_echomode", "1", "Echo mode: 1 - say result of dice to all, 0 - just to players");
	
	AutoExecConfig(true);
	
	SetConVarString(g_DiceVersion, DICE_VERSION);
	MaxToRand = GetConVarInt(g_RandHandle);
	
	HookConVarChange(g_RandHandle, MaxRandChange);
	
}

public OnPluginEnd(){
	CloseHandle(g_DiceVersion);
	CloseHandle(g_RandHandle);
}

public Action:PrintVersion(client, args){
	PrintToChat(client, DICE_VERSION);
}

public MaxRandChange(Handle:cvar, const String:oldVal[], const String:newVal[]){
	MaxToRand = StringToInt(newVal);
}

public Action:CleanDiceLobbys(client, args){
	for(new i = 0; i < MAXPLAYERS; i++){
		lobbyScores[i][0] = 0;
		lobbyScores[i][1] = 0;		
	}
}

public Action:AddToLobby(client, args){
	new i = 0, j = 0;
	if(!CheckClientLobby(client)){
		for(; i < MAXPLAYERS; i++){
			if(lobbyList[i][0] == 0){
				lobbyList[i][0] = client;
				j = 1;
			}
			else if(lobbyList[i][1] == 0){
				lobbyList[i][1] = client;
				j = 0;
				lobbyScores[i][0] = 0;
				lobbyScores[i][1] = 0;
			}
		}
	} else{
		PrintToChat(client, "You already in %i lobby", GetClientLobby(client));
	}
	new String:opponentName[MAX_NAME_LENGTH];
	GetClientName(GetClientWithLobby(i, j), opponentName, MAX_NAME_LENGTH);
	PrintToChat(client, "Now you in %i lobby, your opponent is %s", opponentName);
}

public Action:ResetFromLobby(client, args){
	if(CheckClientLobby(client)){
		for(new i = 0; i < MAXPLAYERS; i++){
			if(lobbyList[i][0] == client){
				lobbyList[i][0] = 0;
			}
			else if(lobbyList[i][1] == client){
				lobbyList[i][1] = 0;
			}
		}
	}
}

bool:CheckClientLobby(client){
    for(new i = 0; i < MAXPLAYERS; i++){
		if(lobbyList[i][0] == client || lobbyList[i][1] == client){
			return true;
		}
    }
	return false;
}

public GetClientLobby(client){
    for(new i = 0; i < MAXPLAYERS; i++){
		if(lobbyList[i][0] == client || lobbyList[i][1] == client)
			return i;
    }
	return 0;
}

public GetClientWithLobby(lobbyNum, clientNum){
	if(lobbyList[lobbyNum][clientNum] != 0)
		return lobbyList[lobbyNum][clientNum];
	return 0;
}

public CheckOpponents(lobbyNum){
	return (lobbyList[lobbyNum][0] != 0 && lobbyList[lobbyNum][1] != 0);
}

public Action:StartDice(client, args){
	if(CheckClientLobby(client) && CheckOpponents(GetClientLobby(client))){
		new lobbyNum = GetClientLobby(client);
		PrintCenterText(GetClientWithLobby(lobbyNum, 0), "Starting dice, wait...");
		PrintCenterText(GetClientWithLobby(lobbyNum, 1), "Starting dice, wait...");
		
		new client1Number = GetRandomInt(0, MaxToRand), client2Number = GetRandomInt(0, MaxToRand);
		
		new String:client1Name[MAX_NAME_LENGTH];
		new String:client2Name[MAX_NAME_LENGTH];
		GetClientName(GetClientWithLobby(lobbyNum, 0), client1Name, MAX_NAME_LENGTH);
		GetClientName(GetClientWithLobby(lobbyNum, 1), client2Name, MAX_NAME_LENGTH);
		
		new bool:resEchoMode = GetConVarBool(g_EchoMode);
		
		if(client1Number > client2Number){
			if(resEchoMode){
				PrintToChatAll("Dice:%s win with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				PrintCenterTextAll("Dice:%s win with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
			} else{
				PrintToChat(GetClientWithLobby(lobbyNum, 0), "Dice:%s win with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				PrintCenterText(GetClientWithLobby(lobbyNum, 0), "Dice:%s win with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				
				PrintToChat(GetClientWithLobby(lobbyNum, 1), "Dice:%s win with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				PrintCenterText(GetClientWithLobby(lobbyNum, 1), "Dice:%s win with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
			}
			
			lobbyScores[lobbyNum][0]++;
		} else if(client1Number < client2Number){
			if(resEchoMode){
				PrintToChatAll("Dice: %s win with %i vs %i of %s", client2Name, client2Number, client1Number, client1Name);
				PrintCenterTextAll("Dice: %s win with %i vs %i of %s", client2Name, client2Number, client1Number, client1Name);	
			} else{
				PrintToChat(GetClientWithLobby(lobbyNum, 0), "Dice:%s win with %i vs %i of %s", client2Name, client2Number, client1Number, client1Name);
				PrintCenterText(GetClientWithLobby(lobbyNum, 0), "Dice:%s win with %i vs %i of %s",  client2Name, client2Number, client1Number, client1Name);
				
				PrintToChat(GetClientWithLobby(lobbyNum, 1), "Dice:%s win with %i vs %i of %s",  client2Name, client2Number, client1Number, client1Name);
				PrintCenterText(GetClientWithLobby(lobbyNum, 1), "Dice:%s win with %i vs %i of %s",  client2Name, client2Number, client1Number, client1Name);
			}
			
			lobbyScores[lobbyNum][1]++;
		} else if((client1Number == client2Number)){
			if(resEchoMode){
				PrintToChatAll("Dice: Draw!%s with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				PrintCenterTextAll("Dice: Draw! %s with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
			}
			else{
				PrintToChat(GetClientWithLobby(lobbyNum, 0), "Dice: Draw!%s with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				PrintCenterText(GetClientWithLobby(lobbyNum, 0), "Dice: Draw!%s with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				
				PrintToChat(GetClientWithLobby(lobbyNum, 1), "Dice: Draw!%s with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
				PrintCenterText(GetClientWithLobby(lobbyNum, 1), "Dice:%s win with %i vs %i of %s",  "Dice: Draw!%s with %i vs %i of %s", client1Name, client1Number, client2Number, client2Name);
			}
		}
		
		if(resEchoMode)
			PrintToChatAll("Now score is: %s - %i, %s - %i", client1Name, lobbyScores[lobbyNum][0], client2Name, lobbyScores[lobbyNum][1]);
		else{
			PrintToChat(GetClientWithLobby(lobbyNum, 0), "Now score is: %s - %i, %s - %i", client1Name, lobbyScores[lobbyNum][0], client2Name, lobbyScores[lobbyNum][1]);
			PrintCenterText(GetClientWithLobby(lobbyNum, 0), "Now score is: %s - %i, %s - %i", client1Name, lobbyScores[lobbyNum][0], client2Name, lobbyScores[lobbyNum][1]);
			
			PrintToChat(GetClientWithLobby(lobbyNum, 1), "Now score is: %s - %i, %s - %i", client1Name, lobbyScores[lobbyNum][0], client2Name, lobbyScores[lobbyNum][1]);
			PrintCenterText(GetClientWithLobby(lobbyNum, 1), "Now score is: %s - %i, %s - %i", client1Name, lobbyScores[lobbyNum][0], client2Name, lobbyScores[lobbyNum][1]);
		}
	}
}

public Action:ShowClientLobbyAndOpponent(client, args){
	if(CheckClientLobby(client)){
		new String:opponentName[MAX_NAME_LENGTH];
		
		if(CheckOpponents(GetClientLobby(client))){
			GetClientName(GetClientOpponent(client), opponentName, MAX_NAME_LENGTH);
			PrintToChat(client, "Your lobby ¹%i and your opponent is %s", GetClientLobby(client), opponentName);
		} else{
			PrintToChat(client, "Your lobby ¹%i and you hasn't an opponent", GetClientLobby(client));
		}
	} else{
		PrintToChat(client, "You are not in a lobby");
	}
}

public OnClientDisconnect(client){
	ResetFromLobby(client, 0);
}

public Action:MoveClientToLobby(client, args){
	new String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	new newLobby = StringToInt(arg);
			
	if(lobbyList[newLobby][0] == 0){
		lobbyScores[GetClientLobby(client)][0] = 0;
		lobbyScores[GetClientLobby(client)][1] = 0;
		
		lobbyScores[newLobby][0] = 0;
		lobbyScores[newLobby][1] = 0;
		
		ResetFromLobby(client, 0);
			
		lobbyList[newLobby][0] = client;
		PrintToChat(client, "Successful! Now you in %i lobby", newLobby);
	} else if(lobbyList[newLobby][1] == 0){
		lobbyScores[GetClientLobby(client)][0] = 0;
		lobbyScores[GetClientLobby(client)][1] = 0;
		
		ResetFromLobby(client, 0);
		lobbyList[newLobby][1] = client;
		
		PrintToChat(client, "Successful! Now you in %i lobby", newLobby);
	} else if(lobbyList[newLobby][0] != 0 && lobbyList[newLobby][1] != 0){
		PrintToChat(client, "Sorry, but %i lobby is full: %N vs %N", newLobby, GetClientWithLobby(newLobby, 0), GetClientWithLobby(newLobby, 1));
	}
}

public GetClientOpponent(client){
	if(CheckClientLobby(client)){
		return lobbyList[GetClientLobby(client)][0] == client ? lobbyList[GetClientLobby(client)][1] : lobbyList[GetClientLobby(client)][0];
	}
	return 0;
}

public Action:CmdPrintLobbies(client, args){
	if(args == 0){
		for(new i = 0; i < MAXPLAYERS; i++){
			if(CheckOpponents(i)){
				new String:client1Name[MAX_NAME_LENGTH];
				new String:client2Name[MAX_NAME_LENGTH];
				GetClientName(lobbyList[i][0], client1Name, MAX_NAME_LENGTH);
				GetClientName(lobbyList[i][1], client2Name, MAX_NAME_LENGTH);
				
				PrintToChat(client, "Lobby ¹%i: %s - %i, %s - %i", i, client1Name, lobbyScores[i][0], client2Name, lobbyScores[i][1]);
			} else if(lobbyList[i][0] != 0){
				new String:clientName[MAX_NAME_LENGTH];
				GetClientName(lobbyList[i][0], clientName, MAX_NAME_LENGTH);
				
				PrintToChat(client, "Lobby ¹%i: %s hasn't an opponent", i, clientName);
			} else if(lobbyList[i][1] != 0){
				new String:clientName[MAX_NAME_LENGTH];
				GetClientName(lobbyList[i][1], clientName, MAX_NAME_LENGTH);
				
				PrintToChat(client, "Lobby ¹%i: %s hasn't an opponent", i, clientName);
			} else{
				PrintToChat(client, "Lobby ¹%i: empty", i);
			}
		} 
	} else{
			new String:buf[32];
			GetCmdArg(1, buf, 32);
			new i = StringToInt(buf);
			if(CheckOpponents(i)){
				new String:client1Name[MAX_NAME_LENGTH];
				new String:client2Name[MAX_NAME_LENGTH];
				GetClientName(lobbyList[i][0], client1Name, MAX_NAME_LENGTH);
				GetClientName(lobbyList[i][1], client2Name, MAX_NAME_LENGTH);
				
				PrintToChat(client, "Lobby ¹%i: %s - %i, %s - %i", i, client1Name, lobbyScores[i][0], client2Name, lobbyScores[i][1]);
			} else if(lobbyList[i][0] != 0){
				new String:clientName[MAX_NAME_LENGTH];
				GetClientName(lobbyList[i][0], clientName, MAX_NAME_LENGTH);
				
				PrintToChat(client, "Lobby ¹%i: %s hasn't an opponent", i, clientName);
			} else if(lobbyList[i][1] != 0){
				new String:clientName[MAX_NAME_LENGTH];
				GetClientName(lobbyList[i][1], clientName, MAX_NAME_LENGTH);
				
				PrintToChat(client, "Lobby ¹%i: %s hasn't an opponent", i, clientName);
			} else{
				PrintToChat(client, "Lobby ¹%i: empty", i);
			}
		}
}