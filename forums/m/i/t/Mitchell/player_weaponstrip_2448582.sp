#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <dhooks>

#define PLUGIN_VERSION 	"1.0.0"

Handle hAcceptInput;

//global stripping entity
int gse = -1;

public Plugin:myinfo = {
	name = "Player_WeaponsStrip Replacement",
	author = "Mitch",
	description = "Changes player_weaponstrips to game_player_equips",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	CreateConVar("sm_player_weaponstrip_version", PLUGIN_VERSION, "Player_WeaponStrip Replacement", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	Handle gameData = LoadGameConfigFile("weaponstrip.games");

	if(gameData == INVALID_HANDLE) {
		SetFailState("Why you no has gamedata?");
	}

	int offset = GameConfGetOffset(gameData, "AcceptInput");
	hAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
	DHookAddParam(hAcceptInput, HookParamType_CharPtr);
	DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
	DHookAddParam(hAcceptInput, HookParamType_Object, 20);
	DHookAddParam(hAcceptInput, HookParamType_Int);
}

public OnEntityCreated(int entity, const char[] classname) {
	if(StrEqual(classname, "player_weaponstrip", false)){
		PrintToChatAll("FOUND WEAPON STRIP");
		DHookEntity(hAcceptInput, true, entity);
	}
}

public MRESReturn AcceptInput(int pThis, Handle hReturn, Handle hParams) {
	char command[PLATFORM_MAX_PATH];
	DHookGetParamString(hParams, 1, command, sizeof(command));
	if(StrContains(command, "Strip", false) >= 0 && IsValidEntity(pThis)) {
		int activator = DHookGetParam(hParams, 2);
		int caller = DHookGetParam(hParams, 3);
		PrintToChatAll("Caller: %i | Activator: %i", caller, activator);
		
		int gpe = getGSE();
		AcceptEntityInput(gpe, "use", activator, caller);
		
		return MRES_ChangedHandled;
	}
	return MRES_Ignored;
}

public int getGSE() {
	if(gse >= -1 || !IsValidEntity(gse)) {
		PrintToChatAll("INVALID G_P_E CREATING NEW ONE");
		int gpe = CreateEntityByName("game_player_equip");
		if(gpe > 0) {
			DispatchKeyValue(gpe, "spawnflags", "3"); // Use only + Strip all weapons
			DispatchSpawn(gpe);
			gse = EntIndexToEntRef(gpe);
		}
		return gpe;
	}
	PrintToChatAll("FOUND G_P_E");
	return EntRefToEntIndex(gse);
}