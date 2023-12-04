#pragma semicolon 1
#include <sourcemod>
#include <dhooks>

#define PLUGIN_VERSION "0.1"

enum OS
{
	OS_Windows,
	OS_Linux
}

OS os_RetVal;

EngineVersion ev_RetVal;

bool bPlayerFix;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	ev_RetVal = GetEngineVersion();
	if (ev_RetVal != Engine_Left4Dead && ev_RetVal != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This is for L4D and L4D2 only");
		return APLRes_SilentFailure;
	}
	
	return APLRes_Success;
}

public Plugin myinfo = 
{
	name = "Survivor Character Fixes",
	author = "cravenge",
	description = "Contains a handful of much needed band-aids for character related stuff",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336328"
};

public void OnPluginStart()
{
	os_RetVal = GetServerOS();
	
	GameData gd_Temp = FetchGameData("survivor_character_fixes");
	if (gd_Temp == null)
	{
		SetFailState("Game data file not found!");
	}
	
	DynamicDetour dd_Temp;
	
	if (ev_RetVal == Engine_Left4Dead2)
	{
		dd_Temp = DynamicDetour.FromConf(gd_Temp, "ConvertToExternalCharacter");
		if (dd_Temp != null)
		{
			if (!dd_Temp.Enable(Hook_Post, dtrConvertToExternalCharacter_Post))
			{
				SetFailState("Failed to make a post detour of \"ConvertToExternalCharacter\"!");
			}
			
			PrintToServer("[FIX] Post detour of \"ConvertToExternalCharacter\" has been successfully made!");
		}
		else
		{
			SetFailState("Signature for \"ConvertToExternalCharacter\" is broken!");
		}
		
		dd_Temp = DynamicDetour.FromConf(gd_Temp, "ForEachSurvivor<PopulateActiveAreaSet>");
		if (dd_Temp != null)
		{
			if (!dd_Temp.Enable(Hook_Pre, dtrForEachSurvivorPAAS_Pre))
			{
				SetFailState("Failed to make a pre-detour of \"ForEachSurvivor<PopulateActiveAreaSet>\"!");
			}
			
			PrintToServer("[FIX] Pre-detour of \"ForEachSurvivor<PopulateActiveAreaSet>\" has been successfully made!");
		}
		else
		{
			SetFailState("Signature for \"ForEachSurvivor<PopulateActiveAreaSet>\" is broken!");
		}
	}
	
	dd_Temp = DynamicDetour.FromConf(gd_Temp, "UTIL_PlayerByIndex");
	if (dd_Temp != null)
	{
		if (!dd_Temp.Enable(Hook_Pre, dtrPlayerByIndex_Pre))
		{
			SetFailState("Failed to make a pre-detour of \"UTIL_PlayerByIndex\"!");
		}
		
		PrintToServer("[FIX] Pre-detour of \"UTIL_PlayerByIndex\" has been successfully made!");
	}
	else
	{
		SetFailState("Signature for \"UTIL_PlayerByIndex\" is broken!");
	}
	
	if (os_RetVal == OS_Windows)
	{
		dd_Temp = DynamicDetour.FromConf(gd_Temp, "ForEachSurvivor<ClosestSurvivorDistanceScan>");
		if (dd_Temp != null)
		{
			if (!dd_Temp.Enable(Hook_Pre, dtrForEachSurvivorCSDS_Pre))
			{
				SetFailState("Failed to make a pre-detour of \"ForEachSurvivor<ClosestSurvivorDistanceScan>\"!");
			}
			
			PrintToServer("[FIX] Pre-detour of \"ForEachSurvivor<ClosestSurvivorDistanceScan>\" has been successfully made!");
		}
		else
		{
			SetFailState("Signature for \"ForEachSurvivor<ClosestSurvivorDistanceScan>\" is broken!");
		}
	}
	else
	{
		dd_Temp = DynamicDetour.FromConf(gd_Temp, "SurvivorResponseCachedInfo::Update");
		if (dd_Temp != null)
		{
			if (!dd_Temp.Enable(Hook_Pre, dtrSRCIUpdatePre))
			{
				SetFailState("Failed to make a pre-detour of \"SurvivorResponseCachedInfo::Update\"!");
			}
			
			PrintToServer("[FIX] Pre-detour of \"SurvivorResponseCachedInfo::Update\" has been successfully made!");
		}
		else
		{
			SetFailState("Signature for \"SurvivorResponseCachedInfo::Update\" is broken!");
		}
	}
	
	delete dd_Temp;
	delete gd_Temp;
	
	CreateConVar("survivor_character_fixes_version", PLUGIN_VERSION, "Version of the plug-in", FCVAR_NOTIFY);
}

public MRESReturn dtrConvertToExternalCharacter_Post(DHookReturn hReturn, DHookParam hParams)
{
	if (hParams.Get(1) > -1)
	{
		return MRES_Ignored;
	}
	
	hReturn.Value = 8;
	return MRES_Override;
}

public MRESReturn dtrForEachSurvivorPAAS_Pre(DHookReturn hReturn, DHookParam hParams)
{
	return HandlePlayerIndexes();
}

public MRESReturn dtrPlayerByIndex_Pre(DHookReturn hReturn, DHookParam hParams)
{
	if (!bPlayerFix)
	{
		return MRES_Ignored;
	}
	
	int iParam = hParams.Get(1);
	if (iParam >= MaxClients)
	{
		bPlayerFix = false;
	}
	
	if (IsClientInGame(iParam))
	{
		int iCharacter = GetEntProp(iParam, Prop_Send, "m_survivorCharacter");
		if (iCharacter > -1 && iCharacter < 4)
		{
			return MRES_Ignored;
		}
		
		hReturn.Value = -1;
		return MRES_Supercede;
	}
	
	return MRES_Ignored;
}

public MRESReturn dtrForEachSurvivorCSDS_Pre(DHookReturn hReturn, DHookParam hParams)
{
	return HandlePlayerIndexes();
}

public MRESReturn dtrSRCIUpdatePre(DHookReturn hReturn)
{
	return HandlePlayerIndexes();
}

OS GetServerOS()
{
	static char sCmdLine[4];
	GetCommandLine(sCmdLine, sizeof(sCmdLine));
	return (sCmdLine[0] == '.') ? OS_Linux : OS_Windows;
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
			SetFailState("Something went wrong while creating the game data file!");
		}
		
		fileTemp.WriteLine("\"Games\"");
		fileTemp.WriteLine("{");
		fileTemp.WriteLine("	\"#default\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Functions\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("				\"callconv\"				\"cdecl\"");
		fileTemp.WriteLine("				\"return\"				\"cbaseentity\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"SurvivorResponseCachedInfo::Update\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"SurvivorResponseCachedInfo::Update\"");
		fileTemp.WriteLine("				\"callconv\"				\"thiscall\"");
		fileTemp.WriteLine("				\"return\"				\"int\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ForEachSurvivor<ClosestSurvivorDistanceScan>\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"signature\"			\"ForEachSurvivor<ClosestSurvivorDistanceScan>\"");
		fileTemp.WriteLine("					\"callconv\"			\"cdecl\"");
		fileTemp.WriteLine("					\"return\"			\"bool\"");
		fileTemp.WriteLine("					\"arguments\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"a1\"");
		fileTemp.WriteLine("						{");
		fileTemp.WriteLine("							\"type\"		\"int\"");
		fileTemp.WriteLine("						}");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_Z18UTIL_PlayerByIndexi\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"SurvivorResponseCachedInfo::Update\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_ZN26SurvivorResponseCachedInfo6UpdateEv\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x85\\x2A\\x7E\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x3B\\x2A\\x2A\\x7F\\x2A\\x3D\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? ? 85 ? 7E ? 8B ? ? ? ? ? 3B ? ? 7F ? 3D */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ForEachSurvivor<ClosestSurvivorDistanceScan>\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x57\\xBF\\x2A\\x2A\\x2A\\x2A\\x39\\x2A\\x2A\\x7C\\x2A\\x53\\x8B\\x2A\\x2A\\x2A\\x56\\x57\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x83\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x2B\\x2A\\x2A\\xC1\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xFF\\x2A\\x84\\x2A\\x74\\x2A\\x83\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x75\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x89\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? 57 BF ? ? ? ? 39 ? ? 7C ? 53 8B ? ? ? 56 57 E8 ? ? ? ? 8B ? 83 ? ? 85 ? 74 ? 8B ? ? 85 ? 74 ? 8B ? ? ? ? ? 2B ? ? C1 ? ? 74 ? 8B ? 8B ? ? ? ? ? 8B ? FF ? 84 ? 74 ? 83 ? ? ? ? ? ? 74 ? 8B ? E8 ? ? ? ? 83 ? ? 75 ? 8B ? ? ? ? ? 89 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Functions\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ConvertToExternalCharacter\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"ConvertToExternalCharacter\"");
		fileTemp.WriteLine("				\"callconv\"				\"cdecl\"");
		fileTemp.WriteLine("				\"return\"				\"int\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ForEachSurvivor<PopulateActiveAreaSet>\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"				\"ForEachSurvivor<PopulateActiveAreaSet>\"");
		fileTemp.WriteLine("				\"callconv\"				\"cdecl\"");
		fileTemp.WriteLine("				\"return\"				\"bool\"");
		fileTemp.WriteLine("				\"arguments\"");
		fileTemp.WriteLine("				{");
		fileTemp.WriteLine("					\"a1\"");
		fileTemp.WriteLine("					{");
		fileTemp.WriteLine("						\"type\"			\"int\"");
		fileTemp.WriteLine("					}");
		fileTemp.WriteLine("				}");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"UTIL_PlayerByIndex\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x57\\x33\\x2A\\x85\\x2A\\x7E\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x3B\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? 57 33 ? 85 ? 7E ? 8B ? ? ? ? ? 3B */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ConvertToExternalCharacter\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_Z26ConvertToExternalCharacter21SurvivorCharacterType\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x8B\\x2A\\x2A\\x75\\x2A\\x83\\x2A\\x2A\\x77\\x2A\\xFF\\x24\\x2A\\xA8\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? ? ? 83 ? ? 8B ? ? 75 ? 83 ? ? 77 ? FF 24 ? A8 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ForEachSurvivor<PopulateActiveAreaSet>\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_Z15ForEachSurvivorI21PopulateActiveAreaSetEbRT_\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x53\\x56\\x57\\xBF\\x2A\\x2A\\x2A\\x2A\\x39\\x2A\\x2A\\x7C\\x2A\\x8B\\x2A\\x2A\\x57\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x83\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x2B\\x2A\\x2A\\xC1\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xFF\\x2A\\x84\\x2A\\x74\\x2A\\x83\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x75\\x2A\\x56\\x8B\\x2A\\xE8\\x35\\xF7\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? ? ? 53 56 57 BF ? ? ? ? 39 ? ? 7C ? 8B ? ? 57 E8 ? ? ? ? 8B ? 83 ? ? 85 ? 74 ? 8B ? ? 85 ? 74 ? 8B ? ? ? ? ? 2B ? ? C1 ? ? 85 ? 74 ? 8B ? 8B ? ? ? ? ? 8B ? FF ? 84 ? 74 ? 83 ? ? ? ? ? ? 74 ? 8B ? E8 ? ? ? ? 83 ? ? 75 ? 56 8B ? E8 35 F7 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("			\"ForEachSurvivor<ClosestSurvivorDistanceScan>\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x57\\xBF\\x2A\\x2A\\x2A\\x2A\\x39\\x2A\\x2A\\x7C\\x2A\\x53\\x8B\\x2A\\x2A\\x56\\x57\\xE8\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\x83\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x2B\\x2A\\x2A\\xC1\\x2A\\x2A\\x85\\x2A\\x74\\x2A\\x8B\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x8B\\x2A\\xFF\\x2A\\x84\\x2A\\x74\\x2A\\x83\\x2A\\x2A\\x2A\\x2A\\x2A\\x2A\\x74\\x2A\\x8B\\x2A\\xE8\\x2A\\x2A\\x2A\\x2A\\x83\\x2A\\x2A\\x75\\x2A\\x8B\\x2A\\x2A\\x2A\\x2A\\x2A\\x89\"");
		fileTemp.WriteLine("				/* ? ? ? ? ? ? ? ? 57 BF ? ? ? ? 39 ? ? 7C ? 53 8B ? ? 56 57 E8 ? ? ? ? 8B ? 83 ? ? 85 ? 74 ? 8B ? ? 85 ? 74 ? 8B ? ? ? ? ? 2B ? ? C1 ? ? 85 ? 74 ? 8B ? 8B ? ? ? ? ? 8B ? FF ? 84 ? 74 ? 83 ? ? ? ? ? ? 74 ? 8B ? E8 ? ? ? ? 83 ? ? 75 ? 8B ? ? ? ? ? 89 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	return new GameData(file);
}

MRESReturn HandlePlayerIndexes()
{
	bPlayerFix = true;
	return MRES_Ignored;
}

