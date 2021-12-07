#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "[TF2] Team Scores", 
	author = "Esat Efe", 
	description = "Developed by Esat Efe.", 
	version = "1.1", 
	url = "sourcemod.net"
};

bool scoresEnabled = false;
int redScore = 0;
int bluScore = 0;
int scoreToWin;
int teamBalanceValueBeforeScoreRound;
int balanceLimitValueBeforeScoreRound;
Handle redHud;
Handle bluHud;
ConVar teamBalance;
ConVar balanceLimit;

public OnPluginStart()
{
	RegAdminCmd("sm_scoreround", ScoreRound, ADMFLAG_GENERIC);
	RegAdminCmd("sm_cancelscoreround", CancelScoreRound, ADMFLAG_GENERIC);
	HookEvent("arena_round_start", Event_teamplay_round_win);
	HookEvent("teamplay_round_start", Event_teamplay_round_win);
	HookEvent("teamplay_round_win", Event_teamplay_round_win);
	HookEvent("teamplay_round_stalemate", Event_teamplay_round_win);
	HookEvent("player_death", Event_player_death);
	HookEvent("player_spawn", Event_player_spawn);
	teamBalance = FindConVar("mp_autoteambalance");
	balanceLimit = FindConVar("mp_teams_unbalance_limit");
	redHud = CreateHudSynchronizer();
	bluHud = CreateHudSynchronizer();
	scoresEnabled = false;
	redScore = 0;
	bluScore = 0;
}

public Action ScoreRound(int client, int args)
{
	if(!scoresEnabled){
		char full[256];
	 
		GetCmdArgString(full, sizeof(full));
		if(args < 1){
			PrintToChat(client, "[SM] Usage: sm_scoreround <score>");
			
			return Plugin_Handled;
		}
		if(args > 100){
			scoreToWin = 100;
		}
		else{
			scoreToWin = StringToInt(full);
		}
		PrintToChatAll("[SM] Score round is enabled! The first team to reach %i scores wins!", scoreToWin);
		scoresEnabled = true;
		redScore = 0;
		bluScore = 0;
		teamBalanceValueBeforeScoreRound = teamBalance.IntValue;
		balanceLimitValueBeforeScoreRound = balanceLimit.IntValue;
		teamBalance.IntValue = 1;
		balanceLimit.IntValue = 1;
	}
	else{
		PrintToChat(client, "[SM] Score round is already enabled! Type !cancelscoreround to cancel score round!");
	}
	return Plugin_Handled;
}

public Action CancelScoreRound(int client, int args)
{
	if(scoresEnabled){
		PrintToChatAll("[SM] Score round is cancelled by an admin!");
		redScore = 0;
		bluScore = 0;
		scoresEnabled = false;
		teamBalance.IntValue = teamBalanceValueBeforeScoreRound;
		balanceLimit.IntValue = balanceLimitValueBeforeScoreRound;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (!IsFakeClient(i)))
			{
				ClearSyncHud(i, redHud);
				ClearSyncHud(i, bluHud);
			}
		}
	}
	else{
		PrintToChat(client, "[SM] Score round is not enabled.");
	}
	return Plugin_Handled;
}

public void UpdateScores(){
	if(scoresEnabled){
		SetHudTextParams(-0.75, 0.20, 99999.0, 255, 0, 0, 255, 0, 1.0, 1.0, 1.0);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (!IsFakeClient(i)))
			{
				ShowSyncHudText(i, redHud, "RED: %i", redScore);
			}
		}
		SetHudTextParams(-0.75, 0.15, 99999.0, 0, 0, 255, 255, 0, 1.0, 1.0, 1.0);
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && (!IsFakeClient(i)))
			{
				ShowSyncHudText(i, bluHud, "BLU: %i", bluScore);
			}
		}
		if(redScore >= scoreToWin){
			new iFlags = GetCommandFlags("mp_forcewin");
			SetCommandFlags("mp_forcewin", iFlags &= ~FCVAR_CHEAT); 
			ServerCommand("mp_forcewin 2");
			SetCommandFlags("mp_forcewin", iFlags);
		}
		if(bluScore >= scoreToWin){
			new iFlags = GetCommandFlags("mp_forcewin");
			SetCommandFlags("mp_forcewin", iFlags &= ~FCVAR_CHEAT); 
			ServerCommand("mp_forcewin 3");
			SetCommandFlags("mp_forcewin", iFlags);
		}
		if(redScore >= scoreToWin && bluScore >= scoreToWin){
			new iFlags = GetCommandFlags("mp_forcewin");
			SetCommandFlags("mp_forcewin", iFlags &= ~FCVAR_CHEAT); 
			ServerCommand("mp_forcewin 0");
			SetCommandFlags("mp_forcewin", iFlags);
		}
	}
}

public Action:Event_player_death(Handle:event, const String:name[], bool:dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(scoresEnabled && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && IsClientInGame(client) && GetClientTeam(client) == 3){
		redScore++;
		UpdateScores();
	}
	if(scoresEnabled && IsClientInGame(attacker) && GetClientTeam(attacker) == 3 && IsClientInGame(client) && GetClientTeam(client) == 2){
		bluScore++;
		UpdateScores();
	}
	
	return Plugin_Handled;
}

public Action:Event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast) {

	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(scoresEnabled){
		SetHudTextParams(-0.75, 0.20, 99999.0, 255, 0, 0, 255, 0, 1.0, 1.0, 1.0);
		ShowSyncHudText(client, redHud, "RED: %i", redScore);
		
		SetHudTextParams(-0.75, 0.15, 99999.0, 0, 0, 255, 255, 0, 1.0, 1.0, 1.0);
		ShowSyncHudText(client, bluHud, "BLU: %i", bluScore);
	}
	
	return Plugin_Handled;
}

public Action:Event_teamplay_round_win(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)))
		{
			ClearSyncHud(i, redHud);
			ClearSyncHud(i, bluHud);
		}
	}
	if(scoresEnabled){
		scoresEnabled = false;
		int redScore = 0;
		int bluScore = 0;
		teamBalance.IntValue = teamBalanceValueBeforeScoreRound;
		balanceLimit.IntValue = balanceLimitValueBeforeScoreRound;
	}

	return Plugin_Handled;
}
