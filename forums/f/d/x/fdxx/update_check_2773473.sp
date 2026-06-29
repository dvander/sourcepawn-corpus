#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public void OnPluginStart()
{
	RegServerCmd("sm_update_check", Cmd_UpdateCheck);
}

Action Cmd_UpdateCheck(int args)
{
	GameData hGameData = new GameData("update_check");

	Address pSteam3Server = hGameData.GetAddress("Steam3Server");
	Address pSteamGameServer = LoadFromAddress(pSteam3Server + view_as<Address>(4), NumberType_Int32);
	Address pWasRestartRequested = LoadFromAddress(pSteamGameServer + view_as<Address>(44*4), NumberType_Int32);

	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetAddress(pWasRestartRequested))
		SetFailState("PrepSDKCall_SetAddress fail");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle hSDKCall = EndPrepSDKCall();
	if (hSDKCall == null)
		SetFailState("EndPrepSDKCall fail");

	int iWasRestartRequested = SDKCall(hSDKCall, pSteamGameServer);
	LogMessage("iWasRestartRequested = %i", iWasRestartRequested);
	 
	delete hSDKCall;
	delete hGameData;

	return Plugin_Handled;
}

