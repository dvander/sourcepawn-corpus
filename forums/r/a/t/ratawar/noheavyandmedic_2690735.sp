#include <sourcemod>
#include <tf2_stocks>
#include <multicolors>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "2.0"

public Plugin myinfo =  {
	
	name = "[TF2] No Heavy and Medic", 
	author = "ampere", 
	description = "This plugin prevents players from running Heavy and Medic at the same time in a team. Mainly for 4v4 purposes.", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/member.php?u=282996"
	
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	
	EngineVersion g_engineversion = GetEngineVersion();
	if (g_engineversion != Engine_TF2)
		SetFailState("This plugin was made for use with Team Fortress 2 only.");
	
}

ConVar gCV_Enabled;

public void OnPluginStart() {
	
	CreateConVar("sm_nhm_version", PLUGIN_VERSION, "Plugin version.", FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	gCV_Enabled = CreateConVar("sm_nhm_enabled", "1", "1- Enable | 0- Disable.", FCVAR_NOTIFY);
	
	AddCommandListener(OnJoinClass, "joinclass");
	
}

public Action OnJoinClass(int client, const char[] command, int argc) {
	
	if (!gCV_Enabled.BoolValue)
		return Plugin_Handled;
	
	TFTeam clientTeam = TF2_GetClientTeam(client);
	TFClassType clientClass = TF2_GetPlayerClass(client);
	
	char arg1[16];
	GetCmdArg(1, arg1, sizeof(arg1));
	
	if (!strcmp(arg1, "heavyweapons")) {
		
		if (clientClass == TFClass_Heavy)
			return Plugin_Handled;
		
		if (DoesTeamHaveMedic(client, clientTeam)) {
			CPrintToChat(client, "{orange}Can't switch to Heavy! There's a Medic in your team.");
			return Plugin_Stop;
		}
		
	}
	
	if (!strcmp(arg1, "medic")) {
		
		if (clientClass == TFClass_Medic)
			return Plugin_Handled;
		
		if (DoesTeamHaveHeavy(client, clientTeam)) {
			CPrintToChat(client, "{orange}Can't switch to Medic! There's a Heavy in your team.");
			return Plugin_Stop;
		}
		
	}
	
	return Plugin_Continue;
	
}

bool DoesTeamHaveHeavy(int client, TFTeam team) {
	
	for (int i = 1; i <= MaxClients; i++) {
		
		if (IsValidClient(i) && i != client && TF2_GetClientTeam(i) == team && TF2_GetPlayerClass(i) == TFClass_Heavy)
			return true;
	}
	
	return false;
	
}

bool DoesTeamHaveMedic(int client, TFTeam team) {
	
	for (int i = 1; i <= MaxClients; i++) {
		
		if (IsValidClient(i) && i != client && TF2_GetClientTeam(i) == team && TF2_GetPlayerClass(i) == TFClass_Medic)
			return true;
	}
	
	return false;
	
}

stock bool IsValidClient(int client, bool fake = true) {
	return (!(1 <= client <= MaxClients) || !IsClientInGame(client) || (fake && IsFakeClient(client))) ? false : true;
} 