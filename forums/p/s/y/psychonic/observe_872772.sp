#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Observe Client",
	author = "WhiteWolf, puopjik, psychonic",
	description = "Observe client when dead",
	version = "1.1.2",
	url = "http://www.whitewolf.us"
};

/* Credits:
	Mani - Showed me his observer code from MAP
*/

/* Globals */
new g_offObserverTarget;
new g_clientObserveTarget[MAXPLAYERS+1];
new bool:g_useSteamBans=false;


public OnPluginStart() {
	new Handle:conVar;
	
	HookEvent("player_spawn", EventPlayerSpawn);
	HookEvent("player_death", EventPlayerDeath);
	
	
	RegAdminCmd("sm_observe", CommandObserve, ADMFLAG_SLAY, "Spectate a player when dead.");
	RegAdminCmd("sm_endobserve", CommandEndObserve, ADMFLAG_SLAY, "End spectating a player.");
	
	LoadTranslations("observe.phrases");
	
	g_offObserverTarget = FindSendPropOffs("CBasePlayer", "m_hObserverTarget");	
	if(g_offObserverTarget == -1) {
		SetFailState("Expected to find the offset to m_hObserverTarget, couldn't.");
	}
	
	conVar = FindConVar("sbsrc_version");
	if(conVar != INVALID_HANDLE) {
		g_useSteamBans = true;
	}
	

}

/********************************************************************************
	Events
*********************************************************************************/

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	/* Suggestions for improvement, or single-shot method? */
	new target = GetClientOfUserId(GetEventInt(event, "userid"));
	for(new client = 1; client < MaxClients; client++) {
		if(g_clientObserveTarget[client] == target && (IsClientObserver(client) || !IsPlayerAlive(client))) {
			SetClientObserver(client, target, true);
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_clientObserveTarget[client] > 0) {
		new target = g_clientObserveTarget[client];
		if(!isValidHumanClient(target)) {
			g_clientObserveTarget[client] = 0;
			return Plugin_Handled;
		}
		
		if(IsPlayerAlive(target)) {
			SetClientObserver(client, target, true);
		}
	}
	return Plugin_Handled;
}
		
public OnClientDisconnect(client) {
	new String:clientName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, MAX_NAME_LENGTH);
	
	g_clientObserveTarget[client] = 0;
	for(new i = 1; i < MaxClients; i++) {
		if(g_clientObserveTarget[i] == client) {
			g_clientObserveTarget[i] = 0;
			if (IsClientInGame(i) && IsClientConnected(i)) {
				PrintToChat(i, "%t", "Target Left", clientName);
			}
		}
	}
}

/********************************************************************************
	Commands
*********************************************************************************/

public Action:CommandEndObserve(client, args) {
	g_clientObserveTarget[client] = 0;
	PrintToChat(client, "%t", "End Observe");
	return Plugin_Handled;
}

public Action:CommandObserve(client, args) {
	decl String:targetName[MAX_NAME_LENGTH], String:targetSteamID[MAX_NAME_LENGTH];
	
	GetCmdArg(1, targetName, sizeof(targetName)); //get username part from arguments
	
	new targetClient = FindTarget(client, targetName, false, false);
	if(targetClient == -1) {
		PrintToChat(client, "%t", "Unknown Target");
	}
	
	GetClientName(targetClient, targetName, sizeof(targetName));
	GetClientAuthString(targetClient, targetSteamID, sizeof(targetSteamID));
	g_clientObserveTarget[client] = targetClient;
	
	if(IsClientObserver(client) || !IsPlayerAlive(client)) {
		if(!SetClientObserver(client, targetClient, true)) {
			PrintToChat(client, "%t", "Observe Failed", targetName);
		}
	} else {
		PrintToChat(client, "%t", "Observe on Spec", targetName, targetSteamID);
	}
	
	return Plugin_Handled;
}

/********************************************************************************
	Helper Methods
*********************************************************************************/

public bool:isValidHumanClient(client) {
	if(client > 0 && IsClientConnected(client) && IsClientInGame(client)) {
		return true;
	}
	return false;
}
		
public bool:SetClientObserver(client, target, bool:sendMessage) {
	if(!isValidHumanClient(client) || !isValidHumanClient(target)) {
		return false;
	}
	
	SetEntDataEnt2(client, g_offObserverTarget, target, true);
	
	if(sendMessage) {
		SendClientObserveMessage(client, target);
	}
	
	if(g_useSteamBans) {
		ClientCommand(client, "sb_status");
	}
		
	return true; //we assume it went through, else SM would throw a native error and we wouldn't get here anyway
}

public SendClientObserveMessage(client, target) {
	decl String:targetName[MAX_NAME_LENGTH], String:targetSteamID[65];
	GetClientName(target, targetName, MAX_NAME_LENGTH);
	GetClientAuthString(target, targetSteamID, 65);
	PrintToChat(client, "%t", "Observing", targetName, targetSteamID);
}