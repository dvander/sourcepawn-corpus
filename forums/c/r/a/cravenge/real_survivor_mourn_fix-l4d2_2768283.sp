#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.2"

Address aRSMF[3];
static int iOriginalBytes_aRSMF[3] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[FIX] Plugin supports L4D2 only!");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D2] Real Survivor Mourn Fix",
	author = "cravenge",
	description = "Makes both survivor sets mourn each other properly",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=335903"
};

public void OnPluginStart()
{
	GameData gd_Temp = FetchGameData("real_survivor_mourn_fix-l4d2");
	if (gd_Temp == null)
	{
		SetFailState("[FIX] Game data file not found!");
	}
	
	Address aTemp = gd_Temp.GetAddress("CheckFriendSightings");
	if (aTemp != Address_Null)
	{
		int iTemp;
		char sTemp[64];
		
		for (int i = 0; i < 3; i++)
		{
			FormatEx(sTemp, sizeof(sTemp), "CheckFriendSightings_CharacterCondition%s", (i != 0) ? ((i != 2) ? "B" : "C") : "A");
			
			iTemp = gd_Temp.GetOffset(sTemp);
			if (iTemp != -1)
			{
				aRSMF[i] = aTemp + view_as<Address>(iTemp);
				
				iOriginalBytes_aRSMF[i] = LoadFromAddress(aRSMF[i], NumberType_Int8);
				if (iOriginalBytes_aRSMF[i] != 0x03 && iOriginalBytes_aRSMF[i] != 0x04)
				{
					SetFailState("Offset for \"%s\" is incorrect!", sTemp);
				}
				
				StoreToAddress(aRSMF[i], iOriginalBytes_aRSMF[i] + 0x04, NumberType_Int8);
				
				PrintToServer("[FIX] Patched \"PlayerSeeDeadPlayer\" concept to check for all 8 characters instead (%i/3)", i + 1);
				
				if (i == 2)
				{
					delete gd_Temp;
				}
			}
			else
			{
				SetFailState("[FIX] Offset for \"%s\" is missing!", sTemp);
			}
		}
	}
	else
	{
		SetFailState("[FIX] Address for \"CheckFriendSightings\" returned NULL!");
	}
	
	CreateConVar("real_survivor_mourn_fix-l4d2_ver", PLUGIN_VERSION, "Version of this plugin", FCVAR_NOTIFY);
}

public void OnPluginEnd()
{
	for (int i = 2; i > -1; --i)
	{
		if (aRSMF[i] == Address_Null)
		{
			continue;
		}
		
		if (i == 0)
		{
			PrintToServer("[FIX] Restoring the original checks for \"PlayerSeeDeadPlayer\" concept...");
		}
		
		StoreToAddress(aRSMF[i], iOriginalBytes_aRSMF[i], NumberType_Int8);
		
		iOriginalBytes_aRSMF[i] = -1;
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
			SetFailState("[FIX] Something went wrong while creating the game data file!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CheckFriendSightings\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"CTerrorPlayer::CheckFriendSightings\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CheckFriendSightings_CharacterConditionA\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"465\"");
		fileTemp.WriteLine("				\"linux\"		\"924\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CheckFriendSightings_CharacterConditionB\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"593\"");
		fileTemp.WriteLine("				\"linux\"		\"1064\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CheckFriendSightings_CharacterConditionC\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"818\"");
		fileTemp.WriteLine("				\"linux\"		\"1341\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CTerrorPlayer::CheckFriendSightings\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN13CTerrorPlayer20CheckFriendSightingsEv\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x81\\x2A\\x2A\\x2A\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x33\\x2A\\x89\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x57\\x33\\x2A\\x89\\x2A\\x2A\\x2A\\x2A\\x2A\\x89\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x39\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\x68\\x2A\\x2A\\x2A\\x2A\\x57\\x57\\x57\\x57\\x8D\\x2A\\x2A\\x2A\\x2A\\x2A\\x51\\x50\\xFF\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x6A\\x2A\\x57\\x68\\x2A\\x2A\\x2A\\x2A\\x57\\x89\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\"");
		fileTemp.WriteLine("				/* 55 8B ? 81 ? ? ? ? ? A1 ? ? ? ? 33 ? 89 ? ? A1 ? ? ? ? 53 56 57 33 ? 89 ? ? ? ? ? 89 ? ? ? ? ? 8B ? 39 ? ? 74 ? 8B ? ? 68 ? ? ? ? 8B ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 68 ? ? ? ? 57 57 57 57 8D ? ? ? ? ? 51 50 FF ? A1 ? ? ? ? 83 ? ? 8B ? ? ? ? ? 8B ? ? 8B ? ? ? ? ? 6A ? 57 68 ? ? ? ? 57 89 ? ? ? ? ? 8B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	
	return new GameData(file);
}

