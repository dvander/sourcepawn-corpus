#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D2] CAI Concept API",
	author = "BHaType",
	description = "Provide single native for vocalize",
	version = "0.1",
	url = "N/A"
}


int g_iOffests[2];

Handle g_hConcept;
Address pAddr, pStringAddr;

public int NAT_CAI_Concept(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	
	int lenght;
	
	GetNativeStringLength(2, lenght);
	lenght += 1;
	
	if (!lenght)
		return 0;
	
	char[] szString = new char[lenght];
	
	GetNativeString(2, szString, lenght);
	
	Store(pStringAddr, szString, lenght);
	
	SDKCall(g_hConcept, 0, client);
	
	RestoreOriginal();
	
	return 0;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("CAI_Concept", NAT_CAI_Concept);
	return APLRes_Success;
}

public void OnPluginStart()
{
	GameData hConf = new GameData("CAI_Concept");
	
	g_iOffests[0] = hConf.GetOffset("Offset");
	g_iOffests[1]++;
	
	if (g_iOffests[0] == 32)
		g_iOffests[1] = 4;
	
	pAddr = hConf.GetAddress("CAI_Concept");
	
	pStringAddr = view_as<Address>(LoadFromAddress(pAddr + view_as<Address>(g_iOffests[0]) + view_as<Address>(g_iOffests[1]), NumberType_Int32));

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
	PrepSDKCall_SetFromConf(hConf, SDKConf_Signature, "CAI_Concept");
	g_hConcept = EndPrepSDKCall();
}

void RestoreOriginal()
{
	static const char g_szOriginal[] = "UseAdrenaline";
	int size = sizeof (g_szOriginal);
	
	Store(pStringAddr, g_szOriginal, size);
}

void Store(Address addr, const char[] buffer, int lenght)
{
	for (int i; i < lenght; i++)
	{
		StoreToAddress(addr + view_as<Address>(i), buffer[i], NumberType_Int8);
	}
}

stock void Print(Address addr, int lenght)
{
	char[] szString = new char[lenght];
	
	for (int i; i < lenght; i++)
	{
		szString[i] = view_as<char>(LoadFromAddress(addr + view_as<Address>(i), NumberType_Int8));
	}
	
	PrintToServer(szString);
}