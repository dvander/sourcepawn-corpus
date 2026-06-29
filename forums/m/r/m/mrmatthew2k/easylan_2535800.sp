#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <entity>  

public Plugin:myinfo =
{
	name = "Easy Lan Manager",
	author = "mrmatthew2k",
	description = "To make lans easier for admins",
	version = "2.0",
	url = "http://www.sourcemod.net"
}
// def

#define TeamSwitchNeeded 0
#define TeamThatIsNeeded 1
#define InventoryRestoreNeeded 2
// variables global


ConVar g_PluginEnabledConVar;
ConVar g_EmergencyConVar;
ConVar g_AutomaticConVar;
ConVar g_AuthorizeConVar;
ConVar g_TournamentNameConVar;
ConVar g_CTTeamConVar;
ConVar g_TTeamConVar;
Handle BlinkerTimer = INVALID_HANDLE;
char authid[MAXPLAYERS + 1][32];
StringMap playersjoin;
int backupinv[MAXPLAYERS + 1][3]; // 0 - Team Needed?, 1 - Team, 2- Inv Needed?
bool gamestate_live = false;
bool gamestate_live_doknife = false;
bool gamestate_live_scoring = false;
bool gamestate_live_nokill = true;
int gamestate_t_score;
int gamestate_ct_score;
int gamestate_live_knifewinner;
bool gamestate_warmup;
bool gamestate_ct_ready;
bool gamestate_t_ready;
int blinks;
// new gamestate_live_secondhalf = false;
char gamestate_ct_team[64] = "Counter-Terrorists";
char gamestate_t_team[64] = "Terrorists";
char hostnameOld[64] = "Counter-Strike: Global Offensive";




public void OnPluginStart() {
	
	playersjoin = new StringMap();
	g_PluginEnabledConVar = CreateConVar("easylan_enabled", "1", "Enables easy lan manager.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_EmergencyConVar = CreateConVar("easylan_emergencystop_enabled", "1", "Enables an emergency !stop command before any damage.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_AutomaticConVar = CreateConVar("easylan_automaticstop_enabled", "1", "Enables an automatic emergency !stop command before any damage.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_AuthorizeConVar = CreateConVar("easylan_require_authorization", "1", "If 0, non-authenticated users (not on team.txt) can perform actions such as !ready and !stay. It is recommended to leave at 1, and use team config files.", FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	g_CTTeamConVar = CreateConVar("ct_team", "Counter-Terrorists", "Counter-Terrorist team convar.", FCVAR_PRINTABLEONLY, false, false);
	g_TTeamConVar = CreateConVar("t_team", "Terrorists", "Terrorist team convar.", FCVAR_PRINTABLEONLY, false, false);
	g_TournamentNameConVar = CreateConVar("easylan_tournament_name", "Tournament Name", "Name of competition for score logger", FCVAR_NOTIFY|FCVAR_DONTRECORD, false, false)
	HookConVarChange(g_PluginEnabledConVar, ConVar_EnableChangeEnabled);
	HookConVarChange(g_TTeamConVar, TTeamConVar_Change);
	HookConVarChange(g_CTTeamConVar, CTTeamConVar_Change);
	
	
	
	ConVar_EnableCheck(); 
	
	//RegServerCmd("ct_team", PutTeamOnCT);
	//RegServerCmd("t_team", PutTeamOnT);
	RegServerCmd("easylan_forcestart", LiveTheGame);
	RegServerCmd("easylan_newmatch", SetupTheGame);
	RegServerCmd("easylan_notlive", UnliveTheGame);
	RegServerCmd("easylan_reinitialize", ReinitializeTheGame);
	RegServerCmd("easylan_listteams", ListTeamNames);
	RegConsoleCmd("sm_stop", TechnicalStop);
	RegConsoleCmd("sm_playon", PlayOn);
	RegConsoleCmd("sm_unpause", PlayOn);
	RegConsoleCmd("sm_pause", PlayStop);
	RegConsoleCmd("sm_stay", TeamStay);
	RegConsoleCmd("sm_ready", TeamReady);
	RegConsoleCmd("sm_notready", TeamNotReady);
	RegConsoleCmd("sm_switch", TeamSwitch);
	RegConsoleCmd("jointeam", Command_Join);
	
	HookUserMessage(GetUserMessageId("VGUIMenu"), CheckTeam, true);
	
	// make the folder for teams
	char argpath[128];
	argpath = "/configs/easylan/teams/"
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,argpath);
	
	

}

public void ConVar_EnableCheck() {
     bool enabled = GetConVarBool(g_PluginEnabledConVar);
 
     if (enabled) {
        OnPluginEnabledConVar();
     } else {
        OnPluginDisabledConVar();
     }
}

public void ConVar_EnableChangeEnabled(Handle:convar, const String:oldValue[], const String:newValue[]) {
     bool enabled = GetConVarBool(g_PluginEnabledConVar);
 
     if (enabled) {
        OnPluginEnabledConVar();
     } else {
        OnPluginDisabledConVar();
     }
}

 
public void OnPluginEnabledConVar() {
	
	Handle g_hostname = FindConVar("mp_backup_round_file_last");
	GetConVarString(g_hostname, hostnameOld, 64);
	ServerCommand("exec sourcemod/easylan/easylan.cfg");
	
	//HookEvent("player_team", CheckTeam);
	

}

public void OnPluginDisabledConVar() {
	
	
	//UnhookEvent("player_team", CheckTeam);
	

}


public void TTeamConVar_Change(Handle:convar, const String:oldValue[], const String:newValue[]) {
	PutTeamOnSide(newValue, CS_TEAM_T);
}

public void CTTeamConVar_Change(Handle:convar, const String:oldValue[], const String:newValue[]) {
	PutTeamOnSide(newValue, CS_TEAM_CT);
}

stock void SwitchPlayerTeam(int client, int team) {
  if (GetClientTeam(client) == team)
    return;

  if (team > CS_TEAM_SPECTATOR) {
    CS_SwitchTeam(client, team);
    CS_UpdateClientModel(client);
    CS_RespawnPlayer(client);
  } else {
    ChangeClientTeam(client, team);
  }
}

stock int GetPlayerCount() {
	int players;
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i))
			players++;
	}
	return players;
}

public void StoreUser(int client) {
	if (IsFakeClient(client)) {
		return;
	} else {
		char buffer[26];
		GetClientAuthId(client, AuthId_Steam2, buffer, sizeof(buffer));
		char id[16];
		for (int i = 0; i < sizeof(id); i++) {
    		id[i] = buffer[i + 10];	
		}
		TrimString(id);
		authid[client] = id;
		PrintToServer("User STEAM_0:0:%s, client %d, cached.", authid[client], client);
	}
}

public void OnClientAuthorized(int client, const char[] auth) {

	StoreUser(client);
	
}

public void OnClientDisconnect(int client) {

	if (gamestate_live && GetClientTeam(client) > CS_TEAM_SPECTATOR && !IsFakeClient(client) && g_AutomaticConVar.BoolValue) {
		//gett all the stufff
		
		backupinv[client][TeamSwitchNeeded] = 1;
		backupinv[client][InventoryRestoreNeeded] = 1;
		backupinv[client][TeamThatIsNeeded] = GetClientTeam(client);
		if (gamestate_live_nokill) {
			ServerCommand("mp_pause_match");
			Handle g_lastbackupvar = FindConVar("mp_backup_round_file_last");
			char g_backupfile[128];
			GetConVarString(g_lastbackupvar, g_backupfile, sizeof(g_backupfile));
			ServerCommand("mp_backup_restore_load_file %s", g_backupfile);
			char bname[36];
			GetClientName(client, bname, 35);
			PrintToChatAll("%s has disconnected before any gunfights and the game has been paused.", bname);
			PrintToServer("%s has disconnected before any gunfights and the game has been paused.", bname);
		}
		else {
			ServerCommand("mp_pause_match");
			char bname[36];
			GetClientName(client, bname, 35);
			PrintToServer("%s has disconnected after damage, game will pause on next round.", bname);
		}
	}
	
	CreateTimer(3.0, NoPlayersCheck);
	
	
}

public Action NoPlayersCheck(Handle timer) {
	if (gamestate_live && (GetPlayerCount() < 1)) {
		
		UnliveTheGame(1);
		ServerCommand("tv_stoprecord");
		char commandbuff[72];
		Format(commandbuff, 72, "hostname \"%s\"", hostnameOld);
		ServerCommand(commandbuff);
		ResetVars();
		if (BlinkerTimer != INVALID_HANDLE) {
			CloseHandle(BlinkerTimer);
			BlinkerTimer = INVALID_HANDLE;
		}
		ServerCommand("mp_unpause_match");
	
	}

}

public void OnClientConnected(int client) {
	
}
public Action CheckTeam(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)  {
	int client = players[0];
	char buffermsg[64];
	int team;
	PbReadString(msg, "name", buffermsg, sizeof(buffermsg));  
	if (g_PluginEnabledConVar.BoolValue && StrEqual(buffermsg, "team", true) && gamestate_live && backupinv[client][TeamSwitchNeeded] == 1) { 

		char bname[36];
		GetClientName(client, bname, 35);
		PrintToServer("%s has reconnected. Trying to put back on team %d", bname, backupinv[client][1]);
		SwitchPlayerTeam(client, backupinv[client][TeamThatIsNeeded]);
		backupinv[client][TeamSwitchNeeded] = 0;

		return Plugin_Handled;
		
	} else if (g_PluginEnabledConVar.BoolValue && playersjoin.GetValue(authid[client], team) && StrEqual(buffermsg, "team", true)) { 
		
		SwitchPlayerTeam(client, team);
		//playersjoin.Remove(authid[client]);
		PrintToServer("Putting player on right team.");
		return Plugin_Handled;
		
	} else if ((!gamestate_live || !g_PluginEnabledConVar.BoolValue) && StrEqual(buffermsg, "team", true)) {
		PrintToServer("No game so join is okay.");
		return Plugin_Continue;
	} else {
		
		return Plugin_Continue;
	}
}


public void OnMapEnd() {
	// prevent double score hooking on the next game
	if (g_PluginEnabledConVar.BoolValue && gamestate_live) {
		UnhookEvent("round_start", YesNoKill);
		UnhookEvent("round_end", Event_CheckScore);
		PrintToServer("The game is over.");
	}
	gamestate_live = false;
	gamestate_live_nokill = true;
	
	gamestate_ct_team = "Counter-Terrorists";
	gamestate_t_team = "Terrorists";
	gamestate_ct_score = 0;
	gamestate_t_score = 0;
	ServerCommand("tv_stoprecord");
	ResetVars();
	
	

}
public void OnMapStart() {
	if (BlinkerTimer != INVALID_HANDLE) {
		CloseHandle(BlinkerTimer);
		BlinkerTimer = INVALID_HANDLE;
	
	}
	if (g_PluginEnabledConVar.BoolValue && gamestate_live) {
	
		UnliveTheGame(1);
	}
	
	gamestate_live = false;
	gamestate_live_nokill = true;
	//gamestate_live_secondhalf = false;
	gamestate_ct_score = 0;
	gamestate_t_score = 0;
	ResetVars();

}
public Action:PutTeamOnSide(const char[] convarvalue, int team) {
	// this function should have the same code at PutTeamOnT except the teamid
	// check if my plugin is enabled
	
	bool enabled = GetConVarBool(g_PluginEnabledConVar);
	if (enabled) {
    	if (gamestate_live) {
    		PrintToServer("Can't set teams after game is already live. Use easylan_notlive and start a new game.");
    		return Plugin_Handled;
    	}
    	
	} else {
       PrintToServer("Plugin disabled. Use easylan_enabled to enable.");
       return Plugin_Handled;
    }
	// checks if theres an argument
	if (strlen(convarvalue) < 1) {
		if (team == CS_TEAM_CT) {
			PrintToServer("Usage: ct_team <teamname>");
		}
		else {
			PrintToServer("Usage: t_team <teamname>");
		}
		return Plugin_Handled;
	}
	// autoteambalance off
	ServerCommand("mp_limitteams 0");
	ServerCommand("mp_autoteambalance 0");
	
	// obtain argument with folder
	char argbuffer[64]
	char reusearg[64];
	strcopy(argbuffer, sizeof(argbuffer), convarvalue);
	reusearg = argbuffer;
	StrCat(argbuffer, sizeof(argbuffer), ".txt");
	char argpath[128];
	argpath = "/configs/easylan/teams/"
	StrCat(argpath, sizeof(argpath), argbuffer);
	// read the file from command
	
	char path[PLATFORM_MAX_PATH]
	char line[128];
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, argpath);
	
	// checking if file exists
	if (!FileExists(path)) {
		PrintToServer("File %s does not exist, but team name will be changed anyway. You can ignore this if intended.", argpath);
		if (team == CS_TEAM_CT) {
			gamestate_ct_team = reusearg;
			ServerCommand("mp_teamname_1 %s", reusearg);
		} else {
			gamestate_t_team = reusearg;
			ServerCommand("mp_teamname_2 %s", reusearg);
		}
		return Plugin_Handled;
	}
	
	Handle fileHandle = OpenFile(path,"r");
	
	while(!IsEndOfFile(fileHandle) && ReadFileLine(fileHandle,line,sizeof(line))) {
		int i = 1;
		bool loop = true;
		while (i < MaxClients && loop) {
			//PrintToServer("Looking for client %d", authid[i]);
			if (IsClientConnected(i) && strlen(authid[i]) > 1 && StrContains(line, authid[i]) > -1) {
				char id[16];
				for (int j = 0; j < sizeof(id); j++) {
    				id[j] = line[j + 10];
				}
				TrimString(id);
				if (team == CS_TEAM_CT) {
					playersjoin.SetValue(id, CS_TEAM_CT, true);
					SwitchPlayerTeam(i, CS_TEAM_CT);
					char authclean[32];
					strcopy(authclean, (strlen(line)), line);
					PrintToServer("Client %d (%s) was moved to the CT team.", i, authclean);
					loop = false;
				} else {
					playersjoin.SetValue(id, CS_TEAM_T, true);
					SwitchPlayerTeam(i, CS_TEAM_T);
					char authclean[32];
					strcopy(authclean, (strlen(line)), line);
					PrintToServer("Client %d (%s) was moved to the T team.", i, authclean);
					loop = false;
				}
			} else {
				//PrintToServer("Clientid: %d or %s doesn't contain %s", i, authid[i], line);
				i++;
			}
		}
		if (loop) {
			char id[16];
			for (int j = 0; j < sizeof(id); j++) {
    				id[j] = line[j + 10];
    		}
			TrimString(id);
			if (team == CS_TEAM_CT) {
				playersjoin.SetValue(id, CS_TEAM_CT, true);
				PrintToServer("Player %s is not in the game yet. Adding to list.", id);
			} else {
				playersjoin.SetValue(id, CS_TEAM_T, true);
				PrintToServer("Player %s is not in the game yet. Adding to list.", id);
			}
		}
		//PrintToServer("Finished %s. Next line", line);
	}
	
	CloseHandle(fileHandle);
	if (team == CS_TEAM_CT) {
	
		PrintToServer("Team %s have been put on the Counter-Terrorist side.", reusearg);
		PrintToChatAll("Team %s have been put on the Counter-Terrorist side.", reusearg);
		gamestate_ct_team = reusearg;
		ServerCommand("mp_teamname_1 %s", reusearg);
	} else {
		PrintToServer("Team %s have been put on the Terrorist side.", reusearg);
		PrintToChatAll("Team %s have been put on the Terrorist side.", reusearg);
		gamestate_t_team = reusearg;
		ServerCommand("mp_teamname_2 %s", reusearg);
	}
	if (StrEqual(gamestate_ct_team, gamestate_t_team, false)) {
		PrintToServer("CT and T side are the same team. This is probably a mistake.");
	}
	return Plugin_Handled;
}

public Action:PutTeamOnT(const char[] convarvalue) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (enabled) {
		if (gamestate_live) {
			PrintToServer("Can't set teams after game is already live. Use easylan_notlive and start a new game.");
			return Plugin_Handled;
    	}
	} else {
		PrintToServer("Plugin disabled. Use easylan_enabled to enable.");
		return Plugin_Handled;
	}
	// checks if theres an argument
	if (strlen(convarvalue) < 1) {
		PrintToServer("Usage: t_team <teamname>");
		return Plugin_Handled;
	}
	ServerCommand("mp_limitteams 0");
	ServerCommand("mp_autoteambalance 0");
	
	// obtain argument with folder
	decl String:argbuffer[64],String:reusearg[64];
	//GetConVarString(g_TTeamConVar, argbuffer, 63);

	strcopy(argbuffer, 63, convarvalue);
	reusearg = argbuffer;
	StrCat(argbuffer, sizeof(argbuffer), ".txt");
	decl String:argpath[128];
	argpath = "/configs/easylan/teams/"
	StrCat(argpath, sizeof(argpath), argbuffer);
	// read the file from command
	
	decl String:path[PLATFORM_MAX_PATH],String:line[128];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,argpath);
	// checking if file exists
	if (!FileExists(path)) {
		PrintToServer("File %s does not exist. You can ignore this.", argpath);
		gamestate_t_team = reusearg;
		ServerCommand("mp_teamname_2 %s", reusearg);
		return Plugin_Handled;
	}
	new Handle:fileHandle=OpenFile(path,"r"); // Opens addons/sourcemod/blank.txt to read from (and only reading)
	while(!IsEndOfFile(fileHandle)&&ReadFileLine(fileHandle,line,sizeof(line))) {
		int i = 1;
		new loop = true;
		while (i <= MaxClients && loop) {
			
			if (strlen(authid[i]) >= 1 && StrContains(line, authid[i]) > -1) {
				
				SwitchPlayerTeam(i, 2);
				char authclean[32];
				strcopy(authclean, (strlen(line)), line);
				PrintToServer("Client %d (%s) was moved to the CT team.", i, authclean);
				loop = false;
			} else {
				//PrintToServer("Clientid: %d or %s doesn't contain %s", i, authid[i], line);
				i++;
			}
		}
		//PrintToServer("Finished %s. Next line", line);
	}
	
	CloseHandle(fileHandle);
	PrintToServer("Team %s have been put on the Terrorist side.", reusearg);
	PrintToChatAll("Team %s have been put on the Terrorist side.", reusearg);
	gamestate_t_team = reusearg;
	ServerCommand("mp_teamname_2 %s", reusearg);
	if (StrEqual(gamestate_ct_team, gamestate_t_team, false)) {
		PrintToServer("CT and T side are the same team. This is probably a mistake.");
	}
	return Plugin_Handled;
	
}
public Action:PlayOn(int client, any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToChat(client, "Easy Lan is disabled.");
		return Plugin_Handled;
	}
	// end of enabled check
	ServerCommand("mp_unpause_match");
	new String:name[36];
	GetClientName(client, name, 35);
	PrintToChatAll("%s has unpaused the match.", name);
	return Plugin_Handled;
}

public Action:PlayStop(int client, any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToChat(client, "Easy Lan is disabled.");
		return Plugin_Handled;
    }
    // end of enabled check
	ServerCommand("mp_pause_match");
	new String:name[36];
	GetClientName(client, name, 35);
	PrintToChatAll("%s has paused the match.", name);
	return Plugin_Handled;
}

public Action:TechnicalStop(int client, any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	new stop_enabled = GetConVarBool(g_EmergencyConVar);
	
	if (!stop_enabled) {
		PrintToChat(client, "The !stop function is disabled.");
		return Plugin_Handled;
    }
	if (!enabled) {
		PrintToChat(client, "Easy Lan is disabled.");
		return Plugin_Handled;
    }
    // end of enabled check
	if (!gamestate_live) {
		PrintToChat(client, "There is no live game being played right now.");
		PrintToServer("Client %d tried to call a technical stop, but there is no live game right now", client);
		return Plugin_Handled;
	}
	if (gamestate_live_doknife) {
		PrintToChat(client, "!stop is not available during a knife round.");
		PrintToServer("Client %d tried to call a technical stop, but there is no live game right now", client);
		return Plugin_Handled;
	}
	if (gamestate_live_nokill) {
		ServerCommand("mp_pause_match");
		new Handle:g_lastbackupvar = FindConVar("mp_backup_round_file_last");
		new String:g_backupfile[128];
		GetConVarString(g_lastbackupvar, g_backupfile, 127);
		ServerCommand("mp_backup_restore_load_file %s", g_backupfile);
		new String:name[36];
		GetClientName(client, name, 35);
		PrintToChatAll("%s has called an emergency technical timeout", name);
		PrintCenterTextAll("%s has called an emergency technical timeout", name);
		PrintToServer("%s has called an emergency technical timeout", name);
	
	} else {
		new String:name[36];
		GetClientName(client, name, 35);
		PrintToChatAll("%s has called an emergency technical timeout, but it is too late too call one.", name);
		PrintToChat(client, "It is too late to call an emergency stop: a player has already been damaged. The match will pause after this round.");
		ServerCommand("mp_pause_match");
		
	}
	return Plugin_Handled;
}

public Action:TeamStay(int client, any args) {
	
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToChat(client, "Easy Lan is disabled.");
		return Plugin_Handled;
    }
	if (gamestate_live_knifewinner <= 1) {
		PrintToChat(client, "There is not active knife round.");
		return Plugin_Handled;
	}
	int pteam;
	int cteam = GetClientTeam(client);
	bool noauth = cteam == gamestate_live_knifewinner && !GetConVarBool(g_AuthorizeConVar);
	bool reqauth = playersjoin.GetValue(authid[client], pteam) && pteam == gamestate_live_knifewinner;
	if (reqauth || noauth) {
		if (gamestate_live_knifewinner == CS_TEAM_CT) {
			PrintToChatAll("%s have elected to !stay.", gamestate_ct_team);
		} else if (gamestate_live_knifewinner == CS_TEAM_T) {
			PrintToChatAll("%s have elected to !stay.", gamestate_t_team);
		}
		
		gamestate_live_doknife = false;
		ServerCommand("exec sourcemod/easylan/live.cfg");
		ServerCommand("mp_warmup_end");
		ServerCommand("sv_hibernate_when_empty 0");
		ServerCommand("mp_backup_round_file easylan");
		gamestate_live = true;
		gamestate_live_knifewinner = 0;

		LiveOn(3);
		gamestate_ct_score = 0;
		gamestate_t_score = 0;
		gamestate_live_scoring = true;
	
	}
	UnhookEvent("round_end", BlinkRound);
	return Plugin_Handled;

}

public Action:TeamSwitch(int client, any args) {
	
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToChat(client, "Easy Lan is disabled.");
		return Plugin_Handled;
    }
	if (gamestate_live_knifewinner <= 1) {
		PrintToChat(client, "There is not active knife round.");
		return Plugin_Handled;
	}
	int pteam;
	int cteam = GetClientTeam(client);
	bool noauth = cteam == gamestate_live_knifewinner && !GetConVarBool(g_AuthorizeConVar);
	bool reqauth = playersjoin.GetValue(authid[client], pteam) && pteam == gamestate_live_knifewinner;
	if (reqauth || noauth) {
		if (gamestate_live_knifewinner == CS_TEAM_CT) {
			PrintToChatAll("%s have elected to !switch.", gamestate_ct_team);
		}
		else if (gamestate_live_knifewinner == CS_TEAM_T) {
			PrintToChatAll("%s have elected to !switch.", gamestate_t_team);
		}
		if (!(StrEqual(gamestate_ct_team, "Counter-Terrorists") && StrEqual(gamestate_t_team, "Terrorists"))) {
			char teambuffer[64];
			teambuffer = gamestate_ct_team;
			gamestate_ct_team = gamestate_t_team;
			gamestate_t_team = teambuffer;
		
		}
		
		for (new i = 1; i < (MaxClients + 1); i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				
				playersjoin.GetValue(authid[i], pteam);
				if (pteam == CS_TEAM_T) {
					playersjoin.SetValue(authid[i], CS_TEAM_CT, true);
					SwitchPlayerTeam(i, CS_TEAM_CT);
				
				} else {
					playersjoin.SetValue(authid[i], CS_TEAM_T, true);
					SwitchPlayerTeam(i, CS_TEAM_T);
				}
			}
		}
		
		ServerCommand("mp_teamname_1 %s", gamestate_ct_team);
		ServerCommand("mp_teamname_2 %s", gamestate_t_team);
		gamestate_live_doknife = false;
		gamestate_live_knifewinner = 0;
		ServerCommand("exec sourcemod/easylan/live.cfg");
		ServerCommand("mp_warmup_end");
		ServerCommand("sv_hibernate_when_empty 0");
		ServerCommand("mp_backup_round_file easylan");
		gamestate_live = true;

		LiveOn(3);
		gamestate_ct_score = 0;
		gamestate_t_score = 0;
		gamestate_live_scoring = true;
	}
	
	UnhookEvent("round_end", BlinkRound);
	return Plugin_Handled;

}

public Action:TeamReady(int client, any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToChat(client, "Easy Lan is disabled.");
		return Plugin_Handled;
	}
	if (!gamestate_warmup) {
		PrintToChat(client, "Warmup mode is not active.");
		return Plugin_Handled;
    }
	int pteam;
	playersjoin.GetValue(authid[client], pteam);
	int cteam = GetClientTeam(client);
	bool noauth = !GetConVarBool(g_AuthorizeConVar);
	if ((pteam == CS_TEAM_CT && gamestate_ct_ready == false) || (cteam == CS_TEAM_CT && noauth)) {
    	gamestate_ct_ready = true;
    	PrintToChatAll("%s are now ready", gamestate_ct_team);
    }
	if ((pteam == CS_TEAM_T && gamestate_t_ready == false) || (cteam == CS_TEAM_T && noauth)) {
		gamestate_t_ready = true;
		PrintToChatAll("%s are now ready", gamestate_t_team);
	}
	return Plugin_Handled;
}

public Action:TeamNotReady(int client, any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToChat(client, "Easy Lan is disabled.");
		return Plugin_Handled;
	}
	if (!gamestate_warmup) {
		PrintToChat(client, "Warmup mode is not active.");
		return Plugin_Handled;
    }
	int pteam;
	playersjoin.GetValue(authid[client], pteam)
	int cteam = GetClientTeam(client);
	bool noauth = !GetConVarBool(g_AuthorizeConVar);
	if ((pteam == CS_TEAM_CT && gamestate_ct_ready == true) || (cteam == CS_TEAM_CT && noauth)) {
		gamestate_ct_ready = false;
		PrintToChatAll("%s are not ready.", gamestate_ct_team);
    }
	if ((pteam == CS_TEAM_T && gamestate_t_ready == true) || (cteam == CS_TEAM_T && noauth))
	{
		gamestate_t_ready = false;
		PrintToChatAll("%s are not ready.", gamestate_t_team);
	}
	return Plugin_Handled;
}

public Action:SetupTheGame(any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToServer("Plugin disabled. Use easylan_enabled to enable.");
		return Plugin_Handled;
	}
	// end of enabled check
	if (gamestate_live) {
		PrintToServer("A game is already live! If you're sure you want a new match use easylan_notlive first.");
		return Plugin_Handled;
	}
	if (args < 2) {
		PrintToServer("Usage: <ct team> <t team> <any number of optional tags> Tags:knife, forcestart");
		return Plugin_Handled;
	}
	// get all argument strings
	decl String:ctbuffer[64],String:tbuffer[64],String:tagbuffer[16],String:secondtagbuffer[16];
	GetCmdArg(1, ctbuffer, 63);
	GetCmdArg(2, tbuffer, 63);
	if (args > 2) {
		GetCmdArg(3, tagbuffer, 15);
		GetCmdArg(4, secondtagbuffer, 15);
		
	}
	// update team convars
	SetConVarString(g_TTeamConVar, tbuffer);
	SetConVarString(g_CTTeamConVar, ctbuffer);
	// changing the convarstring should trigger team related functions
	gamestate_warmup = true;
	// live notlive prefix
	char live_prefix[12] = "*NOT LIVE*";
	if (gamestate_warmup && !gamestate_live) {
		live_prefix = "*LIVE*";
	}
	else if (gamestate_warmup) {
		live_prefix = "*NOT LIVE*";
	}
	ServerCommand("hostname %s %s vs %s", live_prefix, ctbuffer, tbuffer);
	// set knife optional tag
	if (StrEqual(tagbuffer, "knife") || StrEqual(secondtagbuffer, "knife")) {
		gamestate_live_doknife = true;
	}
	
	// set warmup back to false if forcestarting
	if (StrEqual(tagbuffer, "forcestart") || StrEqual(secondtagbuffer, "forcestart")) {
		gamestate_warmup = false;
		ServerCommand("easylan_forcestart");
		return Plugin_Handled;
	
	}
	
	// start the warmup session
	if (gamestate_warmup && BlinkerTimer == INVALID_HANDLE) {
		gamestate_live = false;
		BlinkerTimer = CreateTimer(2.0, WarmupBlinker, _, TIMER_REPEAT);
		ServerCommand("mp_respawn_on_death_ct 1");
		ServerCommand("mp_respawn_on_death_ct 1");
		ServerCommand("mp_startmoney 16000");
		ServerCommand("exec sourcemod/easylan/warmup.cfg");
		PutTeamOnSide(ctbuffer, CS_TEAM_CT);
		PutTeamOnSide(tbuffer, CS_TEAM_T);
		PrintToChatAll("Warmup. *NOT LIVE*");
	
	}
	
	return Plugin_Handled;
}

public Action:LiveTheGame(any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (enabled) {
    	//nothing
	}
	else {
       PrintToServer("Plugin disabled. Use easylan_enabled to enable.");
       return Plugin_Handled;
	}
    // double cheack the teams are correct
	
    // end of enabled check
	if (gamestate_live) {
		PrintToServer("Game is already live!");
		return Plugin_Handled;
	} else {
		//freshest info as possible
		char tstringbuf[128], ctstringbuf[128];
		GetConVarString(g_TTeamConVar, tstringbuf, 128);
		GetConVarString(g_CTTeamConVar, ctstringbuf, 128);
		PutTeamOnSide(ctstringbuf, CS_TEAM_CT);
		PutTeamOnSide(tstringbuf, CS_TEAM_T);
		ServerCommand("exec sourcemod/easylan/live.cfg");
		ServerCommand("mp_warmup_end");
		ServerCommand("sv_hibernate_when_empty 0");
		ServerCommand("mp_respawn_on_death_ct 0");
		ServerCommand("mp_respawn_on_death_ct 0");
		//ServerCommand("mp_startmoney 800");
		ServerCommand("sv_cheats 0");
		// redundant servercommands to make sure all things r good
		ServerCommand("mp_backup_round_file easylan");
		gamestate_live = true;

		
		// knife round
		decl String:argbuffer[64];
		GetCmdArgString(argbuffer, 63);
		if (args > 0 && StrEqual(argbuffer, "knife")) {
			gamestate_live_doknife = true;
		}
		
		
		if (gamestate_live_doknife) {
			ServerCommand("exec sourcemod/easylan/knife.cfg");
			PutTeamOnSide(ctstringbuf, CS_TEAM_CT);
			PutTeamOnSide(tstringbuf, CS_TEAM_T);
			
		} else {
			gamestate_ct_score = 0;
			gamestate_t_score = 0;
			gamestate_live_scoring = true;
		
		}
		
		LiveOn(3);
		gamestate_ct_score = 0;
		gamestate_t_score = 0;
		// change hostname to live
		ServerCommand("hostname *LIVE* %s vs %s", gamestate_ct_team, gamestate_t_team);
		
		HookEvent("player_hurt", NotNoKill);
		HookEvent("round_start", YesNoKill);
		HookEvent("round_end", Event_CheckScore);
		
		new String:versus[256];
		new String:time[32];
		versus = "\"";
		StrCat(versus, 255, gamestate_ct_team);
		StrCat(versus, 255, "_vs_");
		StrCat(versus, 255, gamestate_t_team);
		StrCat(versus, 255, "_");
		IntToString(GetTime(), time, 32);
		StrCat(versus, 255, time);
		StrCat(versus, 255, "\"");
		// why tf did I not use Format()?????
		ServerCommand("tv_record %s", versus);
		
	}
	return Plugin_Handled;
}

public Action:UnliveTheGame(any args) {
	// check if my plugin is enabled
	bool enabled = GetConVarBool(g_PluginEnabledConVar);
	if (!enabled) {
		PrintToServer("Plugin disabled. Use easylan_enabled to enable.");
		return Plugin_Handled;
    }
    // end of enabled check
	if (gamestate_live) {
		UnhookEvent("round_start", YesNoKill);
		UnhookEvent("round_end", Event_CheckScore);
		PrintToServer("The game is canceled. If this was a mistake, type easylan_reinitialize now!!!");
	}
	if (BlinkerTimer != INVALID_HANDLE) {
		CloseHandle(BlinkerTimer);
		BlinkerTimer = INVALID_HANDLE;
	}
	
	gamestate_live = false;
	ServerCommand("tv_stoprecord");
	
	ResetVars();
	return Plugin_Handled;
}

public Action:ReinitializeTheGame(any args) {
	// check if my plugin is enabled
	new enabled = GetConVarBool(g_PluginEnabledConVar);
	if (enabled) {
    	//nothing
	} else {
       PrintToServer("Plugin disabled. Use easylan_enabled to enable.");
       return Plugin_Handled;
    }
    // end of enabled check
	if (!gamestate_live) {
    	HookEvent("round_end", Event_CheckScore);
    	HookEvent("round_start", YesNoKill);
	}
	gamestate_live = true;
	gamestate_live_nokill = false;
	gamestate_live_scoring = true;
	
	

	ServerCommand("mp_pause_match");
	new Handle:g_lastbackupvar = FindConVar("mp_backup_round_file_last");
	new String:g_backupfile[128];
	GetConVarString(g_lastbackupvar, g_backupfile, 127);
	ServerCommand("mp_backup_restore_load_file %s", g_backupfile);
	PrintToChatAll("The game had to be reinitiliazed at the admin's discretion.");
	gamestate_ct_score = CS_GetTeamScore(3);
	gamestate_t_score = CS_GetTeamScore(2);
	
	
	gamestate_live_scoring = true;
	
	
	return Plugin_Handled;
}

public void NotNoKill(Event event, const String:name[], bool:dontBroadcast) {
	gamestate_live_nokill = false;
	UnhookEvent("player_hurt", NotNoKill);
	
}

public void YesNoKill(Event event, const String:name[], bool:dontBroadcast) {

	gamestate_live_nokill = true;
	HookEvent("player_hurt", NotNoKill);
	
}

public Action:LiveOn(int reps) {
	ServerCommand("mp_restartgame 3");
	PrintToChatAll("Live on 3 Restarts!");
	PrintToChatAll("Restart: 1");
	int i = 2;
	while ( i <= (reps))
	{
	CreateTimer((3.8 * (i - 1)), RestartRound, i);
	
	i++;
	}
	
	return Plugin_Continue;
}

public Action:RestartRound(Handle:timer, int i) {

	PrintToChatAll("Restart: %d", (i));
	ServerCommand("mp_restartgame 3");
	
	if (i > 2) {
		PrintToChatAll("Game is now live!");
	}
	
	if (i > 2 && gamestate_live_doknife) {
		PrintToChatAll("KNIFE ROUND");
	}
}


public Action Command_Join(client, args) { 
	if (GetConVarBool(g_PluginEnabledConVar) && gamestate_live) {
		PrintToChat(client, "Teams are locked, because the game is live.");
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}  

public void Event_CheckScore(Event event, const String:name[], bool:dontBroadcast) {
	if (gamestate_live_scoring && !gamestate_live_doknife) {
		new winner = event.GetInt("winner");
		new String:tname[128];
		GetConVarString(g_TournamentNameConVar, tname, 127);
		if (winner == 2) {
			gamestate_t_score++;
		} else if (winner == 3) {
			gamestate_ct_score++;
		}
		if (gamestate_ct_score > gamestate_t_score) {
			PrintToChatAll("[%s] %s are winning %d - %d", tname, gamestate_ct_team, gamestate_ct_score, gamestate_t_score);
		} else if (gamestate_t_score > gamestate_ct_score) {
			PrintToChatAll("[%s] %s are winning %d - %d", tname, gamestate_t_team, gamestate_t_score, gamestate_ct_score);
		} else {
			PrintToChatAll("[%s] The score is tied %d - %d", tname, gamestate_ct_score, gamestate_t_score);
		}
		
		new Handle:maxrounds = FindConVar("mp_maxrounds");
		if ((gamestate_ct_score + gamestate_t_score) == (GetConVarInt(maxrounds) / 2)) {
			Event_Halftime();
		}
	}
	
	if (gamestate_live_doknife) {
		new winner = event.GetInt("winner");
		gamestate_live_knifewinner = winner;
		if (winner == 2) {
			PrintToChatAll("%s have won the knife round and get to !switch or !stay", gamestate_t_team);
		} else if (winner == 3) {
			PrintToChatAll("%s have won the knife round and get to !switch or !stay", gamestate_ct_team);
		}
	
		gamestate_live_doknife = false;
		gamestate_live = true;
		HookEvent("round_end", BlinkRound);
		blinks = 0;
	}
}

public void Event_Halftime() {
	new String:teambuffer[64];
	teambuffer = gamestate_ct_team;
	gamestate_ct_team = gamestate_t_team;
	gamestate_t_team = teambuffer;
	
	int scorebuffer;
	scorebuffer = gamestate_ct_score;
	gamestate_ct_score = gamestate_t_score;
	gamestate_t_score = scorebuffer;
}

public void BlinkRound(Event event, const String:name[], bool:dontBroadcast) {
	if (gamestate_live_knifewinner == 2 && blinks > 0) {
		PrintToChatAll("%s (Terrorists) have won the knife round and get to !switch or !stay", gamestate_t_team);
	}
	if (gamestate_live_knifewinner == 3 && blinks > 0) {
		PrintToChatAll("%s (Counter-Terrorists) have won the knife round and get to !switch or !stay", gamestate_ct_team);
	}
	blinks++;
}

public Action WarmupBlinker(Handle timer) {
	char gamestate_ct_string[16] = "NOT READY";
	char gamestate_t_string[16] = "NOT READY";
	if (gamestate_ct_ready) {
		gamestate_ct_string = "READY";
	}
	if (gamestate_t_ready) {
		gamestate_t_string = "READY";
	}
	PrintHintTextToAll("Warmup\n %s: %s\n %s: %s", gamestate_ct_team, gamestate_ct_string, gamestate_t_team, gamestate_t_string);
	
	if (gamestate_live) {
	
		
		CloseHandle(BlinkerTimer);
		BlinkerTimer = INVALID_HANDLE;
		PrintHintTextToAll("The game has been force started.");
	}
	
	if (gamestate_t_ready && gamestate_ct_ready) {
		ServerCommand("easylan_forcestart");
		CloseHandle(BlinkerTimer);
		BlinkerTimer = INVALID_HANDLE;
		PrintHintTextToAll("Both teams are ready! Starting now!");
	}

}

public void ResetVars() {
	
	playersjoin = new StringMap();
	BlinkerTimer = INVALID_HANDLE;
	gamestate_live = false;
	gamestate_live_doknife = false;
	gamestate_live_scoring = false;
	gamestate_live_nokill = true;
	gamestate_t_score = 0;
	gamestate_ct_score = 0;
	gamestate_live_knifewinner = false;
	gamestate_warmup = false;
	gamestate_ct_ready = false;
	gamestate_t_ready = false;
	blinks = 0;
	
	gamestate_ct_team = "Counter-Terrorists";
	gamestate_t_team = "Terrorists";
	//SetConVarString(g_TTeamConVar, "Terrorists");
	//SetConVarString(g_CTTeamConVar, "Counter-Terrorists");

}

public Action ListTeamNames(any args) {
	char path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"/configs/easylan/teams/");
	Handle Opath = OpenDirectory(path);
	char line[64];
	PrintToServer("Teams:\n");
	while (ReadDirEntry(Opath, line, 64)) {
		int last = (strlen(line)-1);
		if (last >= 4) {
			if (!StrEqual(line,"",false) && !StrEqual(line,".",false) && !StrEqual(line,"..",false))
			{
				char fbuffer[64];
				strcopy(fbuffer, (strlen(line)-3), line);
				PrintToServer("%s", fbuffer);
			}
		}
	}
	PrintToServer("\nAll teams in /configs/easylan/teams/ listed.");
}