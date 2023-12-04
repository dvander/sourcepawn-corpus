#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define GAMEDATA	"keyvalues_getint"

Address
	g_pSavedPlayers,
	g_pSavedPlayerCount;

Handle
	g_hSDKKeyValuesGetInt;

public Plugin myinfo = 
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = ""
};

public void OnPluginStart()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	g_pSavedPlayers = hGameData.GetAddress("g_SavedPlayers");
	if(!g_pSavedPlayers)
		SetFailState("Failed to find address: g_SavedPlayers");

	g_pSavedPlayerCount = hGameData.GetAddress("SavedPlayerCount");
	if(!g_pSavedPlayerCount)
		SetFailState("Failed to find address: SavedPlayerCount");

	StartPrepSDKCall(SDKCall_Raw);
	if(!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "KeyValues::GetInt"))
		SetFailState("Failed to find signature: KeyValues::GetInt");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	g_hSDKKeyValuesGetInt = EndPrepSDKCall();
	if(!g_hSDKKeyValuesGetInt)
		SetFailState("Failed to create SDKCall: KeyValues::GetInt");

	delete hGameData;

	RegAdminCmd("sm_test", cmdTest, ADMFLAG_ROOT);
}

Action cmdTest(int client, int args)
{
	if(!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;

	int iSavedPlayerCount = LoadFromAddress(g_pSavedPlayerCount, NumberType_Int32);
	ReplyToCommand(client, "SavedPlayerCount->%d", iSavedPlayerCount);
	ReplyToCommand(client, "g_pSavedPlayers->%X", LoadFromAddress(g_pSavedPlayers, NumberType_Int32));
	ReplyToCommand(client, "SavedPlayerCount->%X", LoadFromAddress(g_pSavedPlayerCount + view_as<Address>(4), NumberType_Int32));
	if(!iSavedPlayerCount)
		return Plugin_Handled;

	Address pThis;
	for(int i; i < iSavedPlayerCount; i++)
	{
		pThis = LoadFromAddress(LoadFromAddress(g_pSavedPlayers, NumberType_Int32) + view_as<Address>(4 * i), NumberType_Int32);
		if(!pThis)
			continue;

		ReplyToCommand(client, "health->%d userID->%d", SDKCall(g_hSDKKeyValuesGetInt, pThis, "health", 0), SDKCall(g_hSDKKeyValuesGetInt, pThis, "userID", 0));
	}

	return Plugin_Handled;
}
