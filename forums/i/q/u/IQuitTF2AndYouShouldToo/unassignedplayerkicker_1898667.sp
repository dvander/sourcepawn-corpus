#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1

#define PLUGIN_VERSION		"3.0"

#define TEAM_SPECTATOR		1
#define TEAM_RED			2
#define TEAM_BLU			3

new Handle:g_hConVarTimer;
new Handle:g_hConVarMessage;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf") && !StrEqual(Game, "tf_beta"))
	{
		Format(error, err_max, "This plugin only works for TF2 or TF2 Beta.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public Plugin:myinfo = {
	name = "Unassigned Player Kicker",
	author = "abrandnewday",
	description = "Kicks people who haven't joined a team.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=165383"
}

public OnPluginStart() {   
	CreateConVar("sm_unassignedkicker_version", PLUGIN_VERSION, "Unassigned Player Kicker Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	g_hConVarTimer = CreateConVar("sm_unassignedkicker_timer", "600.0", "How long (in seconds) should the timer be, before it checks the connected player's team? (Default = 600.0 (10 minutes))");
	g_hConVarMessage = CreateConVar("sm_unassignedkicker_message", "If you return, please join a team", "What do you want the kick reason to say?");
}

public OnClientPutInServer(client) {
    CreateTimer(GetConVarFloat(g_hConVarTimer), Timer_CheckPlayerTeam, GetClientUserId(client));
}

public Action:Timer_CheckPlayerTeam(Handle:timer, any:userid) {
	new client = GetClientOfUserId(userid);
	
	if (client == 0) return Plugin_Handled;
	if (GetUserFlagBits(client) && ADMFLAG_GENERIC) return Plugin_Handled;
	if (!IsClientConnected(client)) return Plugin_Handled;
	if (IsClientSourceTV(client)) return Plugin_Handled;
	if (IsClientReplay(client)) return Plugin_Handled;
	
	decl String:kickmessage[255];
	GetConVarString(g_hConVarMessage, kickmessage, sizeof(kickmessage));
	
	if (IsClientInGame(client)) {
		if (!IsValidTeam(client)) {
			KickClient(client, kickmessage);
		}
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

bool:IsValidTeam(client) {
    return (GetClientTeam(client) != 0);
}  