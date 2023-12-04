#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma semicolon 1
#pragma newdecls required

Handle armsHandle;
Handle modelHandle;

char defaultArms[2][PLATFORM_MAX_PATH] = { "models/weapons/t_arms.mdl", "models/weapons/ct_arms.mdl" };
char defaultModels[2][PLATFORM_MAX_PATH] = { "models/player/tm_anarchist.mdl", "models/player/ctm_fbi.mdl" };

char stockModels[][] = { "models/player/tm_professional.mdl", "models/player/ctm_swat.mdl" };

public Plugin myinfo = {
	name = "Skin & Arms Fix",
	author = "NomisCZ (-N-)",
	description = "Arms fix",
	version = "1.1.11111111111111111",
	url = "http://steamcommunity.com/id/olympic-nomis-p"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("n_arms_fix");
	armsHandle = CreateGlobalForward("ArmsFix_OnArmsSafe", ET_Ignore, Param_Cell);
	modelHandle = CreateGlobalForward("ArmsFix_OnModelSafe", ET_Ignore, Param_Cell);
	return APLRes_Success;
}

public void OnMapStart() {
	char sCurrentMap[256];
	GetCurrentMap(sCurrentMap, sizeof(sCurrentMap));
	CheckMapsKv(sCurrentMap);
}

public void OnPluginStart() {
	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
} 

void PrecacheModels() {
	for (int i = 0; i < sizeof(defaultArms); i++) {
		if(defaultArms[i][0] && !IsModelPrecached(defaultArms[i]))
			PrecacheModel(defaultArms[i]);
	}
	
	for (int i = 0; i < sizeof(defaultModels); i++) {
		if(defaultModels[i][0] && !IsModelPrecached(defaultModels[i]))
			PrecacheModel(defaultModels[i]);
	}
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidClient(client) && IsPlayerAlive(client)) {
		CS_UpdateClientModel(client);

		SetEntPropString(client, Prop_Send, "m_szArmsModel", "");
		
		int iTeam = (GetClientTeam(client) == CS_TEAM_CT ? 1 : 0);
		
		if(defaultModels[iTeam][0] && IsModelPrecached(defaultModels[iTeam])) {
			SetEntityModel(client, defaultModels[iTeam]);
		}
		if(defaultArms[iTeam][0] && IsModelPrecached(defaultArms[iTeam])) {
			SetEntPropString(client, Prop_Send, "m_szArmsModel", defaultArms[iTeam]);
		}
		
		CreateTimer(0.2, Timer_CallForward, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Timer_CallForward(Handle timer, int userid) {
	CallArmsForward(GetClientOfUserId(userid));
	RequestFrame(Frame_CallModelForward, userid);
}

void Frame_CallModelForward(int userid) {
	CallModelForward(GetClientOfUserId(userid));
}

void CallModelForward(int client) {
	Call_StartForward(modelHandle);
	Call_PushCell(client);
	Call_Finish();
}

void CallArmsForward(int client) {
	Call_StartForward(armsHandle);
	Call_PushCell(client);
	Call_Finish();
}

bool IsValidClient(int client, bool bot = false) {
	if (client > 0 && 
		client <= MaxClients && 
		IsClientConnected(client) && 
		IsClientInGame(client) && 
		(bot || !IsFakeClient(client)))
		return true;
	return false;
}

stock bool CheckMapsKv(const char[] sCurrentMap) {
	Handle kv = CreateKeyValues("GameModes.txt");
	if (FileToKeyValues(kv, "scripts/items/items_game.txt")) {
		if (KvJumpToKey(kv, "maps")) {
			if (KvGotoFirstSubKey(kv, false)) {
				if (KvJumpToKey(kv, sCurrentMap)) {
					char sBuffer[PLATFORM_MAX_PATH];
					if (KvJumpToKey(kv, "t_models")) {
						if (KvGotoFirstSubKey(kv, false)) {
							do {
								KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
								if(sBuffer[0] == '\0')
									continue;
								SplitString(sBuffer, "_var", sBuffer, sizeof(sBuffer));
								char sPathBuffer[PLATFORM_MAX_PATH];
								FormatEx(sPathBuffer, sizeof(sPathBuffer), "models/player/%s.mdl", sBuffer);
								if(StrEqual(sPathBuffer, defaultModels[CS_TEAM_T-2], false))
									strcopy(defaultModels[CS_TEAM_T-2], sizeof(defaultModels[]), stockModels[CS_TEAM_T-2]);
								break;
							} while (KvGotoNextKey(kv));
						}
						KvGoBack(kv);
					}
					KvGoBack(kv);
					if (KvJumpToKey(kv, "ct_models")) {
						if (KvGotoFirstSubKey(kv, false)) {
							do {
								KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
								if(sBuffer[0] == '\0')
									continue;
								SplitString(sBuffer, "_var", sBuffer, sizeof(sBuffer));
								char sPathBuffer[PLATFORM_MAX_PATH];
								FormatEx(sPathBuffer, sizeof(sPathBuffer), "models/player/%s.mdl", sBuffer);
								if(StrEqual(sPathBuffer, defaultModels[CS_TEAM_CT-2], false))
									strcopy(defaultModels[CS_TEAM_CT-2], sizeof(defaultModels[]), stockModels[CS_TEAM_CT-2]);
								break;
							} while (KvGotoNextKey(kv));
						}
					}
				}
			}
		}
	}
	kv = CreateKeyValues(sCurrentMap);
	char sPath[PLATFORM_MAX_PATH];
	FormatEx(sPath, sizeof(sPath), "maps/%s.kv", sCurrentMap);
	if (FileToKeyValues(kv, sPath)) {
		char sBuffer[PLATFORM_MAX_PATH];
		if (KvJumpToKey(kv, "t_models")) {
			if (KvGotoFirstSubKey(kv, false)) {
				do {
					KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
					if(sBuffer[0] == '\0')
						continue;
					SplitString(sBuffer, "_var", sBuffer, sizeof(sBuffer));
					char sPathBuffer[PLATFORM_MAX_PATH];
					FormatEx(sPathBuffer, sizeof(sPathBuffer), "models/player/%s.mdl", sBuffer);
					if(StrEqual(sPathBuffer, defaultModels[CS_TEAM_T-2], false))
						strcopy(defaultModels[CS_TEAM_T-2], sizeof(defaultModels[]), stockModels[CS_TEAM_T-2]);
					break;
				} while (KvGotoNextKey(kv));
			}
			KvGoBack(kv);
		}
		KvGoBack(kv);
		if (KvJumpToKey(kv, "ct_models")) {
			if (KvGotoFirstSubKey(kv, false)) {
				do {
					KvGetSectionName(kv, sBuffer, sizeof(sBuffer));
					if(sBuffer[0] == '\0')
						continue;
					SplitString(sBuffer, "_var", sBuffer, sizeof(sBuffer));
					char sPathBuffer[PLATFORM_MAX_PATH];
					FormatEx(sPathBuffer, sizeof(sPathBuffer), "models/player/%s.mdl", sBuffer);
					if(StrEqual(sPathBuffer, defaultModels[CS_TEAM_CT-2], false))
						strcopy(defaultModels[CS_TEAM_CT-2], sizeof(defaultModels[]), stockModels[CS_TEAM_CT-2]);
					break;
				} while (KvGotoNextKey(kv));
			}
		}
	}
	delete kv;

	PrecacheModels();
}