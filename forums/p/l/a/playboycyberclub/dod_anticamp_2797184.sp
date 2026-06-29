#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.1.8"

public Plugin:myinfo = 
{
	name = "DoD:S Anticamp", 
	author = "Misery", 
	description = "DoD Anti-Campeurs Source", 
	version = PLUGIN_VERSION, 
	url = "http://thelw.verygames.net"
};

new Handle:a_CvarLowHealth = INVALID_HANDLE;
new Handle:a_CvarRadius = INVALID_HANDLE;
new Handle:a_CvarPollCount = INVALID_HANDLE;
new Handle:a_CvarAnticamp_mg_Enable = INVALID_HANDLE;
new Handle:a_CvarAnticamp_sniper_Enable = INVALID_HANDLE;
new Handle:a_CvarAnticamp_Notify = INVALID_HANDLE;
new Handle:a_CvarAnticamp_slap_Enable = INVALID_HANDLE;
new Handle:a_CvarAnticamp_Discount_Enable = INVALID_HANDLE;

new Handle:a_CheckListTimers[MAXPLAYERS + 1];
new Handle:a_CaughtListTimers[MAXPLAYERS + 1];
new Handle:a_InfoCamp[MAXPLAYERS + 1];
new Float:a_lastPos[MAXPLAYERS + 1][3];
new a_timerCount[MAXPLAYERS + 1];

new a_Message_Mg[64];
new a_Message_Sniper[64];
new a_Message_Beacon_On[64];
new a_Activate_Plugin[64];
new a_CountBeforeSlap[64];
new a_HaloSprite;
new orange;

public OnPluginStart() {
	LoadTranslations("dod_anticamp.phrases");
	CreateConVar("sm_dod_anticamp_version", PLUGIN_VERSION, "DoD:S Anticamp Version", FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	a_CvarLowHealth = CreateConVar("sm_anticamp_minHP", "15", "Règle le niveau en-dessous duquel la détection est désactivée");
	a_CvarRadius = CreateConVar("sm_anticamp_zone", "200", "La zone autour du joueur à surveiller");
	a_CvarPollCount = CreateConVar("sm_anticamp_temps", "20", "Combien de temps autorisé avant déclenchement");
	a_CvarAnticamp_mg_Enable = CreateConVar("sm_anticamp_mg", "0", "Active/Désactive Anticamp pour les MG");
	a_CvarAnticamp_sniper_Enable = CreateConVar("sm_anticamp_sniper", "0", "Active/Désactive Anticamp pour le SNIPER");
	a_CvarAnticamp_Notify = CreateConVar("sm_anticamp_affiche", "1", "Active/Désactive un message à l'arrivée des joueurs");
	a_CvarAnticamp_slap_Enable = CreateConVar("sm_anticamp_baffe", "1", "Active/Désactive une baffe après le beacon");
	a_CvarAnticamp_Discount_Enable = CreateConVar("sm_anticamp_compte", "1", "Active/Désactive un compte de 3 seconde avant le beacon");
	
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("dod_stats_weapon_attack", PlayerAttackEvent);
}

public OnClientPutInServer(client) {
	if (client != 0 && IsClientConnected(client))
		a_InfoCamp[client] = CreateTimer(25.0, InfoCamp, client, TIMER_FLAG_NO_MAPCHANGE);
}

public OnClientDisconnect(client) {
	if (client != 0) {
		if (a_InfoCamp[client] != INVALID_HANDLE) {
			CloseHandle(a_InfoCamp[client]);
			a_InfoCamp[client] = INVALID_HANDLE;
		}
		a_Message_Mg[client] = 0;
		a_Message_Sniper[client] = 0;
		a_Message_Beacon_On[client] = 0;
		a_Activate_Plugin[client] = 0;
		a_CountBeforeSlap[client] = 0;
		KillTimer1(client);
		KillTimer2(client);
	}
}

public Action:EventPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client)) {
		a_Message_Mg[client] = 0;
		a_Message_Sniper[client] = 0;
		a_Message_Beacon_On[client] = 0;
		a_Activate_Plugin[client] = 0;
		
		if (GetConVarInt(a_CvarAnticamp_slap_Enable) == 0)
			a_CountBeforeSlap[client] = 3;
		else
			a_CountBeforeSlap[client] = 0;
		
		KillTimer1(client);
		KillTimer2(client);
		GetClientAbsOrigin(client, a_lastPos[client]);
	}
}

public PlayerAttackEvent(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (client != 0 && IsClientInGame(client)) {
		if (a_Activate_Plugin[client] == 0) {
			a_Activate_Plugin[client] = 1;
			a_CheckListTimers[client] = CreateTimer(5.0, CheckCamperTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			if (!GetConVarInt(a_CvarAnticamp_mg_Enable)) {
				new weapon_def = GetEventInt(event, "weapon");
				switch (weapon_def) {
					case 15, 16, 35, 36: {
						if (a_Message_Mg[client] == 0) {
							a_Message_Mg[client] = 1;
							PrintToChat(client, "%c %t: %c %t", "\x01", "Anticamp MG", "\x04", "OFF");
							KillTimer1(client);
						}
					}
				}
			}
			if (!GetConVarInt(a_CvarAnticamp_sniper_Enable)) {
				new weapon_def = GetEventInt(event, "weapon");
				switch (weapon_def) {
					case 9, 10, 33, 34: {
						if (a_Message_Sniper[client] == 0) {
							a_Message_Sniper[client] = 1;
							PrintToChat(client, "%c %t: %c %t", "\x01", "Anticamp SNIPER", "\x04", "OFF");
							KillTimer1(client);
						}
					}
				}
			}
		}
	}
}

public bool:IsCamping(client, Float:vec1[3], Float:vec2[3]) {
	if (GetVectorDistance(vec1, vec2) < GetConVarInt(a_CvarRadius) && GetConVarInt(a_CvarLowHealth) <= GetClientHealth(client))
		return true;
	KillTimer2(client);
	return false;
}

public Action:CheckCamperTimer(Handle:timer, any:client) {
	a_CheckListTimers[client] = INVALID_HANDLE;
	
	new Float:currentPos[3];
	GetClientAbsOrigin(client, currentPos);
	if (IsCamping(client, a_lastPos[client], currentPos)) {
		a_timerCount[client] = 1;
		a_CaughtListTimers[client] = CreateTimer(1.0, CaughtCampingTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	} else {
		if (a_Message_Beacon_On[client] == 1) {
			a_Message_Beacon_On[client] = 0;
			a_CountBeforeSlap[client] = 0;
			PrintToChat(client, "%c %t: %c %t", "\x01", "BEACON", "\x04", "OFF");
		}
		a_CheckListTimers[client] = CreateTimer(5.0, CheckCamperTimer, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	a_lastPos[client] = currentPos;
	return Plugin_Handled;
}

public Action:CaughtCampingTimer(Handle:timer, any:client) {
	a_CaughtListTimers[client] = INVALID_HANDLE;
	
	new Float:currentPos[3];
	GetClientAbsOrigin(client, currentPos);
	if (!IsCamping(client, a_lastPos[client], currentPos)) {
		a_timerCount[client] = 1;
		a_CheckListTimers[client] = CreateTimer(5.0, CheckCamperTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	}
	
	if (a_timerCount[client] < GetConVarInt(a_CvarPollCount)) {
		a_timerCount[client]++;
		if (GetConVarInt(a_CvarAnticamp_Discount_Enable) == 1 && a_CountBeforeSlap[client] >= 2) {
			new TimerBeforeBeacon = GetConVarInt(a_CvarPollCount) - a_timerCount[client];
			switch (TimerBeforeBeacon) {
				case 1:
				CreateTimer(1.0, count_1, client, TIMER_FLAG_NO_MAPCHANGE);
				case 2:
				CreateTimer(1.0, count_2, client, TIMER_FLAG_NO_MAPCHANGE);
				case 3:
				CreateTimer(1.0, count_3, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		a_CaughtListTimers[client] = CreateTimer(1.0, CaughtCampingTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		return Plugin_Handled;
	} else {
		if (IsPlayerAlive(client) && !IsFakeClient(client) && IsCamping(client, a_lastPos[client], currentPos)) {
			CreateTimer(0.6, BeaconTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			a_timerCount[client] = 1;
			a_CaughtListTimers[client] = CreateTimer(1.0, CaughtCampingTimer, client, TIMER_FLAG_NO_MAPCHANGE);
		} else {
			a_timerCount[client] = 1;
			a_CheckListTimers[client] = CreateTimer(5.0, CheckCamperTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			a_lastPos[client] = currentPos;
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}

public Action:count_1(Handle:timer, any:client) {
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
		PrintCenterText(client, "1");
}

public Action:count_2(Handle:timer, any:client) {
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
		PrintCenterText(client, "2");
}

public Action:count_3(Handle:timer, any:client) {
	if (client != 0 && IsClientInGame(client) && !IsFakeClient(client))
		PrintCenterText(client, "3");
}

KillTimer1(client) {
	if (a_CheckListTimers[client] != INVALID_HANDLE) {
		CloseHandle(a_CheckListTimers[client]);
		a_CheckListTimers[client] = INVALID_HANDLE;
	}
}

KillTimer2(client) {
	if (a_CaughtListTimers[client] != INVALID_HANDLE) {
		CloseHandle(a_CaughtListTimers[client]);
		a_CaughtListTimers[client] = INVALID_HANDLE;
	}
}

public Action:BeaconTimer(Handle:timer, any:client) {
	if (client == 0 || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
		return Plugin_Handled;
	
	decl Float:location[3];
	decl Float:PositionCamper[3];
	GetClientAbsOrigin(client, location);
	GetClientAbsOrigin(client, PositionCamper);
	if (a_Message_Beacon_On[client] == 0)
		a_Message_Beacon_On[client] = 1;
	
	if (GetConVarInt(a_CvarAnticamp_slap_Enable) == 1) {
		if (a_CountBeforeSlap[client] < 3)
			a_CountBeforeSlap[client] += 1;
		
		switch (a_CountBeforeSlap[client]) {
			case 1:
			PrintToChat(client, "%t...", "Move");
			case 2:
			PrintToChat(client, "%t...", "Warning");
			case 3: {
				PrintToChat(client, "%t...", "NoCamp");
				SlapPlayer(client, 5, true);
			}
		}
	}
	new color[] =  { 0, 0, 150, 255 };
	TE_SetupBeamRingPoint(location, 10.0, 400.0, orange, a_HaloSprite, 0, 10, 1.6, 10.0, 0.5, color, 10, 0);
	TE_SendToAll(0.0);
	new color2[] =  { 0, 0, 255, 255 };
	TE_SetupBeamRingPoint(location, 10.0, 400.0, orange, a_HaloSprite, 0, 10, 1.6, 10.0, 0.5, color2, 10, 0);
	TE_SendToAll(0.2);
}

public Action:InfoCamp(Handle:timer, any:client) {
	a_InfoCamp[client] = INVALID_HANDLE;
	if (GetConVarInt(a_CvarAnticamp_Notify) && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		PrintToChat(client, "%c%c[AntiCamp]%c %t", "\x01", "\x04", "\x01", "Anticamp ON");
} 