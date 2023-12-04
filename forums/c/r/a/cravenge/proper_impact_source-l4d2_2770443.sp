#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "0.2"

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
	name = "[L4D2] Proper Impact Source",
	author = "cravenge",
	description = "No more nonsensical null sourced Charger impacts",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=336203"
};

public void OnPluginStart()
{
	GameData gd_Temp = FetchGameData("proper_impact_source-l4d2");
	if (gd_Temp == null)
	{
		SetFailState("Game data file not found!");
	}
	
	Address aTemp = gd_Temp.GetAddress("ForEachPlayerCID");
	if (aTemp != Address_Null)
	{
		int iTemp = gd_Temp.GetOffset("ForEachPlayerCID_StaggerSource");
		if (iTemp != -1)
		{
			aTemp += view_as<Address>(iTemp);
			
			iTemp = LoadFromAddress(aTemp, NumberType_Int8);
			if (iTemp != 0xC7 && iTemp != 0x6A)
			{
				SetFailState("Offset for \"ForEachPlayerCID_StaggerSource\" is incorrect!");
			}
			
			StoreToAddress(aTemp, (iTemp == 0x6A) ? 0x56 : 0x89, NumberType_Int8);
			StoreToAddress(aTemp + view_as<Address>(1), (iTemp == 0xC7) ? 0x7C : 0x90, NumberType_Int8);
			
			if (iTemp == 0xC7)
			{
				for (iTemp = 0; iTemp < 4; iTemp++)
				{
					StoreToAddress(aTemp + view_as<Address>(iTemp + 4), 0x90, NumberType_Int8);
				} 
			}
			
			PrintToServer("[PIS] Rewrote \"ForEachPlayer<ChargeImpactDistributor>\" to pass the Charger's index instead as the source of the impact");
			
			delete gd_Temp;
		}
		else
		{
			SetFailState("Offset for \"ForEachPlayerCID_StaggerSource\" is missing!");
		}
	}
	else
	{
		SetFailState("Address for \"ForEachPlayerCID\" returned NULL!");
	}
	
	CreateConVar("proper_impact_source-l4d2_ver", PLUGIN_VERSION, "Version of the plug-in", FCVAR_NOTIFY);
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
		fileTemp.WriteLine("	\"left4dead2\"");
		fileTemp.WriteLine("	{");
		fileTemp.WriteLine("		\"Addresses\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ForEachPlayerCID\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"signature\"	\"ForEachPlayer<ChargeImpactDistributor>\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Offsets\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ForEachPlayerCID_StaggerSource\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"windows\"	\"294\"");
		fileTemp.WriteLine("				\"linux\"		\"906\"");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("		");
		fileTemp.WriteLine("		\"Signatures\"");
		fileTemp.WriteLine("		{");
		fileTemp.WriteLine("			\"ForEachPlayer<ChargeImpactDistributor>\"");
		fileTemp.WriteLine("			{");
		fileTemp.WriteLine("				\"library\"	\"server\"");
		fileTemp.WriteLine("				\"linux\"		\"@_Z13ForEachPlayerI23ChargeImpactDistributorEbRT_\"");
		fileTemp.WriteLine("				\"windows\"	\"\\x53\\x8B\\x2A\\x83\\x2A\\x2A\\x83\\x2A\\x2A\\x83\\x2A\\x2A\\x55\\x8B\\x2A\\x2A\\x89\\x2A\\x2A\\x2A\\x8B\\x2A\\x81\\x2A\\x2A\\x2A\\x2A\\x2A\\x56\\x57\\x8B\\x2A\\x2A\\x8B\\x2A\\x89\"");
		fileTemp.WriteLine("				/* 53 8B ? 83 ? ? 83 ? ? 83 ? ? 55 8B ? ? 89 ? ? ? 8B ? 81 ? ? ? ? ? 56 57 8B ? ? 8B ? 89 */");
		fileTemp.WriteLine("			}");
		fileTemp.WriteLine("		}");
		fileTemp.WriteLine("	}");
		fileTemp.WriteLine("}");
		
		fileTemp.Close();
	}
	return new GameData(file);
}

