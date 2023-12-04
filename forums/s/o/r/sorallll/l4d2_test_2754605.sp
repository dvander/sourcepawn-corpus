#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#define GAMEDATA	"l4d2_test"

Handle g_hSDK_Call[3]; 

public Plugin myinfo=
{
	name = "l4d2 test",
	author = "",
	description = "",
	version = "",
	url = ""
}

public void OnPluginStart()
{
	vLoadGameData();
	RegAdminCmd("sm_test0", cmdTest0, ADMFLAG_ROOT);
	RegAdminCmd("sm_test1", cmdTest1, ADMFLAG_ROOT);
}

public Action cmdTest0(int client, int args)
{
	if(client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2)
		return Plugin_Handled;

	SDKCall(g_hSDK_Call[0], client, "Player.Heartbeat");
	return Plugin_Handled;
}

public Action cmdTest1(int client, int args)
{
	if(client == 0 || !IsClientInGame(client) || IsFakeClient(client) || GetClientTeam(client) != 2)
		return Plugin_Handled;

	SDKCall(g_hSDK_Call[0], client, "Player.Heartbeat");
	SDKCall(g_hSDK_Call[1], client, "Player.Heartbeat");
	SDKCall(g_hSDK_Call[2], client, "Player.Heartbeat");
	return Plugin_Handled;
}

void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::StopTrackedSound") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::StopTrackedSound");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDK_Call[0] = EndPrepSDKCall();
	if(g_hSDK_Call[0] == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::StopTrackedSound");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CCSPlayer::EmitPrivateSound") == false)
		SetFailState("Failed to find signature: CCSPlayer::EmitPrivateSound");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDK_Call[1] = EndPrepSDKCall();
	if(g_hSDK_Call[1] == null)
		SetFailState("Failed to create SDKCall: CCSPlayer::EmitPrivateSound");

	StartPrepSDKCall(SDKCall_Player);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CTerrorPlayer::TrackSound") == false)
		SetFailState("Failed to find signature: CTerrorPlayer::TrackSound");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	g_hSDK_Call[2] = EndPrepSDKCall();
	if(g_hSDK_Call[2] == null)
		SetFailState("Failed to create SDKCall: CTerrorPlayer::TrackSound");

	delete hGameData;
}