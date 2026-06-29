#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Default Glove Blocker",
	author = "UUZ",
	description = "",
	version = "0.2",
	url = ""
};

Handle g_hGameConf;
Handle g_hPrecacheModel;

public MRESReturn Detour_PrecacheModel(int entity, Handle hReturn, Handle hParams)
{
	char model[256];
	DHookGetParamString(hParams, 1, model, sizeof(model));
	if (strncmp(model, "models/weapons/v_models/arms/glove_hardknuckle/", 47) == 0) {
		DHookSetReturn(hReturn, 0);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

public void OnPluginStart()
{
	g_hGameConf = LoadGameConfigFile("default_glove_blocker.games");
	if (g_hGameConf == null) {
		SetFailState("Failed to load \"default_glove_blocker.games\" gamedata");
	}

	Address engine = CreateEngineInterface("VEngineServer023");
	if (engine == Address_Null) {
		SetFailState("Failed to get interface for \"VEngineServer023\"");
	}

	g_hPrecacheModel = DHookCreate(0, HookType_Raw, ReturnType_Int, ThisPointer_Address);
	if (!g_hPrecacheModel) {
		SetFailState("Failed to setup hook for \"PrecacheModel\"");
	}
	DHookAddParam(g_hPrecacheModel, HookParamType_CharPtr);
	DHookAddParam(g_hPrecacheModel, HookParamType_Bool);

	if (!DHookSetFromConf(g_hPrecacheModel, g_hGameConf, SDKConf_Virtual, "PrecacheModel")) {
		SetFailState("Failed to load \"PrecacheModel\" offset from gamedata");
	}
	DHookRaw(g_hPrecacheModel, false, engine, _, Detour_PrecacheModel);

	delete g_hGameConf;
}

stock Address CreateEngineInterface(const char[] sInterfaceKey, Address ptr = Address_Null) {
	static Handle hCreateInterface = null;
	if (hCreateInterface == null) {
		if (g_hGameConf == null)
			return Address_Null;

		StartPrepSDKCall(SDKCall_Static);
		if (!PrepSDKCall_SetFromConf(g_hGameConf, SDKConf_Signature, "CreateInterface")) {
			LogError("[Create Engine Interface] Failed to get CreateInterface");
			return Address_Null;
		}

		PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

		hCreateInterface = EndPrepSDKCall();
		if (hCreateInterface == null) {
			LogError("[Create Engine Interface] Function CreateInterface was not loaded right.");
			return Address_Null;
		}
	}

	if (g_hGameConf == null)
		return Address_Null;

	char sInterfaceName[64];
	if (!GameConfGetKeyValue(g_hGameConf, sInterfaceKey, sInterfaceName, sizeof(sInterfaceName)))
		strcopy(sInterfaceName, sizeof(sInterfaceName), sInterfaceKey);

	Address addr = SDKCall(hCreateInterface, sInterfaceName, ptr);
	if (addr == Address_Null) {
		LogError("[Create Engine Interface] Failed to get pointer to interface %s(%s)", sInterfaceKey, sInterfaceName);
		return Address_Null;
	}

	return addr;
}
