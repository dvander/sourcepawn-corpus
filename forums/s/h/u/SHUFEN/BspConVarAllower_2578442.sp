#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <dhooks>

KeyValues kv;
KeyValues config;
Handle hAcceptInput;

public Plugin myinfo = {
	name = "BSP ConVar Allower",
	author = "SHUFEN from POSSESSION.tokyo",
	description = "Allows server commands to maps",
	version = "0.1",
	url = "https://possession.tokyo"
};

public void OnPluginStart() {
	if (!CheckTxtFile_bspconvar_whitelist()) return;

	if (hAcceptInput == null) {
		char tmpOffset[148];

		switch(GetEngineVersion()) {
			case Engine_CSGO:
				tmpOffset = "sdktools.games\\engine.csgo";
			default:
				SetFailState("This plugin is only for CS:GO");
		}

		Handle temp = LoadGameConfigFile(tmpOffset);

		if (temp == null)
			SetFailState("Why you no has gamedata?");

		int offset = GameConfGetOffset(temp, "AcceptInput");
		hAcceptInput = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, AcceptInput);
		DHookAddParam(hAcceptInput, HookParamType_CharPtr);
		DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
		DHookAddParam(hAcceptInput, HookParamType_CBaseEntity);
		DHookAddParam(hAcceptInput, HookParamType_Object, 20);
		DHookAddParam(hAcceptInput, HookParamType_Int);

		delete temp;
	}
}

public void OnPluginEnd() {
	if (kv != INVALID_HANDLE)
		delete kv;
	if (config != INVALID_HANDLE)
		delete config;
}

bool CheckTxtFile_bspconvar_whitelist() {
	if (kv != INVALID_HANDLE)
		delete kv;
	kv = new KeyValues("convars");
	if (!kv.ImportFromFile("bspconvar_whitelist.txt")) {
		SetFailState("Couldn't get KeyValues from bspconvar_whitelist.txt");
		return false;
	}
	if (config != INVALID_HANDLE)
		delete config;
	config = new KeyValues("convars");
	if (!config.ImportFromFile("bspconvar_whitelist_permanent.txt")) {
		SetFailState("Couldn't get KeyValues from bspconvar_whitelist_permanent.txt");
		return false;
	}
	return true;
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrEqual(classname, "point_servercommand", false))
		DHookEntity(hAcceptInput, false, entity);
}

public MRESReturn AcceptInput(int entity, Handle hReturn, Handle hParams) {
	if (!IsValidEntity(entity))
		return MRES_Ignored;

	char eCommand[128], eParam[256], eServerCommand[64];

	DHookGetParamString(hParams, 1, eCommand, 128);

	if (StrEqual(eCommand, "Command", false)) {
		int type = DHookGetParamObjectPtrVar(hParams, 4, 16, ObjectValueType_Int);
		if (type == 2) {
			DHookGetParamObjectPtrString(hParams, 4, 0, ObjectValueType_String, eParam, 256);

			SplitString(eParam, " ", eServerCommand, 64);
			if (!kv.JumpToKey(eServerCommand, false) && config.JumpToKey(eServerCommand, false)) {
				ServerCommand(eParam);
			}
			kv.Rewind();
			config.Rewind();
		}
	}

	return MRES_Ignored;
}
