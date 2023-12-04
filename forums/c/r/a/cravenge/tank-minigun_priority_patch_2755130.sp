#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.4"

Address aTMPP = Address_Null;
static int iOriginalBytes_TMPP[6] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev_RetVal = GetEngineVersion();
	if (ev_RetVal != Engine_Left4Dead && ev_RetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[TMPP] Plugin Supports L4D And L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D/L4D2] Tank - MiniGun Priority Patch",
	author = "cravenge",
	description = "Shifts The Tank's Priority Towards MiniGunners From Highest To None.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333869"
};

public void OnPluginStart()
{
	GameData gd_TMPP = FetchGameData("tank-minigun_priority_patch");
	if (gd_TMPP == null)
	{
		SetFailState("[TMPP] Game Data Not Found!");
	}
	
	aTMPP = gd_TMPP.GetAddress("UpdateTankAttack");
	if (aTMPP != Address_Null)
	{
		int iOffset_TMPP = gd_TMPP.GetOffset("TAUpdate_MiniGunCondition");
		if (iOffset_TMPP != -1)
		{
			int iByte_TMPP = LoadFromAddress(aTMPP + view_as<Address>(iOffset_TMPP), NumberType_Int8);
			if (iByte_TMPP == 0x74 || iByte_TMPP == 0x0F)
			{
				aTMPP += view_as<Address>(iOffset_TMPP);
				
				int i;
				for (i = 0; i < 6; i++)
				{
					iOriginalBytes_TMPP[i] = LoadFromAddress(aTMPP + view_as<Address>(i), NumberType_Int8);
				}
				
				StoreToAddress(aTMPP, (iByte_TMPP != 0x0F) ? 0xEB : 0xE9, NumberType_Int8);
				if (iByte_TMPP != 0x74)
				{
					for (i = 1; i < 6; i++)
					{
						StoreToAddress(aTMPP + view_as<Address>(i), (i == 5) ? 0x00 : GetNextProperOffset(i), NumberType_Int8);
					}
				}
				
				PrintToServer("[TMPP] Tanks Will No Longer Get Baited By MiniGunners From This Point On!");
			}
			else
			{
				SetFailState("[TMPP] Offset \"TAUpdate_MiniGunCondition\" Incorrect!");
			}
		}
		else
		{
			SetFailState("[TMPP] Offset \"TAUpdate_MiniGunCondition\" Missing!");
		}
	}
	else
	{
		SetFailState("[TMPP] Address \"UpdateTankAttack\" Missing!");
	}
	
	delete gd_TMPP;
	
	CreateConVar("tank-minigun_priority_patch_ver", PLUGIN_VERSION, "Tank - MiniGun Priority Patch Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnPluginEnd()
{
	if (aTMPP == Address_Null)
	{
		return;
	}
	
	PrintToServer("[TMPP] Tanks Will Solely Focus On MiniGunners Once Again!");
	
	for (int i = 0; i < 6; i++)
	{
		StoreToAddress(aTMPP + view_as<Address>(i), iOriginalBytes_TMPP[i], NumberType_Int8);
		
		iOriginalBytes_TMPP[i] = -1;
	}
}

GameData FetchGameData(const char[] file)
{
	char sFilePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFilePath, sizeof(sFilePath), "gamedata/%s.txt", file);
	if (!FileExists(sFilePath))
	{
		File fileTemp = OpenFile(sFilePath, "w");
		if (fileTemp == null)
		{
			SetFailState("[TMPP] Game Data Creation Aborted!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"#default\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"UpdateTankAttack\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"TankAttack::Update\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TankAttack::Update\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN10TankAttack6UpdateEP4Tankf\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TAUpdate_MiniGunCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"1339\"");
		fileTemp.WriteLine("				\"linux\"		\"1106\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TankAttack::Update\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x83\\x2A\\x2A\\x53\\x55\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x56\"");
		fileTemp.WriteLine("				/* 83 ? ? 53 55 8B ? ? ? ? ? ? 8B ? ? ? ? ? 8B ? ? ? ? ? 56 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TAUpdate_MiniGunCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"1537\"");
		fileTemp.WriteLine("				\"linux\"		\"979\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"TankAttack::Update\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x81\\xEC\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x57\\x8B\\x2A\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\"");
		fileTemp.WriteLine("				/* 55 8B ? 81 ? ? ? ? ? 53 56 57 8B ? ? 8B ? ? ? ? ? 8B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	
	return new GameData(file);
}

int GetNextProperOffset(int iGivenVal)
{
	int iRetOff = iOriginalBytes_TMPP[iGivenVal + 1];
	static bool bMustAdjust;
	
	if (iGivenVal != 1)
	{
		if (bMustAdjust)
		{
			if (iRetOff == 0xFF)
			{
				iRetOff = 0x00;
			}
			else
			{
				bMustAdjust = false;
			}
			
			iRetOff += 0x01;
		}
		return iRetOff;
	}
	
	if (iRetOff != 0xFF)
	{
		return iRetOff + 0x01;
	}
	
	bMustAdjust = true;
	return 0x00;
}

