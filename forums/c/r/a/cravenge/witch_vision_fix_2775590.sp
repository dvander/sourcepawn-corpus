#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.3"

#define NOP_BYTE 0x90

enum OS
{
	OS_Windows,
	OS_Linux
}

OS os_Bit;

Address aWVF[2];
EngineVersion ev_Bit;

int iOriginalBytes_WVF[47] = {-1, ...}, iExtraOGBytes_WVF[23] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	ev_Bit = GetEngineVersion();
	if (ev_Bit != Engine_Left4Dead && ev_Bit != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This is for L4D and L4D2 only");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "Witch Vision Fix",
	author = "cravenge",
	description = "Resolves an issue with calm Witches unable to spot incapacitated survivors",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=337119"
};

public void OnPluginStart()
{
	GameData gd_Temp = FetchGameData("witch_vision_fix");
	if (gd_Temp == null)
	{
		SetFailState("Game data file not found!");
	}
	
	os_Bit = GetServerOS();
	
	Address aTemp = gd_Temp.GetAddress("IsIgnored_WV");
	if (aTemp != Address_Null)
	{
		int iTemp = gd_Temp.GetOffset("WVIsIgnored_HasEntityConfirmation");
		if (iTemp != -1)
		{
			aWVF[0] = aTemp + view_as<Address>(iTemp);
			
			iTemp = gd_Temp.GetOffset("WVIsIgnored_PatchCount");
			if (iTemp > 0)
			{
				for (int i; i < iTemp; i++)
				{
					iOriginalBytes_WVF[i] = LoadFromAddress(aWVF[0] + view_as<Address>(i), NumberType_Int8);
					if (!i && iOriginalBytes_WVF[0] != 0x85)
					{
						SetFailState("Offset for \"WVIsIgnored_HasEntityConfirmation\" is incorrect!");
					}
					
					StoreToAddress(aWVF[0] + view_as<Address>(i), (os_Bit == OS_Windows) ? NOP_BYTE : ((ev_Bit == Engine_Left4Dead2 && (2 > i || 3 < i) && 6 > i) ? ((i % 2 != 0) ? ((i == 1) ? 0x4F : 0x4B) : 0xEB) : NOP_BYTE), NumberType_Int8);
				}
				
				PrintToServer("[FIX] Gave the Witches clearer visions!");
			}
			else
			{
				SetFailState("Offset for \"WVIsIgnored_PatchCount\" is either missing or zero!");
			}
		}
		else
		{
			SetFailState("Offset for \"WVIsIgnored_HasEntityConfirmation\" is missing!");
		}
		
		if (os_Bit == OS_Linux && ev_Bit == Engine_Left4Dead)
		{
			iTemp = gd_Temp.GetOffset("WVIsIgnored_IsIncapacitatedCheck");
			if (iTemp != -1)
			{
				aWVF[1] = aTemp + view_as<Address>(iTemp);
				
				for (iTemp = 0; iTemp < 23; iTemp++)
				{
					iExtraOGBytes_WVF[iTemp] = LoadFromAddress(aWVF[1] + view_as<Address>(iTemp), NumberType_Int8);
					if (!iTemp && iExtraOGBytes_WVF[0] != 0x8B)
					{
						SetFailState("Offset for \"WVIsIgnored_IsIncapacitatedCheck\" is incorrect!");
					}
					
					StoreToAddress(aWVF[1] + view_as<Address>(iTemp), NOP_BYTE, NumberType_Int8);
				}
			}
			else
			{
				SetFailState("Offset for \"WVIsIgnored_IsIncapacitatedCheck\" is missing!");
			}
		}
	}
	else
	{
		SetFailState("Address for \"IsIgnored_WV\" returned NULL!");
	}
	
	CreateConVar("witch_vision_fix_version", PLUGIN_VERSION, "Version of the Witch Vision Fix plug-in", FCVAR_NOTIFY);
}

public void OnPluginEnd()
{
	int x, j, iTemp;
	
	for (int i = 1; i > -1; --i)
	{
		if (aWVF[i] == Address_Null)
		{
			continue;
		}
		
		if (i != 1)
		{
			PrintToServer("[FIX] Taking away the enhanced visions of the Witches...");
		}
		
		x = (!i) ? 46 : 22;
		for (j = x; j > -1; --j)
		{
			iTemp = (i) ? iExtraOGBytes_WVF[j] : iOriginalBytes_WVF[j];
			if (iTemp == -1)
			{
				continue;
			}
			
			StoreToAddress(aWVF[i] + view_as<Address>(j), iTemp, NumberType_Int8);
		}
	}
}

GameData FetchGameData(const char[] name)
{
	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "gamedata/%s.txt", name);
	if (!FileExists(sFile))
	{
		File fileTemp = OpenFile(sFile, "w");
		if (fileTemp == null)
		{
			SetFailState("Something went wrong while creating the game data file!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"#default\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"IsIgnored_WV\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"WitchVision::IsIgnored\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"WitchVision::IsIgnored\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"linux\"		\"@_ZNK11WitchVision9IsIgnoredEP11CBaseEntity\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"WVIsIgnored_HasEntityConfirmation\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"122\"");
		fileTemp.WriteLine("				\"linux\"		\"68\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"WVIsIgnored_PatchCount\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"46\"");
		fileTemp.WriteLine("				\"linux\"		\"19\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"WVIsIgnored_IsIncapacitatedCheck\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"linux\"		\"134\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"WitchVision::IsIgnored\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"\\x56\\x57\\x8B\\xF9\\xE8\\x2A\\x2A\\x2A\\x2A\\x84\\xC0\\x8B\"");
		fileTemp.WriteLine("				/* 56 57 8B F9 E8 ? ? ? ? 84 C0 8B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"WVIsIgnored_HasEntityConfirmation\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"133\"");
		fileTemp.WriteLine("				\"linux\"		\"55\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"WVIsIgnored_PatchCount\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"47\"");
		fileTemp.WriteLine("				\"linux\"		\"39\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"WitchVision::IsIgnored\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\xEC\\x56\\x57\\x8B\\xF9\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x75\\x08\\x84\"");
		fileTemp.WriteLine("				/* 55 8B EC 56 57 8B F9 E8 ? ? ? ? 8B 75 08 84 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	return new GameData(name);
}

OS GetServerOS()
{
	char sCmdLine[4];
	GetCommandLine(sCmdLine, sizeof(sCmdLine));
	return (sCmdLine[0] == '.') ? OS_Linux : OS_Windows;
}

