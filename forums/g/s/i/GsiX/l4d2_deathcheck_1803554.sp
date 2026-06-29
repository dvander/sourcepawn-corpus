#include <sourcemod> 
#include <sdktools>

new Handle:deathcheck_enable;
new Handle:deathcheck_force;
new bool:HookStatus = false;
new bool:Debug = false;
new survivors;

public Plugin:myinfo = { 
    name = "[L4D, L4D2] No Death Check Until Dead", 
    author = "chinagreenelvis edited by GsiX", 
    description = "Prevents mission loss until all human players have died.", 
    version = "1.4.7", 
    url = "https://forums.alliedmods.net/showthread.php?t=142432" 
}; 

public OnPluginStart() {  
	deathcheck_enable = CreateConVar("deathcheck_enable", "1", "0: Disable plugin, 1: Enable plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	deathcheck_force = CreateConVar("deathcheck_force", "1", "0: All survivor must die to end the round (including bot), 1: If last human player die round will end", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	AutoExecConfig(true, "l4d2_deathcheck");
	HookConVarChange(deathcheck_enable,	CVAR_Toggle);
	HookConVarChange(deathcheck_force,	CVAR_Toggle);
}

public OnClientDisconnect() {
	DeadCheck();
}

public OnGameFrame() {
	if ((!HookStatus) && (GetConVarInt(deathcheck_enable) == 1)) {
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsValidSurvivor(i))
			{
				Hook_EVENT();
				if (Debug) PrintToServer("[DEADCHECK]: Alive human dectected!!");
				break;
			}
		}
	}
}

public CVAR_Toggle(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (GetConVarInt(deathcheck_enable) == 1) {
		if (!HookStatus) Hook_EVENT();
	}
	else {
		if (HookStatus) UnHook_EVENT();
	}
	DeadCheck();
}

public EVENT_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	if (HookStatus)	UnHook_EVENT();
	if (Debug) PrintToServer("[DEADCHECK]: Round End");
}

public EVENT_DeadCheck(Handle:event, const String:name[], bool:dontBroadcast) {
	DeadCheck();
}

DeadCheck() {
	if ((HookStatus) && (GetConVarInt(deathcheck_enable) == 1)) {
		survivors = 0;
		for (new i = 1; i <= MaxClients; i++) {
			if(IsValidSurvivor(i)) survivors ++;
		}
		if (survivors > 0) {
			if (GetConVarInt(FindConVar("director_no_death_check")) != 1)
				SetConVarInt(FindConVar("director_no_death_check"), 1);
		}
		if (survivors == 0) {
			SetConVarInt(FindConVar("director_no_death_check"), 0);
			if (GetConVarInt(deathcheck_force) == 1) {
				new oldFlags = GetCommandFlags("scenario_end"); 
				SetCommandFlags("scenario_end", oldFlags & ~(FCVAR_CHEAT|FCVAR_LAUNCHER)); 
				ServerCommand("scenario_end"); 
				ServerExecute(); 
				SetCommandFlags("scenario_end", oldFlags);
			}
		}
		if (Debug) PrintToServer("[DEADCHECK]: DeadCheck Executed");
	}
}

Hook_EVENT() {
	if ((!HookStatus) && (GetConVarInt(deathcheck_enable) == 1)) {
		HookStatus = true;
		SetConVarInt(FindConVar("director_no_death_check"), 1);
		HookEvent("player_bot_replace",			EVENT_DeadCheck); 
		HookEvent("bot_player_replace",			EVENT_DeadCheck); 
		HookEvent("player_death",				EVENT_DeadCheck);
		HookEvent("player_team",				EVENT_DeadCheck);
		HookEvent("round_end",					EVENT_RoundEnd);
		if (Debug) PrintToServer("[DEADCHECK]: Hook Start");
	}
	else {
		if (HookStatus) UnHook_EVENT();
	}
}

UnHook_EVENT() {
	HookStatus = false;
	SetConVarInt(FindConVar("director_no_death_check"), 0);
	UnhookEvent("player_bot_replace",	EVENT_DeadCheck); 
	UnhookEvent("bot_player_replace",	EVENT_DeadCheck); 
	UnhookEvent("player_death",			EVENT_DeadCheck);
	UnhookEvent("player_team",			EVENT_DeadCheck);
	UnhookEvent("round_end",			EVENT_RoundEnd);
	if (Debug) PrintToServer("[DEADCHECK]: Hook End");
}

stock bool:IsValidSurvivor(client) {
	if (!IsClientConnected(client))  return false;
	if (!IsClientInGame(client)) return false;
	if (!IsPlayerAlive(client)) return false;
	if (GetClientTeam(client) != 2) return false;
	if (IsFakeClient(client)) return false;
	return true;
}

