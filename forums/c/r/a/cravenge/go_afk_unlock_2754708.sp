#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.3"

bool bIsL4D;
Address aGoAFK[4] = {Address_Null, ...};

static int iOriginalBytes_GoAFK[8] = {-1, ...};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion ev_RetVal = GetEngineVersion();
	if (ev_RetVal != Engine_Left4Dead && ev_RetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "[GoAFK Unlock] Plugin Supports L4D And L4D2 Only!");
		return APLRes_SilentFailure;
	}
	
	bIsL4D = (ev_RetVal == Engine_Left4Dead);
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "[L4D/L4D2] \"go_away_from_keyboard\" Unlock",
	author = "cravenge",
	description = "Lets Players Be Able To Idle All The Time.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=333815"
};

public void OnPluginStart()
{
	GameData gd_GoAFK = FetchGameData("go_afk_unlock");
	if (gd_GoAFK == null)
	{
		SetFailState("[GoAFK Unlock] Game Data Not Found!");
	}
	
	int iOffset_GoAFK;
	
	aGoAFK[0] = gd_GoAFK.GetAddress("PlayerPreThink");
	if (aGoAFK[0] != Address_Null)
	{
		aGoAFK[1] = aGoAFK[0];
		
		iOffset_GoAFK = gd_GoAFK.GetOffset("PreThink_CompetitiveCondition");
		if (iOffset_GoAFK != -1)
		{
			if (LoadFromAddress(aGoAFK[0] + view_as<Address>(iOffset_GoAFK), NumberType_Int8) == 0x0F)
			{
				aGoAFK[0] += view_as<Address>(iOffset_GoAFK);
				
				for (int i = 0; i < 6; i++)
				{
					iOriginalBytes_GoAFK[i] = LoadFromAddress(aGoAFK[0] + view_as<Address>(i), NumberType_Int8);
					
					StoreToAddress(aGoAFK[0] + view_as<Address>(i), 0x90, NumberType_Int8);
				}
				
				PrintToServer("[GoAFK Unlock] Idling Is Now Unrestricted!");
			}
			else
			{
				SetFailState("[GoAFK Unlock] Offset \"PreThink_CompetitiveCondition\" Incorrect!");
			}
		}
		else
		{
			SetFailState("[GoAFK Unlock] Offset \"PreThink_CompetitiveCondition\" Missing!");
		}
		
		iOffset_GoAFK = gd_GoAFK.GetOffset("PreThink_HumanSurvivorsCondition");
		if (iOffset_GoAFK != -1)
		{
			if (LoadFromAddress(aGoAFK[1] + view_as<Address>(iOffset_GoAFK), NumberType_Int8) == 0x01)
			{
				aGoAFK[1] += view_as<Address>(iOffset_GoAFK);
				
				StoreToAddress(aGoAFK[1], 0x00, NumberType_Int8);
				
				PrintToServer("[GoAFK Unlock] Auto Idle Now Works Everytime!");
			}
			else
			{
				SetFailState("[GoAFK Unlock] Offset \"PreThink_HumanSurvivorsCondition\" Incorrect!");
			}
		}
		else
		{
			SetFailState("[GoAFK Unlock] Offset \"PreThink_HumanSurvivorsCondition\" Missing!");
		}
	}
	else
	{
		SetFailState("[GoAFK Unlock] Address \"PlayerPreThink\" Missing!");
	}
	
	if (!bIsL4D)
	{
		aGoAFK[2] = gd_GoAFK.GetAddress("PlayerGoingAFK");
		if (aGoAFK[2] != Address_Null)
		{
			aGoAFK[3] = aGoAFK[2];
			
			iOffset_GoAFK = gd_GoAFK.GetOffset("GoAFKInput_CompetitiveCondition");
			if (iOffset_GoAFK != -1)
			{
				int iByte = LoadFromAddress(aGoAFK[2] + view_as<Address>(iOffset_GoAFK), NumberType_Int8);
				if (iByte == 0x75 || iByte == 0x74)
				{
					aGoAFK[2] += view_as<Address>(iOffset_GoAFK);
					
					for (int i = 0; i < 2; i++)
					{
						iOriginalBytes_GoAFK[i + 6] = LoadFromAddress(aGoAFK[2] + view_as<Address>(i), NumberType_Int8);
					}
					
					StoreToAddress(aGoAFK[2], (iByte != 0x74) ? 0x90 : 0xEB, NumberType_Int8);
					if (iByte != 0x74)
					{
						StoreToAddress(aGoAFK[2] + view_as<Address>(1), 0x90, NumberType_Int8);
					}
					
					PrintToServer("[GoAFK Unlock] \"go_away_from_keyboard\" Is Now Unrestricted!");
				}
				else
				{
					SetFailState("[GoAFK Unlock] Offset \"GoAFKInput_CompetitiveCondition\" Incorrect!");
				}
			}
			else
			{
				SetFailState("[GoAFK Unlock] Offset \"GoAFKInput_CompetitiveCondition\" Missing!");
			}
			
			iOffset_GoAFK = gd_GoAFK.GetOffset("GoAFKInput_HumanSurvivorsCondition");
			if (iOffset_GoAFK != -1)
			{
				if (LoadFromAddress(aGoAFK[3] + view_as<Address>(iOffset_GoAFK), NumberType_Int8) == 0x01)
				{
					aGoAFK[3] += view_as<Address>(iOffset_GoAFK);
					
					StoreToAddress(aGoAFK[3], 0x00, NumberType_Int8);
					
					PrintToServer("[GoAFK Unlock] \"go_away_from_keyboard\" Now Works Everytime!");
				}
				else
				{
					SetFailState("[GoAFK Unlock] Offset \"GoAFKInput_HumanSurvivorsCondition\" Incorrect!");
				}
			}
			else
			{
				SetFailState("[GoAFK Unlock] Offset \"GoAFKInput_HumanSurvivorsCondition\" Missing!");
			}
		}
		else
		{
			SetFailState("[GoAFK Unlock] Address \"PlayerGoingAFK\" Missing!");
		}
	}
	
	delete gd_GoAFK;
	
	CreateConVar("go_afk_unlock_version", PLUGIN_VERSION, "\"go_away_from_keyboard\" Unlock Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnPluginEnd()
{
	int i;
	
	if (aGoAFK[0] != Address_Null)
	{
		PrintToServer("[GoAFK Unlock] Bringing Back Restriction Of Idling...");
		
		for (i = 0; i < 6; i++)
		{
			StoreToAddress(aGoAFK[0] + view_as<Address>(i), iOriginalBytes_GoAFK[i], NumberType_Int8);
			
			iOriginalBytes_GoAFK[i] = -1;
		}
	}
	
	if (aGoAFK[1] != Address_Null)
	{
		PrintToServer("[GoAFK Unlock] Restoring Original Behavior Of Auto Idle...");
		
		StoreToAddress(aGoAFK[1], 0x01, NumberType_Int8);
	}
	
	if (bIsL4D)
	{
		return;
	}
	
	if (aGoAFK[2] != Address_Null)
	{
		PrintToServer("[GoAFK Unlock] Bringing Back Restriction Of \"go_away_from_keyboard\"...");
		
		for (i = 0; i < 2; i++)
		{
			StoreToAddress(aGoAFK[2] + view_as<Address>(i), iOriginalBytes_GoAFK[i + 6], NumberType_Int8);
			
			iOriginalBytes_GoAFK[i + 6] = -1;
		}
	}
	
	if (aGoAFK[3] != Address_Null)
	{
		PrintToServer("[GoAFK Unlock] Restoring Original Behavior Of \"go_away_from_keyboard\"...");
		
		StoreToAddress(aGoAFK[3], 0x01, NumberType_Int8);
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
			SetFailState("[GoAFK Unlock] Game Data Creation Aborted!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"#default\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"PlayerPreThink\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"CTerrorPlayer::PreThink\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CTerrorPlayer::PreThink\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN13CTerrorPlayer8PreThinkEv\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"PreThink_CompetitiveCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"290\"");
		fileTemp.WriteLine("				\"linux\"		\"134\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"PreThink_HumanSurvivorsCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"406\"");
		fileTemp.WriteLine("				\"linux\"		\"1036\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CTerrorPlayer::PreThink\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x83\\x2A\\x2A\\x56\\x57\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x8B\"");
		fileTemp.WriteLine("				/* 83 ? ? 56 57 8B ? E8 ? ? ? ? 8B ? E8 ? ? ? ? 8B ? 8B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"PlayerGoingAFK\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"CTerrorPlayer::Input_GoAwayFromKeyboard\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"PreThink_CompetitiveCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"309\"");
		fileTemp.WriteLine("				\"linux\"		\"295\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"PreThink_HumanSurvivorsCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"428\"");
		fileTemp.WriteLine("				\"linux\"		\"450\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"GoAFKInput_CompetitiveCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"10\"");
		fileTemp.WriteLine("				\"linux\"		\"14\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"GoAFKInput_HumanSurvivorsCondition\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"38\"");
		fileTemp.WriteLine("				\"linux\"		\"130\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"CTerrorPlayer::PreThink\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x55\\x8B\\x2A\\x83\\x2A\\x2A\\xA1\\x2A\\x2A\\x2A\\x2A\\x33\\x2A\\x89\\x2A\\x2A\\x56\\x57\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xE8\"");
		fileTemp.WriteLine("				/* 55 8B ? 83 ? ? A1 ? ? ? ? 33 ? 89 ? ? 56 57 8B ? E8 ? ? ? ? 8B ? E8 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"CTerrorPlayer::Input_GoAwayFromKeyboard\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN13CTerrorPlayer24Input_GoAwayFromKeyboardEv\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x57\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x84\\x2A\\x75\\x2A\\x56\\x6A\"");
		fileTemp.WriteLine("				/* 57 8B ? E8 ? ? ? ? 84 ? 75 ? 56 6A */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	
	return new GameData(file);
}

