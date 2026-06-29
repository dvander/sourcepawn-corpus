#pragma semicolon 1
#include <sourcemod>
#include <MemoryEx/MemoryAlloc>

#define PLUGIN_VERSION "0.4"

OS os_Bit;

Address aCNPF;

static int iOriginalBytes_CNPF[8] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This is for L4D2 only");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D2] Charger Navigation Pathing Fix",
	author = "cravenge",
	description = "Resolves an issue regarding navigation pathing for Chargers",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showpost.php?p=2774066&postcount=11"
};

public void OnPluginStart()
{
	os_Bit = GetServerOS();
	
	CheckInitPEB();
	
	CreateConVar("charger_nav_path_fix-l4d2_ver", PLUGIN_VERSION, "Version of the plug-in", FCVAR_NOTIFY);
}

public void MemoryEx_InitPEB()
{
	GameData gd_Temp = FetchGameData("charger_nav_path_fix-l4d2");
	if (gd_Temp == null)
	{
		SetFailState("Game data file not found!");
	}
	
	int iTemp;
	
	Address aTemp = gd_Temp.GetAddress("CRTNMUpdate");
	if (aTemp != Address_Null)
	{
		iTemp = gd_Temp.GetOffset("CRTNMUpdate_OnGroundConfirmation");
		if (iTemp != -1)
		{
			aCNPF = aTemp + view_as<Address>(iTemp);
			
			for (iTemp = 0; iTemp < 8; iTemp++)
			{
				iOriginalBytes_CNPF[iTemp] = LoadFromAddress(aCNPF + view_as<Address>(iTemp), NumberType_Int8);
				if (!iTemp && ((os_Bit == OS_Linux && iOriginalBytes_CNPF[0] != 0xF6) || (os_Bit == OS_Windows && iOriginalBytes_CNPF[0] != 0x8B)))
				{
					SetFailState("Offset for \"CRTNMUpdate_OnGroundConfirmation\" is incorrect!");
				}
				
				if (os_Bit != OS_Windows && iTemp > 5)
				{
					break;
				}
			}
		}
		else
		{
			SetFailState("Offset for \"CRTNMUpdate_OnGroundConfirmation\" is missing!");
		}
		
		iTemp = gd_Temp.GetOffset("CRTNMUpdate_End");
		if (iTemp != -1)
		{
			aTemp += view_as<Address>(iTemp);
			
			iTemp = LoadFromAddress(aTemp, NumberType_Int8);
			if ((os_Bit != OS_Windows && iTemp != 0xC7) || (os_Bit != OS_Linux && iTemp != 0x8B))
			{
				SetFailState("Offset for \"CRTNMUpdate_End\" is incorrect!");
			}
			
			delete gd_Temp;
		}
		else
		{
			SetFailState("Offset for \"CRTNMUpdate_End\" is missing!");
		}
	}
	else
	{
		SetFailState("Address for \"CRTNMUpdate\" returned NULL!");
	}
	
	iTemp = (os_Bit != OS_Linux) ? 21 : 20;
	
	Address aMem = VirtualAlloc(iTemp);
	if (aMem != Address_Null)
	{
		Address aNext, aOffset;
		
		int[] iBytes = new int[iTemp];
		int x, i;
		
		iBytes[x++] = 0x84;
		iBytes[x++] = 0xC0;
		
		iBytes[x++] = 0x0F;
		iBytes[x++] = 0x84;
		
		aNext = aMem + view_as<Address>(x + 4);
		aOffset = aTemp - aNext;
		
		ArrayPushDword(iBytes, x, view_as<int>(aOffset));
		
		for (i = 0; i < 8; i++)
		{
			if (iOriginalBytes_CNPF[i] == -1)
			{
				continue;
			}
			
			iBytes[x++] = iOriginalBytes_CNPF[i];
		}
		
		iBytes[x++] = 0xE9;
		
		iTemp -= 13;
		
		aNext = aMem + view_as<Address>(x + 4);
		aOffset = aCNPF + view_as<Address>(iTemp);
		
		ArrayPushDword(iBytes, x, view_as<int>(aOffset - aNext));
		
		iTemp += 13;
		StoreToAddressArray(aMem, iBytes, iTemp);
		
		x = 0;
		
		iBytes[x++] = 0xE9;
		
		aNext = aCNPF + view_as<Address>(5);
		aOffset = aMem - aNext;
		
		ArrayPushDword(iBytes, x, view_as<int>(aOffset));
		
		for (i = x; i < 8; i++)
		{
			if (iOriginalBytes_CNPF[i] == -1)
			{
				continue;
			}
			
			iBytes[x++] = 0x90;
		}
		
		StoreToAddressArray(aCNPF, iBytes, x);
		
		PrintToServer("[FIX] Inserted missing validation check for last nav area in \"ChargerReturnToNavMesh::Update\"!");
	}
	else
	{
		SetFailState("No memory block allocated!");
	}
}

public void OnPluginEnd()
{
	if (aCNPF == Address_Null)
	{
		return;
	}
	
	PrintToServer("Extracting last nav area validation check from \"ChargerReturnToNavMesh::Update\"...");
	
	for (int i = 7; i > -1; --i)
	{
		if (iOriginalBytes_CNPF[i] == -1)
		{
			continue;
		}
		
		StoreToAddress(aCNPF + view_as<Address>(i), iOriginalBytes_CNPF[i], NumberType_Int8);
		
		iOriginalBytes_CNPF[i] = -1;
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
			SetFailState("Something went wrong while creating the game data file!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CRTNMUpdate\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"ChargerReturnToNavMesh::Update\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CRTNMUpdate_OnGroundConfirmation\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"23\"");
		fileTemp.WriteLine("				\"linux\"		\"26\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CRTNMUpdate_End\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"202\"");
		fileTemp.WriteLine("				\"linux\"		\"225\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ChargerReturnToNavMesh::Update\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN22ChargerReturnToNavMesh6UpdateEP7Chargerf\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x83\\x2A\\x2A\\x56\\x57\\x8B\\x2A\\x2A\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xFF\\x2A\\x8B\"");
		fileTemp.WriteLine("				/* 55 8B ? 83 ? ? 56 57 8B ? ? 8B ? 8B ? ? ? ? ? 8B ? FF ? 8B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	return new GameData(file);
}

