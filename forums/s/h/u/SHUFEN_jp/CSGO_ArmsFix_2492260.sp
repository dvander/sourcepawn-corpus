#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

bool g_bLateLoad = false;

char defaultArms[][] = { "models/weapons/ct_arms.mdl", "models/weapons/t_arms.mdl" };
char defaultModels[][] = { "models/player/ctm_fbi.mdl", "models/player/tm_phoenix.mdl" };

char sArmsQueue[MAXPLAYERS+1][PLATFORM_MAX_PATH];
char sModelsQueue[MAXPLAYERS+1][PLATFORM_MAX_PATH];

int iOffset_Arms;

Handle hSetModels = INVALID_HANDLE;
bool bPendingChangeModel[MAXPLAYERS+1] = {false, ...};

public Plugin myinfo = {

	name = "Skin & Arms Fix [Stand Alone Version]",
	author = "NomisCZ (-N-) + SHUFEN from POSSESSION.tokyo",
	description = "Arms fix",
	version = "1.1 DHooks",
	url = "http://steamcommunity.com/id/olympic-nomis-p + https://possession.tokyo"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public void OnPluginStart() {
	char modname[50];
	GetGameFolderName(modname, sizeof(modname));
	if (!StrEqual(modname, "csgo", false))
		SetFailState("Sorry! This plugin only works on Counter-Strike: Global Offensive.");

	iOffset_Arms = FindSendPropInfo("CCSPlayer", "m_szArmsModel");
	if (iOffset_Arms == -1)
		SetFailState("* FATAL ERROR: Failed to get offset for CCSPlayer::m_szArmsModel");

	if(LibraryExists("dhooks")) {
		Handle hGameData = LoadGameConfigFile("CSGO_ArmsFix.games");

		if(hGameData != null) {
			int iOffset = GameConfGetOffset(hGameData, "SetModel");
			delete hGameData;
			if(iOffset != -1) {
				hSetModels = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHook_SetModels);
				DHookAddParam(hSetModels, HookParamType_CharPtr);
			}
		}
	}

	HookEvent("player_spawn", Event_Spawn, EventHookMode_Post);
	HookEvent("cs_pre_restart", Event_RoundChange);

	if(g_bLateLoad) {
		for (int client = 1; client <= MaxClients; client++) {
			if (!IsClientInGame(client))
				continue;

			OnClientPutInServer(client);
		}
	}
}

public void OnMapStart() {
	PrecacheModels();
}

void PrecacheModels() {
	for (int i = 0; i < sizeof(defaultArms); i++) {
		PrecacheModel(defaultArms[i]);
	}
	
	for (int i = 0; i < sizeof(defaultModels); i++) {
		PrecacheModel(defaultModels[i]);
	}
}

public void OnClientPutInServer(int client)
{
	DHookEntity(hSetModels, false, client);

	bPendingChangeModel[client] = false;
	sArmsQueue[client][0] = '\0';
	sModelsQueue[client][0] = '\0';
}

public void OnClientDisconnect(int client) {
	bPendingChangeModel[client] = false;
	sArmsQueue[client][0] = '\0';
	sModelsQueue[client][0] = '\0';
}

public Action Event_RoundChange(Handle event, const char[] name, bool dontBroadcast) {
	for (int client = 1; client <= MaxClients; client++) {
		bPendingChangeModel[client] = true;
		sArmsQueue[client][0] = '\0';
		sModelsQueue[client][0] = '\0';
	}
}

public Action Event_Spawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));

	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);

	bPendingChangeModel[client] = true;
	sArmsQueue[client][0] = '\0';
	sModelsQueue[client][0] = '\0';
	
	if (IsValidClient(client) && IsPlayerAlive(client)) {
		CS_UpdateClientModel(client);

		SetEntPropString(client, Prop_Send, "m_szArmsModel", "");
		
		int team = GetClientTeam(client);
		
		if (team == CS_TEAM_T) {
			SetEntityModel(client, defaultModels[1]);
			SetEntPropString(client, Prop_Send, "m_szArmsModel", defaultArms[1]);

		} else if (team == CS_TEAM_CT) {
			SetEntityModel(client, defaultModels[0]);
			SetEntPropString(client, Prop_Send, "m_szArmsModel", defaultArms[0]);
		}
		
		CreateTimer(0.2, Timer_UnBlockChangeModel, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}

	return Plugin_Continue;
}

public Action Timer_UnBlockChangeModel(Handle timer, int userid) {
	int client = GetClientOfUserId(userid);
	bPendingChangeModel[client] = false;
	if(sModelsQueue[client][0] && IsModelPrecached(sModelsQueue[client])) {
		SetEntityModel(client, sModelsQueue[client]);
		sModelsQueue[client][0] = '\0';
	}
	if(sArmsQueue[client][0] && IsModelPrecached(sArmsQueue[client])) {
		SetEntDataString(client, iOffset_Arms, sArmsQueue[client], PLATFORM_MAX_PATH, true);
		RequestFrame(RefreshArms, client);
		sArmsQueue[client][0] = '\0';
	}
}

static char sLatestBuffer[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public void OnPostThinkPost(int client) {
	if(!bPendingChangeModel[client]) {
		sLatestBuffer[client][0] = '\0';
		SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		return;
	}
	char sBuffer[PLATFORM_MAX_PATH];
	GetEntDataString(client, iOffset_Arms, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, sLatestBuffer[client], false)) return;
	strcopy(sLatestBuffer[client], sizeof(sLatestBuffer[]), sBuffer);
	if(StrEqual(sBuffer, defaultArms[GetClientTeam(client) == CS_TEAM_CT ? 0 : 1], false)) {
		return;
	}
	strcopy(sArmsQueue[client], sizeof(sArmsQueue[]), sBuffer);
	SetEntDataString(client, iOffset_Arms, defaultArms[GetClientTeam(client) == CS_TEAM_CT ? 0 : 1], PLATFORM_MAX_PATH, true);
}

public MRESReturn DHook_SetModels(int pThis, Handle hParams) {
	char sBuffer[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, defaultModels[GetClientTeam(pThis) == CS_TEAM_CT ? 0 : 1], false)) {
		return MRES_Ignored;
	}
	if(bPendingChangeModel[pThis]) {
		strcopy(sModelsQueue[pThis], sizeof(sModelsQueue[]), sBuffer);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

void RefreshArms(int client) {
	for (int iSlot = 0; iSlot < 5; iSlot++) {
		int entity = GetPlayerWeaponSlot(client, iSlot);
		if(IsValidEntity(entity)) {
			if(GetHammerIdOfEntity(entity) > 0 || Entity_HasChildren(entity)) continue;

			char sClassname[64], sCurrentClassname[64];
			GetEntityClassname(entity, sClassname, sizeof(sClassname));
			int iCurrent = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			int iClip = GetEntProp(entity, Prop_Send, "m_iClip1", 4, 0);
			int offset_ammo = FindDataMapInfo(client, "m_iAmmo");
			int offset = offset_ammo + (GetEntProp(entity, Prop_Data, "m_iPrimaryAmmoType") * 4);
			int iAmmo = GetEntData(client, offset);
			if(entity != iCurrent) {
				if(IsValidEntity(iCurrent))
					GetEntityClassname(iCurrent, sCurrentClassname, sizeof(sCurrentClassname));
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", entity);
			}
			RemovePlayerItem(client, entity);
			if(IsValidEntity(entity))
				AcceptEntityInput(entity, "kill");

			DataPack pack = new DataPack();
			CreateTimer(0.2, Timer_RefreshArms_Post, pack);
			pack.WriteCell(client);
			pack.WriteString(sClassname);
			pack.WriteCell(iClip);
			pack.WriteCell(iAmmo);
			pack.WriteString(sCurrentClassname);

			break;
		}
	}
}

public Action Timer_RefreshArms_Post(Handle timer, DataPack pack) {
	if(pack) {
		pack.Reset();
		int client = pack.ReadCell();
		char sClassname[64];
		pack.ReadString(sClassname, sizeof(sClassname));
		int iClip = pack.ReadCell();
		int iAmmo = pack.ReadCell();
		char sCurrentClassname[64];
		pack.ReadString(sCurrentClassname, sizeof(sCurrentClassname));
		if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client)) {
			if(sClassname[0] != '\0') {
				int weapon = GivePlayerItem(client, sClassname);

				DataPack pack2 = new DataPack();
				CreateTimer(0.2, Timer_RefreshArms_Post2, pack2);
				pack2.WriteCell(client);
				pack2.WriteCell(weapon);
				pack2.WriteString(sClassname);
				pack2.WriteCell(iClip);
				pack2.WriteCell(iAmmo);
				pack2.WriteString(sCurrentClassname);
			}
		}
	}
	delete pack;
}

public Action Timer_RefreshArms_Post2(Handle timer, DataPack pack) {
	if(pack) {
		pack.Reset();
		int client = pack.ReadCell();
		int weapon = pack.ReadCell();
		char sClassname[64];
		pack.ReadString(sClassname, sizeof(sClassname));
		int iClip = pack.ReadCell();
		int iAmmo = pack.ReadCell();
		char sCurrentClassname[64];
		pack.ReadString(sCurrentClassname, sizeof(sCurrentClassname));
		if (IsClientInGame(client) && !IsFakeClient(client) && IsPlayerAlive(client)) {
			if(IsValidEntity(weapon)) {
				if(iClip >= 0)
					SetEntProp(weapon, Prop_Send, "m_iClip1", iClip, 4, 0);
				if(iAmmo >= 0) {
					int offset_ammo = FindDataMapInfo(client, "m_iAmmo");
					int offset = offset_ammo + (GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoType") * 4);
					SetEntData(client, offset, iAmmo, 4, true);
				}
			}
			if(sCurrentClassname[0] != '\0') {
				FakeClientCommand(client,"use %s", sCurrentClassname);
			}
			else if(sClassname[0] != '\0') {
				FakeClientCommand(client,"use %s", sClassname);
			}
		}
	}
	delete pack;
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

stock int GetHammerIdOfEntity(int entity) {
	if(IsValidEntity(entity)) {
		return GetEntProp(entity, Prop_Data, "m_iHammerID");
	}
	return -1;
}

stock bool Entity_HasChildren(int entity) {
	for (int x = MAXPLAYERS+1; x < GetMaxEntities(); x++) {
		if (!IsValidEntity(x))
			continue;
		
		int parent = GetEntPropEnt(entity, Prop_Data, "m_pParent");
		if (parent == entity)
			return true;
	}
	return false;
}