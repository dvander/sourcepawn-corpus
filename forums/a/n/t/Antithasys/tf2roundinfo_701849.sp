#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"
#define TEAM_RED 2
#define TEAM_BLUE 3

new Handle:Timer = INVALID_HANDLE;
new Handle:TFGameModeCP = INVALID_HANDLE;
new Handle:TFGameModePL = INVALID_HANDLE;
new TimeInRound, OldBlueScore, OldRedScore;
new PlayersTeam[MAXPLAYERS + 1];
new bool:IsWaiting = false;
new bool:GameEnded = false;

public Plugin:myinfo =
{
	name = "TF2 Round Info",
	author = "Antithasys",
	description = "Gives information on the current round in TF2.",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("tf2roundinfo_verison", PLUGIN_VERSION, "TF2 Round Info Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegConsoleCmd("roundtime", Command_RoundTime, "Returns the round time left");
	TFGameModeCP = FindConVar("tf_gamemode_cp");
	TFGameModePL = FindConVar("tf_gamemode_pl");
	HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Pre);
	HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("teamplay_point_captured", HookControlPointCapture, EventHookMode_PostNoCopy);
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("TF2INFO_GetRoundTimeLeft", Native_GetRoundTimeLeft);
   CreateNative("TF2INFO_DidTeamsSwitch", Native_DidTeamsSwitch);
   return true;
}

public Action:Command_RoundTime(client, args)
{
	new mins, secs;
	mins = TimeInRound / 60;
	secs = TimeInRound % 60;
	if (secs < 10)
		ReplyToCommand(client, "Time Left In Round: %i:0%i", mins, secs);
	else
		ReplyToCommand(client, "Time Left In Round: %i:%i", mins, secs);
	return Plugin_Handled;
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new TimerInitalLength = GetEntProp(FindEntityByClassname(-1, "team_round_timer"), Prop_Send, "m_nTimerInitialLength");
	new SetupTimeLength = GetEntProp(FindEntityByClassname(-1, "team_round_timer"), Prop_Send, "m_nSetupTimeLength");
	if (TimeInRound == 0 && !IsWaiting) {
		IsWaiting = true;
		return;
	}
	if (IsWaiting) {
		IsWaiting = false;
		TimeInRound = TimerInitalLength + SetupTimeLength - 1;
		CreateRoundTimer();
		return;
	}
	GameEnded = DidTeamsSwitch();
	ResetTeams();
	if (GetConVarBool(TFGameModeCP) || GetConVarBool(TFGameModePL)) {
		if (GameEnded) {
			TimeInRound = TimerInitalLength + SetupTimeLength - 1;
			CreateRoundTimer();
			return;
		} else {
			TimeInRound = TimeInRound + SetupTimeLength - 1;
			CreateRoundTimer();
			return;
		}
	}
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (Timer != INVALID_HANDLE) {
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
	OldBlueScore = GetTeamScore(TEAM_BLUE);
	OldRedScore = GetTeamScore(TEAM_RED);
	GameEnded = false;
	SavePlayersTeams();
	return;
}

public HookControlPointCapture(Handle:event, const String:name[], bool:dontBroadcast)
{
	new TimerInitalLength = GetEntProp(FindEntityByClassname(-1, "team_round_timer"), Prop_Send, "m_nTimerInitialLength");
	TimeInRound = TimeInRound + TimerInitalLength;
	return;
}

public Action:Timer_RoundTimeLeft(Handle:timer, any:client)
{
	TimeInRound--;
	return Plugin_Continue;
}

stock CreateRoundTimer()
{
	if (Timer != INVALID_HANDLE) {
		CloseHandle(Timer);
		Timer = INVALID_HANDLE;
	}
	Timer = CreateTimer(1.0, Timer_RoundTimeLeft, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

stock SavePlayersTeams()
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++) {
		if (IsClientInGame(i))
			PlayersTeam[i] = GetClientTeam(i);
	}
}

stock ResetTeams()
{
	new maxclients = GetMaxClients();
	for (new i = 1; i <= maxclients; i++) {
		PlayersTeam[i] = 0;
	}
}

stock bool:DidTeamsSwitch()
{
	if (OldBlueScore != OldRedScore) {
		if (OldBlueScore != GetTeamScore(TEAM_BLUE)
		&& OldRedScore != GetTeamScore(TEAM_RED))
			return true;
		else
			return false;
	} else {	
		new maxclients = GetMaxClients();
		new cteam, count;
		count = GetClientCount();
		for (new i = 1; i <= maxclients; i++) {
			if (IsClientInGame(i) && PlayersTeam[i] != 0) {
				if (PlayersTeam[i] != GetClientTeam(i))
					cteam++;
			}
		}
		if ((cteam / count) > 0.60)
			return true;
	}
	return false;
}

public Native_GetRoundTimeLeft(Handle:plugin, numParams)
{
	SetNativeCellRef(1, TimeInRound);
}

public Native_DidTeamsSwitch(Handle:plugin, numParams)
{
	if (GameEnded)
		return true;
	return false;
}