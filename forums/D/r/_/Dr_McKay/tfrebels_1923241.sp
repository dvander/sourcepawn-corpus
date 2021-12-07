#pragma semicolon 1

#include <sourcemod>
#include <colors>
#include <tf2>

public Plugin:myinfo = {
	name		= "[TF2] Rebels",
	author		= "Dr. McKay",
	description	= "https://forums.alliedmods.net/showthread.php?t=212030",
	version		= "1.0.0",
	url			= "http://www.doctormckay.com"
};

new bool:isRebel[MAXPLAYERS + 1];

public OnPluginStart() {
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	isRebel[client] = false;
}

public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker == 0 || isRebel[attacker]) {
		return;
	}
	if(TFTeam:GetClientTeam(attacker) == TFTeam_Red && TFTeam:GetClientTeam(victim) == TFTeam_Blue) {
		isRebel[attacker] = true;
		SetEntityRenderColor(attacker, 0, 255, 0, 255);
		decl String:clientName[MAX_NAME_LENGTH];
		GetClientName(attacker, clientName, sizeof(clientName));
		CRemoveTags(clientName, sizeof(clientName));
		CPrintToChatAllEx(attacker, "{green}[SM] {teamcolor}%s {default}is now a rebel!", clientName);
	}
}