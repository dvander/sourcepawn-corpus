#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

#define L4D_MAXPLAYERS 14
#define L4D_TEAM_UNASSIGNED 0
#define L4D_TEAM_SPECTATOR 1
#define L4D_TEAM_SURVIVOR 2
#define L4D_TEAM_INFECTED 3

public Plugin:info = {
	name = "[MV] L4D TakeOverBot",
	version = PLUGIN_VERSION,
	description = "Let's you take over bots when you're dead.",
	author = "Matthias Vance",
	url = "http://www.matthiasvance.com/" // Nothing there at the moment
}

new Handle:hSetHumanSpec, Handle:hTakeOverBot;
new bool:bRoundEnd = false;
//new nDeadPlayers[L4D_MAXPLAYERS];

public OnPluginStart() {
	CreateConVar("mv_l4d_takeoverbot_version", PLUGIN_VERSION, "[MV] L4D TakeOverBot Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY);

	new Handle:hConfig = LoadGameConfigFile("mv_l4d_takeoverbot");
	if(hConfig == INVALID_HANDLE) {
		SetFailState("[MV] Could not load mv_l4d_takeoverbot gamedata.");
	} else {
		// SetHumanSpec
		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "SetHumanSpec")) {
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
			hSetHumanSpec = EndPrepSDKCall();
		}

		// TakeOverBot
		StartPrepSDKCall(SDKCall_Player);
		if(PrepSDKCall_SetFromConf(hConfig, SDKConf_Signature, "TakeOverBot")) {
			PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
			hTakeOverBot = EndPrepSDKCall();
		}

		if(hSetHumanSpec == INVALID_HANDLE || hTakeOverBot == INVALID_HANDLE) {
			SetFailState("[MV] Could not find the correct signatures.");
		} else {
			HookEvent("player_death", event_PlayerDeath);
			HookEvent("mission_lost", event_MissionLost);
			HookEvent("round_start", event_RoundStart);
			/*HookEvent("player_bot_replace", event_PlayerBotReplace);
			HookEvent("player_spawn", event_PlayerSpawn);*/

			CreateConVar("tob_enable", "1");
			CreateConVar("tob_respawn_time", "5.0", "", 0, true, 5.0);
		}
	}
}

/*
stock array_filter(array[], nLength) {
	new nValue;
	for(new i = 0; i < nLength - 1; i++) {
		nValue = array[i];
		if(!nValue) {
			array[i] = array[i + 1];
			array[i + 1] = 0;
		}
	}
}

stock array_remove(array[], nLength, value) {
	new index = array_find_int(array, nLength, value);
	if(index != -1) {
		array[index] = 0;
	}
}

stock array_clear(array[], nLength) {
	for(new i = 0; i < nLength; i++) {
		array[i] = 0;
	}
}

public RemoveDeadPlayer(nClient) {
	array_remove(nDeadPlayers, sizeof(nDeadPlayers), nClient);
	array_filter(nDeadPlayers, sizeof(nDeadPlayers));
}

public AddDeadPlayer(nClient) {
	for(new i = 0; i < sizeof(nDeadPlayers); i++) {
		if(!nDeadPlayers[i]) {
			nDeadPlayers[i] = nClient;
			break;
		}
	}
}

public Action:event_PlayerSpawn(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) {
	new nClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	RemoveDeadPlayer(nClient);
}

public Action:event_PlayerBotReplace(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) {
	new nBot = GetClientOfUserId(GetEventInt(hEvent, "bot"));
	if(GetClientTeam(nBot) == L4D_TEAM_SURVIVOR) {
		// Check for available clients
		new nClient = nDeadPlayers[0];
		if(nClient) {
			TakeOverBot(nClient);
		}
	}
}*/

public Action:event_MissionLost(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) {
	bRoundEnd = true;
}

public OnClientDisconnect(nClient) {
	//RemoveDeadPlayer(nClient);
}

public Action:event_RoundStart(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) {
	bRoundEnd = false;
	//array_clear(nDeadPlayers);
}

public Action:event_PlayerDeath(Handle:hEvent, String:sEventName[], bool:bDontBroadcast) {
	new nClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(!bRoundEnd && nClient && IsClientConnected(nClient) && !IsFakeClient(nClient) && GetClientTeam(nClient) == L4D_TEAM_SURVIVOR) {
		/*if(GetFirstDeadPlayer()) {
			AddDeadPlayer(nClient);
		} else {*/
			TakeOverBot(nClient);
		/*}*/
	}
}

public TakeOverBot(nClient) {
	new nBot = FindBot(L4D_TEAM_SURVIVOR, true);
	if(nBot) {
		new Handle:hConVar = FindConVar("tob_respawn_time");
		new Handle:hPanel = CreatePanel();

		new String:sMessage[64];
		Format(sMessage, sizeof(sMessage), "You will take over a survivor bot in %d seconds.", GetConVarInt(hConVar));
		DrawPanelText(hPanel, sMessage);
		SendPanelToClient(hPanel, nClient, panel_TakeOverBot, 3);
		CloseHandle(hPanel);

		SDKCall(hSetHumanSpec, nBot, nClient);

		ChangeClientTeam(nClient, L4D_TEAM_SPECTATOR);
		CreateTimer(GetConVarFloat(hConVar), timer_ChangeTeam, nClient);
	}
}

public panel_TakeOverBot(Handle:hPanel, MenuAction:action, param1, param2) {
	// Do nothing
}

public Action:timer_ChangeTeam(Handle:hTimer, any:nClient) {
	if(!bRoundEnd && IsClientConnected(nClient) && GetClientTeam(nClient) == L4D_TEAM_SPECTATOR) {
		new nBot = FindBot(L4D_TEAM_SURVIVOR, true);
		if(nBot) {
			SDKCall(hSetHumanSpec, nBot, nClient);
			SDKCall(hTakeOverBot, nClient, true);
		} else {
			nBot = FindBot(L4D_TEAM_SURVIVOR, false);
			if(nBot) {
				SDKCall(hSetHumanSpec, nBot, nClient);
				SDKCall(hTakeOverBot, nClient, true);
			}
		}
	}
}

stock FindBot(nTeam, bool:bAlive) {
	for(new i = 1; i < L4D_MAXPLAYERS; i++) {
		if(IsClientConnected(i) && IsFakeClient(i) && GetClientTeam(i) == nTeam) {
			if(bAlive) {
				if(IsPlayerAlive(i)) {
					return i;
				}
			} else {
				return i;
			}
		}
	}
	return 0;
}