#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.1.1"

new Handle:CheckTimer = INVALID_HANDLE;
new Handle:ConVar_Time = INVALID_HANDLE;
new Handle:ConVar_Team = INVALID_HANDLE;
new Handle:ConVar_Class = INVALID_HANDLE;
new Handle:ConVar_Admin = INVALID_HANDLE;

new Float:TimerRate;

public Plugin:myinfo = {
	name = "Auto DeSpectate",
	author = "Oshroth",
	description = "Adds Spectators to game",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart() {
	decl String:game[12];
	
	GetGameFolderName(game, sizeof(game));
	if (StrContains(game, "tf") == -1) SetFailState("Auto DeSpectate is designed for TF2");
	
	ConVar_Time = CreateConVar("sm_despec_time", "120", "How often the game moves spectators. 0 to disable plugin", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0);
	ConVar_Team = CreateConVar("sm_despec_team", "0", "How players are moved. 0 - Spectators are moved to smaller team. 1 - Moved to RED. 2 - Moved to BLU", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 2.0);
	ConVar_Class = CreateConVar("sm_despec_class", "0", "What class players are spawned as. 0 - random. 1 - 9 specific class", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 9.0);
	ConVar_Admin = CreateConVar("sm_despec_admins_immune", "1", "Are admins immune to the plugin", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	CreateConVar("tf_despec_version", PLUGIN_VERSION, "Version", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_NOTIFY);
	
	HookEvent("teamplay_round_start", Event_RoundStart);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("arena_round_start", Event_RoundStart);
	
	HookConVarChange(ConVar_Time, ConVar_Time_Changed);
	
	
	
	
}

public OnConfigsExecuted() {
	TimerRate = GetConVarFloat(ConVar_Time);
	StartTimer();
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	StartTimer()
}

public ConVar_Time_Changed(Handle:convar, const String:oldValue[], const String:newValue[]) {
	TimerRate = StringToFloat(newValue);
	
	StartTimer(true);
}

public Action:Timer_MoveSpec(Handle:timer) {
	new AdminSwitch = GetConVarBool(ConVar_Admin);
	new TeamMode = GetConVarInt(ConVar_Team);
	new ClientTeam;
	
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) && IsClientInGame(i)) {
			ClientTeam = GetClientTeam(i);
			if (ClientTeam == _:TFTeam_Unassigned || ClientTeam == _:TFTeam_Spectator) {
				if(GetUserAdmin(i) != INVALID_ADMIN_ID && AdminSwitch) {
					continue;
				}
				switch(TeamMode) {
					case 0: {
						new RedCount = GetTeamClientCount(_:TFTeam_Red);
						new BlueCount = GetTeamClientCount(_:TFTeam_Blue);
						
						if(BlueCount < RedCount) {
							JoinTeam(i, TFTeam_Blue);
						} else {
							JoinTeam(i, TFTeam_Red);
						}
					}
					case 1: { //Red Team
						JoinTeam(i, TFTeam_Red);
					}
					case 2: { //Blue Team
						JoinTeam(i, TFTeam_Blue);
					}
				}
			}
		}
	}
	
	return Plugin_Continue
}

/* Returns false if client couldn't join any team. true otherwise */
bool:JoinTeam(client, TFTeam:team) {
	new ClientTeam;
	
	ChangeClientTeam(client, _:team);
	ClientTeam = GetClientTeam(client);
	
	if (ClientTeam == _:TFTeam_Unassigned || ClientTeam == _:TFTeam_Spectator) {
		//If Client was unable to join team try the other team.
		if(team == TFTeam_Red) {
			ChangeClientTeam(client, _:TFTeam_Blue);
		} else {
			ChangeClientTeam(client, _:TFTeam_Red);
		}
		ClientTeam = GetClientTeam(client);
		if (ClientTeam == _:TFTeam_Unassigned || ClientTeam == _:TFTeam_Spectator) {
			
			return false;
		}
	}
	SetClass(client);
	
	return true;
}

StartTimer(bool:restart = false) {
	if(TimerRate == 0 || restart) {
		if(CheckTimer != INVALID_HANDLE) {
			CloseHandle(CheckTimer);
			CheckTimer = INVALID_HANDLE;
		}
	}
	if(CheckTimer == INVALID_HANDLE && TimerRate != 0) {
		CheckTimer = CreateTimer(TimerRate, Timer_MoveSpec, _, TIMER_REPEAT);
	}
}

SetClass(client) {
	new TeamClass = GetConVarInt(ConVar_Class);
	
	if(TF2_GetPlayerClass(client) != TFClass_Unknown) {
		return;
	}
	switch (TeamClass) {
		case 1:
		TF2_SetPlayerClass(client, TFClass_Scout, false);
		case 2:
		TF2_SetPlayerClass(client, TFClass_Soldier, false);
		case 3:
		TF2_SetPlayerClass(client, TFClass_Pyro, false);
		case 4:
		TF2_SetPlayerClass(client, TFClass_DemoMan, false);
		case 5:
		TF2_SetPlayerClass(client, TFClass_Heavy, false);
		case 6:
		TF2_SetPlayerClass(client, TFClass_Engineer, false);
		case 7:
		TF2_SetPlayerClass(client, TFClass_Medic, false);
		case 8:
		TF2_SetPlayerClass(client, TFClass_Sniper, false);
		case 9:
		TF2_SetPlayerClass(client, TFClass_Spy, false);
		default:
		TF2_SetPlayerClass(client, TFClassType:GetRandomInt(1, 9), false);
	}
	if(TF2_GetPlayerClass(client) != TFClass_Unknown) {
		return;
	}
	for(new i = 1; i <= 9; i++) {
		//Player was unable to join a class. Trying all classes
		TF2_SetPlayerClass(client, TFClassType:i, false);
		if(TF2_GetPlayerClass(client) != TFClass_Unknown) {
			return;
		}
	}
}
