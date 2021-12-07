/**
 * Sourcemod 1.7 Plugin Template
 */
#pragma semicolon 1
#include <sourcemod>

#include <sdktools>
#include <dhooks>

#pragma newdecls required

Handle g_DHookTakeHealth;

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.kit_overheal");
	if (!hGameConf) {
		SetFailState("Failed to load gamedata (tf2.kit_overheal).");
	}
	
	int offset = GameConfGetOffset(hGameConf, "CTFPlayer::TakeHealth()");
	if (offset == -1) {
		SetFailState("Missing offset for CTFPlayer::TakeHealth()");
	}
	
	g_DHookTakeHealth = DHookCreate(offset, HookType_Entity, ReturnType_Int,
			ThisPointer_CBaseEntity);
	DHookAddParam(g_DHookTakeHealth, HookParamType_Float); // flHealth
	DHookAddParam(g_DHookTakeHealth, HookParamType_Int); // bitsDamageType
	
	delete hGameConf;
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	DHookEntity(g_DHookTakeHealth, false, client, .callback = OnTakeHealthPre);
}

public MRESReturn OnTakeHealthPre(int client, Handle hReturn, Handle hParams) {
	// rewrite flag for overheal
	// I'm not sure what the flag stands for, but it's taken from ConditionGameRulesThink (which does overheal)
	int bitsDamageType = 6;
	DHookSetParam(hParams, 2, bitsDamageType);
	
	float flHealthToAdd = DHookGetParam(hParams, 1);
	DHookSetParam(hParams, 1, flHealthToAdd);
	
	return MRES_ChangedHandled;
}
