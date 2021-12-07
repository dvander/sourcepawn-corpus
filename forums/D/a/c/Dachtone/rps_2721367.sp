#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <dhooks>

#define PLUGIN_VERSION 	"1.0"

#define DHookMode_Pre 	false
#define DHookMode_Post 	true

Handle callENTINDEX;

Handle hookSetRPSResult;

int offsetTauntRPSResult;
int offsetReceiverValue;

bool shouldRPS[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Rock, Paper, Scissors",
	author = "Dachtone",
	description = "Cheat in RPS",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/profiles/76561198050338268"
};

public void OnPluginStart()
{
	CreateConVar("rps_version", PLUGIN_VERSION, "Rock, Paper, Scissors Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	
	if (!SetupHooksAndCalls())
		return;
	
	RegAdminCmd("sm_rps", AdminRPS, ADMFLAG_SLAY);
	
	LoadTranslations("common.phrases");
	LoadTranslations("rps.phrases");
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
			OnClientPutInServer(i);
	}
}

bool SetupHooksAndCalls()
{
	// Load GameData
	GameData data = LoadGameConfigFile("rps");
	if (data == null)
	{
		SetFailState("Unable to find the gamedata");
		return false;
	}
	
	/* SetRPSResult */
	
	// DHooks
	Address addressSetRPSResult = GameConfGetAddress(data, "SetRPSResult");
	if (addressSetRPSResult == Address_Null)
	{
		delete data;
		SetFailState("Unable to get SetRPSResult address");
		return false;
	}
	
	// hookSetRPSResult = DHookCreateDetour(addressSetRPSResult, CallConv_THISCALL, ReturnType_Void, ThisPointer_CBaseEntity);
	hookSetRPSResult = DHookCreateDetour(addressSetRPSResult, CallConv_CDECL, ReturnType_Void, ThisPointer_Ignore);
	if (hookSetRPSResult == null)
	{
		delete data;
		SetFailState("Unable to create SetRPSResult detour");
		return false;
	}
	
	// void CTFPlayer::AcceptTauntWithPartner(CTFPlayer *initiator)
	DHookAddParam(hookSetRPSResult, HookParamType_Int, .custom_register = DHookRegister_ESI); // Treat the pointer as an integer
	DHookAddParam(hookSetRPSResult, HookParamType_Int, .custom_register = DHookRegister_EBX); // iInitiator
	DHookAddParam(hookSetRPSResult, HookParamType_Int, .custom_register = DHookRegister_EBP); // Base pointer
	
	// We have to preserve the value in this register for the original function to continue executing,
	// so we'll add it as a parameter and have DHooks copy its original value back upon hook completion
	DHookAddParam(hookSetRPSResult, HookParamType_Int, .custom_register = DHookRegister_ECX);
	
	if (!DHookEnableDetour(hookSetRPSResult, DHookMode_Pre, OnSetRPSResult))
	{
		delete data;
		SetFailState("Failed to enable SetRPSResult detour");
		return false;
	}
	
	/* m_iTauntRPSResult */
	
	char buffer[8];
	if (!GameConfGetKeyValue(data, "m_iTauntRPSResult", buffer, sizeof(buffer)))
	{
		delete data;
		SetFailState("Offset for m_iTauntRPSResult not found");
		return false;
	}
	
	offsetTauntRPSResult = StringToInt(buffer);
	
	/* iReceiver */
	
	if (!GameConfGetKeyValue(data, "iReceiver", buffer, sizeof(buffer)))
	{
		delete data;
		SetFailState("Offset for iReceiver not found");
		return false;
	}
	
	offsetReceiverValue = StringToInt(buffer);
	
	/* ENTINDEX */
	
	// SDKTools
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(data, SDKConf_Signature, "ENTINDEX"))
	{
		delete data;
		EndPrepSDKCall();
		
		SetFailState("Unable to start the preparation of ENTINDEX SDK call");
		
		return false;
	}
	
	// int ENTINDEX(CBaseEntity *pEnt)
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_ByValue); // Treat the pointer as an integer
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
    
	callENTINDEX = EndPrepSDKCall();
	if (callENTINDEX == null)
	{
		delete data;
		SetFailState("Unable to prepare ENTINDEX SDK call");
		return false;
	}
	
	/* Clean up */
	
	delete data;
	
	return true;
}

public void OnClientPutInServer(int client)
{
	shouldRPS[client] = false;
}

public void OnClientDisconnect(int client)
{
	shouldRPS[client] = false;
}

// void CTFPlayer::AcceptTauntWithPartner(CTFPlayer *initiator)
public MRESReturn OnSetRPSResult(Handle params)
{
	Address clientCBaseEntity = DHookGetParam(params, 1);
	int client = GetClientFromCBaseEntity(clientCBaseEntity);
	if (!IsValidClient(client))
		return MRES_Ignored;
	
	int partner = GetEntPropEnt(client, Prop_Send, "m_hHighFivePartner");
	if (!IsValidClient(partner))
		return MRES_Ignored;
	
	if (shouldRPS[client] == shouldRPS[partner])
		return MRES_Ignored;
	
	Address addressTauntRPSResult = clientCBaseEntity + view_as<Address>(offsetTauntRPSResult);
	int result = LoadFromAddress(addressTauntRPSResult, NumberType_Int32);
	if ((shouldRPS[client] && result < 3) || (shouldRPS[partner] && result >= 3))
		return MRES_Ignored;
	
	switch (result)
	{
		case 0:
			result = 5;
		case 1:
			result = 3;
		case 2:
			result = 4;
		case 3:
			result = 1;
		case 4:
			result = 2;
		case 5:
			result = 0;
	}
	StoreToAddress(addressTauntRPSResult, result, NumberType_Int32);
	
	int initiatorValue = DHookGetParam(params, 2);
	
	Address ebp = DHookGetParam(params, 3);
	Address addressReceiverValue = ebp - view_as<Address>(offsetReceiverValue);
	int receiverValue = LoadFromAddress(addressReceiverValue, NumberType_Int32);
	
	DHookSetParam(params, 2, receiverValue);
	StoreToAddress(addressReceiverValue, initiatorValue, NumberType_Int32);
	
	return MRES_ChangedHandled;
}

public Action AdminRPS(int client, int args)
{
	if (args < 1)
	{
		if (!IsValidClient(client))
			return Plugin_Handled;
		
		shouldRPS[client] = !shouldRPS[client];
		
		char name[32];
		GetClientName(client, name, sizeof(name));
		PrintToChat(client, "[SM] %t.", shouldRPS[client] ? "Player will cheat" : "Player will play fair", name);
		LogAction(client, client, "\"%L\" toggled RPS cheat for \"%L\"", client, client);
		
		return Plugin_Handled;
	}
	
	char pattern[32];
	GetCmdArg(1, pattern, sizeof(pattern));
	
	int targets[MAXPLAYERS];
	char target_name[32];
	bool tn_is_ml;
	int count = ProcessTargetString(pattern, client, targets, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml);
	if (count <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < count; i++)
	{
		shouldRPS[targets[i]] = !shouldRPS[targets[i]];
		LogAction(client, targets[i], "\"%L\" toggled RPS cheat for \"%L\"", client, targets[i]);
	}
	
	if (count == 1)
	{
		char name[32];
		GetClientName(targets[0], name, sizeof(name));
		if (IsValidClient(client))
			PrintToChat(client, "[SM] %t.", shouldRPS[targets[0]] ? "Player will cheat" : "Player will play fair", name);
		else
			ReplyToCommand(client, "[SM] %t.", shouldRPS[targets[0]] ? "Player will cheat" : "Player will play fair", name);
	}
	else
	{
		if (IsValidClient(client))
			PrintToChat(client, "[SM] %t.", "Toggled cheat for players", target_name);
		else
			ReplyToCommand(client, "[SM] %t.", "Toggled cheat for players", target_name);
	}
	
	return Plugin_Handled;
}

stock int GetClientFromCBaseEntity(Address pointer)
{
	return SDKCall(callENTINDEX, pointer);
}

stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	if (!IsClientConnected(client) || !IsClientInGame(client))
		return false;
	
	if (IsClientSourceTV(client) || IsClientReplay(client))
		return false;
	
	return true;
}