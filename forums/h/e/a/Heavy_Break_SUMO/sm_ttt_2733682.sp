#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>


public Plugin:myinfo = 
{
    name = "Trouble in Terrorist Town/Among Us mode para Counter-Strike: Source",
    author = "Heavy Break Server",
    description = "The allies must protect the hostages from the impostors, if the impostors manage to kill a certain number of hostages in a certain time, the allies will lose, the impostors are chosen randomly each round.", 
    version = "1.0",
    url = "http://steamcommunity.com/groups/heavy_break/  -  Plugin/mod by: Heavy Break SUMO"
};


/* |--------------------------|
   |	 GLOBAL VARIABLES	  |
   |--------------------------| */


// IsPlayerAlive breaks if !IsClientInGame, so do it allways like this althought you knew that client is in game: [if (IsClientInGame(i) && IsPlayerAlive(i) {...} )]

// #defines:
const MAX_PLAYER_QUANTITY_CSS = 65; // 65 is the maximum player quantity avaliable in a Counter-Strike: Source server. There are some servers with 128 player capacity.
const MAX_HOSTAGE_QUANTITY = 125; // Maximum number of hostages possible on a map (you can change it if you want, i think there are no limits in the number of hostages that can be). You can increase or decrease the number.

/* |---------------|
   |    STRUCTS	   |
   |---------------| */


enum STR_PLAYER { 
	bool: isAnImpostor,
	ban_innHurtHostage, // Number of times an impostor hurted a hostage.
	Float: ban_impHurtImp, // Amount of damage done by being an imposter to an imposter.
	Float: ban_innHurtInn, // Amount of damage done by being an innocent to an innocent. (This is probably not necessary because they can be wrong and there will be no problem because they don't know who the impostors are).
	previousMoneyAmount, // This variable is used so that the game does not change the amount of money to the player for killing hostages and others when in this game mode it shouldn't happen.
};

// Remember that players will be able to see the following features or not depending on whether the sm_ttt_command_info command is activated or not.
enum STR_ROUNDCFG { 
	numberOfPlayers, // From the last-last configuration (or if there was not, from the number of players 0), it is used to see which configuration is used depending on the number of players there are for the round.
	numberOfImpostors2, // Number of impostors that will be assigned at the beginning of the round.
	numberOfHostages, // Number of hostages that will spawn at the start of the round.
	numberOfHostagesToKill2, // Number of hostages that the impostors will require to kill to win the game.
	amountOfHostagesHealth // Amount of health the hostages will have to make it easier or more difficult for the impostors to kill them.
}; // When the variables do not have data type indicators at the beginning, they are all integers/new in this structure.

// To see where on a map you are, type cl_showpos 1 in the game console.
enum STR_HOSTAGE_SPAWN { 
	Float: pos[3], // pos: 0X 1Y 2Z
	Float: ang[3]  // ang: 0X 1Y 2Z
};



// I declare the variables with the indicated structures. They look like matrix but they are structure vectors:
new Player[MAX_PLAYER_QUANTITY_CSS][STR_PLAYER]; 
new RoundCfg[MAX_PLAYER_QUANTITY_CSS][STR_ROUNDCFG];
new MAX_FILE_CONFIGS_QUANTITY = 0;
new hostageSpawn[MAX_PLAYER_QUANTITY_CSS][STR_HOSTAGE_SPAWN]; 
new MAP_HOSTAGE_ENT_QUANTITY = 0;

new bool: changingPlayerMoney = false; // This variable is used so that two money exchanges are not obstructed and occur simultaneously, which would cause the server, the plugin to crash or simply start to go wrong.

// I declare pointers to the plugin's own conVars:
new Handle: sm_ttt_overlay_impostors = INVALID_HANDLE; 
new Handle: sm_ttt_overlay_innocents = INVALID_HANDLE; 
new Handle: sm_ttt_min_player_quantity = INVALID_HANDLE;
new Handle: sm_ttt_dead_players_mute = INVALID_HANDLE;
new Handle: sm_ttt_same_impostors = INVALID_HANDLE;
new Handle: sm_ttt_say_if_was_an_impostor = INVALID_HANDLE;
new Handle: sm_ttt_ban_innocent_hostage_hurt = INVALID_HANDLE;
new Handle: sm_ttt_ban_impostor_hurt_impostor = INVALID_HANDLE; 
new Handle: sm_ttt_ban_innocent_hurt_innocent = INVALID_HANDLE; 
new Handle: sm_ttt_ban_time = INVALID_HANDLE; 
new Handle: sm_ttt_impostor_win_money = INVALID_HANDLE;
new Handle: sm_ttt_innocent_win_money = INVALID_HANDLE;
new Handle: sm_ttt_impostor_win_points = INVALID_HANDLE;
new Handle: sm_ttt_innocent_win_points = INVALID_HANDLE;
new Handle: sm_ttt_weapon_sounds = INVALID_HANDLE;
new Handle: sm_ttt_impostors_only_chat = INVALID_HANDLE;
new Handle: sm_ttt_command_impostors = INVALID_HANDLE;
new Handle: sm_ttt_command_info = INVALID_HANDLE;
new Handle: sm_ttt_ban_admins = INVALID_HANDLE;
new Handle: sm_ttt_mute_admins = INVALID_HANDLE;
new Handle: sm_ttt_hostage_random_spawn = INVALID_HANDLE;
new Handle: sm_ttt_show_every_hostage_spawn = INVALID_HANDLE; // You should end the round to see every hostage spawn.
new Handle: sm_ttt_rules_advice_repeat_time = INVALID_HANDLE;
new Handle: sm_ttt_scoreboard_player_alive_check = INVALID_HANDLE;


new bool: matchStarted; // When there are enough players in the game to have a good game and not too few, the game begins.
new numberOfPlayersToStartMatch = 0; // Useful to use with the previous variable. Counts the current connected players in the game.
new greatestClientNumber; // To optimize. If there are fewer players than the maximum amount allowed on server (MaxClients), it doesn't make sense to traverse the entire vector of Players to MaxClients.
new impostorPerClientNumber[MAX_PLAYER_QUANTITY_CSS]; // So that doing certain things is faster than processing all the players to see which are imposters and which are not; for example, when printing them in the menu.
new roundCfgPosVec = 0; // Position in the vector of configurations by number of players.
new roundNumberOfPlayers = 0; // Number of players alive at the end of the freeze time at the start of the round (mp_freezetime).
new numberOfImpostors; // Number of impostors at the start of the round.
new currentNumberOfImpostors = 0; // Number of impostors alive so far.
new numberOfHostagesToKill = 1; // Number of hostages they need to kill.
new Handle: mp_roundtime; // round time in server.cfg or map.cfg. Default CSS conVar.
new Handle: mp_freezetime; // freeze time at the beginning of the round in server.cfg or map.cfg. Default CSS conVar.
new Handle: mp_round_restart_delay; // Waiting time until the round ends until it goes to the next. Default CSS conVar.
new Handle: mp_startmoney; // Initial amount of money of the games (usually 800$) (mp_startmoney). Default CSS conVar.
new roundTimer; // To force the round to end at the time it should end (with the game timer, when it marks 00:00).
new disableChangingMoneyTimer; // Timer to change the money that the game has assigned to a player, so you only win or lose at the end of the round.
new bool: playersCanSpawn; // Lapse of time between which the round ends for any reason and the frozen time ends at the start of the next round.
new money_count; // To give money to the players.
new T_SCORE = 0; // I accumulate the score that the impostors would have.
new CT_SCORE = 0; // I accumulate the score that the innocents would have.
new hostageEntityNumber[MAX_HOSTAGE_QUANTITY]; // Entity number (assigned by sourcemod or by the Source engine itself) of each hostage to know which entities to remove and which not.




/* --------------------------------------
	  LOAD EVENTS AND DEFINE FUNCTIONS
   -------------------------------------- */


public OnPluginStart()
{	
	LoadTranslations("ttt.phrases"); // FILE NAME TO GO IN addons / sourcemod / translations / <FILE NAME>. THAT FILE MUST HAVE THE WORDS IN THE DIFFERENT LANGUAGES (fr, es, ru, chi, etc). 
	
	AddTempEntHook("Shotgun Shot", CSS_Hook_ShotgunShot);	
	
	// Call some pre-existing convars from the game needed:
	mp_roundtime = FindConVar("mp_roundtime");	
	mp_freezetime = FindConVar("mp_freezetime");
	mp_round_restart_delay = FindConVar("mp_round_restart_delay");
	mp_startmoney = FindConVar("mp_startmoney");
	
	// Later it will serve to assign money to the players.
	money_count = FindSendPropInfo("CCSPlayer", "m_iAccount");
	
	// Loading events to modify and use (your declarations):
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_ClientSpawn, EventHookMode_Post);
	HookEvent("player_connect", Event_PlayerConnect, EventHookMode_Post);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("hostage_hurt", EventHostageHurt, EventHookMode_Post);
	HookEvent("hostage_killed", EventHostageKilled, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre); 

	sm_ttt_overlay_impostors = CreateConVar("sm_ttt_overlay_impostors", "overlays/ttt/impostors_overlay", "Path to overlay material file to show to impostors.");
	sm_ttt_overlay_innocents = CreateConVar("sm_ttt_overlay_innocents", "overlays/ttt/innocents_overlay", "Path to overlay material file to show to innocents.");
	sm_ttt_min_player_quantity = CreateConVar("sm_ttt_min_player_quantity", "4", "Minimum number of players to start the serious game. If it is 0 or less, the game starts with any number of players, even if they were very few.");
	sm_ttt_dead_players_mute = CreateConVar("sm_ttt_dead_players_mute", "1", "If it is 1, the dead players CANNOT speak or write to the living players, only with other dead players, if it is 0, they can.");
	sm_ttt_same_impostors = CreateConVar("sm_ttt_same_impostors", "1", "If it is 1, the impostors can be the same as in the previous round. If it is 0 no. If it is 2, the number of impostors is random (always less than half the total number of players).");
	sm_ttt_say_if_was_an_impostor = CreateConVar("sm_ttt_say_if_was_an_impostor", "1", "Tell all players if the player who died was an imposter.");
	sm_ttt_ban_innocent_hostage_hurt = CreateConVar("sm_ttt_ban_innocent_hostage_hurt", "11", "Amount of times an innocent could injure a hostage until banned. If he kills him he counts as if he had hurt him 3 times. If it is 0 it is disabled.");
	sm_ttt_ban_impostor_hurt_impostor = CreateConVar("sm_ttt_ban_impostor_kill_impostor", "300", "Amount of health that an impostor must take from an impostor to be banned. If it is 0 it is disabled.");
	sm_ttt_ban_innocent_hurt_innocent = CreateConVar("sm_ttt_ban_innocent_kill_innocent", "700", "Amount of health that an innocent should take from another innocent to be banned. If it is 0 it is disabled.");
	sm_ttt_ban_time = CreateConVar("sm_ttt_ban_time", "20", "Number of minutes that a player will be banned in case of commenting on the indicated amount of inconsistencies. In case it is 0 the ban will be permanent."); 
	sm_ttt_impostor_win_money = CreateConVar("sm_ttt_impostor_win_money", "4000", "Amount of money that will be assigned to impostors if they win.");
	sm_ttt_innocent_win_money = CreateConVar("sm_ttt_innocent_win_money", "2000", "Amount of money that will be assigned to the innocent if they win.");
	sm_ttt_impostor_win_points = CreateConVar("sm_ttt_impostor_win_points", "3", "Amount of frags that will be assigned to impostors if they win.");
	sm_ttt_innocent_win_points = CreateConVar("sm_ttt_innocent_win_points", "1", "Amount of frags that will be assigned to innocents if they win.");
	sm_ttt_weapon_sounds = CreateConVar("sm_ttt_weapon_sounds", "1", "Allows or not the alive players, to hear the shots of the other players or not. If it is 0 the alive players will only be able to hear their own shots. If it's 1, everyone can listen.");
	sm_ttt_impostors_only_chat = CreateConVar("sm_ttt_impostors_only_chat", "1", "If enabled, imposters will be able to communicate with each other via team chat.");
	sm_ttt_command_impostors = CreateConVar("sm_ttt_command_impostors", "2", "If 0, only dead admins will be able to use this command. If 1, only dead players will be able to use this command. If 2, only impostors will be able to use this command. If 3, only impostors and dead players will be able to use this command. Dead admins will allways be able to use this command.");
	sm_ttt_command_info = CreateConVar("sm_ttt_command_info", "1", "If 0 nobody will be able to use this command. If 1 everyone will be able to use it.");	
	sm_ttt_ban_admins = CreateConVar("sm_ttt_ban_admins", "1", "If 0 admins won't be automatically banned in case they break the limits.");
	sm_ttt_mute_admins = CreateConVar("sm_ttt_mute_admins", "1", "If 0 admins won't be muted when they die. Admins will be able to use Team chat to communicate something to everybody.");	
	sm_ttt_hostage_random_spawn = CreateConVar("sm_ttt_hostage_random_spawn", "1", "If 0, hostages allways spawn in the same positions. If 1 they spawn in rnadom positions.");
	sm_ttt_show_every_hostage_spawn = CreateConVar("sm_ttt_show_every_hostage_spawn", "0", "THIS IS ONLY TO CHECK IF YOUR SPAWN CONFIGS ARE AS YOU IMAGINED IT OR IF YOU WANT TO MODIFY THEM. WHEN PLAYING WITH PEOPLE DISABLE IT. End round to see changes. To enable it 1 and to disable it and play normaly 0.");
	sm_ttt_rules_advice_repeat_time = CreateConVar("sm_ttt_rules_advice_repeat_time", "60", "Time in seconds between rules message displays for all players. 0 to disable.");
	sm_ttt_scoreboard_player_alive_check = CreateConVar("sm_ttt_scoreboard_player_alive_check", "0", "Players can see if the other players are alive or not with the scoreboard.");
	HookConVarChange(sm_ttt_scoreboard_player_alive_check, OnConVarChangeAliveCheck);
	
	RegConsoleCmd("sm_info", Command_info, "Shows the player certain details of the game.");
	RegConsoleCmd("sm_impostors", Command_impostors, "Shows the player who are the impostors.");
	RegConsoleCmd("sm_tttrules", Command_tttrules, "Shows the player the rules of the game.");
	RegConsoleCmd("say", Command_Say, "It comes by default with the game, it happens when a player sends a message commonly."); // ESTO SOLO HACE QUE AL ESCRIBIR ALGO SI ESTABAS GAGEADO NO PUEDAS ESCRIBIR.
	RegConsoleCmd("say_team", Command_Say_Team, "It comes by default with the game, it happens when a player sends a team-message commonly.");
	
	return; 
}




/* |--------------------------------------------------------------------------- |
   |								GAME EVENTS									|
   |--------------------------------------------------------------------------- | */


public void OnMapStart() 
{
	// Message to advice players how to see rules:
	if (GetConVarFloat(sm_ttt_rules_advice_repeat_time) > 0) {
		CreateTimer(GetConVarFloat(sm_ttt_rules_advice_repeat_time), TTTRulesDisplayAdvice, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}

	// If there is a minimum number of players defined for the game to start, it is marked that the game did not start when starting the map. Else, is marked as started.
	if (GetConVarInt(sm_ttt_min_player_quantity) > 0) {
		matchStarted = false; 
	} else {
		matchStarted = true;
	}
	
	// The following makes it possible to prevent players from seeing if other players are alive:
    if (!GetConVarBool(sm_ttt_scoreboard_player_alive_check)) {
	    new playerManagerEnt = -1;
	    playerManagerEnt = FindEntityByClassname(playerManagerEnt, "cs_player_manager");
	    if (playerManagerEnt != INVALID_ENT_REFERENCE) {
	        SDKHook(playerManagerEnt, SDKHook_ThinkPost, Hook_OnThinkPost_Player);
	    }
    }
    
	// I INITIALIZE THE STRUCTURE:
	new i = 0; 
	while (i < MaxClients) { 
		Player[i][isAnImpostor] = false;
		Player[i][ban_innHurtHostage] = 0;
		Player[i][ban_impHurtImp] = 0;
		Player[i][ban_innHurtInn] = 0;
		Player[i][previousMoneyAmount] = 0; 
		i++;
	}
	
	
  /* | ----------------------------------------------------------------------------- |
	 | TOMO CONFIGURACIONES DE LOS ARCHIVOS Y LAS GUARDO EN VECTORES DE ESTRUCTURAS  |
	 | ----------------------------------------------------------------------------- | */
	
	decl String: filePath[PLATFORM_MAX_PATH]; // You have to save the file address in a special way so I save it in this character vector.
    decl String: currentMapName[64];
    GetCurrentMap(currentMapName, sizeof(currentMapName)); // I get the name of the current map to later read the configuration of its spawns and know how is the spawn file config name:
	BuildPath(Path_SM, filePath, sizeof(filePath), "%s%s%s", "configs/ttt/hostage_spawnpoints/", currentMapName, ".txt"); 
	new Handle: file = OpenFile(filePath, "r"); 
	// IF THE FILE IS NOT FOUND, IT SHOWS AN ERROR:
	if (file == INVALID_HANDLE) { PrintToChatAll("%s%t", "[TTT] ERROR - ", "Hostage spawns file error"); MAP_HOSTAGE_ENT_QUANTITY = 0; return Plugin_Continue; }	
	
	decl String: textLine[120];

	MAP_HOSTAGE_ENT_QUANTITY = 0; 
	while (!IsEndOfFile(file)) {
		ReadFileLine(file, textLine, sizeof(textLine)); // I read a line from the text file. It will automatically read the next one with each while iteration unless the file is closed and reopened.
		
		// I CONFIRM THAT IT IS NOT A READING TEXT LINE INSTEAD OF ONE WITH VALUES TO TAKE:
		if (textLine[0] != '/' && textLine[1] != '/' && textLine[0] != '\n' && textLine[0] != '\0') {
			// I INITIALIZE THE STRUCTURE AT THE SAME TIME:
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][pos][0] = 0; // IT LOOKS LIKE A THREE-DIMENSIONAL MATRIX BUT IT IS A VECTOR WITHIN A VECTOR OF STRUCTURES. THE SECOND DIMENSION IS THE NAME OF THE STRUCTURE VECTOR. 
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][pos][1] = 0; 
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][pos][2] = 0; 
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][0] = 0; 
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][1] = 0; 
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][2] = 0;	
			i = 0;
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; } // I MOVE FORWARD WHILE IT IS NOT THE FIRST VALUE
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][pos][0] = stringToPosOrAng(textLine, i);
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; } // I MOVE FORWARD WHILE IT ISN'T A VALUE
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][pos][1] = stringToPosOrAng(textLine, i);
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; } // I MOVE FORWARS WHILE IT ISN'T A VALUE
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][pos][2] = stringToPosOrAng(textLine, i);
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][pos][2] -= 65; // I lower 65 to that coordinate because when taking the values with cl_showpos 1, the values it indicates are 65 times (apparently) higher than the position in which the player is standing.
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; } // SAME...
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][0] = stringToPosOrAng(textLine, i);
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; } 
			hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][1] = stringToPosOrAng(textLine, i);
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; } 
			if (textLine[i] == '-') {  	// I BRING ALL THE StringToPosOrAng FUNCTION BECAUSE THE LAST VALUE MAY BE '\ n' (End of line in file) OR '\ 0' (end of character vector).
				i++;
				while (textLine[i] != ' ' && textLine[i] != '|' && textLine[i] != '\n' && textLine[i] != '\0') { // I CONFIRM THAT IT IS A NUMBER
					hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][2] = hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][2] * 10 + charToInt(textLine[i]); // IT GOES CONVERTING THE NUMBER AS THE CHARACTERS ARE READ.
					i++;
				}		
				hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][2] = hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][2] * (-1); // LO HAGO NEGATIVO.		
			} else {
				while (textLine[i] != ' ' && textLine[i] != '|' && textLine[i] != '\n' && textLine[i] != '\0') { // DOY POR CONFIRMADO QUE ES UN NUMERO
					hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][2] = hostageSpawn[MAP_HOSTAGE_ENT_QUANTITY][ang][2] * 10 + charToInt(textLine[i]); // VA CONVIRTIENDO EL NUMERO A MEDIDA QUE SE LEEN LOS CARACTERES.
					i++;
				}	
			}
			
			MAP_HOSTAGE_ENT_QUANTITY++;			
		}
		
	}
	// FINISHED GETTING THE SPAWN POSITIONS FROM THE ARCHIVE HOSTAGE

	// I CLOSE THE FILE SO THAT IT DOES NOT STAY UNNECESSARILY OPENED (I MAY USE THE PROCESSOR UNNECESSARILY).
	CloseHandle(file); 
	file = INVALID_HANDLE; 

	
	// ---------------------------------------------------------------------------------------------------
	// I READ THE ROUND SETTINGS BY NUMBER OF PLAYERS FROM THE FILE AND SAVE THEM IN THE STRUCTURE VECTOR:
	
	BuildPath(Path_SM, filePath, sizeof(filePath), "configs/ttt/ttt_configs_per_player_quantity.txt"); 
	file = OpenFile(filePath, "r"); 
	// IF THE FILE IS NOT FOUND SHOWS AN ERROR:
	if (file == INVALID_HANDLE) { PrintToChatAll("%s%t", "[TTT] ERROR - ", "Round configs file error"); return Plugin_Continue; } 
	
	MAX_FILE_CONFIGS_QUANTITY = 0; // NUMBER OF CONFIGURATIONS IN THE TEXT FILE
	while (!IsEndOfFile(file)) {
		
		ReadFileLine(file, textLine, sizeof(textLine)); // I read a line from the text file. It will automatically read the next one with each while iteration unless the file is closed and reopened.
		
		// I CONFIRM THAT IT IS NOT A LEGIBLE TEXT LINE INSTEAD OF ONE WITH VALUES TO TAKE:
		if (textLine[0] != '/' && textLine[1] != '/' && textLine[0] != '\n' && textLine[0] != '\0') { // IF IN THE TEXT LINE THE FIRST CHARACTERS ARE: //, THE FOLLOWING IN THE LINE IS ONLY TEXT SO IT IS NOT EVALUATED.

			// IN STEP I INITIALIZE THE STRUCTURE AT THE SAME TIME:
			RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfPlayers] = 0;
			RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfImpostors2] = 0;
			RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostages] = 0;	
			RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostagesToKill2] = 0;
			RoundCfg[MAX_FILE_CONFIGS_QUANTITY][amountOfHostagesHealth] = 0; 	
	
			i = 0;
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; } // // I MOVE FORWARD WHILE IT IS NOT THE FIRST VALUE

			while (textLine[i] != ' ' && textLine[i] != '|') { // I CONFIRM THAT IT IS A NUMBER
				RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfPlayers] = RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfPlayers] * 10 + charToInt(textLine[i]); // VA CONVIRTIENDO EL NUMERO A MEDIDA QUE SE LEEN LOS CARACTERES.
				i++;
			}
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; }
			
			while (textLine[i] != ' ' && textLine[i] != '|') { 
				RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfImpostors2] = RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfImpostors2] * 10 + charToInt(textLine[i]);
				i++;
			}
		
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; }
			
			while (textLine[i] != ' ' && textLine[i] != '|') { 
				RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostages] = RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostages] * 10 + charToInt(textLine[i]);
				i++;
			}
			
			while (textLine[i] == ' ' || textLine[i] == '|') { i++; }
			
			while (textLine[i] != ' ' && textLine[i] != '|') { 
				RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostagesToKill2] = RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostagesToKill2] * 10 + charToInt(textLine[i]);
				i++;
			}

			while (textLine[i] == ' ' || textLine[i] == '|') { i++; }
			
			while (textLine[i] != ' ' && textLine[i] != '|' && textLine[i] != '\n' && textLine[i] != '\0') { 
				RoundCfg[MAX_FILE_CONFIGS_QUANTITY][amountOfHostagesHealth] = RoundCfg[MAX_FILE_CONFIGS_QUANTITY][amountOfHostagesHealth] * 10 + charToInt(textLine[i]);
				i++;
			}	

			// if IN CASE THERE ARE MORE HOSTAGES THAN SPAWNS OF HOSTAGES:
			if (RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostages] > MAP_HOSTAGE_ENT_QUANTITY - 1) {
				RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostages] = MAP_HOSTAGE_ENT_QUANTITY - 1;
				if (RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostagesToKill2] > MAP_HOSTAGE_ENT_QUANTITY - 1) {
					RoundCfg[MAX_FILE_CONFIGS_QUANTITY][numberOfHostagesToKill2] = MAP_HOSTAGE_ENT_QUANTITY - 1;
				}
			}
			
			MAX_FILE_CONFIGS_QUANTITY++;
		}
		
	}
	// I FINISH OF GETTING THE SETTINGS BY AMOUNT OF PLAYERS IN THE FILE

	// I CLOSE THE FILE SO THAT IT DOES NOT STAY UNNECESSARILY OPENED (I MAY USE THE PROCESSOR UNNECESSARILY).
	CloseHandle(file); 
	file = INVALID_HANDLE; 
	
	// I initialize more variables:
	changingPlayerMoney = false; 
	playersCanSpawn = true; 
	numberOfPlayersToStartMatch = 0;
	roundNumberOfPlayers = 0; 
	
	return Plugin_Continue;
}	

// Timer of the message with the command that allows you to see the rules:
public Action TTTRulesDisplayAdvice(Handle timer) 
{ 
	PrintToChatAll("%s%t%s%t", "\x07FF7700[TTT] ", "Rules advertisment 1", " \x0733FF88!tttrules \x07FF7700", "Rules advertisment 2");
	return Plugin_Continue;
}


public float stringToPosOrAng(char[] textLine, int& i) 
{
	float pos1 = 0;
	if (textLine[i] == '-') {  
				
		i++;
		while (textLine[i] != ' ' && textLine[i] != '|') { // I CONFIRM THAT IT IS A NUMBER
			pos1 = pos1 * 10 + charToInt(textLine[i]); // IT GOES CONVERTING THE NUMBER WHEN THE CHARACTERS ARE READ.
			i++;
		}
				
		pos1 = pos1 * (-1); // I MAKE IT NEGATIVE.
				
	} else {

		while (textLine[i] != ' ' && textLine[i] != '|') { // I CONFIRM THAT IT IS A NUMBER
			pos1 = pos1 * 10 + charToInt(textLine[i]); // IT GOES CONVERTING THE NUMBER WHEN THE CHARACTERS ARE READ.
			i++;
		}
				
	}

	return pos1;
}

		
// HELPER:
public int charToInt(char character) 
{
	switch (character) {
		case '0': { return 0; }
		case '1': { return 1; }		
		case '2': { return 2; }
		case '3': { return 3; }
		case '4': { return 4; }
		case '5': { return 5; }
		case '6': { return 6; }
		case '7': { return 7; }
		case '8': { return 8; }
		case '9': { return 9; }
	}
	// IT SHOULD NOT GET THROUGH HERE BECAUSE IT SHOULD BE A NUMBER. IT ALREADY DEPENDS ON WHAT THEY HAVE CREATED THE TEXT FILE WITH THE CONFIGURATIONS WELL OR NOT.
	return -1;
}

// THE FOLLOWING IS ONLY TO ALLOW OR NOT PLAYERS TO SEE WHETHER THE PLAYERS ARE ALIVE OR NOT ON THE SCOREBOARD:
public OnConVarChangeAliveCheck(Handle: convar, const String: oldValue[], const String: newValue[])
{	
	new playerManagerEnt = -1; 
	playerManagerEnt = FindEntityByClassname(playerManagerEnt, "cs_player_manager");
	if (playerManagerEnt != INVALID_ENT_REFERENCE) {	
		if (newValue[0] == '0') { 
			SDKHook(playerManagerEnt, SDKHook_ThinkPost, Hook_OnThinkPost_Player); // I PREVENT PLAYERS FROM SEEING WHO IS ALIVE.
		} else {
			SDKUnhook(playerManagerEnt, SDKHook_ThinkPost, Hook_OnThinkPost_Player); // I ALLOW PLAYERS TO SEE WHO IS ALIVE.
		}
	}
	return Plugin_Handled;
}

// THE FOLLOWING IS SO THAT THE PLAYERS CANNOT SEE IF THE OTHER PLAYERS ARE ALIVE OR NOT FROM THE LIST (WITH tab IN-GAME):
public Hook_OnThinkPost_Player(playerManagerEnt) 
{
	new playersToDisable[MAXPLAYERS+1] = {1,...};  
	static isAliveOffset = -1;
	
	if (isAliveOffset == -1) {
		isAliveOffset = FindSendPropInfo("CCSPlayerResource", "m_bAlive");
	}
		    
	SetEntDataArray(playerManagerEnt, isAliveOffset, playersToDisable, MaxClients+1);
	
	return Plugin_Handled;
} 




public OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage); // <--- To be able to modify shots damage.
	return;
}



//WITH THE FOLLOWING, THE DAMAGE IS MEASURED AND THE BANS ARE ADJUSTED (IN CASE OF BEING FROM THE SAME TEAM, THOSE WHO ATTACK EACH OTHER IF THE DAMAGE IS EQUALED TO BE EVEN MORE).
public Action OnPlayerTakeDamage(int victim, int &attacker, int &inflictor, &Float: damage, int &damagetype)
{//        killed himself     killed by map       killed by prop
	if (victim == attacker || attacker == 0 || attacker > MaxClients) {  // If killed himself don't process.
		return Plugin_Continue;
	}
	
	if (!Player[attacker - 1][isAnImpostor] && !Player[victim - 1][isAnImpostor]) 
	{ // INNOCENT ATTACKS INNOCENT:
		if (damage <= GetClientHealth(victim)) { // IF THE DAMAGE WAS GREATER THAN THE HEALTH THE CLIENT HAD, THE DAMAGE IS THE SAME AS THE HEALTH THE CLIENT HAD.
			Player[attacker - 1][ban_innHurtInn] += damage;
		} else {
			Player[attacker - 1][ban_innHurtInn] += GetClientHealth(victim);
		}
		
		// IF CAUSED ENOUGH DAMAGE BY BEING INNOCENT AND HURTING INNOCENTS, WILL BE BANNED:
		if (Player[attacker - 1][ban_innHurtInn] >= GetConVarInt(sm_ttt_ban_innocent_hurt_innocent) && GetConVarInt(sm_ttt_ban_innocent_hurt_innocent) > 0) 
		{ 
			// 			CAN BAN ADMINS              		CAN'T BAN ADMINS AND WASN'T AN ADMIN			
			if (GetConVarBool(sm_ttt_ban_admins) || !GetConVarBool(sm_ttt_ban_admins) && !isPlayerAnAdmin(attacker)) { 
				PrintToChat(attacker, "%s%t", "\x07FF0000[TTT] - ", "BAN - innocent kill/hurt innocent chat msg");
				decl String: banMessage[85];
				Format(banMessage, sizeof(banMessage), "%t", "BAN - innocent kill/hurt innocent msg");
				BanPlayer(attacker, banMessage);
			} else { // Otherwise, the player was an admin and admins cannot be banned if the convar sm_ban_admins was 0.
				PrintToChat(attacker, "%s%t", "\x07FF0000[TTT] - ", "BAD ADMIN");
			}
		}			
	} else if (Player[attacker - 1][isAnImpostor] && Player[victim - 1][isAnImpostor]) { 
		// IMPOSTOR ATTACKS IMPOSTOR
		if (damage <= GetClientHealth(victim)) { // IF THE DAMAGE WAS GREATER THAN THE HEALTH THE CLIENT HAD, THE DAMAGE IS THE SAME AS THE HEALTH THE CLIENT HAD.
			Player[attacker - 1][ban_impHurtImp] += damage;
		} else {
			Player[attacker - 1][ban_impHurtImp] += GetClientHealth(victim);
		}
		
		// IF CAUSED ENOUGH DAMAGE BY BEING INNOCENT AND HURTING INNOCENTS, WILL BE BANNED:
		if (Player[attacker - 1][ban_impHurtImp] >= GetConVarInt(sm_ttt_ban_impostor_hurt_impostor) && GetConVarInt(sm_ttt_ban_impostor_hurt_impostor) > 0) 
		{		
			if (GetConVarBool(sm_ttt_ban_admins) || !GetConVarBool(sm_ttt_ban_admins) && !isPlayerAnAdmin(attacker)) { 
				PrintToChat(attacker, "%s%t", "\x07FF0000[TTT] - ", "BAN - impostor kill/hurt impostor chat msg");
				decl String: banMessage[85];
				Format(banMessage, sizeof(banMessage), "%t", "BAN - impostor kill/hurt impostor msg");
				BanPlayer(attacker, banMessage);				
			} else { // If not, the player was an admin and admins cannot be banned if the convar sm_ban_admins was 0.
				PrintToChat(attacker, "%s%t", "\x07FF0000[TTT] - ", "BAD ADMIN");
			}
		}		
	} 
	
    // Make friendly fire damage equal to the original damage. WITHOUT SDKHOOKS IT DOES NOT WORK.
    if (GetClientTeam(attacker) == GetClientTeam(victim))
	{
		damage *= 2.45; // Testing on my own it seems that the original damage is 245% times higher than attacking someone on your own team by default.
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
} 

// THE FOLLOWING FUNCTION ALLOWS DEAD PLAYERS TO HEAR SHOTS AND OTHERS WHILE LIVE PLAYERS NOT IN CASE THE CONFIGURATION HAS BEEN ADJUSTED SO THAT THE GUN SHOOTS CANNOT BE HEARD:
public Action CSS_Hook_ShotgunShot(const String:te_name[], const Players[], numClients, Float:delay) 
{
	if (GetConVarBool(sm_ttt_weapon_sounds)) {
		return Plugin_Continue;
	} // else disable sound for alive players:
	
	decl newClients[MaxClients]; // Vector with the dimensions of the number of players that the server supports.
	new newTotal = 0;
	
	new i = 1;
	while (i <= MaxClients)
	{	
		if (IsClientInGame(i) && !IsPlayerAlive(i))
		{
			newClients[newTotal] = i; // The client is added to the vector with the people who are going to be shown (made to listen) what happened.
			newTotal++; 			  // (THAT AREN'T ALIVE)
		}
		i++;
	}	
	
	if (newTotal == numClients) { // If there are no players alive, show what happened to all players.
		return Plugin_Continue;
	} else if (newTotal == 0) { // If all players are alive do not show what happened to any player.
		return Plugin_Stop;
	} // Otherwise, what will be shown (the sound of the shot) is processed for the players who are dead obtained in the previous while.
	
	decl Float:vTemp[3];
	TE_Start("Shotgun Shot");
	TE_ReadVector("m_vecOrigin", vTemp);
	TE_WriteVector("m_vecOrigin", vTemp);
	TE_WriteFloat("m_vecAngles[0]", TE_ReadFloat("m_vecAngles[0]"));
	TE_WriteFloat("m_vecAngles[1]", TE_ReadFloat("m_vecAngles[1]"));
	TE_WriteNum("m_iWeaponID", TE_ReadNum("m_iWeaponID"));
	TE_WriteNum("m_iMode", TE_ReadNum("m_iMode"));
	TE_WriteNum("m_iSeed", TE_ReadNum("m_iSeed"));
	TE_WriteNum("m_iPlayer", TE_ReadNum("m_iPlayer"));
	TE_WriteFloat("m_fInaccuracy", TE_ReadFloat("m_fInaccuracy"));
	TE_WriteFloat("m_fSpread", TE_ReadFloat("m_fSpread"));
	TE_Send(newClients, newTotal, delay); // newClients == vector with the client numbers that will be shown.
	// newTotal is up to which position of the vector it will show (make the players hear the shot).
	
	// If Plugin_Stop is returned, what would have happened won't happen.
	return Plugin_Stop;
}




public Action: Command_Say(int client, int args) 
{
	decl String: clientName[40];
	decl String: writtenCharVec[130]; // 127 characters allows to write the CSS in the server chat
	
	GetClientName(client, clientName, sizeof(clientName));
	GetCmdArgString(writtenCharVec, sizeof(writtenCharVec)); // transfers what the player wrote in that variable.
	StripQuotes(writtenCharVec); // THIS TAKES THE ASTERISKS OUT OF WHAT IS WRITTEN. IT'S NOT LIKE THIS: "writtenCharVec". WITH StripQuotes LOOKS LIKE: writtenCharVec .
	
	// If what has been writen was the command "!impostors", only the one who wrote it can see it.
	if (IsClientInGame(client) && IsPlayerAlive(client) && strcmp(writtenCharVec, "!impostors") == 0) {
		PrintToChat(client, "%s%t%s%s%s%s", "\x0766EEFF[TTT] ", "NOBODY CAN SEE WHAT YOU WROTE", ": ", hexColorByClientNumber(client), clientName, ": \x01!impostors");
		return Plugin_Handled;
	}

	// The following makes if a player was dead; other players can only see what you wrote if they were also dead:
	new i = 1;	
	if (!IsPlayerAlive(client) && GetConVarBool(sm_ttt_dead_players_mute)) 
	{
		while (i <= MaxClients) {
			if (IsClientInGame(i) && !IsPlayerAlive(i)) 
			{
				PrintToChat(i, "%s%s%s%s%s", "\x0766EEFF[TTT ONLY DEAD PLAYERS CHAT] ", hexColorByClientNumber(client), clientName, ": \x01", writtenCharVec);
			}
			i++;
		}	
		return Plugin_Handled; 
		
	} else if (!IsPlayerAlive(client) && !GetConVarBool(sm_ttt_dead_players_mute)) { // THE PLAYER IS DEAD BUT THE CONVAR IS NOT ACTIVE
		// IF IT WAS ALLOWED FOR LIVING PLAYERS TO VIEW WHAT THE DEAD WROTE, IT IS PRINTED FOR EVERYONE (DO THIS ONLY IF THE SERVER HAS MANY RELIABLE AND ACTIVE ADMINS TO CONTROL THAT DO NOT DATE):
		PrintToChatAll("%s%s%s%s%s", "\x0766EEFF-DEAD- ", hexColorByClientNumber(client), clientName, ": \x01", writtenCharVec);
		return Plugin_Handled;
		
	} 
	// IF THE PLAYER WAS ALIVE SEND THE MESSAGE TO EVERYONE:
	PrintToChatAll("%s%s%s%s", hexColorByClientNumber(client), clientName, ": \x01", writtenCharVec);
	
	return Plugin_Handled;
}


public Action: Command_Say_Team(int client, int args)
{
	if (GetConVarBool(sm_ttt_impostors_only_chat)) {
		// IF THE PLAYER WAS AN IMPOSTOR AND USED THE TEAM CHAT SEND THE MESSAGE ONLY TO THE OTHER IMPOSTORS.
		if (Player[client - 1][isAnImpostor] && !playersCanSpawn && IsPlayerAlive(client)) // IT IS KNOWN THAT IsClientInGame BECAUSE WHEN AN IMPOSTOR IS DISCONNECTED AUTOMATICALLY IT WILL STOP BEING AN IMPOSTOR SO THE FIRST BOOL WOULD NOT BE FULFILLED.
		{
			decl String: clientName[40];
			decl String: writtenCharVec[130]; 
	
			GetClientName(client, clientName, sizeof(clientName));
			GetCmdArgString(writtenCharVec, sizeof(writtenCharVec)); // transfer what the player wrote in that variable.
			StripQuotes(writtenCharVec); // THIS TAKES THE ASTERISKS OUT OF WHAT WAS WROTE
			
			new i = 0;
			while (i < numberOfImpostors) {
				if (Player[impostorPerClientNumber[i] - 1][isAnImpostor]) {
					PrintToChat(impostorPerClientNumber[i], "%s%s%s%s%s", "\x07FF0000[TTT ONLY IMPOSToRS CHAT] ", hexColorByClientNumber(client), clientName, ": \x01", writtenCharVec);
					i++;
				}
			}
		
		} else if (!isPlayerAnAdmin(client) || isPlayerAnAdmin(client) && GetConVarBool(sm_ttt_mute_admins)){
			PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x04", "ACCES DENIED - Impostors only chat");
		} else { // ELSE THE PLAYER WAS ADMIN AND THE ADMINS COULDN'T BE MUTED:
			// ADMINS CAN SEND A MESSAGE TO EVERYONE BEING DEAD AS FOLLOWS:
			decl String: clientName[40];
			decl String: writtenCharVec[130];
			GetClientName(client, clientName, sizeof(clientName));
			GetCmdArgString(writtenCharVec, sizeof(writtenCharVec));
			StripQuotes(writtenCharVec);
			PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x04", "SPECIAL ADMIN MESSAGE");
			PrintToChatAll("%s%s%s%s", "\x07FF7700[TTT ADMIN MESSAGE]\x04 ", clientName, ": \x01", writtenCharVec);
		}
		
	} else {
		PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "Deactivated team chat");
	}

	return Plugin_Handled;
}


public Action: Command_info(int client, int args)
{
	if (client == 0) // IN CASE SOMEONE TRIES TO ACCESS FROM THE TERMINAL/CMD.
	{
		ReplyToCommand(client, "%s%t", "[TTT] ", "Command is in-game only");
		return Plugin_Handled;
	}	
	
	if (GetConVarBool(sm_ttt_command_info)) { // IF THE COMMAND WAS AVAILABLE, PRINT THE MENU:
		
		char charVec[60]; 
		
		Menu menu = new Menu(menuInfoCallback);
		menu.SetTitle("%t", "Round info menu display");
		
		Format(charVec, sizeof(charVec), "%t%i", "Amount of initial impostors", numberOfImpostors);
		menu.AddItem("option1", charVec);
		Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages they must kill", RoundCfg[roundCfgPosVec][numberOfHostagesToKill2]);
		menu.AddItem("option2", charVec);
		Format(charVec, sizeof(charVec), "%t%i", "Initial hostage health amount", RoundCfg[roundCfgPosVec][amountOfHostagesHealth]); 
		menu.AddItem("option3", charVec);
		Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages on the map", RoundCfg[roundCfgPosVec][numberOfHostages]); 
		menu.AddItem("option4", charVec);
		Format(charVec, sizeof(charVec), "%t%i", "Initial amount of players in the round", roundNumberOfPlayers); 
		menu.AddItem("option5", charVec);		
				
		menu.Display(client, GetConVarFloat(mp_roundtime) * 60); // I MULTIPLY THE TIME BY 60 BECAUSE IT IS IN SECONDS
		
	} else { // ELSE NOTIFY THE PLAYER THAT IT WAS NOT AVAILABLE:
		
		PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "Command !info disabled");
	
	}
	
	return Plugin_Handled;
}


public int menuInfoCallback(Menu menu, MenuAction action, int client, int optionNumber)
{ 
	switch (action) { 
		case MenuAction_Select: // I DO NOT USE strcmp BECAUSE ANY SELECTED OPtION WILL MAKE THE SAME HAPPEN.
		{ // THE FOLLOWING OF THE case IS SIMPLY SO THAT THE MENU DOES NOT DISAPPEAR (BECAUSE IT WOULD BE DELETED BUT WITH THE Case MenuAction_End)
			char charVec[60]; // VARIABLE TO WHICH THE charVec WILL BE ASSIGNED TO PRINT IN THE MENU.
				
			Menu menu2 = new Menu(menuInfoCallback);
			menu2.SetTitle("%t", "Round info menu display");
			
			Format(charVec, sizeof(charVec), "%t%i", "Amount of initial impostors", numberOfImpostors);
			menu2.AddItem("option1", charVec);
			Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages they must kill", RoundCfg[roundCfgPosVec][numberOfHostagesToKill2]);
			menu2.AddItem("option2", charVec);
			Format(charVec, sizeof(charVec), "%t%i", "Initial hostage health amount", RoundCfg[roundCfgPosVec][amountOfHostagesHealth]); 
			menu2.AddItem("option3", charVec);
			Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages on the map", RoundCfg[roundCfgPosVec][numberOfHostages]); 
			menu2.AddItem("option4", charVec);	
			Format(charVec, sizeof(charVec), "%t%i", "Initial amount of players in the round", roundNumberOfPlayers); 
			menu.AddItem("option5", charVec);					
					
			menu2.Display(client, GetConVarFloat(mp_roundtime) * 60); // I MULTIPLY THE TIME BY 60 BECAUSE IT IS IN SECONDS

		}
		
		case MenuAction_End: // FOR ANYTHING THAT MAKES THE MENU TERMINATE HOW TO SELECT THE OPTION TO EXIT OR OPEN ANOTHER MENU WHEN IT WAS OPEN:
		{
			delete menu; // THE MENU MEMORY IS FREE.
		}	
	}
	return Plugin_Handled;
}




public Action: Command_tttrules(int client, int args)
{

	if (client == 0) 
	{
		ReplyToCommand(client, "%s%t", "[TTT] ", "Command is in-game only");
		return Plugin_Handled;
	}
    
	char charVec[60]; 
	
	// I create the menu:
	Menu menu = new Menu(menuTTTRulesCallback);
	menu.SetTitle("%t", "TTT RULES MENU TITLE");
	Format(charVec, sizeof(charVec), "%t", "Game mode rules");
	menu.AddItem("rules", charVec); // option1
	Format(charVec, sizeof(charVec), "%t", "Useful chat commands");
	menu.AddItem("commands", charVec); // option2
	// I print it to the player:
	menu.Display(client, GetConVarFloat(mp_roundtime) * 60);

	return Plugin_Handled;
}


public int menuTTTRulesCallback(Menu menu, MenuAction action, int client, int optionNumber)
{
	switch (action) { 
		case MenuAction_Select: 
		{ 
			char selectedOption[9];
			menu.GetItem(optionNumber, selectedOption, sizeof(selectedOption));
			
			if (strcmp(selectedOption, "rules") == 0) {
				char charVec[80];
				new Handle:DescriptionPanel = CreatePanel();
				// Format ARE TO GRAB THE LINES TO ADD TO THE PANEL (MENU) FROM THE TRANSLATIONS.
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES"); 
				SetPanelTitle(DescriptionPanel, charVec); 
				DrawPanelText(DescriptionPanel, " "); 
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 1");
				DrawPanelText(DescriptionPanel, charVec);
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 2");
				DrawPanelText(DescriptionPanel, charVec);
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 3");
				DrawPanelText(DescriptionPanel, charVec);
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 4");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 5");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 6");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 7");
				DrawPanelText(DescriptionPanel, charVec); 			
				Format(charVec, sizeof(charVec), "%t", "GAME MODE RULES - LINE 8");				
				DrawPanelText(DescriptionPanel, charVec); 
				DrawPanelText(DescriptionPanel, " ");
				Format(charVec, sizeof(charVec), "%s%t", "0- ", "Back menu");
				DrawPanelText(DescriptionPanel, charVec);
				SendPanelToClient(DescriptionPanel, client, menuTTTRulesBackToMenu, GetConVarFloat(mp_roundtime) * 60); 
			}
			
			if (strcmp(selectedOption, "commands") == 0) {
				char charVec[60];
				new Handle:DescriptionPanel = CreatePanel();
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS");
				SetPanelTitle(DescriptionPanel, charVec); 
				DrawPanelText(DescriptionPanel, " "); 
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 1");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 2");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 3");
				DrawPanelText(DescriptionPanel, charVec); 	
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 4");
				DrawPanelText(DescriptionPanel, charVec); 	
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 5");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 6");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 7");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 8");
				DrawPanelText(DescriptionPanel, charVec); 
				Format(charVec, sizeof(charVec), "%t", "USEFUL CHAT COMMANDS - LINE 9");
				DrawPanelText(DescriptionPanel, charVec); 
				DrawPanelText(DescriptionPanel, " "); 
				Format(charVec, sizeof(charVec), "%s%t", "0- ", "Back menu");
				DrawPanelText(DescriptionPanel, charVec);
				SendPanelToClient(DescriptionPanel, client, menuTTTRulesBackToMenu, GetConVarFloat(mp_roundtime) * 60); 				
			}			
  			
		}
		
		case MenuAction_End: 
		{
			delete menu; // THE MENU MEMORY IS FREE.
		}		
	}		

	return Plugin_Handled;
}


public int menuTTTRulesBackToMenu(Menu menu, MenuAction action, int client, int optionNumber)
{
	switch (action) { 
		case MenuAction_Select: 
		{ 
			char charVec[60]; 
			
			Menu menu2 = new Menu(menuTTTRulesCallback);
			menu2.SetTitle("%t", "TTT RULES MENU TITLE");
			Format(charVec, sizeof(charVec), "%t", "Game mode rules");
			menu2.AddItem("rules", charVec); // option1
			Format(charVec, sizeof(charVec), "%t", "Useful chat commands");
			menu2.AddItem("commands", charVec); // option2
			menu2.Display(client, GetConVarFloat(mp_roundtime) * 60);				
		}
		case MenuAction_End: 
		{
			delete menu; // THE MENU MEMORY IS FREE.
		}		
	}	
	return Plugin_Handled;
}




public Action Event_RoundStart(Handle event, const String: name[], bool dontBroadcast) // INCLUDES FREEZETIME
{	
	// INSTEAD OF STARTING 2 TIMERS AT THE SAME TIME, START ONE AND WHEN THAT ENDS ANOTHER STARTS, IT IS ALSO MORE OPTIMAL: WHEN THE TIME ARRIVES, I START A FUNCTION WITH ANOTHER TIMER.
	roundTimer = CreateTimer(GetConVarFloat(mp_freezetime), SetRolesAndHostages); // The first parameter is in seconds.
	// Always vary a little (like a second) the timer; the same is not so important because it is not more than that.
	
	// I UNMUTE THE PLAYERS AND TAKE THE OVERLAY OUT OF THEM ALL AT THE SAME TIME:
	new i = 1; 
    while (i <= MaxClients) 
    {
        if (IsClientInGame(i) && IsPlayerAlive(i)) 
        {
        	ClientCommand(i, "r_screenoverlay \"%s\"", ""); // AS THE LAST PARAMETER IS "" THE OVERLAY IS NONE (WHICH MEANS THAT THERE IS NO OVERLAY FOR THE PLAYER).
        	SetClientListeningFlags(i, VOICE_NORMAL); // THIS WORKS TO MUTE AND UNMUTE
        } 
        i++;
    }	
    
	// I REMOVE ALL THE HOSTAGES THAT CAME DEFAULT WITH THE MAP (IF ANY).
    
    if (roundNumberOfPlayers > 0) { 
		new entityNumber = -1;
		entityNumber = FindEntityByClassname(entityNumber, "hostage_entity");	
		while (entityNumber != -1)
		{	
			AcceptEntityInput(entityNumber, "kill");
			entityNumber = FindEntityByClassname(entityNumber, "hostage_entity");
		}		    
	
		// I SPAWN ALL THE HOSTAGES OF THE CONFIGURATIONS:
		decl Ent; 
		PrecacheModel("hostage_entity" ,true); 
		decl Float: position[3];
		decl Float: angles[3];
	
		// IF YOU PUT A SPAWN NEAR OR CLOSE TO A CT SPAWNPOINT THROW INVALID CT SPAWN, THIS MAKES IT BREAK THE PLUGIN SO WHEN CREATING FILES WITH HOSTAWN SPAWNS DO IT BEARING IN MIND THAT THERE DOESN'T HAVE TO BE A HOSTAWN IN A CT SPAWN OR T. FOR DOUBTS, TAKE IT INTO ACCOUNT.
		i = 0;
		new j;
		while (i < MAP_HOSTAGE_ENT_QUANTITY) { 
			
			j = 0;
			while (j < 3) { // I CAST BECAUSE IT DOESN'T LET ME PUT THE VALUES DIRECTLY IN THE FUNCTION WITH THE STRUCTURE.
				position[j] = hostageSpawn[i][pos][j];
				angles[j] = hostageSpawn[i][ang][j];		
				j++;
			}	
		
			Ent = CreateEntityByName("hostage_entity"); // I CREATE THE HOSTAGE ENTITY.
			DispatchKeyValue(Ent, "physdamagescale", "0.0");
			DispatchKeyValue(Ent, "model", "hostage_entity"); 
			DispatchKeyValue(Ent, "targetname", "hostage_entity");
			DispatchSpawn(Ent); 
			TeleportEntity(Ent, position, angles, NULL_VECTOR); // I REMOVE IT TOWARDS THE POSITIONS THAT WERE TAKEN FROM THE TEXT FILE.
			SetEntityMoveType(Ent, MOVETYPE_VPHYSICS); // WITH THIS LINE THE HOSTAGES CANNOT BE CALLED. NOT EVEN WITH THE .nav CAN BE CALLED.
	
			i++;
		}
	}
		
	return Plugin_Continue;
}



public Action SetRolesAndHostages(Handle timer) 
{ // WHEN THE FREEZETIME ENDS, THE PLAYERS AND OTHERS ARE COUNTED AND THOSE WHO DID NOT START AT THE START ARE PREVENTED FROM SPAWNE.
	roundTimer = CreateTimer(GetConVarFloat(mp_roundtime) * 60, ForceRoundEndWhenRoundTimeEnd); // Second timer from the same round with a time coordinated with the previous timer.
	playersCanSpawn = false; // I PREVENT PLAYERS WHO ARE NOT AT THE START OF THE ROUND (IN THE FREEZETIME) FROM JOINING.

	/* |------------------------------------------------------------|
	   |   I DETERMINE THE NEW IMPOSTORS WHEN THE FREEZETIME ENDS.  |
	   |------------------------------------------------------------| */
	
	// I COUNT THE NUMBER OF PLAYERS THERE WILL BE IN THE ROUND AND I ASSUME THAT NONE IS AN IMPOSTOR, LATER RANDOMLY ASSIGNING TO IMPOSTORS:
	
	roundNumberOfPlayers = 0; 
	new i = 0; 
    while (i < MaxClients) 
    {
        if (IsClientInGame(i + 1) && IsPlayerAlive(i + 1)) 
        { 
        	Player[i][isAnImpostor] = false;
        	greatestClientNumber = i + 1; // I REMAIN WITH THE HIGHEST CLIENT NUMBER SO I DO NOT HAVE TO PROCESS ALL THE CLIENTS (EVEN DISCONNECTED ONES) UNNECESSARILY.
			roundNumberOfPlayers++;
        } 
        i++;
    }

    
    new previousNumberOfImpostors = numberOfImpostors; // <--- To randomize in case the previous impostors cannot be equal to the current ones (by a convar).
    roundCfgPosVec = -1;
    
	if (roundNumberOfPlayers > 0) 
	{    
		// I SEARCH FOR THE CONFIGURATION OF THE GAME (ROUND) THAT CORRESPONDS TO THE CURRENT NUMBER OF PLAYERS THANKS TO THE CONFIGURATIONS TAKEN FROM THE TEXT FILE:
		
		i = 0; 
		while (roundNumberOfPlayers > RoundCfg[i][numberOfPlayers] && i < MAX_FILE_CONFIGS_QUANTITY) { 
			i++; 
		}
		roundCfgPosVec = i;
		if (roundCfgPosVec == MAX_FILE_CONFIGS_QUANTITY) { roundCfgPosVec = MAX_FILE_CONFIGS_QUANTITY - 1; } // IF THIS CONDITION IS GIVEN IT IS BECAUSE THE LAST CONFIGURATION DID NOT HAVE AS HIGH A NUMBER OF PLAYERS AS THE CURRENT SO THE CONFIGURATION WITH THE MOST NUMBER OF PLAYERS IS ASSIGNED (THE CONFIGURATIONS (AND THE CONFIGURATION FILE) ARE ORDERED LESS THAN GREATER NUMBER OF PLAYERS PER ROUND CONFIGURATION).
		
		numberOfImpostors = RoundCfg[roundCfgPosVec][numberOfImpostors2]; // I MAKE THE VARIABLE numberOfImpostors BECAUSE IT WILL BE NECESSARY IN CASE THERE IS A RANDOM NUMBER OF IMPOSTORS	
		currentNumberOfImpostors = RoundCfg[roundCfgPosVec][numberOfImpostors2]; // I EQUAL AND REMAIN WITH AN ACCUMULATOR VARIABLE AND ANOTHER WITH WHICH I WOULD HAVE AT THE START OF THE ROUND.
		numberOfHostagesToKill = RoundCfg[roundCfgPosVec][numberOfHostagesToKill2]; // cantHostagesInicial == hostageQuantity == RoundCfg[roundCfgPosVec][numberOfHostages]. 

		// I SAVE THE ENTITY NUMBERS OF THE HOSTAGES (ALWAYS DEPEND ON THE NUMBER OF ENTITIES ON THE MAP AND IF SPAWNE MORE PLAYERS THE ENTITY NUMBERS CHANGE).
		if (!GetConVarBool(sm_ttt_show_every_hostage_spawn) && MAP_HOSTAGE_ENT_QUANTITY - 1 >= RoundCfg[roundCfgPosVec][numberOfHostages]) { // IF THE SPAWNS OF THE HOSTAGES ARE NOT BEING CHECKED		
		// IF IT IS SO I DETERMINE WHICH HOSTAGES STILL ALIVE AND WHICH HOSTAGES ARE ELIMINATED. ELSE I LEAVE ALL THE HOSTAGES COMING IN THE CONFIGURATIONS.
		
			// THE FOLLOWING IS DONE AFTER HAVING SPAWNEED ALL THE HOSTAGES OF THE CONFIGURATIONS IN THE FILE WITH THE COORDINATES IN WHICH THEY SHOULD SPAWNE.
			new entityNumber = -1;
			entityNumber = FindEntityByClassname(entityNumber, "hostage_entity");		
				
			i = 0;
			while (i < MAP_HOSTAGE_ENT_QUANTITY) 
			{	
				hostageEntityNumber[i] = entityNumber;
				entityNumber = FindEntityByClassname(entityNumber, "hostage_entity");
				i++;
			}				
			
			// WHAT HAPPENS NEXT IS NOT THAT HOSTAGES ARE SPAWNED IN CERTAIN POSITIONS; IS THAT CERTAIN HOSTAGES IN THE POSITIONS OF THE SPAWNS CONFIG FILE (ALREADY SPAWNED) ARE ELIMINATED (REMEMBER THAT ALL THOSE WHO COME BY DEFAULT WITH THE MAP AND ARE LET ALIVE ALL THOSE WHO COME IN THE FILE WITH CONFIGURATIONS).
			i = 0;
			if (!GetConVarBool(sm_ttt_hostage_random_spawn)) // IF THE SPAWNS WERE NOT RANDOM, I LEAVE THEM ALIVE (WHATEVER THEY ARE) ALWAYS:
			{	
				//if (!GetConVarBool(sm_ttt_show_every_hostage_spawn)) { // IF WEREN'T CHECKING THE SPAWNS OF THE HOSTAGES ON THE MAP:
					// WHILE i IS LESS THAN THE NUMBER OF HOSTAGES ON THE MAP I ASSIGN THEM THE INDICATED HEALTH:
					while (i < RoundCfg[roundCfgPosVec][numberOfHostages]) // I THINK THEM WILL BE THE FIRST HOSTAGES ON SPAWN CONFIGS.
					{
						SetEntProp(hostageEntityNumber[i], Prop_Data, "m_iHealth", RoundCfg[roundCfgPosVec][amountOfHostagesHealth]); 		
						i++;
					}	
					// I ELIMINATE THE OTHER HOSTAGES (THEIR ENTITIES) BY NOT BEING WITHIN THE RANGE OF THE NUMBER OF HOSTAGES INDICATED:		
					while (i < MAP_HOSTAGE_ENT_QUANTITY)
					{ 		
						AcceptEntityInput(hostageEntityNumber[i], "kill");
						i++;
					}		
				//}
	
			} else { // ELSE, IF WERE RANDOM SPAWNS, I LET HOSTAGES ALIVE RANDOMLY:

				// I ASSIGN THEM CFG HEALTH OR ELIMINATE THEM DEPENDING ON WHAT HAS ASSIGNED TO THEM:
				new bool: deleteHostage[MAP_HOSTAGE_ENT_QUANTITY]; // IF IT IS true THE HOSTAGE DIES, ELSE HE IS ALLOWED TO LIVE AND IS ASSIGNED THE HEALTH THAT THE CONFIGURATIONS WILL INDICATE:
				// I INITIALIZE THE VECTOR AFFIRMING THAT ALL HOSTAGES WILL BE REMOVED:
				i = 0;
				while (i < MAP_HOSTAGE_ENT_QUANTITY) {
					deleteHostage[i] = true;
					i++;
				}	
				
				// HOSTAGES ARE RANDOMLY CHOSEN TO BE ADMITTED FOR THE ROUND
				new numberOfHostagesToAdmit[RoundCfg[roundCfgPosVec][numberOfHostages]]; 
				new randomInt;
	
				i = 0;
				while (i < RoundCfg[roundCfgPosVec][numberOfHostages]) {
					randomInt = GetRandomInt(1, MAP_HOSTAGE_ENT_QUANTITY);
					while (isLikeAPreviousValue2(i, numberOfHostagesToAdmit, randomInt)) {
						randomInt = GetRandomInt(1, MAP_HOSTAGE_ENT_QUANTITY);
					}
					numberOfHostagesToAdmit[i] = randomInt; // I SAVE THE VALUES JUST TO CONFIRM THAT THE SAME HOSTAGE IS NOT GOING TO BE CHOSEN TWICE.
					deleteHostage[randomInt - 1] = false;
					i++;
				} 

				i = 0; 		
				while (i < MAP_HOSTAGE_ENT_QUANTITY) {
					if (deleteHostage[i]) {
						AcceptEntityInput(hostageEntityNumber[i], "kill"); // WE WILL REMOVE IT FOR THIS ROUND
					} else { 
						SetEntProp(hostageEntityNumber[i], Prop_Data, "m_iHealth", RoundCfg[roundCfgPosVec][amountOfHostagesHealth]); // ASSIGN THE INDICATED HEALTH
					}
					i++;
				}
			}
		}
	
		// ----------------------------------------------
		//				 RANDOMIZE IMPOSTORS
		// ----------------------------------------------

	    i = 0;
	    new randomInt;
	    if (GetConVarInt(sm_ttt_same_impostors) == 1) { // IF THEY COULD BE THE SAME IMPOSTERS AS THE PREVIOUS ROUNDS ARE SIMPLY RANDOMIZED:
		    while (i < numberOfImpostors) {
		   		randomInt = GetRandomInt(1, greatestClientNumber); 
		   		while (isLikeAPreviousValue(randomInt, i) || !IsClientInGame(randomInt) || !IsPlayerAlive(randomInt)) { // SO THAT THE SAME PLAYER IS NOT REPEATED AS IMPOSTER TWICE.
		   			randomInt = GetRandomInt(1, greatestClientNumber); 
		   		}  		
		   		Player[randomInt - 1][isAnImpostor] = true;
		   		impostorPerClientNumber[i] = randomInt;
		   		i++;  		
		  	}
	    } else if (GetConVarInt(sm_ttt_same_impostors) == 0) { // BUT THEY CANNOT BE THE SAME IMPOSTORS AS BEFORE SO I MAKE A MORE COMPLEX RANDOMIZATION:
	 		new previousImpostors[previousNumberOfImpostors];  
	 		while (i < previousNumberOfImpostors) { // I EQUAL THE CLIENTS OF THE PREVIOUS IMPOSTORS TO THE NEW VECTOR TO CONFIRM THAT THEY ARE NOT THE SAME:
	 			previousImpostors[i] = impostorPerClientNumber[i];
	 			i++;
	 		}
	 		
	 	 	i = 0;
	 	 	
	 	 	if (numberOfImpostors >= roundNumberOfPlayers / 2) { numberOfImpostors = (roundNumberOfPlayers / 2) - 1; } // TO AVOID PROBLEMS THAT MAY BE GENERATED BY BAD CONFIGURATIONS OF THE TEXT FILES.
	 	 	
		    while (i < numberOfImpostors) { // REMEMBER THAT FOR THIS THE NUMBER OF IMPOSTORS HAS TO BE LESS THAN THE NUMBER OF INNOCENTS. ELSE THERE WILL BE A CALL TO THE SAME while INFINITELY.
		   		randomInt = GetRandomInt(1, greatestClientNumber);  
		   		while (isLikeAPreviousValue(randomInt, i) || esIgualAAlgunImpostorAnterior(previousNumberOfImpostors, previousImpostors[previousNumberOfImpostors], randomInt) || !IsClientInGame(randomInt) || !IsPlayerAlive(randomInt)) 
		   		{  
		   			randomInt = GetRandomInt(1, greatestClientNumber);
		   		}  		
		   		Player[randomInt - 1][isAnImpostor] = true;
		   		impostorPerClientNumber[i] = randomInt;
		   		i++;  		
		  	}	 	 	
	 	 	
	 	} else  { // ELSE THE NUMBER OF IMPOSTORS IS RANDOM. sm_ttt_same_impostors would be 2 or any number other than 0 or 1 
			numberOfImpostors = GetRandomInt(1, (roundNumberOfPlayers / 2) - 1); // (ALWAYS THAT RANDOM AMOUNT LESS THAN HALF THE TOTAL PLAYERS).
			currentNumberOfImpostors = numberOfImpostors;
			while (i < numberOfImpostors) {
		   		randomInt = GetRandomInt(1, greatestClientNumber); 
		   		while (isLikeAPreviousValue(randomInt, i) || !IsClientInGame(randomInt) || !IsPlayerAlive(randomInt)) {  
		   			randomInt = GetRandomInt(1, greatestClientNumber); 
		   		}  		
		   		Player[randomInt - 1][isAnImpostor] = true;
		   		impostorPerClientNumber[i] = randomInt;
		   		i++;  		
		  	} 		
		}
		
		// ----------------------------------------------------------
		// SEND MESSAGE INDICATING YOUR ROLE AND COLOR TO THE PLAYERS
		// ----------------------------------------------------------
		
		decl String: overlaypath[PLATFORM_MAX_PATH];	
		i = 1; 
		
		if (GetConVarBool(sm_ttt_command_info)) {
		
			while (i <= greatestClientNumber) {	
				
				if (IsClientInGame(i) && IsPlayerAlive(i)) {
				
					if (!Player[i - 1][isAnImpostor]) { // IF IS'T AN IMPOSTOR
		
						GetConVarString(sm_ttt_overlay_innocents, overlaypath, sizeof(overlaypath));
						ClientCommand(i, "r_screenoverlay \"%s\"", overlaypath);
						PrintHintText(i, "%t\n%t", "YOU ARE AN INNOCENT", "BEFORE THEY KILL ENOUGH HOSTAGES!");
						PrintCenterText(i, "%t", "YOU ARE AN INNOCENT 2!");
						PrintToChat(i, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x0766BBDD ", "YOU ARE AN INNOCENT 3!"); 
		
					} else { // IS AN IMPOSTOR
					
						GetConVarString(sm_ttt_overlay_impostors, overlaypath, sizeof(overlaypath));
						ClientCommand(i, "r_screenoverlay \"%s\"", overlaypath);
						PrintHintText(i, "%t", "YOU ARE AN IMPOSToR");
						PrintCenterText(i, "%t", "YOU ARE AN IMPOSToR");
						PrintToChat(i, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x07FF0000 ", "YOU ARE AN IMPOSToR");
						PrintToChat(i, "%s%t%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x07FF0000 ", "YOU ARE AN IMPOSToR 2!", " \x0766EEFF!impostors\x07FF0000 ", "YOU ARE AN IMPOSToR 3!");
						PrintToChat(i, "%s%t%i%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x07FF0000 ", "You should kill", numberOfHostagesToKill, "before time is up");
					}
						
					char charVec[60]; 
	
					// CREATE MENU
					Menu menu = new Menu(menuInfoCallback);
					menu.SetTitle("%t", "Round info menu display");
						
					Format(charVec, sizeof(charVec), "%t%i", "Amount of initial impostors", numberOfImpostors); // THE Format ARE FOR THE TRANSLATIONS ONLY. BUT THEY COULD BE const char[] IF THEY WEREN'T TRANSLATIONS.
					menu.AddItem("option1", charVec);
					Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages they must kill", RoundCfg[roundCfgPosVec][numberOfHostagesToKill2]);
					menu.AddItem("option2", charVec);
					Format(charVec, sizeof(charVec), "%t%i", "Initial hostage health amount", RoundCfg[roundCfgPosVec][amountOfHostagesHealth]); 
					menu.AddItem("option3", charVec);
					Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages on the map", RoundCfg[roundCfgPosVec][numberOfHostages]); 
					menu.AddItem("option4", charVec);	
					Format(charVec, sizeof(charVec), "%t%i", "Initial amount of players in the round", roundNumberOfPlayers); 
					menu.AddItem("option5", charVec);		
				
					// DISPLAY MENU TO PLAYER
					menu.Display(i, GetConVarFloat(mp_roundtime) * 60); // I MULTIPLY THE TIME BY 60 BECAUSE IT IS IN SECONDS				
					
					// IF YOU DON'T FORMAT THE COLOR AT THE BEGINNING (FOR EXAMPLE WITH THE \x04 THAT IS BEFORE ALL THE FOLLOWING VECTOR OF CHARACTERS) NOTHING OF THE FOLLOWING IS FORMAT. I THINK IT DOESN'T MATTER WHAT COLOR; SIMPLY SOME AT THE BEGINNING; EVEN IF IT'S THE \x01 I THINK IT WORKS THE SAME.
					PrintToChat(i, "%s%t%s%s%s", "\x04[TTT] ", "Your color is", hexColorByClientNumber(i), colorNameByClientNumber(i), "\x04.");
					
				}
					
				i++;						
			}
		
		} else { // ELSE THE !Info COMMAND WAS NOT AVAILABLE.

			while (i <= greatestClientNumber) {	
				
				if (IsClientInGame(i) && IsPlayerAlive(i)) {
				
					if (!Player[i - 1][isAnImpostor]) { // IF IS'T AN IMPOSTOR
		
						GetConVarString(sm_ttt_overlay_innocents, overlaypath, sizeof(overlaypath));
						ClientCommand(i, "r_screenoverlay \"%s\"", overlaypath);
						PrintHintText(i, "%t\n%t", "YOU ARE AN INNOCENT", "BEFORE THEY KILL ENOUGH HOSTAGES!");
						PrintCenterText(i, "%t", "YOU ARE AN INNOCENT 2!");
						PrintToChat(i, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x0766BBDD ", "YOU ARE AN INNOCENT 3!"); 
		
					} else { // IS AN IMPOSTOR
					
						GetConVarString(sm_ttt_overlay_impostors, overlaypath, sizeof(overlaypath));
						ClientCommand(i, "r_screenoverlay \"%s\"", overlaypath);
						PrintHintText(i, "%t", "YOU ARE AN IMPOSToR");
						PrintCenterText(i, "%t", "YOU ARE AN IMPOSToR");
						PrintToChat(i, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x07FF0000 ", "YOU ARE AN IMPOSToR");
						PrintToChat(i, "%s%t%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x07FF0000 ", "YOU ARE AN IMPOSToR 2!", " \x0766EEFF!impostors\x07FF0000 ", "YOU ARE AN IMPOSToR 3!" );
						PrintToChat(i, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]\x07FF0000 ", "You should kill 2");
					}
					
					PrintToChat(i, "%s%t%s%s%s", "\x04[TTT] ", "Your color is", hexColorByClientNumber(i), colorNameByClientNumber(i), "\x04.");
					
				}
					
				i++;						
			}
	
		}
		
	} else {
		roundCfgPosVec = 0;
	}
	return Plugin_Continue;
}


public int menuInfoStartCallback(Menu menu, MenuAction action, int client, int optionNumber)
{ 
	switch (action) { 
		case MenuAction_Select: 
		{ // THE FOLLOWING OF THE case IS SIMPLY SO THAT THE MENU DOES NOT DISAPPEAR (BECAUSE IT WOULD BE DELETED BUT WITH THE Case MenuAction_End)
			char charVec[60]; 
				
			Menu menu2 = new Menu(menuInfoCallback);
			menu2.SetTitle("%t", "Round info menu display");
					
			Format(charVec, sizeof(charVec), "%t%i", "Amount of initial impostors", numberOfImpostors);
			menu2.AddItem("option1", charVec);
			Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages they must kill", RoundCfg[roundCfgPosVec][numberOfHostagesToKill2]);
			menu2.AddItem("option2", charVec);
			Format(charVec, sizeof(charVec), "%t%i", "Initial hostage health amount", RoundCfg[roundCfgPosVec][amountOfHostagesHealth]); 
			menu2.AddItem("option3", charVec);
			Format(charVec, sizeof(charVec), "%t%i", "Initial number of hostages on the map", RoundCfg[roundCfgPosVec][numberOfHostages]); 
			menu2.AddItem("option4", charVec);	
			Format(charVec, sizeof(charVec), "%t%i", "Initial amount of players in the round", roundNumberOfPlayers); 
			menu.AddItem("option5", charVec);		
			
			menu2.Display(client, GetConVarFloat(mp_roundtime) * 60); // I MULTIPLY THE TIME BY 60 BECAUSE IT IS IN SECONDS	
					
		}
		
		case MenuAction_End: 
		{
			delete menu; // THE MENU MEMORY IS FREE.
		}	
	}
	return Plugin_Handled;
}


public Action ForceRoundEndWhenRoundTimeEnd(Handle timer) 
{ 
	CT_SCORE++;
	SetTeamScore(CS_TEAM_CT, CT_SCORE); 
	SetInnocentsCreditsByWinning();
	CS_TerminateRound(GetConVarFloat(mp_round_restart_delay), CSRoundEnd_HostagesRescued); 
	return Plugin_Continue;
}




public Action Event_ClientSpawn(Handle event, const String: name[], bool dontBroadcast)
{ 
	new client = GetClientOfUserId(GetEventInt(event, "userid")); 

	// THE SECOND CONDITION OF THE IF IS TO PREVENT THE ROUND FROM ENDING TWICE AT THE SAME TIME.
	if (roundNumberOfPlayers == 0 && !playersCanSpawn) { 
		roundNumberOfPlayers++; 
		playersCanSpawn = true;
		CS_TerminateRound(GetConVarFloat(mp_round_restart_delay), CSRoundEnd_GameStart);
		return Plugin_Handled;
	}
	
	// THIS MEANS THAT WHILE THERE ARE LESS THAN A CERTAIN NUMBER OF PLAYERS, THE SAME PLAYERS CAN PLAY IN A NOT-SERIOUSLY WAY UNTIL ENOUGH PLAYERS ARE CONNECTED (IT WOULD NOT SENSE TO PLAY THIS MODE WITH ONLY TWO PEOPLE, FOR THAT REASON FOR EXAMPLE).
	if (!playersCanSpawn && matchStarted) 
	{ 
		ForcePlayerSuicide(client);
		SetEntProp(client, Prop_Data, "m_iFrags", GetClientFrags(client) + 1); // To compensate for the point that is lost by using the kill command or dying from doing an incorrect action on the map.
		PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] ", "Can't spawn");
		return Plugin_Handled;
	} 

	// IF NOT, I LOCK THE MINIMAP (HUD / RADAR) SO THAT CANNOT SEE WHERE THE PLAYERS ARE IN IT.
	SetEntPropFloat(client, Prop_Send, "m_flFlashDuration", 3600.0);
	SetEntPropFloat(client, Prop_Send, "m_flFlashMaxAlpha", 0.5);
	AsignarColorDeJugadorPorNumeroDeCliente(client); // COLORS ARE ASSIGNED DEPENDING ON THE PLAYER'S CLIENT NUMBER (client) IN A DEFAULT WAY.
	
	return Plugin_Handled;	
	
}




public Action Event_PlayerConnect(Handle event, const String: name[], bool dontBroadcast)
{ 
	numberOfPlayersToStartMatch++;
	new minimumAmountOfPlayers = GetConVarInt(sm_ttt_min_player_quantity); 
	if (!matchStarted && numberOfPlayersToStartMatch >= minimumAmountOfPlayers) // If this happens there are already a decent amount of players to start.
	{
		PrintToChatAll("%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] ", "Enough players to start");
		matchStarted = true;
		CT_SCORE = 0;
		T_SCORE = 0;
		SetTeamScore(CS_TEAM_CT, 0);
		SetTeamScore(CS_TEAM_T, 0);
		new i = 1;
		while (i <= minimumAmountOfPlayers) { 
			if (IsClientInGame(i)) { // IT SEEMS THIS EVALUATES WHEN A CUSTOMER IS CONNECTED BUT NOT WHEN THEY ARE ALREADY IN THE DEPARTURE SO YOU HAVE TO LEAVE THE IS CLIENT IN GAME
				SetEntData(i, money_count, GetConVarInt(mp_startmoney)); // typical game start with $800. IF THE CONVAR WITH THE INITIAL MONEY AMOUNT WAS MODIFIED, THAT AMOUNT WILL BE USED. USE THE CONVAR WITH THE AMOUNT OF INITIAL MONEY THAT THE SERVER HAS.
			}
			i++;			
		}
		
		if (!playersCanSpawn) {
			CS_TerminateRound(GetConVarFloat(mp_round_restart_delay), CSRoundEnd_GameStart); 
		}
	} 

	return Plugin_Continue;
}




public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnPlayerTakeDamage); 
	return;
}


public Action Event_PlayerDisconnect(Handle event, const String: name[], bool dontBroadcast) 
{ 	
	numberOfPlayersToStartMatch--; 
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (Player[client - 1][isAnImpostor]) {
    	decl String: clientName[40];  
    	GetEventString(event, "name", clientName, sizeof(clientName));
    	PrintToChatAll("%s%s%s%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] ", hexColorByClientNumber(client), clientName, "\x07FF7700", "Disconnected and wan an impostor"); 

     	Player[client - 1][isAnImpostor] = false; // <--- SO THAT WHEN A PLAYER IS DISCONNECTED IF THEY JUST ASKED WHO THE IMPOSTOR WAS, DON'T SHOW A NEW PLAYER THAT WASN'T IN GAME SINCE THE ROUND STARTED.
		Player[client - 1][ban_innHurtHostage] = 0;
		Player[client - 1][ban_impHurtImp] = 0;
		Player[client - 1][ban_innHurtInn] = 0;
    	
    	if (IsPlayerAlive(client)) { // IF PLAYER WAS ALIVE.
    		currentNumberOfImpostors--;
			if (currentNumberOfImpostors == 0 && !playersCanSpawn) { 
				CT_SCORE++;
				SetInnocentsCreditsByWinning();
				SetTeamScore(CS_TEAM_CT, CT_SCORE); 
				CS_TerminateRound(GetConVarFloat(mp_round_restart_delay), CSRoundEnd_CTWin); 		
			}
		}
	}	

	return Plugin_Continue;
}




public Action EventHostageHurt(Handle event, const String: name[], bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!Player[client - 1][isAnImpostor]) { // IF AN INNOCENT HURTS A HOSTAGE:
		PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF0000", "You don't have to hurt hostages!");
		Player[client - 1][ban_innHurtHostage]++;
		// IF ALREADY HURTED TOO MANY:
		if (GetConVarInt(sm_ttt_ban_innocent_hostage_hurt) >= 0 && Player[client - 1][ban_innHurtHostage] >= GetConVarInt(sm_ttt_ban_innocent_hostage_hurt)) 
		{	
			if (GetConVarBool(sm_ttt_ban_admins) || !GetConVarBool(sm_ttt_ban_admins) && !isPlayerAnAdmin(client)) { 
				PrintToChat(client, "%s%t", "\x07FF0000[TTT] - ", "BAN - innocent kill/hurt hostage chat msg");
				decl String: banMessage[85];
				Format(banMessage, sizeof(banMessage), "%t", "BAN - innocent kill/hurt hostage msg");
				BanPlayer(client, banMessage);
			} else { // Else, player was an admin and can't ban admins.
				PrintToChat(client, "%s%t", "\x07FF0000[TTT] - ", "BAD ADMIN");
			}
			
		}
		return Plugin_Continue;
		
	} // Else, player was an impostor: 
		
	if (!changingPlayerMoney) { // IF A MONEY CHANGE HASN'T PRODUCED TOO LITTLE AGO (THE TIME BETWEEN THE MONEY CHANGES):
		changingPlayerMoney = true;
		Player[client - 1][previousMoneyAmount] = GetEntData(client, money_count); // RECEIVE THE AMOUNT OF MONEY HAD BEFORE INJURING THE HOSTAGE.
		disableChangingMoneyTimer = CreateTimer(0.1, disableChangingMoney, client); 	 
	} 
	
	return Plugin_Continue; 
}


public Action disableChangingMoney(Handle timer, int client) 
{ 
	if (IsClientInGame(client) && IsPlayerAlive(client)) { 
		SetEntData(client, money_count, Player[client - 1][previousMoneyAmount]); // I PUT BACK THE SAME AMOUNT OF MONEY THAT THE PLAYER HAD BEFORE.
	}
	changingPlayerMoney = false;
	KillTimer(disableChangingMoneyTimer);
	disableChangingMoneyTimer = INVALID_HANDLE;
	return Plugin_Continue; 
}




public Action Event_PlayerDeath(Handle event, const String: Death_Name[], bool dontBroadcast) 
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker")); 
	new killed = GetClientOfUserId(GetEventInt(event, "userid")); 
	new bool: killedHimself = (killer == killed || killer == 0); 

	SetEntProp(killed, Prop_Data, "m_iDeaths", GetEntProp(killed, Prop_Data, "m_iDeaths") - 1); // THIS IS SO THAT DEATH IS NOT ADDED AND MAKE THE SYSTEM OF QUANTITIES OF DEATHS REPLACING IT BY AMOUNT OF ROUNDS LOST WITH THE ROLE THAT THE PLAYER HAS PLAYED (IMPOSTOR OR INNOCENT).

	// I REMOVE THE OVERLAY FROM THE MURDERED:
	ClientCommand(killed, "r_screenoverlay \"%s\"", ""); // AS THE LAST PARAMETER IS "" THE OVERLAY IS NONE (SO THERE IS NO OVERLAY FOR THE PLAYER).
	// MUTE THE ONE WHO DIED SO THAT HE DOES NOT DATE UNLESS HE IS AN ADMIN TO CONTROL THE GAME (IF THE CONVAR sm_ttt_mute_admins WAS 0 THE SECOND).
	if (GetConVarFloat(sm_ttt_dead_players_mute)) { 
		if (!isPlayerAnAdmin(killed) || isPlayerAnAdmin(killed) && GetConVarBool(sm_ttt_mute_admins)) {
	 		SetClientListeningFlags(killed, VOICE_MUTED); // THIS WORKS TO MUTE AND UNMUTE PLAYERS.
	 		PrintToChat(killed, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x04", "You are silenced");
	 	} else {
	 		PrintToChat(killed, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x04", "You aren't silenced because you are an admin");
		}
	} 

	// If it was an impostor, I reduce the counter.
	if (Player[killed - 1][isAnImpostor]) { 
		if (GetConVarBool(sm_ttt_say_if_was_an_impostor)) { // IF THE CONVAR WAS ACTIVE PRINT THAT IT WAS AN IMPOSTOR.
    		decl String: clientName[40];  
    		GetClientName(killed, clientName, sizeof(clientName));	
    		PrintToChatAll("%s%s%s%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] ", hexColorByClientNumber(killed), clientName, "\x07FF7700", "Was an impostor!"); 
    	}
		currentNumberOfImpostors--;
	} 
	
	
	if (killer != 0) // IF THE KILLER IS NOT THE MAP:
	{
		// I make the points obtained by killing not count. They will only count if they were impostors and win or if they were innocent and win; otherwise they will not get points.
		if (GetClientTeam(killer) == GetClientTeam(killed) && !killedHimself) {  
			SetEntProp(killer, Prop_Data, "m_iFrags", GetClientFrags(killer) + 1); // I add because killing a teammate subtracts a point.	
		} else if (!killedHimself) { 
			SetEntProp(killer, Prop_Data, "m_iFrags", GetClientFrags(killer) - 1); // Rest a point because when killing a player from the opposing team they add one up.
		} // Else lose a point automatically the one that was killed because he killed himself (he was not killed by another player) and pass points are subtracted.
	}
	// If there are no more impostors, the innocent win (I make them be considered as anti-terrorists).
	if (currentNumberOfImpostors == 0 && !playersCanSpawn) { // BECAUSE playersCanSpawn COVERS THE BEGINNING OF THE NEXT ROUND ALSO SO IF AN IMPOSTER GETS SUICIDE AND WAS THE ONLY IMPOSTOR IN THE NEXT ROUND, IT WILL NOT MAKE THE ROUND END BY THE EXECUTION SEQUENCE.
		CT_SCORE++;
		SetInnocentsCreditsByWinning();
		SetTeamScore(CS_TEAM_CT, CT_SCORE); 
		CS_TerminateRound(GetConVarFloat(mp_round_restart_delay), CSRoundEnd_CTWin); 		
	}
	
	if (killedHimself || playersCanSpawn) { // playersCanSpawn IS THE LAPSE IN WHICH THE ROUND ENDS AND THE NEXT ROUND ENDS. (IT DOES NOT MAKE SENSE TO CONTINUE HIDING THE MAP OR ANYTHING IN THAT PERIOD BECAUSE THE ROUND IS ALREADY FINISHED).
		// I ADD THE EQUAL DEATH AS A PUNISHMENT FOR KILLING HIMSELF SO THAT YOU ARE MORE ATTENTIVE:
		SetEntProp(killed, Prop_Data, "m_iDeaths", GetEntProp(killed, Prop_Data, "m_iDeaths") + 1); // THIS IS SO THAT DEATH IS NOT ADDED AND MAKE THE SYSTEM OF QUANTITIES OF DEATHS REPLACING IT BY AMOUNT OF ROUNDS LOST WITH THE ROLE THAT THE PLAYER HAS PLAYED (IMPOSTOR OR INNOCENT).
		return Plugin_Continue; // Continue normally
	} // Else

	if (!changingPlayerMoney && killer != 0) { // IF A MONEY CHANGE WAS NOT TAKING PLACE TOO LITTLE AGO (THE TIME LAPSE BETWEEN THE MONEY CHANGES) AND THE KILLER IS NOT THE MAP:
		changingPlayerMoney = true;
		Player[killer - 1][previousMoneyAmount] = GetEntData(killer, money_count); // RECEIVE THE AMOUNT OF MONEY HAD BEFORE INJURING THE HOSTAGE.

		disableChangingMoneyTimer = CreateTimer(0.1, disableChangingMoney2, killer); 
	}

	dontBroadcast = true; // (YOU CAN SEE THAT BY DEFAULT dontBroadcast IS false).
	// This is to don't show player's death to everyone.
	return Plugin_Handled;
	
}


public Action disableChangingMoney2(Handle timer, int client) 
{ 
	if (IsClientInGame(client) && IsPlayerAlive(client)) { 
		SetEntData(client, money_count, Player[client - 1][previousMoneyAmount]); // I PUT BACK THE SAME AMOUNT OF MONEY THAT THE PLAYER HAD BEFORE.
	}
	changingPlayerMoney = false;
	KillTimer(disableChangingMoneyTimer);
	disableChangingMoneyTimer = INVALID_HANDLE;
	return Plugin_Continue; 
}




public Action EventHostageKilled(Handle event, const String: name[], bool dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!playersCanSpawn) { 
		numberOfHostagesToKill--;
	}

	if(!Player[client - 1][isAnImpostor]) {
		PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF0000", "You don't have to hurt hostages!");
		Player[client - 1][ban_innHurtHostage] += 2; // IT COUNTS AS IF HE HAD HURT HIM TWICE (THE POINT FOR HURT IS ALSO ADDED FOR WHAT WOULD BE 3 IN TOTAL).
		if (GetConVarInt(sm_ttt_ban_innocent_hostage_hurt) > 0 && Player[client - 1][ban_innHurtHostage] >= GetConVarInt(sm_ttt_ban_innocent_hostage_hurt)) 
		{
			if (GetConVarBool(sm_ttt_ban_admins) || !GetConVarBool(sm_ttt_ban_admins) && !isPlayerAnAdmin(client)) { 
				PrintToChat(client, "%s%t", "\x07FF0000[TTT] - ", "BAN - innocent kill/hurt hostage chat msg");
				BanPlayer(client, "Matar o lastimar a demasiados rehenes siendo inocente.");
			} else { // If not, the player was an admin and admins cannot be banned.
				PrintToChat(client, "%s%t", "\x07FF0000[TTT] - ", "BAD ADMIN");
			}
		}
	} else if (numberOfHostagesToKill > 0 && !playersCanSpawn) {
		PrintToChat(client, "%s%t%i%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF]", "Well done 1", numberOfHostagesToKill , "Well done 2");
		
		if (!changingPlayerMoney) { // IF A MONEY CHANGE WAS NOT TAKING PLACE TOO LITTLE AGO (THE TIME LAPSE BETWEEN THE MONEY CHANGES) AND THE KILLER IS NOT THE MAP:
			changingPlayerMoney = true;
			Player[client - 1][previousMoneyAmount] = GetEntData(client, money_count); // RECEIVE THE AMOUNT OF MONEY HAD BEFORE INJURING THE HOSTAGE.

			disableChangingMoneyTimer = CreateTimer(0.1, disableChangingMoney3, client); 
		}		
	} else {
		PrintToChat(client, "%s%t", "\x04[TTT] ", "Enought hostages deleted!");	
		
		if (!changingPlayerMoney) { 
			changingPlayerMoney = true;
			Player[client - 1][previousMoneyAmount] = GetEntData(client, money_count); 

			disableChangingMoneyTimer = CreateTimer(0.1, disableChangingMoney3, client); 
		}
	}

	if (numberOfHostagesToKill == 0 && !playersCanSpawn) {
		SetEntData(client, money_count, GetEntData(client, money_count) + 3300); // <---- TO MAKE SURE THE PLAYER WON'T LOOSE MONEY
		T_SCORE++;
		SetImpostorsCreditsByWinning();
		SetTeamScore(CS_TEAM_T, T_SCORE); 
		CS_TerminateRound(GetConVarFloat(mp_round_restart_delay), CSRoundEnd_TerroristWin); 
	}
	
	return Plugin_Continue;
}


public Action disableChangingMoney3(Handle timer, int client) 
{ 
	if (IsClientInGame(client) && IsPlayerAlive(client)) { 
		SetEntData(client, money_count, Player[client - 1][previousMoneyAmount]);
	}
	changingPlayerMoney = false;
	KillTimer(disableChangingMoneyTimer);
	disableChangingMoneyTimer = INVALID_HANDLE;
	return Plugin_Continue; 
}




public Action: Command_impostors(int client, int args) 
{
	if (client == 0) 
	{
		ReplyToCommand(client, "%s%t", "[TTT] ", "Command is in-game only");
		return Plugin_Handled;
	}
	
	// If 0, only dead admins will be able to use this command. 
	// If 1, only dead players will be able to use this command. 
	// If 2, only impostors will be able to use this command. 
	// If 3, only impostors and dead players will be able to use this command. 
	// Dead admins will allways be able to use this command.		
	
	new conVarValue = GetConVarInt(sm_ttt_command_impostors);

	if (conVarValue == 0 && !IsPlayerAlive(client) && isPlayerAnAdmin(client) ||
		conVarValue == 1 && !IsPlayerAlive(client) ||
		conVarValue == 2 && Player[client - 1][isAnImpostor] ||
		conVarValue == 3 && (Player[client - 1][isAnImpostor] || !IsPlayerAlive(client))) { 

	    decl String:clientName[60];
	    
	  	Menu menu = new Menu(menuImpostorsCallback);
	  	menu.SetTitle("%t", "Impostors menu title");
	  	
	  	PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "Impostors menu title");
	  	
		decl String: menuOptionName[9];
		new menuOptionNumber = 1; 
		new i = 0;
		while (i < numberOfImpostors) { 
	   		if (Player[impostorPerClientNumber[i] - 1][isAnImpostor]) // IF YOU PRINT A CUSTOMER WHO LEFT THE GAME, IT GOES (AND BREAKS THE GAME / PLUGIN ALONG WITH THE FUNCTION YOU ARE WANTING TO SEARCH / PRINT).
	        {		
				GetClientName(impostorPerClientNumber[i], clientName, sizeof(clientName));	
				PrintToChat(client, "%s%s", hexColorByClientNumber(impostorPerClientNumber[i]), clientName);
				Format(menuOptionName, sizeof(menuOptionName), "%s%i", "option", menuOptionNumber);
				Format(clientName, sizeof(clientName), "%s%s%s%c", clientName, " (", colorNameByClientNumber(impostorPerClientNumber[i]), ')');
				menu.AddItem(menuOptionName, clientName); 
				menuOptionNumber++;
			}
			i++;
		}
		menu.Display(client, GetConVarFloat(mp_roundtime) * 60); // FOR THE MENU REMAIN UNTIL THE PLAYER CLOSES IT.

	} else if (conVarValue == 0) { PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "You can't use impostors command 0"); }
	  else if (conVarValue == 1) { PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "You can't use impostors command 1"); }
	  else if (conVarValue == 2) { PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "You can't use impostors command 2"); }
	  else { /* Else: conVarValue should be 3 */ PrintToChat(client, "%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "You can't use impostors command 3"); }

	return Plugin_Handled;
}


public int menuImpostorsCallback(Menu menu, MenuAction action, int client, int optionNumber)
{ 
	switch (action) { 
		case MenuAction_Select: // I DON'T USE strcmp BECAUSE ANY SELECTED OPtION WILL MAKE THE SAME HAPPEN.
		{ // THE FOLLOWING OF THE case IS SIMPLY SO THAT THE MENU DOES NOT DISAPPEAR (BECAUSE IT WOULD BE DELETED BUT WITH THE Case MenuAction_End)
			decl String: menuOptionName[40];
			decl String: clientName[40];
			GetClientName(client, clientName, sizeof(clientName));
				
			Menu menu2 = new Menu(menuImpostorsCallback); 
			menu2.SetTitle("%t", "Impostors menu title"); 
				
			new menuOptionNumber = 1;
			new i = 0;
			while (i < numberOfImpostors) { 
				if (Player[impostorPerClientNumber[i] - 1][isAnImpostor]) // IF YOU PRINT A PLAYER WHO LEFT THE GAME, IT GOES (AND BREAKS THE GAME / PLUGIN ALONG WITH THE FUNCTION YOU ARE WANTING TO SEARCH / PRINT).
			    {		
					GetClientName(impostorPerClientNumber[i], clientName, sizeof(clientName));	
					Format(menuOptionName, sizeof(menuOptionName), "%s%i", "option", menuOptionNumber);
					menu2.AddItem(menuOptionName, clientName); 
					menuOptionNumber++;
				}
				i++;
			}
			menu2.Display(client, GetConVarFloat(mp_roundtime) * 60); 
		}
		
		case MenuAction_End: 
		{
			delete menu; 
		}

	}

	return Plugin_Handled;

}




public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason) 
{	
	if (roundTimer != INVALID_HANDLE) {
		KillTimer(roundTimer); // Kill the timer (any of the 2, the 1st and the second one use the same variable roundTimer).
		roundTimer = INVALID_HANDLE; 
	}
	
	playersCanSpawn = true;	
	
	// I REMOVE THE MENU TO ALL THE PLAYERS:
	new Handle: DescriptionPanel = CreatePanel();
	
	SetPanelTitle(DescriptionPanel, "."); 
	DrawPanelText(DescriptionPanel, ".");	 

	new i = 1;	
	while (i <= MaxClients) {
		if (IsClientInGame(i)) { 
			SendPanelToClient(DescriptionPanel, i, menuStopCallback, 1);  
		}
		i++;
	}

	// I NOTIFY EVERYONE WHO THE IMPOSTORS WERE:

	decl String:clientName[40];
	PrintToChatAll("%s%t", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] \x07FF7700", "The impostors were:");

	i = 0;
	while (i < numberOfImpostors) { 
   		if (Player[impostorPerClientNumber[i] - 1][isAnImpostor]) 
        {		
			GetClientName(impostorPerClientNumber[i], clientName, sizeof(clientName));	
			PrintToChatAll("%s%s", hexColorByClientNumber(impostorPerClientNumber[i]), clientName);
		}
		i++;
	}

	return Plugin_Continue;
}


public int menuStopCallback(Menu menu, MenuAction action, int client, int optionNumber) { 
	switch (action) { 
		case MenuAction_Select: { 
			delete menu;
		}
		case MenuAction_End: {
			delete menu; 
		}

	}
	return Plugin_Handled;
}


public void OnMapEnd() 
{ // I INITIALIZE OR END THE VARIABLES AGAIN SO THAT BUGS ARE NOT PRODUCED IN THE FOLLOWING MAP:
	changingPlayerMoney = false; 
	matchStarted = false; 
	roundCfgPosVec = 0;
	roundNumberOfPlayers = 0; 
	if (roundTimer != INVALID_HANDLE) { KillTimer(roundTimer); roundTimer = INVALID_HANDLE; }
	if (disableChangingMoneyTimer) { KillTimer(disableChangingMoneyTimer); disableChangingMoneyTimer = INVALID_HANDLE; }
	T_SCORE = 0;
	CT_SCORE = 0;
	SetTeamScore(CS_TEAM_CT, 0); 
	SetTeamScore(CS_TEAM_T, 0); 

	return Plugin_Continue;
}




/*| ------------------------------------------ |
  |				     HELPERS				   |
  | ------------------------------------------ | */


bool isPlayerAnAdmin(int client) 
{ 
	new AdminId: ID = GetUserAdmin(client);
	return (ID != INVALID_ADMIN_ID); // IF id == INVALID_ADMIN_ID was not an admin, if not equal, was admin.
}


void SetImpostorsCreditsByWinning() 
{
	changingPlayerMoney = true; 
	if (disableChangingMoneyTimer != INVALID_HANDLE) { 
		KillTimer(disableChangingMoneyTimer); 
		disableChangingMoneyTimer = INVALID_HANDLE;
	}
	
	new amountOfMoneyToAdd = GetConVarInt(sm_ttt_impostor_win_money);
	new amountOfFragsToAdd = GetConVarInt(sm_ttt_impostor_win_points);

	new i = 1;
	while (i <= greatestClientNumber) {
		if (IsClientInGame(i)) {	
			if (!Player[i - 1][isAnImpostor]) {
				SetEntProp(i, Prop_Data, "m_iDeaths", GetEntProp(i, Prop_Data, "m_iDeaths") + 1);
			} else {
				SetEntData(i, money_count, GetEntData(i, money_count) + amountOfMoneyToAdd); 
				SetEntProp(i, Prop_Data, "m_iFrags", GetClientFrags(i) + amountOfFragsToAdd); 				
			}
		}	
		i++;
	}
	
	changingPlayerMoney = false;
	return;
}


void SetInnocentsCreditsByWinning() 
{
	changingPlayerMoney = true; 
	if (disableChangingMoneyTimer != INVALID_HANDLE) { 
		KillTimer(disableChangingMoneyTimer); 
		disableChangingMoneyTimer = INVALID_HANDLE;
	}
	
	new amountOfMoneyToAdd = GetConVarInt(sm_ttt_innocent_win_money);
	new amountOfFragsToAdd = GetConVarInt(sm_ttt_innocent_win_points);	
	
	new i = 1;
	while (i <= greatestClientNumber) { 
		
		if (IsClientInGame(i)) {
			if (!Player[i - 1][isAnImpostor]) { 
				SetEntData(i, money_count, GetEntData(i, money_count) + amountOfMoneyToAdd); 
				SetEntProp(i, Prop_Data, "m_iFrags", GetClientFrags(i) + amountOfFragsToAdd); 
			} else {
				SetEntProp(i, Prop_Data, "m_iDeaths", GetEntProp(i, Prop_Data, "m_iDeaths") + 1); // I ADD A DEATH TO THE IMPOSTORS FOR HAVING LOST.
			}
		}
		i++;

	}		
	changingPlayerMoney = false;	
	return;
}


bool isLikeAPreviousValue2(int previousNumberOfHostages, int[] numbersOfHostagesToKillUntilNow, int randomInt) 
{
	new i = 0;
	
	while (i < previousNumberOfHostages) {
		if (numbersOfHostagesToKillUntilNow[i] == randomInt) {
			return true;
		}
		i++;
	}
	
	return false;
}		


bool isLikeAPreviousValue(int randomInt, int ultPos)
{
	new i = 0;
	while (i < ultPos) {
		
		if (randomInt == impostorPerClientNumber[i]) {
			return true;
		}
		i++;
		
	}
	return false;

}


bool esIgualAAlgunImpostorAnterior(int previousNumberOfImpostors, int[] previousImpostors, int randomInt) 
{
	new i = 0;
	
	while (i < previousNumberOfImpostors) {
		if (previousImpostors[i] == randomInt) {
			return true;
		}
		i++;
	}
	
	return false;
}


public void BanPlayer(int client, const String: reason[])
{ 
	new String: steamid[50]; 
	decl String: clientName[40];
	
	GetClientName(client, clientName, sizeof(clientName));
	
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	LogAction(client, -1, "\"%L\" added ban (minutes \"%d\") (id \"%s\") (reason \"%s\")", client, GetConVarInt(sm_ttt_ban_time), steamid, reason);
	BanIdentity(steamid, GetConVarInt(sm_ttt_ban_time), BANFLAG_AUTHID, reason, "sm_addban", client);
	KickClient(client, "%s%t%i%t", reason, "BAN - You will be able to play again in", GetConVarInt(sm_ttt_ban_time), "BAN - minutes"); 
	
	PrintToChatAll("%s%s%s%t%s", "\x0766EEFF[\x07FF0000TTT\x0766EEFF] ", hexColorByClientNumber(client), clientName, "BAN - player has been banned automatically by", reason);
	
	// I REMOVE ALL THE ACCUMULATED AMOUNTS OF BAN THAT THE CLIENT HAD (IN CASE IT DON'T NOT INCLUDE THE OnClientDisconnect) BECAUSE THIS WOULD NOT HAPPEN THE SAME:
    Player[client - 1][isAnImpostor] = false; 
	Player[client - 1][ban_innHurtHostage] = 0;
	Player[client - 1][ban_impHurtImp] = 0;
	Player[client - 1][ban_innHurtInn] = 0;	

	// BAN WORKS. WHEN THE SERVER IS TURNED OFF, ALL PLAYERS WHO HAVE BEEN BANNED WILL STOP BEING. TO REMOVE THE BAN, IT IS DONE WITH sm_unban <BANNED CLIENT ID / STEAMID / ETC>.

	return Plugin_Handled;
}


void AsignarColorDeJugadorPorNumeroDeCliente(client)
{ // THE RETURNS AT THE END OF THE IF ARE TO OPTIMIZE, BUT EVEN THOUGH HAVING TAKEN A COLOR, IT WILL CONTINUE TO EVALUATE. COLORS ARE ASSIGNED ACCORDING TO THE NUMBER OF PLAYER. AFTER I CAN MAKE A SYSTEM SO THAT EACH ONE CAN CHOOSE ITS COLOR, AS IN AMONG US, THE SAME WOULD BE MANY MORE COLORS.
	if (client == 1) { SetEntityRenderColor(client, 255, 0, 0, 255); return; } // 1 RED Hex: FF0000
	if (client == 2) { SetEntityRenderColor(client, 0, 76, 255, 255); return; } // 2 BLUE Hex: 004CFF
	if (client == 3) { SetEntityRenderColor(client, 0, 209, 69, 255); return; } // 3 GREEN Hex: 00D145
	if (client == 4) { SetEntityRenderColor(client, 255, 255, 0, 255); return; } // 4 YELLOW Hex: FFFF00
	if (client == 5) { SetEntityRenderColor(client, 255, 143, 235, 255); return; } // 5 PINK Hex: FF8FEB
	if (client == 6) { SetEntityRenderColor(client, 255, 170, 0, 255); return; } // 6 ORANGE Hex: FFAA00
	if (client == 7) { SetEntityRenderColor(client, 0, 0, 0, 255); return; } // 7 BLACK Hex: 000000
	if (client == 8) { SetEntityRenderColor(client, 0, 198, 255, 255); return; } // 8 LIGHT-BLUE Hex: 00C6FF
	if (client == 9) { SetEntityRenderColor(client, 196, 78, 0, 255); return; } // 9 BROWN Hex: C44E00
	if (client == 10) { SetEntityRenderColor(client, 144, 255, 0, 255); return; } // 10 LIGHT GREEN Hex: 72FF00
	if (client == 11) { SetEntityRenderColor(client, 178, 0, 255, 255); return; } // 11 PURPLE Hex: B200FF
	if (client == 12) { SetEntityRenderColor(client, 0, 255, 169, 255); return; } // 12 LIME Hex: 00FFA9
	if (client == 13) { SetEntityRenderColor(client, 183, 0, 0, 255); return; } // 13 RED BROWN Hex: B70000
	if (client == 14) { SetEntityRenderColor(client, 62, 43, 0, 255); return; } // 14 GREEN BROWN Hex: 3E2B00
	if (client == 15) { SetEntityRenderColor(client, 153, 153, 153, 255); return; } // 15 GREY Hex: 999999
	if (client == 16) { SetEntityRenderColor(client, 255, 255, 255, 255); return; } // 16 WHITE Hex: FFFFFF
	if (client == 17) { SetEntityRenderColor(client, 0, 127, 14, 255); return; } // 17 DARK GREEN Hex: 007F0E
	if (client == 18) { SetEntityRenderColor(client, 229, 186, 32, 255); return; } // 18 LIGHT ORANGE (GOLD) Hex: E5BA20
	if (client == 19) { SetEntityRenderColor(client, 115, 0, 168, 255); return; } // 19 DARK PURPLE Hex: 7300A8
	if (client == 20) { SetEntityRenderColor(client, 38, 170, 101, 255); return; } // 20 APPLE DARK GREEN Hex: 26AA65
	if (client == 21) { SetEntityRenderColor(client, 255, 15, 59, 255); return; } // 21 LIGHT RED Hex: FF0F3B
	if (client == 22) { SetEntityRenderColor(client, 255, 227, 89, 255); return; } // 22 LIGHT YELLOW Hex: FFE359
	if (client == 23) { SetEntityRenderColor(client, 255, 0, 220, 255); return; } // 23 STRONG PINK Hex: FF00DC
	if (client == 24) { SetEntityRenderColor(client, 188, 157, 100, 255); return; } // 24 BRONZE (REALLY LIGHT ORANGE) Hex: BC9D64
	if (client == 25) { SetEntityRenderColor(client, 67, 128, 137, 255); return; } // 25 GREY LIGHT-BLUE Hex: 438089
	if (client == 26) { SetEntityRenderColor(client, 182, 255, 132, 255); return; } // 26 WATER GREEN Hex: B6FF84
	if (client == 27) { SetEntityRenderColor(client, 223, 155, 255, 255); return; } // 27 LIGHT PURPLE Hex: DF9BFF
	if (client == 28) { SetEntityRenderColor(client, 186, 171, 147, 255); return; } // 28 LIGHT BRONZE Hex: BAAB93
	if (client == 29) { SetEntityRenderColor(client, 193, 0, 93, 255); return; } // 29 BROWNIE PURPLE Hex: C1005D
	if (client == 30) { SetEntityRenderColor(client, 0, 216, 119, 255); return; } // 30 STRONG GREEN WATER Hex: 00D877
	if (client == 31) { SetEntityRenderColor(client, 0, 188, 188, 255); return; } // 31 DARK LIGHT-BLUE Hex: 00BCBC
	if (client == 32) { SetEntityRenderColor(client, 255, 194, 248, 255); return; } // 32 LIGHT PINK Hex: FFC2F8
	if (client == 33) { SetEntityRenderColor(client, 255, 0, 0, 255); return; } // << REPEAT >>  // 1 RED
	if (client == 34) { SetEntityRenderColor(client, 0, 76, 255, 255); return; } // 2 BLUE
	if (client == 35) { SetEntityRenderColor(client, 0, 209, 69, 255); return; } // 3 GREEN
	if (client == 36) { SetEntityRenderColor(client, 255, 255, 0, 255); return; } // 4 YELLOW
	if (client == 37) { SetEntityRenderColor(client, 255, 143, 235, 255); return; } // 5 PINK
	if (client == 38) { SetEntityRenderColor(client, 255, 170, 0, 255); return; } // 6 ORANGE
	if (client == 39) { SetEntityRenderColor(client, 0, 0, 0, 255); return; } // 7 BLACK
	if (client == 40) { SetEntityRenderColor(client, 0, 198, 255, 255); return; } // 8 LIGHT-BLUE
	if (client == 41) { SetEntityRenderColor(client, 196, 78, 0, 255); return; } // 9 BROWN
	if (client == 42) { SetEntityRenderColor(client, 144, 255, 0, 255); return; } // 10 LIGHT GREEN
	if (client == 43) { SetEntityRenderColor(client, 178, 0, 255, 255); return; } // 11 PURPLE
	if (client == 44) { SetEntityRenderColor(client, 0, 255, 169, 255); return; } // 12 LIME
	if (client == 45) { SetEntityRenderColor(client, 183, 0, 0, 255); return; } // 13 RED BROWN
	if (client == 46) { SetEntityRenderColor(client, 62, 43, 0, 255); return; } // 14 GREEN BROWN
	if (client == 47) { SetEntityRenderColor(client, 153, 153, 153, 255); return; } // 15 GREY
	if (client == 48) { SetEntityRenderColor(client, 255, 255, 255, 255); return; } // 16 WHITE
	if (client == 49) { SetEntityRenderColor(client, 0, 127, 14, 255); return; } // 17 DARK GREEN
	if (client == 50) { SetEntityRenderColor(client, 229, 186, 32, 255); return; } // 18 LIGHT ORANGE (GOLD)
	if (client == 51) { SetEntityRenderColor(client, 115, 0, 168, 255); return; } // 19 DARK PURPLE
	if (client == 52) { SetEntityRenderColor(client, 38, 170, 101, 255); return; } // 20 APPLE DARK GREEN
	if (client == 53) { SetEntityRenderColor(client, 255, 15, 59, 255); return; } // 21 LIGHT RED
	if (client == 54) { SetEntityRenderColor(client, 255, 227, 89, 255); return; } // 22 LIGHT YELLOW
	if (client == 55) { SetEntityRenderColor(client, 255, 0, 220, 255); return; } // 23 STRONG PINK
	if (client == 56) { SetEntityRenderColor(client, 188, 157, 100, 255); return;} // 24 BRONZE (REALLY LIGHT ORANGE)
	if (client == 57) { SetEntityRenderColor(client, 67, 128, 137, 255); return; } // 25 GREY LIGHT-BLUE
	if (client == 58) { SetEntityRenderColor(client, 182, 255, 132, 255); return; } // 26 WATER GREEN
	if (client == 59) { SetEntityRenderColor(client, 223, 155, 255, 255); return; } // 27 LIGHT PURPLE
	if (client == 60) { SetEntityRenderColor(client, 186, 171, 147, 255); return; } // 28 LIGHT BRONZE
	if (client == 61) { SetEntityRenderColor(client, 193, 0, 93, 255); return; } // 29 BROWNIE PURPLE
	if (client == 62) { SetEntityRenderColor(client, 0, 216, 119, 255); return; } // 30 STRONG GREEN WATER
	if (client == 63) { SetEntityRenderColor(client, 0, 188, 188, 255); return; } // 31 DARK LIGHT-BLUE
	if (client == 64) { SetEntityRenderColor(client, 255, 194, 248, 255); return; } // 32 LIGHT PINK
	if (client == 65) { SetEntityRenderColor(client, 255, 0, 0, 255); return; } // << REPEAT >>  // 1 RED

	return;
}


char[] hexColorByClientNumber(int clientNumber) 
{
	decl String: hexColor[11];
	switch (clientNumber) 
	{
		
		case 1: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF0000"); return hexColor; } 
		case 2: { Format(hexColor, sizeof(hexColor), "%s", "\x07004CFF"); return hexColor; } 
		case 3: { Format(hexColor, sizeof(hexColor), "%s", "\x0700D145"); return hexColor; } 
		case 4: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFFF00"); return hexColor; } 
		case 5: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF8FEB"); return hexColor; } 
		case 6: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFAA00"); return hexColor; } 
		case 7: { Format(hexColor, sizeof(hexColor), "%s", "\x07000000"); return hexColor; } 
		case 8: { Format(hexColor, sizeof(hexColor), "%s", "\x0700C6FF"); return hexColor; } 
		case 9: { Format(hexColor, sizeof(hexColor), "%s", "\x07C44E00"); return hexColor; } 
		case 10: { Format(hexColor, sizeof(hexColor), "%s", "\x0772FF00"); return hexColor; } 
		case 11: { Format(hexColor, sizeof(hexColor), "%s", "\x07B200FF"); return hexColor; } 
		case 12: { Format(hexColor, sizeof(hexColor), "%s", "\x0700FFA9"); return hexColor; } 
		case 13: { Format(hexColor, sizeof(hexColor), "%s", "\x07B70000"); return hexColor; } 
		case 14: { Format(hexColor, sizeof(hexColor), "%s", "\x073E2B00"); return hexColor; } 
		case 15: { Format(hexColor, sizeof(hexColor), "%s", "\x07999999"); return hexColor; } 
		case 16: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFFFFF"); return hexColor; } 
		case 17: { Format(hexColor, sizeof(hexColor), "%s", "\x07007F0E"); return hexColor; } 
		case 18: { Format(hexColor, sizeof(hexColor), "%s", "\x07E5BA20"); return hexColor; } 
		case 19: { Format(hexColor, sizeof(hexColor), "%s", "\x077300A8"); return hexColor; } 
		case 20: { Format(hexColor, sizeof(hexColor), "%s", "\x0726AA65"); return hexColor; } 
		case 21: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF0F3B"); return hexColor; } 
		case 22: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFE359"); return hexColor; } 
		case 23: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF00DC"); return hexColor; } 
		case 24: { Format(hexColor, sizeof(hexColor), "%s", "\x07BC9D64"); return hexColor; } 
		case 25: { Format(hexColor, sizeof(hexColor), "%s", "\x07438089"); return hexColor; } 
		case 26: { Format(hexColor, sizeof(hexColor), "%s", "\x07B6FF84"); return hexColor; } 
		case 27: { Format(hexColor, sizeof(hexColor), "%s", "\x07DF9BFF"); return hexColor; } 
		case 28: { Format(hexColor, sizeof(hexColor), "%s", "\x07BAAB93"); return hexColor; } 
		case 29: { Format(hexColor, sizeof(hexColor), "%s", "\x07C1005D"); return hexColor; } 
		case 30: { Format(hexColor, sizeof(hexColor), "%s", "\x0700D877"); return hexColor; } 
		case 31: { Format(hexColor, sizeof(hexColor), "%s", "\x0700BCBC"); return hexColor; } 
		case 32: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFC2F8"); return hexColor; } 
		case 33: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF0000"); return hexColor; } // REPEAT
		case 34: { Format(hexColor, sizeof(hexColor), "%s", "\x07004CFF"); return hexColor; } 
		case 35: { Format(hexColor, sizeof(hexColor), "%s", "\x0700D145"); return hexColor; } 
		case 36: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFFF00"); return hexColor; } 
		case 37: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF8FEB"); return hexColor; } 
		case 38: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFAA00"); return hexColor; } 
		case 39: { Format(hexColor, sizeof(hexColor), "%s", "\x07000000"); return hexColor; } 
		case 40: { Format(hexColor, sizeof(hexColor), "%s", "\x0700C6FF"); return hexColor; } 
		case 41: { Format(hexColor, sizeof(hexColor), "%s", "\x07C44E00"); return hexColor; } 
		case 42: { Format(hexColor, sizeof(hexColor), "%s", "\x0772FF00"); return hexColor; } 
		case 43: { Format(hexColor, sizeof(hexColor), "%s", "\x07B200FF"); return hexColor; } 
		case 44: { Format(hexColor, sizeof(hexColor), "%s", "\x0700FFA9"); return hexColor; } 
		case 45: { Format(hexColor, sizeof(hexColor), "%s", "\x07B70000"); return hexColor; } 
		case 46: { Format(hexColor, sizeof(hexColor), "%s", "\x073E2B00"); return hexColor; } 
		case 47: { Format(hexColor, sizeof(hexColor), "%s", "\x07999999"); return hexColor; } 
		case 48: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFFFFF"); return hexColor; } 
		case 49: { Format(hexColor, sizeof(hexColor), "%s", "\x07007F0E"); return hexColor; } 
		case 50: { Format(hexColor, sizeof(hexColor), "%s", "\x07E5BA20"); return hexColor; } 
		case 51: { Format(hexColor, sizeof(hexColor), "%s", "\x077300A8"); return hexColor; } 
		case 52: { Format(hexColor, sizeof(hexColor), "%s", "\x0726AA65"); return hexColor; } 
		case 53: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF0F3B"); return hexColor; } 
		case 54: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFE359"); return hexColor; } 
		case 55: { Format(hexColor, sizeof(hexColor), "%s", "\x07FF00DC"); return hexColor; } 
		case 56: { Format(hexColor, sizeof(hexColor), "%s", "\x07BC9D64"); return hexColor; } 
		case 57: { Format(hexColor, sizeof(hexColor), "%s", "\x07438089"); return hexColor; } 
		case 58: { Format(hexColor, sizeof(hexColor), "%s", "\x07B6FF84"); return hexColor; } 
		case 59: { Format(hexColor, sizeof(hexColor), "%s", "\x07DF9BFF"); return hexColor; } 
		case 60: { Format(hexColor, sizeof(hexColor), "%s", "\x07BAAB93"); return hexColor; } 
		case 61: { Format(hexColor, sizeof(hexColor), "%s", "\x07C1005D"); return hexColor; } 
		case 62: { Format(hexColor, sizeof(hexColor), "%s", "\x0700D877"); return hexColor; } 
		case 63: { Format(hexColor, sizeof(hexColor), "%s", "\x0700BCBC"); return hexColor; } 
		case 64: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFC2F8"); return hexColor; } 
		case 65: { Format(hexColor, sizeof(hexColor), "%s", "\x07FFC2F8"); return hexColor; } // REPEAT
		
	}
	// else { COLOR DIDN'T FOUND:
	Format(hexColor, sizeof(hexColor), "%s", "COLORERROR");
	return hexColor;
}


char[] colorNameByClientNumber(int clientNumber) 
{
	decl String: colorName[19];
	
	switch (clientNumber) 
	{
		
		case 1: { Format(colorName, sizeof(colorName), "%t", "red"); return colorName; } 
		case 2: { Format(colorName, sizeof(colorName), "%t", "blue"); return colorName; } 
		case 3: { Format(colorName, sizeof(colorName), "%t", "green"); return colorName; } 
		case 4: { Format(colorName, sizeof(colorName), "%t", "yellow"); return colorName; } 
		case 5: { Format(colorName, sizeof(colorName), "%t", "pink"); return colorName; } 
		case 6: { Format(colorName, sizeof(colorName), "%t", "orange"); return colorName; } 
		case 7: { Format(colorName, sizeof(colorName), "%t", "black"); return colorName; } 
		case 8: { Format(colorName, sizeof(colorName), "%t", "light blue"); return colorName; } 
		case 9: { Format(colorName, sizeof(colorName), "%t", "brown"); return colorName; } 
		case 10: { Format(colorName, sizeof(colorName), "%t", "light green"); return colorName; } 
		case 11: { Format(colorName, sizeof(colorName), "%t", "purple"); return colorName; } 
		case 12: { Format(colorName, sizeof(colorName), "%t", "lime"); return colorName; } 
		case 13: { Format(colorName, sizeof(colorName), "%t", "red brown"); return colorName; } 
		case 14: { Format(colorName, sizeof(colorName), "%t", "green brown"); return colorName; } 
		case 15: { Format(colorName, sizeof(colorName), "%t", "grey"); return colorName; } 
		case 16: { Format(colorName, sizeof(colorName), "%t", "white"); return colorName; } 
		case 17: { Format(colorName, sizeof(colorName), "%t", "dark green"); return colorName; } 
		case 18: { Format(colorName, sizeof(colorName), "%t", "light orange"); return colorName; } 
		case 19: { Format(colorName, sizeof(colorName), "%t", "dark purple"); return colorName; } 
		case 20: { Format(colorName, sizeof(colorName), "%t", "apple dark green"); return colorName; } 
		case 21: { Format(colorName, sizeof(colorName), "%t", "light red"); return colorName; } 
		case 22: { Format(colorName, sizeof(colorName), "%t", "light yellow"); return colorName; } 
		case 23: { Format(colorName, sizeof(colorName), "%t", "strong pink"); return colorName; } 
		case 24: { Format(colorName, sizeof(colorName), "%t", "bronze"); return colorName; } 
		case 25: { Format(colorName, sizeof(colorName), "%t", "grey light blue"); return colorName; } 
		case 26: { Format(colorName, sizeof(colorName), "%t", "water green"); return colorName; } 
		case 27: { Format(colorName, sizeof(colorName), "%t", "light purple"); return colorName; } 
		case 28: { Format(colorName, sizeof(colorName), "%t", "light bronze"); return colorName; } 
		case 29: { Format(colorName, sizeof(colorName), "%t", "brownie purple"); return colorName; } 
		case 30: { Format(colorName, sizeof(colorName), "%t", "strong water green"); return colorName; } 
		case 31: { Format(colorName, sizeof(colorName), "%t", "dark light blue"); return colorName; } 
		case 32: { Format(colorName, sizeof(colorName), "%t", "light pink"); return colorName; } 
		case 33: { Format(colorName, sizeof(colorName), "%t", "red"); return colorName; } // REPEAT
		case 34: { Format(colorName, sizeof(colorName), "%t", "blue"); return colorName; } 
		case 35: { Format(colorName, sizeof(colorName), "%t", "green"); return colorName; } 
		case 36: { Format(colorName, sizeof(colorName), "%t", "yellow"); return colorName; } 
		case 37: { Format(colorName, sizeof(colorName), "%t", "pink"); return colorName; } 
		case 38: { Format(colorName, sizeof(colorName), "%t", "orange"); return colorName; } 
		case 39: { Format(colorName, sizeof(colorName), "%t", "black"); return colorName; } 
		case 40: { Format(colorName, sizeof(colorName), "%t", "light blue"); return colorName; } 
		case 41: { Format(colorName, sizeof(colorName), "%t", "brown"); return colorName; } 
		case 42: { Format(colorName, sizeof(colorName), "%t", "light green"); return colorName; } 
		case 43: { Format(colorName, sizeof(colorName), "%t", "purple"); return colorName; } 
		case 44: { Format(colorName, sizeof(colorName), "%t", "lime"); return colorName; } 
		case 45: { Format(colorName, sizeof(colorName), "%t", "red brown"); return colorName; } 
		case 46: { Format(colorName, sizeof(colorName), "%t", "green brown"); return colorName; } 
		case 47: { Format(colorName, sizeof(colorName), "%t", "grey"); return colorName; } 
		case 48: { Format(colorName, sizeof(colorName), "%t", "white"); return colorName; } 
		case 49: { Format(colorName, sizeof(colorName), "%t", "dark green"); return colorName; } 
		case 50: { Format(colorName, sizeof(colorName), "%t", "light orange"); return colorName; } 
		case 51: { Format(colorName, sizeof(colorName), "%t", "dark purple"); return colorName; } 
		case 52: { Format(colorName, sizeof(colorName), "%t", "apple dark green"); return colorName; } 
		case 53: { Format(colorName, sizeof(colorName), "%t", "light red"); return colorName; } 
		case 54: { Format(colorName, sizeof(colorName), "%t", "light yellow"); return colorName; } 
		case 55: { Format(colorName, sizeof(colorName), "%t", "strong pink"); return colorName; } 
		case 56: { Format(colorName, sizeof(colorName), "%t", "bronze"); return colorName; } 
		case 57: { Format(colorName, sizeof(colorName), "%t", "grey light blue"); return colorName; } 
		case 58: { Format(colorName, sizeof(colorName), "%t", "water green"); return colorName; } 
		case 59: { Format(colorName, sizeof(colorName), "%t", "light purple"); return colorName; } 
		case 60: { Format(colorName, sizeof(colorName), "%t", "light bronze"); return colorName; } 
		case 61: { Format(colorName, sizeof(colorName), "%t", "brownie purple"); return colorName; } 
		case 62: { Format(colorName, sizeof(colorName), "%t", "strong water green"); return colorName; } 
		case 63: { Format(colorName, sizeof(colorName), "%t", "dark light blue"); return colorName; } 
		case 64: { Format(colorName, sizeof(colorName), "%t", "light pink"); return colorName; } 
		case 65: { Format(colorName, sizeof(colorName), "%t", "light pink"); return colorName; } // REPEAT
		
	} // else { COLOR ERROR:
	
	Format(colorName, sizeof(colorName), "%s", "[COLOR ERROR]");
	return colorName;
}