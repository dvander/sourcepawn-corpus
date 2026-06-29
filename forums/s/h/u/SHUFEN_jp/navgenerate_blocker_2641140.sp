#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define NAV_CANT_ACCESS_FILE 0

Handle hLoad;
Handle hBeginGeneration;

bool g_bEnabledAutoNavGenerate = false;

public Plugin myinfo = {
	name = "Nav Generate Blocker",
	author = "SHUFEN from POSSESSION.tokyo",
	description = "",
	version = "0.1",
	url = "https://possession.tokyo"
};

public void OnPluginStart() {
	Handle hGameData = LoadGameConfigFile("navgenerate_blocker.games");
	if (hGameData == null) {
		SetFailState("Couldn't find navgenerate_blocker.games gamedata.");
	}

	hLoad = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Int, ThisPointer_Address);
	if (!hLoad) {
		delete hGameData;
		SetFailState("Failed to setup detour for CNavMesh::Load.");
	}
	if (!DHookSetFromConf(hLoad, hGameData, SDKConf_Signature, "CNavMesh::Load")) {
		delete hGameData;
		SetFailState("Failed to load CNavMesh::Load signature from gamedata.");
	}
	if (!DHookEnableDetour(hLoad, false, Detour_OnLoad)) {
		delete hGameData;
		SetFailState("Failed to detour CNavMesh::Load.");
	}

	hBeginGeneration = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Void, ThisPointer_Address);
	if (!hBeginGeneration) {
		delete hGameData;
		SetFailState("Failed to setup detour for CNavMesh::BeginGeneration.");
	}
	if (!DHookSetFromConf(hBeginGeneration, hGameData, SDKConf_Signature, "CNavMesh::BeginGeneration")) {
		delete hGameData;
		SetFailState("Failed to load CNavMesh::BeginGeneration signature from gamedata.");
	}
	DHookAddParam(hBeginGeneration, HookParamType_Bool);
	if (!DHookEnableDetour(hBeginGeneration, false, Detour_OnBeginGeneration)) {
		delete hGameData;
		SetFailState("Failed to detour CNavMesh::BeginGeneration.");
	}
	delete hGameData;

	RegAdminCmd("sm_navgenerate", Command_NavGenerate, ADMFLAG_ROOT, "Generate a blank .nav file for current map");
	RegAdminCmd("sm_navgeneratenextmap", Command_NavGenerateNextMap, ADMFLAG_ROOT, "Generate a blank .nav file for next map");

	ConVar hConVar;

	(hConVar = CreateConVar("sm_navgenerate_autogenerate", "1", "Enable/Disable auto generate a blank .nav file for next map", _, true, 0.0, true, 1.0)).AddChangeHook(OnAutoGenerateChanged);
	g_bEnabledAutoNavGenerate = hConVar.BoolValue;

	delete hConVar;
}

public void OnAutoGenerateChanged(ConVar cvar, const char[] oldVal, const char[] newVal) {
	g_bEnabledAutoNavGenerate = cvar.BoolValue;
}

public void OnMapEnd() {
	if (g_bEnabledAutoNavGenerate) {
		char szNextMap[PLATFORM_MAX_PATH];
		if (GetNextMap(szNextMap, sizeof(szNextMap))) {
			GenerateBlankNavFile(szNextMap);
		}
	}
}

public Action OnLogAction(Handle source, Identity ident, int client, int target, const char[] message) {
	if (g_bEnabledAutoNavGenerate) {
		if (StrContains(message, "changed map to") != -1) {
			char buffer[PLATFORM_MAX_PATH];
			strcopy(buffer, sizeof(buffer), message);
			buffer[FindCharInString(buffer, '\"', true)] = '\0';
			GenerateBlankNavFile(buffer[FindCharInString(buffer, '\"', true) + 1]);
		}
	}
}

public MRESReturn Detour_OnLoad(Address pThis, Handle hReturn, Handle hParams) {
	char szMapName[PLATFORM_MAX_PATH], szNavFilePath[PLATFORM_MAX_PATH];
	GetCurrentMap(szMapName, sizeof(szMapName));
	FormatEx(szNavFilePath, sizeof(szNavFilePath), "maps/%s.nav", szMapName);
	if (FileExists(szNavFilePath, false))
		return MRES_Ignored;

	LogMessage("NavGenerateBlocker -> Superseded \"CNavMesh::Load\" Function: return NAV_CANT_ACCESS_FILE;");
	DHookSetReturn(hReturn, NAV_CANT_ACCESS_FILE);
	return MRES_Supercede;
}

public MRESReturn Detour_OnBeginGeneration(Address pThis, Handle hReturn, Handle hParams) {
	LogMessage("NavGenerateBlocker -> Skipped \"CNavMesh::BeginGeneration\" Function");
	return MRES_Supercede;
}

public Action Command_NavGenerate(int client, int args) {
	char szMapName[PLATFORM_MAX_PATH];
	GetCurrentMap(szMapName, sizeof(szMapName));

	GenerateBlankNavFile(szMapName);
	return Plugin_Handled;
}

public Action Command_NavGenerateNextMap(int client, int args) {
	char szNextMap[PLATFORM_MAX_PATH];
	if (GetNextMap(szNextMap, sizeof(szNextMap))) {
		GenerateBlankNavFile(szNextMap);
	}
	return Plugin_Handled;
}

int NAV_BLANKFILE_DATA[] = {206, 250, 237, 254, 16, 0, 0, 0, 1, 0, 0, 0, 14, 238, 118, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0,
						0, 168, 119, 198, 0, 160, 240, 68, 0, 254, 63, 196, 0, 204, 113, 198, 0, 0, 22, 69, 0, 254, 63, 196, 0, 254, 63, 196, 0, 254, 63, 196,
						0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 4, 0, 0, 0, 0, 0, 118, 119, 198, 0, 48, 242, 68, 0, 254, 63,
						196, 8, 1, 0, 0, 0, 0, 254, 113, 198, 0, 48, 242, 68, 0, 254, 63, 196, 8, 2, 0, 0, 0, 0, 254, 113, 198, 0, 56, 21, 69, 0,
						254, 63, 196, 8, 3, 0, 0, 0, 0, 118, 119, 198, 0, 56, 21, 69, 0, 254, 63, 196, 8, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
						0, 0, 0, 139, 187, 111, 61, 212, 233, 139, 62, 0, 0, 128, 63, 0, 0, 128, 63, 0, 0, 128, 63, 0, 0, 128, 63, 0, 0, 0, 0, 0,
						0, 0, 0, 0, 0, 0, 0, 0};

bool GenerateBlankNavFile(const char[] map) {
	char szNavFilePath[PLATFORM_MAX_PATH];
	FormatEx(szNavFilePath, sizeof(szNavFilePath), "maps/%s.nav", map);

	if (FileExists(szNavFilePath, false)) {
		LogMessage("File \"%s\" has already exist.", szNavFilePath);
		return false;
	}

	File hFile = OpenFile(szNavFilePath, "wb");
	if (hFile == null) {
		LogMessage("Couldn't create file \"%s\" for writing.", szNavFilePath);
		return false;
	}

	for (int x = 0; x < sizeof(NAV_BLANKFILE_DATA); x++)
		hFile.WriteInt8(NAV_BLANKFILE_DATA[x]);

	hFile.Close();
	return true;
}
