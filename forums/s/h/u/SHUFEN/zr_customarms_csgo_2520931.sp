/*  ZR Custom CS:GO Arms
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <zombiereloaded>
#include <cstrike>
#include <n_arms_fix>
#include <dhooks>

#define DEFAULT_ARMS "models/weapons/ct_arms.mdl"

public Plugin:myinfo =
{
	name = "ZR Custom CS:GO Arms",
	author = "Franc1sco franug + SHUFEN from POSSESSION.tokyo",
	description = "",
	version = "5.0.1",
	url = "http://steamcommunity.com/id/franug"
};

new Handle:kv;
new Handle:hPlayerClasses, String:sClassPath[PLATFORM_MAX_PATH] = "configs/zr/playerclasses.txt";

new Handle:trie_classes;
new Handle:trie_classes_models;

Handle hSetModels = INVALID_HANDLE;
bool bHooked[MAXPLAYERS+1] = {false, ...};
bool bPendingChangeModel[MAXPLAYERS+1] = {false, ...};

bool g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	RegPluginLibrary("zr_customarms_csgo");
	
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart() 
{
	trie_classes = CreateTrie();
	trie_classes_models = CreateTrie();

	HookEvent("player_spawn", OnSpawnPre, EventHookMode_Pre);

	if(LibraryExists("dhooks")) {
		Handle hGameData = LoadGameConfigFile("plugin.zr_customarms_csgo");

		if(hGameData != null) {
			int iOffset = GameConfGetOffset(hGameData, "SetModel");
			delete hGameData;
			if(iOffset != -1) {
				hSetModels = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHook_SetModels);
				DHookAddParam(hSetModels, HookParamType_CharPtr);
			}
		}
	}

	if(g_bLateLoad)
		for (int i = 1; i <= MaxClients; ++i) {
			OnClientPutInServer(i);
		}
}

public OnMapStart()
{
	PrecacheModel(DEFAULT_ARMS);
}

public void OnClientPutInServer(int client) {
	bPendingChangeModel[client] = false;
	DHookEntity(hSetModels, false, client);
	bHooked[client] = true;
}

public void OnClientDisconnect_Post(int client) {
	bPendingChangeModel[client] = false;
}

public Action OnSpawnPre(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	bPendingChangeModel[client] = true;
}

public void ArmsFix_OnModelSafe(int client) {
	Model(client);
}

public void ArmsFix_OnArmsSafe(int client)
{
	Arms(client);
}

public ZR_OnClientInfected(client, attacker, bool:motherInfect, bool:respawnOverride, bool:respawn)
{
	Arms(client);
}

public ZR_OnClientHumanPost(client, bool:respawn, bool:protect)
{
	Arms(client);
}

Arms(client)
{
	if(!IsPlayerAlive(client)) return;
	
	new cindex = ZR_GetActiveClass(client);
	if(!ZR_IsValidClassIndex(cindex)) return;
	
	decl String:namet[64],String:model[128], String:currentmodel[128];
	ZR_GetClassDisplayName(cindex, namet, sizeof(namet));
	if(!GetTrieString(trie_classes, namet, model, sizeof(model)))
	{
		return;
	}
	
	GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, sizeof(currentmodel));
	
	if(strlen(model) > 3) 
	{
		if(!StrEqual(currentmodel, model)) 
		{
			SetEntPropString(client, Prop_Send, "m_szArmsModel", model);
			CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		if(!StrEqual(currentmodel, DEFAULT_ARMS))
		{
			SetEntPropString(client, Prop_Send, "m_szArmsModel", DEFAULT_ARMS);
			CreateTimer(0.15, RemoveItemTimer, EntIndexToEntRef(client), TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

void Model(int client) {
	bPendingChangeModel[client] = false;
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client)) {
		int cindex = ZR_GetActiveClass(client);
		if(!ZR_IsValidClassIndex(cindex)) return;
		char namet[64], skin[PLATFORM_MAX_PATH], currentskin[PLATFORM_MAX_PATH];
		ZR_GetClassDisplayName(cindex, namet, sizeof(namet));

		if(GetTrieString(trie_classes_models, namet, skin, sizeof(skin))) {
			GetClientModel(client, currentskin, sizeof(currentskin));
			if(strlen(skin) > 3)
				if(!StrEqual(currentskin, skin, false)) {
					LateSetEntityModel(client, skin);
				}
		}
	}
}

public MRESReturn DHook_SetModels(int pThis, Handle hParams) {
	char sBuffer[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, sBuffer, sizeof(sBuffer));
	if(IsClientInGame(pThis) && IsPlayerAlive(pThis) && bPendingChangeModel[pThis]) {
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void LateSetEntityModel(int client, const char[] model) {
	DataPack pack = new DataPack();
	RequestFrame(Frame_LateSetEntityModel, pack);
	pack.WriteCell(GetClientUserId(client));
	pack.WriteString(model);
}

public void Frame_LateSetEntityModel(DataPack pack) {
	if(pack) {
		pack.Reset();
		int client = GetClientOfUserId(pack.ReadCell());
		char model[PLATFORM_MAX_PATH];
		pack.ReadString(model, sizeof(model));
		if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && model[0] != '\0' && IsModelPrecached(model)) {
			SetEntityModel(client, model);
		}
	}
	delete pack;
}

public Action RemoveItemTimer(Handle timer ,any ref)
{
	int client = EntRefToEntIndex(ref);

	if (client != INVALID_ENT_REFERENCE)
	{
		int item = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

		if (item > 0)
		{
			RemovePlayerItem(client, item);

			Handle ph=CreateDataPack();
			WritePackCell(ph, EntIndexToEntRef(client));
			WritePackCell(ph, EntIndexToEntRef(item));
			CreateTimer(0.15 , AddItemTimer, ph, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action AddItemTimer(Handle timer ,any ph)
{ 
	int client, item;

	ResetPack(ph);

	client = EntRefToEntIndex(ReadPackCell(ph));
	item = EntRefToEntIndex(ReadPackCell(ph));

	if (client != INVALID_ENT_REFERENCE && item != INVALID_ENT_REFERENCE)
	{
		EquipPlayerWeapon(client, item);
	}
}

//

public OnAllPluginsLoaded()
{
	if (hPlayerClasses != INVALID_HANDLE)
	{
		UnhookConVarChange(hPlayerClasses, OnClassPathChange);
		CloseHandle(hPlayerClasses);
	}
	if ((hPlayerClasses = FindConVar("zr_config_path_playerclasses")) == INVALID_HANDLE)
	{
		SetFailState("Zombie:Reloaded is not running on this server");
	}
	HookConVarChange(hPlayerClasses, OnClassPathChange);
}

public OnClassPathChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(sClassPath, sizeof(sClassPath), newValue);
	OnConfigsExecuted();
}

public OnConfigsExecuted()
{
	CreateTimer(0.2, OnConfigsExecutedPost);
}

public Action:OnConfigsExecutedPost(Handle:timer)
{
	if (kv != INVALID_HANDLE)
	{
		CloseHandle(kv);
	}
	kv = CreateKeyValues("classes");
	
	decl String:buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "%s", sClassPath);
	
	if (!FileToKeyValues(kv, buffer))
	{
		SetFailState("Class data file \"%s\" not found", buffer);
	}
	
	if (KvGotoFirstSubKey(kv))
	{
		ClearTrie(trie_classes);
		ClearTrie(trie_classes_models);
		decl String:name[64],String:model[128],String:skin[128];
		
		do
		{
			KvGetString(kv, "name", name, sizeof(name));
			KvGetString(kv, "arms_path", model, sizeof(model), " ");
			KvGetString(kv, "model_path", skin, sizeof(skin), " ");
			
			SetTrieString(trie_classes, name, model);
			SetTrieString(trie_classes_models, name, skin);
			
			if(strlen(model) > 3 && FileExists(model) && !IsModelPrecached(model)) PrecacheModel(model);
			if(strlen(skin) > 3 && FileExists(skin) && !IsModelPrecached(skin)) PrecacheModel(skin);
			
		} while (KvGotoNextKey(kv));
	}
	KvRewind(kv);
}
	