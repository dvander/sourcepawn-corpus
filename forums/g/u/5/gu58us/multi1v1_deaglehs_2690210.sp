#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <multicolors>
#include <multi1v1>

#pragma semicolon 1
#pragma newdecls required

bool g_bHeadShot[MAXPLAYERS+1];

public Plugin myinfo = {
    name = "CS:GO Multi1v1: Deagle Headshot round addon",
    author = "Bara/Gus",
    description = "Adds an unranked Deagle headshot round-type / This has been modified to allow for a deagle headshot",
    version = "1.0.0",
    url = "git.tf/Bara"
};

public void OnPluginStart() {
    // Lateload support
    for(int client = 1; client <= MaxClients; client++) {
		if(client > 0 && client <= MaxClients && IsClientInGame(client)) {
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(victim > 0 && victim <= MaxClients && attacker > 0 && attacker <= MaxClients && IsClientInGame(victim) && IsClientInGame(attacker)) {
		if (g_bHeadShot[victim] && g_bHeadShot[attacker]) {
			if(damagetype & CS_DMG_HEADSHOT) {
				return Plugin_Continue;
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void Multi1v1_OnRoundTypesAdded() {
    Multi1v1_AddRoundType("Deagle Headshot", "deagle headshot", HeadshotHandler, true, false, "", true);
}

public void HeadshotHandler(int client) {
	
	GivePlayerItem(client, "weapon_deagle");
	
	g_bHeadShot[client] = true;
	
	CPrintToChat(client, "{darkred}This is a deagle headshot only round!");
}

// Reset stuff
public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason) {
	for(int client = 1; client <= MaxClients; client++) {
		if(client > 0 && client <= MaxClients && IsClientInGame(client)) {
			g_bHeadShot[client] = false;
		}
	}
}
