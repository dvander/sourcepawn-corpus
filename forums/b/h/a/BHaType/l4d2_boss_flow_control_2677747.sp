#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define ConfigSettings "data/l4d2_spawn_flow_control.cfg"

public Plugin myinfo = 
{
	name = "[L4D2] Boss Flow Control",
	author = "BHaType",
	description = "Spawns witch/tank via flow",
	version = "0.0",
	url = "0xA2"
};

enum struct pSettings
{
	float iTankFlow;
	int iTanks;
	
	float iWitchFlow;
	int iWithes;
	
	float iMustTankFlow;
	float iMustWitchFlow;
	
	int iTries;
}

Handle g_hSpawnTank, g_hSpawnWitch, g_hGetSpawn, g_hMaxFlow, g_hIntroState;
Address TheZombieManager, TheNavAreas;
int TheCount, g_iTanks, g_iWitches;
float g_flEveryWitchFlow, g_flEveryTankFlow;
bool g_bLoaded;
pSettings Settings;

static float g_flMaxFlow;

methodmap Address
{
	property float MaxFlow
    {
        public get()
		{
			return !(g_flMaxFlow) ? ((g_flMaxFlow = SDKCall(g_hMaxFlow))) : g_flMaxFlow;
		}
    }
	
	property float Flow
    {
        public get()
		{
			return view_as<float>(LoadFromAddress(this + view_as<Address>(340), NumberType_Int32));
		}
    }
	
	public static float ByPercent (float flFlow)
	{
		return flFlow * 100.0 / TheNavAreas.MaxFlow;
	}
	
	public void Origin (float vBuffer[3])
	{
		float vMins[3], vMaxs[3];
		
		vMins[0] = view_as<float>(LoadFromAddress(this + view_as<Address>(4), NumberType_Int32));
		vMins[1] = view_as<float>(LoadFromAddress(this + view_as<Address>(8), NumberType_Int32));
		vMins[2] = view_as<float>(LoadFromAddress(this + view_as<Address>(12), NumberType_Int32));
		
		vMaxs[0] = view_as<float>(LoadFromAddress(this + view_as<Address>(16), NumberType_Int32));
		vMaxs[1] = view_as<float>(LoadFromAddress(this + view_as<Address>(20), NumberType_Int32));
		vMaxs[2] = view_as<float>(LoadFromAddress(this + view_as<Address>(24), NumberType_Int32));
		
		AddVectors(vMins, vMaxs, vBuffer);
		ScaleVector(vBuffer, 0.5);
	}
	
	public static Address NearestArea(float vOrigin[3])
	{
		Address iResult, iArea;
		float vPos[3], flSave, flDistance = 666666.666666;
		
		for (int i = 1; i <= TheCount; i++)
		{
			iArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(4 * GetRandomInt(0, TheCount)), NumberType_Int32));
			
			if (iArea == Address_Null || LoadFromAddress(iArea + view_as<Address>(84), NumberType_Int32) != 0x20000000)
				continue;
		
			iArea.Origin(vPos);
			
			if ((flSave = GetVectorDistance(vPos, vOrigin)) < flDistance)
			{
				flDistance = flSave;
				iResult = iArea;
			}
		}
		
		return iResult;
	}
	
	property float FurthestFlow
    {
        public get()
		{
			float flResult, flSave, vOrigin[3];
			Address iArea;
			
			for (int i = 1; i <= MaxClients; i++)
			{
				if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i))
					continue;
				
				GetClientAbsOrigin(i, vOrigin);
				iArea = Address.NearestArea (vOrigin);
				
				if (iArea == Address_Null)
					continue;
					
				if ((flSave = iArea.Flow) > flResult)
					flResult = flSave;
			}
			
			return flResult;
		}
    }
};

public void OnGameFrame ()
{
	if (!IsServerProcessing() || SDKCall(g_hIntroState) || !g_bLoaded)
		return;
		
	float flFlow = Address.ByPercent(TheNavAreas.FurthestFlow);
	int index;
	
	if (((flFlow >= g_flEveryTankFlow && g_iTanks < Settings.iTanks || flFlow >= Settings.iMustTankFlow && Settings.iMustTankFlow > 0.0 && g_iTanks < Settings.iTanks) && (index = 8)) || (flFlow >= g_flEveryWitchFlow && g_iWitches < Settings.iWithes || flFlow >= Settings.iMustWitchFlow && Settings.iMustWitchFlow > 0.0 && g_iWitches < Settings.iWithes) && (index = 7))
	{
		float vOrigin[3];
		
		SDKCall(g_hGetSpawn, TheZombieManager, index, Settings.iTries, 0, vOrigin);
		
		switch (index)
		{
			case 8:
			{
				SDKCall(g_hSpawnTank, TheZombieManager, vOrigin, GetRandomFloat(0.0, 360.0));
				PrintToChatAll("Tank");
				
				g_iTanks++;
				if (g_flEveryTankFlow != 99999999999.666) 
					g_flEveryTankFlow = Settings.iTankFlow / Settings.iTanks * g_iTanks;
			}
			case 7:
			{
				SDKCall(g_hSpawnWitch, TheZombieManager, vOrigin, 0.0);
				PrintToChatAll("Witch");
				
				g_iWitches++;
				
				if (g_flEveryWitchFlow != 99999999999.666) 
					g_flEveryWitchFlow = Settings.iWitchFlow / Settings.iWithes * g_iWitches;
			}
		}
	}
}

public void OnPluginStart()
{
	GameData hData = new GameData("l4d2_boss_flow_control");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "ZombieManager::SpawnTank");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	g_hSpawnTank = EndPrepSDKCall();	
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "ZombieManager::SpawnWitch");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_QAngle, SDKPass_ByRef);
	g_hSpawnWitch = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "ZombieManager::GetRandomPZSpawnPosition");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef, _, VENCODE_FLAG_COPYBACK);
	g_hGetSpawn = EndPrepSDKCall();	
	
	StartPrepSDKCall(SDKCall_Static);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "GetMaxFlowDistance");
	PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
	g_hMaxFlow = EndPrepSDKCall();
		
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(hData, SDKConf_Signature, "CTerrorGameRules::IsInIntro");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hIntroState = EndPrepSDKCall();
	
	TheZombieManager = hData.GetAddress("TheZombieManager");
	
	delete hData;
	
	hData = new GameData("l4d2_nav_loot");
	
	TheNavAreas = hData.GetAddress("TheNavAreas");
	Address iAddress = hData.GetAddress("TheCount");
	
	if (iAddress == Address_Null)
		TheCount = GetValidAreasCount();
	else
		TheCount = LoadFromAddress(hData.GetAddress("TheCount"), NumberType_Int32) - 1;
	
	delete hData;
	
	HookEvent("round_start", EvStart, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("text", Text);
}

public void OnMapEnd()
{
	g_bLoaded = false;
	g_flMaxFlow = 0.0;
	g_iTanks = 0;
	g_iWitches = 0;
}

public void OnMapStart()
{
	ResetStruct();
	LoadConfig();
}

public void EvStart (Event event, const char[] name, bool dontbroadcast)
{
	g_iTanks = 0;
	g_iWitches = 0;
}

public Action Text (int client, int args)
{
	PrintToChatAll("Furthest Flow %f MaxFlow %f Proccents %f", TheNavAreas.FurthestFlow, TheNavAreas.MaxFlow, Address.ByPercent(TheNavAreas.FurthestFlow));
}

void ResetStruct ()
{
	Settings.iTankFlow = 0.0;
	Settings.iTanks = 0;
	
	Settings.iWitchFlow = 0.0;
	Settings.iWithes = 0;
	
	Settings.iMustTankFlow = 0.0;
	Settings.iMustWitchFlow = 0.0;
}

int GetValidAreasCount ()
{
	int index;
	Address iArea;
	
	for (int i = 1; i <= 10000; i++)
	{
		iArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(4 * i), NumberType_Int32));
		
		if (iArea == Address_Null)
			break;
			
		index++;
	}
	
	return index;
}

void LoadConfig ()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof szPath, ConfigSettings);
	
	if (!FileExists(szPath))
	{
		SetFailState("[Flow Spawn Control] Config not found, unloading....");
		return;
	}
	
	KeyValues hKeyValues = new KeyValues("Settings");
	hKeyValues.ImportFromFile(szPath);
	
	Settings.iTankFlow = hKeyValues.GetFloat("Tank Flow");
	Settings.iWitchFlow = hKeyValues.GetFloat("Witch Flow");
	
	Settings.iTanks = hKeyValues.GetNum("Max Tanks");
	Settings.iWithes = hKeyValues.GetNum("Max Witches");
	
	Settings.iTries = hKeyValues.GetNum("Tries");
	
	char szMap[64];
	GetCurrentMap(szMap, sizeof szMap);

	if	(hKeyValues.JumpToKey(szMap))
	{
		Settings.iMustTankFlow = hKeyValues.GetFloat("Tank Flow Spawn");
		Settings.iMustWitchFlow = hKeyValues.GetFloat("Witch Flow Spawn");
		
		Settings.iTankFlow = hKeyValues.GetFloat("Tank Flow");
		Settings.iWitchFlow = hKeyValues.GetFloat("Witch Flow");
		
		Settings.iTanks = hKeyValues.GetNum("Max Tanks");
		Settings.iWithes = hKeyValues.GetNum("Max Witches");
		
		Settings.iTries = hKeyValues.GetNum("Tries");
	}
	
	g_flEveryTankFlow = Settings.iTankFlow / Settings.iTanks;
	g_flEveryWitchFlow = Settings.iWitchFlow / Settings.iWithes;
	
	if (g_flEveryTankFlow <= 0.0)
		g_flEveryTankFlow = 99999999999.666;
		
	if (g_flEveryWitchFlow <= 0.0)
		g_flEveryWitchFlow = 99999999999.666;
	
	hKeyValues.Rewind();
	delete hKeyValues;
	
	LogMessage("[Flow Spawn Control] Configs has been successfully loaded");
	g_bLoaded = true;
}