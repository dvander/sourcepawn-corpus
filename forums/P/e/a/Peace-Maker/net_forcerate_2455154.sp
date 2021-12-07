#pragma semicolon 1
#include <sdktools>
#pragma newdecls required

ConVar net_forcerate;
Address engine;
Handle hGetPlayerNetInfo;
int m_RateOffset;

public Plugin myinfo = 
{
	name = "Forcerate",
	author = "Tobba, Peace-Maker",
	description = "Forces network rates beyond normal limits",
	version = "1.0",
	url = ""
}

public void OnPluginStart()
{
	net_forcerate = CreateConVar("net_forcerate", "0");
	
	Handle hGameConf = LoadGameConfigFile("net_forcerate.games");
	if (!hGameConf)
		SetFailState("Failed to find net_forcerate.games.txt gamedata file.");
	
	// Grab all the required info from the gamedata file.
	char sInterfaceName[64];
	if(!GameConfGetKeyValue(hGameConf, "INTERFACEVERSION_VENGINESERVER", sInterfaceName, sizeof(sInterfaceName)))
	{
		CloseHandle(hGameConf);
		SetFailState("Failed to get INTERFACEVERSION_VENGINESERVER interface name");
	}
	
	m_RateOffset = GameConfGetOffset(hGameConf, "m_Rate");
	if (m_RateOffset == -1)
	{
		CloseHandle(hGameConf);
		SetFailState("Failed to find m_Rate offset in gamedata.");
	}
	
	// Prepare a call to CreateInterface.
	StartPrepSDKCall(SDKCall_Static);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CreateInterface"))
	{
		CloseHandle(hGameConf);
		SetFailState("Failed to find CreateInterface symbol.");
	}
	
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Pointer, VDECODE_FLAG_ALLOWNULL);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain); 
	Handle hCreateInterface = EndPrepSDKCall();
	if (!hCreateInterface)
	{
		CloseHandle(hGameConf);
		SetFailState("Failed to create SDK call for CreateInterface.");
	}
	
	// Get the IVEngineServer pointer
	engine = view_as<Address>(SDKCall(hCreateInterface, sInterfaceName, 0));
	if (engine == Address_Null)
	{
		CloseHandle(hGameConf);
		SetFailState("Failed to get IVEngineServer interface pointer.");
	}
	
	// Prepare a call to IVEngineServer::GetPlayerNetInfo
	StartPrepSDKCall(SDKCall_Raw);
	if (!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "GetPlayerNetInfo"))
	{
		CloseHandle(hGameConf);
		SetFailState("Failed to find GetPlayerNetInfo offset.");
	}
	
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	
	hGetPlayerNetInfo = EndPrepSDKCall();
	if (!hGetPlayerNetInfo)
	{
		CloseHandle(hGameConf);
		SetFailState("Failed to create SDK call for IVEngineServer::GetPlayerNetInfo.");
	}
	
	CloseHandle(hGameConf);
}

public void OnClientSettingsChanged(int client)
{
	if (IsFakeClient(client))
		return;
	
	int forcerate = net_forcerate.IntValue;
	if (forcerate > 0)
		SetRate(client, forcerate);
}

void SetRate(int client, int forcerate)
{
	Address netchannel = GetPlayerNetInfo(client);
	if (netchannel == Address_Null)
		return;
	
	Address rateaddr = netchannel + view_as<Address>(m_RateOffset);
	if (LoadFromAddress(rateaddr, NumberType_Int32) != GetClientDataRate(client))
		LogError("Rate offset might be wrong. Actual rate: %d, Rate at offset: %d", GetClientDataRate(client), LoadFromAddress(rateaddr, NumberType_Int32));
	else
		StoreToAddress(rateaddr, forcerate, NumberType_Int32);
}

Address GetPlayerNetInfo(int client)
{
	return view_as<Address>(SDKCall(hGetPlayerNetInfo, engine, client));
}
