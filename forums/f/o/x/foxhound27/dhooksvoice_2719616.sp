#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>


Handle g_hProcessVoice = INVALID_HANDLE;
int g_iHookID[MAXPLAYERS+1] = { -1, ... };

public void OnPluginStart()
{
	int offset = GameConfGetOffset(GetConfig(), "CGameClient::ProcessVoiceData");
	
	g_hProcessVoice = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Address, Hook_ProcessVoiceData);
	DHookAddParam(g_hProcessVoice, HookParamType_ObjectPtr);
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		g_iHookID[client] = DHookRaw(g_hProcessVoice, true, GetIMsgHandler(client));
	}
}

public void OnClientDisconnect(int client)
{
	if (g_iHookID[client] != -1)
	{
		DHookRemoveHookID(g_iHookID[client]);
		
		g_iHookID[client] = -1;
	}
}

public MRESReturn Hook_ProcessVoiceData(Address pthis, Handle hParams) {
	Address pIClient = pthis - view_as < Address > (4);
	int client = GetPlayerSlot(pIClient) + 1;

	PrintToChat(client, "%N (%i) is speaking!", client, client);

	return MRES_Ignored;
}
/*
* Internal Functions
*/
stock Handle GetConfig()
{
	static Handle hGameConf = INVALID_HANDLE;
	
	if (hGameConf == INVALID_HANDLE)
	{
		hGameConf = LoadGameConfigFile("dhooks.mic");
	}
	
	return hGameConf;
}

stock Address GetBaseServer()
{
	static Address pBaseServer = Address_Null;
	
	if (pBaseServer == Address_Null)
	{
		pBaseServer = GameConfGetAddress(GetConfig(), "CBaseServer");
	}
	
	return pBaseServer;
}

stock Address GetIClient(int slot) {
	static Handle hGetClient = INVALID_HANDLE;

	if (hGetClient == INVALID_HANDLE) {
		StartPrepSDKCall(SDKCall_Raw);
		if (PrepSDKCall_SetFromConf(GetConfig(), SDKConf_Virtual, "CBaseServer::GetClient") == false) {
			LogError("Failed signature: CBaseServer::GetClient");
		} else {
			PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
			PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);

			hGetClient = EndPrepSDKCall();

			if (hGetClient == null) LogError("Failed creating SDKCall: CBaseServer::GetClient");
		}

	}

	return view_as < Address > (SDKCall(hGetClient, GetBaseServer(), slot));
}

stock GetPlayerSlot(Address pIClient)
{
	static Handle hPlayerSlot = INVALID_HANDLE;
	
	if (hPlayerSlot == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetConfig(), SDKConf_Virtual, "CBaseClient::GetPlayerSlot");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		hPlayerSlot = EndPrepSDKCall();
	}
	
	return SDKCall(hPlayerSlot, pIClient);
}

stock Address GetIMsgHandler(int client)
{
	return GetIClient(client - 1) + view_as<Address>(4);
}
