#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.1"

bool bIsL4D;
Address aVTB = Address_Null;

static int iOriginalBytes_VTB[2] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev_RetVal = GetEngineVersion();
	if (ev_RetVal != Engine_Left4Dead && ev_RetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[VTB] Plugin Supports L4D And L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	bIsL4D = (ev_RetVal == Engine_Left4Dead);
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D/L4D2] Vigilant Tank Behavior",
	author = "cravenge",
	description = "Forces Tanks To Take Initiative In Attacking After Spawning.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=334690"
};

public void OnPluginStart()
{
	GameData gd_VTB = FetchGameData("vigilant_tank_behavior");
	if (gd_VTB == null)
	{
		SetFailState("[VTB] Game Data Not Found!");
	}
	
	aVTB = gd_VTB.GetAddress("ActionInitialized_TB");
	if (aVTB != Address_Null)
	{
		int iOffset_VTB = gd_VTB.GetOffset("TBInitialContainedAction_FinaleCondition");
		if (iOffset_VTB != -1)
		{
			int iByte = LoadFromAddress(aVTB + view_as<Address>(iOffset_VTB), NumberType_Int8);
			if (iByte == 0x75 || iByte == 0x74)
			{
				aVTB += view_as<Address>(iOffset_VTB);
				
				for (int i = 0; i < 2; i++)
				{
					iOriginalBytes_VTB[i] = LoadFromAddress(aVTB + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(aVTB, (iByte != 0x74) ? 0xEB : 0x90, NumberType_Int8);
				if (iByte != 0x75)
				{
					StoreToAddress(aVTB + view_as<Address>(1), 0x90, NumberType_Int8);
				}
				
				PrintToServer("[VTB] Patched Tank's Behavior To Remain Alert At All Times!");
			}
			else
			{
				SetFailState("[VTB] Offset \"TBInitialContainedAction_FinaleCondition\" Incorrect!");
			}
		}
		else
		{
			SetFailState("[VTB] Offset \"TBInitialContainedAction_FinaleCondition\" Missing!");
		}
	}
	else
	{
		SetFailState("[VTB] Address \"ActionInitialized_TB\" Missing!");
	}
	
	delete gd_VTB;
	
	CreateConVar("vigilant_tank_behavior_version", PLUGIN_VERSION, "Vigilant Tank Behavior Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnPluginEnd()
{
	if (aVTB == Address_Null)
	{
		return;
	}
	
	PrintToServer("[VTB] Changes Made To Tank's Behavior Have Been Reverted!");
	
	for (int i = 0; i < 2; i++)
	{
		StoreToAddress(aVTB + view_as<Address>(i), iOriginalBytes_VTB[i], NumberType_Int8);
		
		iOriginalBytes_VTB[i] = -1;
	}
}

GameData FetchGameData(const char[] file)
{
	char sFilePath[128];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/%s.txt", file);
	if (!FileExists(sFilePath))
	{
		File fileTemp = OpenFile(sFilePath, "w");
		if (fileTemp == null)
		{
			SetFailState("[VTB] Game Data Creation Aborted!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"#default\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ActionInitialized_TB\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"TankBehavior::InitialContainedAction\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TankBehavior::InitialContainedAction\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN12TankBehavior22InitialContainedActionEP4Tank\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TBInitialContainedAction_FinaleCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"49\"");
		fileTemp.WriteLine("				\"linux\"		\"101\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TankBehavior::InitialContainedAction\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\xA1\\x2A\\x2A\\x2A\\x2A\\x80\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x75\\x2A\\x80\\x2A\\x2A\\x2A\\x75\"");
		fileTemp.WriteLine("				/* A1 ? ? ? ? 80 ? ? ? ? ? ? 75 ? 80 ? ? ? 75 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TBInitialContainedAction_FinaleCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"16\"");
		fileTemp.WriteLine("				\"linux\"		\"23\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TankBehavior::InitialContainedAction\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\" \"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x84\\x2A\\x75\\x2A\\x8B\"");
		fileTemp.WriteLine("				/* 55 8B ? 8B ? ? ? ? ? E8 ? ? ? ? 84 ? 75 ? 8B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	
	return new GameData(file);
}

