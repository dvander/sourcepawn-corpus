#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#define PL_VERSION "0.0.3"
#define RCBOT_TEAM 2
#define RCBOT_SPAWN_DELAY 0.1


#define TEAM_RED 2
#define TEAM_BLUE 3
#define TEAM_SPEC 1
#define TEAM_BOT 0

//new g_BotID = 0;
new bool:g_NotNow = false;
new bool:g_Kick = false;
//new bool:g_ThisMap = false;
//new g_RCbotClasses[10] = {1, 1, 3, 7, 4, 6, 9, 5, 2, 8};
new g_ClassesRCbot[10] = {1, 1, 8, 2, 4, 7, 5, 3, 9, 6};
new String:g_Classes[10][255] = {"Unknown","Scout", "Soldier", "Pyro", "Demoman", "Heavy", "Engineer", "Medic", "Sniper", "Spy"};

public Plugin:myinfo = {
	name = "TF2 Co-Op",
	author = "Darkimmortal",
	description = "Team Fortress 2 Co-Op Mod",
	version = PL_VERSION,
	url = "http://www.gamingmasters.co.uk/"
}

stock IsClientBot(client){
	///decl String:name[255];
	//GetClientName(client, name, sizeof(name));
	//new bool:result = ;
	//PrintToServer("SPAM LOL [%i] [%s]", result, name);
	//return (StrContains(name, "-[GM]") != -1 || StrContains(name, "RCBot") != -1);
	//new team = GetClientTeam(client);
	//return (team == TEAM_RED || team == TEAM_BOT);
	return GetClientTime(client) > 24*60*60;
}

public CheckBotCount(bool:dc){
	if(!g_NotNow){
		new playas, aredbot, aspecbot, bots;//, noInf;
		//do {
		for(new i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i)){
				decl String:name[255];
				GetClientName(i, name, sizeof(name));
				if(IsClientBot(i)) {
					if(!g_Kick){
						bots ++;
					}
					if(GetClientTeam(i) == TEAM_RED){
						if(g_Kick){
							bots ++;
						}
						aredbot = i;
					} else/* if(GetClientTeam(i) == TEAM_SPEC)*/{
						aspecbot = i;
					}
				} else if(GetClientTeam(i) == TEAM_BLUE) {
					playas ++;
				}
			}
			
		}
		if(bots < playas && (!g_Kick || aspecbot > 0)){
			if(g_Kick){
				ChangeClientTeam(aspecbot, TEAM_RED);
				CreateTimer(10.0, Timer_Spawn, aspecbot);
			} else {
				AddBot();
				//ServerCommand("rcbotd addbot %i 2", TFClassType:g_RCbotClasses[GetClass()]);
			}				
		} else if(bots > playas-(dc ? 1 : 0) && (/*!g_Kick || */aredbot > 0)) {
			//ServerCommand("rcbotd kickbot");		
			if(g_Kick){
				ChangeClientTeam(aredbot, TEAM_SPEC);
			} else {
				ServerCommand("kickid %i", GetClientUserId(aredbot));
			}
		}// else {
			//PrintToChatAll("\x05[TF2 Co-Op] \x03Debug: [%i] [%i]", aspecbot, aredbot);
		//}
		//noInf ++;
		//} while(playas != bots && noInf < 100);
	}	
}

public AddBot(){
	ServerCommand("rcbotd addbot");	
}

public OnMapStart(){
	if(g_Kick){
		ServerCommand("sm_kick @bots");
		for(new i = 0; i < 16; i++){
			CreateTimer(RCBOT_SPAWN_DELAY*i+5.0, Timer_AddBot);
			CreateTimer(RCBOT_SPAWN_DELAY*i+8.0, Timer_CheckBot);
		}
	}
	//g_NotNow = true;
	CreateTimer(4.0, Timer_NoWaiting);
	CreateTimer(15.0, Timer_NotNow);
}

public Action:Timer_NotNow(Handle:Timer){
	g_NotNow = false;
	//g_ThisMap = false;
}

public OnPluginStart(){	
	//if(GetConVarInt(FindConVar("hostport")) != 27019){
	////	SetFailState("TF2 Co-Op has automatically terminated as it is not running on a server with port 27019.");
	//}
	
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i) && !IsClientBot(i)) {
			CheckBotCount(false);
		}
	}
	//ServerCommand("plugin_load \"..\\bin\\HPB_bot2\"");
	/*ServerCommand("sm_kick @bots");
	for(new i = 0; i < 16; i++){
		CreateTimer(0.3*i+5.0, Timer_AddBot);
		CreateTimer(0.3*i+8.0, Timer_CheckBot);
	}*/
	HookEvent("player_spawn", Event_player_spawn);
	HookEvent("player_death", Event_player_death_before, EventHookMode_Pre);
	HookEvent("player_team", Event_player_team);
	HookEvent("player_team", Event_player_team_before, EventHookMode_Pre);
	HookEvent("player_disconnect", Event_player_disconnect);
	HookEvent("player_connect", Event_player_connect, EventHookMode_Pre);
	HookEvent("teamplay_waiting_ends", Event_teamplay_waiting_ends_b, EventHookMode_Pre);
	HookEvent("teamplay_waiting_begins", Event_teamplay_waiting_begins);
	HookEvent("teamplay_game_over", Event_teamplay_game_over_b, EventHookMode_Pre);
	//HookEvent("teamplay_round_start", Event_teamplay_round_start);
	RegAdminCmd("sm_botreset", Command_BotReset, ADMFLAG_KICK, "sm_botreset");	
	new Handle:infoTimer = CreateTimer(90.0, Timer_Info, infoTimer, TIMER_REPEAT);	
	//g_ThisMap = true;
	//CheckBotCount(false);
	//CreateTimer(2.0, Timer_Done);
	ServerCommand("hostname \"GamingMasters.co.uk #5 -- TF2 Co-Op -- v%s\"", PL_VERSION);
}
/*
public Action:Timer_Done(Handle:Timer){
	for(new i = 0; i < 25; i ++){
		PrintToServer(" \n");
	}
	PrintToServer(" Welcome to TF2 Co-Op by Darkimmortal.\n");	
}*/
	
public Action:Timer_Info(Handle:infoTimer){
	PrintToChatAll("\x05[TF2 Co-Op] \x03This server is running \x04TF2 Co-Op Mod by Darkimmortal\x03, created for GamingMasters.co.uk.");
}

public Action:Timer_AddBot(Handle:timer){	
	//new TFClassType:class = TFClassType:g_RCbotClasses[GetClass()];
	//PrintToChatAll("\x05[TF2 Co-Op] \x03Debug: [rcbotd addbot %i %i]", class, RCBOT_TEAM);
	AddBot();
	//ServerCommand("rcbotd addbot %i %i", class, RCBOT_TEAM);
}
public Action:Timer_CheckBot(Handle:timer){	
	CheckBotCount(false);
}
public Action:Timer_NoWaiting(Handle:timer){	
	ServerCommand("mp_waitingforplayers_cancel 1");
}
public Action:Timer_Kick(Handle:timer, any:client){	
	if(IsClientInGame(client)){
		ServerCommand("kickid %i", GetClientUserId(client));
		AddBot();
		//ServerCommand("rcbotd addbot %i 2", TFClassType:g_RCbotClasses[GetClass()]);
	}
}
public Action:Timer_Spawn(Handle:timer, any:client){	
	if(IsClientInGame(client))
		TF2_RespawnPlayer(client);
}
/*
public Action:Timer_Name(Handle:Timer, any:client){	
	decl String:name[255];
	Format(name, sizeof(name), "TF2 Co-Op Bot #%i", g_BotID);
	ClientCommand(client, "name \"%s\"", name);
	//SetClientInfo(client, "name", name);
}*/

public Action:Event_player_connect(Handle:event, const String:name[], bool:dontBroadcast){
	/*decl String:clientName[32], String:networkID[17], String:address[32];
	GetEventString(event, "name", clientName, sizeof(clientName));
	GetEventString(event, "networkid", networkID, sizeof(networkID));
	GetEventString(event, "address", address, sizeof(address));
	
	new Handle:newEvent = CreateEvent("player_connect", true);
	SetEventString(newEvent, "name", clientName);
	SetEventInt(newEvent, "index", GetEventInt(event, "index"));
	SetEventInt(newEvent, "userid", GetEventInt(event, "userid"));
	SetEventString(newEvent, "networkid", networkID);
	SetEventString(newEvent, "address", address);
	
	FireEvent(newEvent, true);*/
	if(g_Kick)
		return Plugin_Handled;	
	return Plugin_Continue;
}

public Action:Event_player_disconnect(Handle:event, const String:name[], bool:dontBroadcast){
	CheckBotCount(true);	
	if(g_Kick)
		return Plugin_Handled;
	return Plugin_Continue;
	//ServerCommand("rcbotd kickbot");
}

public Action:Command_BotReset(client, args){	
	for(new i=1;i<=MaxClients;i++) {
		if(IsClientInGame(i) && IsClientBot(i)) {
			ServerCommand("kickid %i", GetClientUserId(i));
		}
	}
	if(g_Kick){
		for(new i = 0; i < 16; i++){
			CreateTimer(RCBOT_SPAWN_DELAY*i+5.0, Timer_AddBot);
			CreateTimer(RCBOT_SPAWN_DELAY*i+8.0, Timer_CheckBot);
		}
	} else {
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientInGame(i) && !IsClientBot(i)) {
				CheckBotCount(false);
			}
		}
	}
}


public GetClass(){
	/*new bots;
	for(new i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i)){
			if(IsClientBot(i)) {
				bots ++;
			}
		}		
	}
	
	switch(bots){
		case 0: return 1;
		case 1: return 2;
		case 2: return 9;
		case 3: return 7;
		case 4: return 4;
		case 5: return 1;
		case 6: return 2;
		case 7: return 4;
		case 8: return 5;
		case 9: return 9;
		case 10: return 7;
		case 11: return 5;
		case 12: return 1;
		case 13: return 6;
		case 14: return 6;
		case 15: return 1;
		case 16: return 5;
		default: return 7;
	}*/
	//return 7;
	return GetRandomInt(1, 9);
}

public OnClientPutInServer(client){
	CheckBotCount(false);
	//if(!IsClientBot(client)) {
		//ChangeClientTeam(client, TEAM_BLUE);
		//TF2_SetPlayerClass(client, TFClassType:1);
		//CheckBotCount(false);
		//ServerCommand("rcbotd addbot");
	//} else {
		//ChangeClientTeam(client, TEAM_RED);
		//CheckBotCount(false);
		//decl String:name[255];
		//Format(name, sizeof(name), "TF2 Co-Op Bot #%i", g_BotID);
		//ClientCommand(client, "name \"%s\"", name);
		//CreateTimer(1.0, Timer_Class, client);
		//SetClientInfo(client, "name", name);
		//g_BotID ++;
	//}
}


/*
public OnPlayerConnect(client){
	if(GetClientTeam(client) == TEAM_RED){
		OnClientPutInServer(client);
	}
}*/

public Action:Event_player_death_before(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));	
	if(g_Kick && IsClientInGame(client) && IsClientBot(client)) {
		ServerCommand("kickid %i", GetClientUserId(client));
		CreateTimer(0.5, Timer_AddBot);
	} else {
		if(IsClientBot(client) && GetRandomInt(0, 5) == 3){
			
			new aredbot;
			decl String:naem[255];
			for(new i = 1; i <= MaxClients; i++) {
				if(IsClientInGame(i)){
					if(IsClientBot(i)) {
						if(GetClientTeam(i) == TEAM_RED){
							aredbot = i;
						}
					}
				}				
			}
			
			GetClientName(aredbot, naem, sizeof(naem));			
			
			PrintToChatAll("\x05[TF2 Co-Op] \x04%s\x03 (\x04%s\x03) is being swapped out.", naem, g_Classes[g_ClassesRCbot[TF2_GetPlayerClass(client)]]);
			CreateTimer(1.0, Timer_Kick, aredbot);
		} else if(GetClientTeam(client) == TEAM_BLUE || GetClientTeam(client) == TEAM_RED)
			CreateTimer(1.5, Timer_Spawn, client);
	}
		
}

public Action:Event_teamplay_waiting_begins(Handle:event, const String:name[], bool:dontBroadcast){	
	CreateTimer(4.0, Timer_NoWaiting);
}


public Action:Event_teamplay_waiting_ends_b(Handle:event, const String:name[], bool:dontBroadcast){	
	//if(!g_ThisMap){
	if(g_Kick){
		ServerCommand("sm_kick @bots");
		for(new i = 0; i < 16; i++){
			CreateTimer(RCBOT_SPAWN_DELAY*i+5.0, Timer_AddBot);
			CreateTimer(RCBOT_SPAWN_DELAY*i+8.0, Timer_CheckBot);
		}
	}
	//	g_ThisMap = true;
	//}
}

public Action:Event_teamplay_game_over_b(Handle:event, const String:name[], bool:dontBroadcast){	
	//if(!g_ThisMap){
	if(g_Kick){
		ServerCommand("sm_kick @bots");
	}
}

public Action:Event_player_team_before(Handle:event, const String:name[], bool:dontBroadcast){
	return Plugin_Handled;
}

public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0 && IsClientInGame(client) && !IsClientBot(client)) {
		CheckBotCount(false);
	}
}
	
public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientInGame(client) && !IsClientBot(client)) {
		//if(GetClientTeam(client) == TEAM_SPEC){		
		CheckBotCount(false);
		//}
		if(GetClientTeam(client) == TEAM_RED){
			ChangeClientTeam(client, TEAM_BLUE);
			ForcePlayerSuicide(client);
			PrintHintText(client, "You're a human (hopefully) so you stay in BLU.");
			return Plugin_Handled;
		}// else {
		//}
	} else if(g_Kick) {
		decl String:namee[255];
		GetClientName(client, namee, sizeof(namee));
		if(StrContains(namee, "RCBot") != -1)
			ChangeClientTeam(client, TEAM_SPEC);
		//TF2_SetPlayerClass(client, TFClassType:g_RCbotClasses[GetClass()]);
		/*if(GetClientTeam(client) == TEAM_BLUE){
			ChangeClientTeam(client, TEAM_RED);
			ForcePlayerSuicide(client);
			return Plugin_Handled;
		}*/
	}
	return Plugin_Continue;
}