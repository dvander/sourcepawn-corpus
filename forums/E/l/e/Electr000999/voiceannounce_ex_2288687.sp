#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <dhooks>
#include <voiceannounce_ex>

#define PLUGIN_VERSION "2.0.0"

new Handle:g_hProcessVoice = INVALID_HANDLE,
	Handle:g_hOnClientTalking = INVALID_HANDLE,
	Handle:g_hOnClientTalkingEnd = INVALID_HANDLE,
	bool:g_bLateLoad = false;

new g_iHookID[MAXPLAYERS+1] = { -1, ... };
new Handle:g_hClientMicTimers[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

new bool:is_csgo;
new Handle:hCSGOVoice;

public Plugin:myinfo = 
{
	name = "VoiceAnnounceEx",
	author = "Franc1sco franug, Mini and GoD-Tony",
	description = "Feature for developers to check/control client mic usage.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	if(GetEngineVersion() == Engine_CSGO) is_csgo = true;
	else is_csgo = false;

	
	CreateNative("IsClientSpeaking", Native_IsClientTalking);

	RegPluginLibrary("voiceannounce_ex");

	g_bLateLoad = late;
	return APLRes_Success;
}

public Native_IsClientTalking(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	if (client > MaxClients || client <= 0)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not valid.");
		return false;
	}

	if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client is not in-game.");
		return false;
	}

	if (IsFakeClient(client))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Cannot do mic checks on fake clients.");
		return false;
	}

	return (g_hClientMicTimers[client] == INVALID_HANDLE) ? false : true;
}

public OnPluginStart()
{
	CreateConVar("voiceannounce_ex_version", PLUGIN_VERSION, "plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	new offset;
	if(is_csgo)
	{
		offset = GameConfGetOffset(GetConfig(), "OnVoiceTransmit");

		if(offset == -1)
			SetFailState("Failed to get offset");

	
		hCSGOVoice = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, CSGOVoicePost);
	}
	else
	{
		offset = GameConfGetOffset(GetConfig(), "CGameClient::ProcessVoiceData");
	
		g_hProcessVoice = DHookCreate(offset, HookType_Raw, ReturnType_Void, ThisPointer_Address, Hook_ProcessVoiceData);
		DHookAddParam(g_hProcessVoice, HookParamType_ObjectPtr);
	}

	g_hOnClientTalking = CreateGlobalForward("OnClientSpeakingEx", ET_Single, Param_Cell);
	g_hOnClientTalkingEnd = CreateGlobalForward("OnClientSpeakingEnd", ET_Ignore, Param_Cell);

	if (g_bLateLoad)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				OnClientPostAdminCheck(i);
			}
		}
	}
}


public OnClientPostAdminCheck(client)
{
	if(client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		CreateTimer(5.0, tmrHook, client, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:tmrHook(Handle:timer, any:client)
{
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		if(is_csgo) DHookEntity(hCSGOVoice, true, client); 
		else g_iHookID[client] = DHookRaw(g_hProcessVoice, true, GetIMsgHandler(client));

		if (g_hClientMicTimers[client] != INVALID_HANDLE)
			KillTimer(g_hClientMicTimers[client]);
		g_hClientMicTimers[client] = INVALID_HANDLE;
	}
}


public OnClientDisconnect(client)
{
	if(is_csgo)
	{
		if (g_iHookID[client] != -1)
		{
			DHookRemoveHookID(g_iHookID[client]);
			
			g_iHookID[client] = -1;
		}
	}
	if (g_hClientMicTimers[client] != INVALID_HANDLE)
		KillTimer(g_hClientMicTimers[client]);
	g_hClientMicTimers[client] = INVALID_HANDLE;
}

public MRESReturn:Hook_ProcessVoiceData(Address:this_adr, Handle:hParams)
{
	new Address:pIClient = this_adr - Address:4;
	new client = GetPlayerSlot(pIClient) + 1;
		
	if (g_hClientMicTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hClientMicTimers[client]);
		g_hClientMicTimers[client] = CreateTimer(0.3, Timer_ClientMicUsage, GetClientUserId(client));
	}
		
	if (g_hClientMicTimers[client] == INVALID_HANDLE)
	{
		g_hClientMicTimers[client] = CreateTimer(0.3, Timer_ClientMicUsage, GetClientUserId(client));
	}

	new bool:returnBool = true;
	Call_StartForward(g_hOnClientTalking);
	Call_PushCell(client);
	Call_Finish(_:returnBool);

	if (!returnBool)
	{
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn:CSGOVoicePost(param1, Handle:hReturn) 
{ 	
	if (g_hClientMicTimers[param1] != INVALID_HANDLE)
	{
		KillTimer(g_hClientMicTimers[param1]);
		g_hClientMicTimers[param1] = CreateTimer(0.3, Timer_ClientMicUsage, GetClientUserId(param1));
	}
		
	if (g_hClientMicTimers[param1] == INVALID_HANDLE)
	{
		g_hClientMicTimers[param1] = CreateTimer(0.3, Timer_ClientMicUsage, GetClientUserId(param1));
	}

	new bool:returnBool = true;
	Call_StartForward(g_hOnClientTalking);
	Call_PushCell(param1);
	Call_Finish(_:returnBool);

	if (!returnBool)
	{
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}  

public Action:Timer_ClientMicUsage(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	g_hClientMicTimers[client] = INVALID_HANDLE;
	
	Call_StartForward(g_hOnClientTalkingEnd);
	Call_PushCell(client);
	Call_Finish();
}

/*
* Internal Functions
* Credits go to GoD-Tony
*/
stock Handle:GetConfig()
{
	static Handle:hGameConf = INVALID_HANDLE;
	
	if (hGameConf == INVALID_HANDLE)
	{
		hGameConf = LoadGameConfigFile("voiceannounce_ex.games");
	}
	
	return hGameConf;
}

stock Address:GetBaseServer()
{
	static Address:pBaseServer = Address_Null;
	
	if (pBaseServer == Address_Null)
	{
		pBaseServer = GameConfGetAddress(GetConfig(), "CBaseServer");
	}
	
	return pBaseServer;
}

stock Address:GetIClient(slot)
{
	static Handle:hGetClient = INVALID_HANDLE;
	
	if (hGetClient == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetConfig(), SDKConf_Virtual, "CBaseServer::GetClient");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		hGetClient = EndPrepSDKCall();
	}
	
	return Address:SDKCall(hGetClient, GetBaseServer(), slot);
}

stock GetPlayerSlot(Address:pIClient)
{
	static Handle:hPlayerSlot = INVALID_HANDLE;
	
	if (hPlayerSlot == INVALID_HANDLE)
	{
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetFromConf(GetConfig(), SDKConf_Virtual, "CBaseClient::GetPlayerSlot");
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		hPlayerSlot = EndPrepSDKCall();
	}
	
	return SDKCall(hPlayerSlot, pIClient);
}

stock Address:GetIMsgHandler(client)
{
	return GetIClient(client - 1) + Address:4;
}