#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define MAXFIXES 64
#define CONFIG_NAME "data/l4d2_navigation_fix.cfg"

Address TheNavAreas;
int TheCount;
bool g_bLateload;
any g_iPatches[MAXFIXES][3];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("round_start_post_nav", eNavigation);
	
	if (g_bLateload)
		LoadConfig();
}

public void OnMapStart()
{
	GameData hData = new GameData("l4d2_nav_loot");
	
	TheNavAreas = hData.GetAddress("TheNavAreas");
	TheCount = LoadFromAddress(hData.GetAddress("TheCount"), NumberType_Int32);
	
	delete hData;
	
	if (TheNavAreas == Address_Null || !TheCount)
		SetFailState("[Navigation Fixes] Bad data, please check your gamedata");
}

public void eNavigation (Event event, const char[] name, bool dontbroadcast)
{
	CreateTimer(1.0, tStart);
}

public Action tStart (Handle timer)
{
	LoadConfig();
}

void LoadConfig()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof szPath, "%s", CONFIG_NAME);
	
	KeyValues hKeyValues;
	
	if ((hKeyValues = ConfigOpen(szPath)) == null)
	{
		delete hKeyValues;
		return;
	}
	
	char szName[36], szTemp[4];
	int index, iBase, iSpawn, iCounter, iHammerID, entity;
	bool bPatched;
	Address iArea;
	
	GetCurrentMap(szName, sizeof szName);
	
	hKeyValues.JumpToKey(szName);
	
	for (int i = 1; i <= MAXFIXES; i++)
	{
		IntToString(i, szTemp, sizeof szTemp);
		
		if (hKeyValues.JumpToKey(szTemp))
		{
			index = hKeyValues.GetNum("Area");
			
			if (index < 0)
			{
				LogError("Invalid nagivation index %i", index);
				hKeyValues.GoBack();
				continue;
			}
			
			iBase = hKeyValues.GetNum("Base Flags");
			iSpawn = hKeyValues.GetNum("Spawn Flags");
			iHammerID = hKeyValues.GetNum("Wall");
			
			for (int l = 1; l <= TheCount; l++)
			{
				if (l != index)
					continue;
				
				iArea = view_as<Address>(LoadFromAddress(TheNavAreas + view_as<Address>(4 * l), NumberType_Int32));
				
				StoreToAddress(iArea + view_as<Address>(84), iBase, NumberType_Int32);
				StoreToAddress(iArea + view_as<Address>(127), iSpawn, NumberType_Int32);
				
				bPatched = true;
				break;
			}
			
			if (iHammerID > 0)
			{
				entity = FindEntity(iHammerID);
				
				if (entity == -1)
				{
					LogError("Invalid wall hammerid %i", iHammerID);
					continue;
				}
				
				SetEntProp(entity, Prop_Data, "m_iHammerID", i);
				HookSingleEntityOutput(entity, "OnBreak", OnOutput, true);
				
				g_iPatches[i][0] = iArea;
				g_iPatches[i][1] = iBase;
				g_iPatches[i][2] = iSpawn;
			}
			
			if (!bPatched)
			{
				LogError("Nagivation area with index %i does not exist (map %s)", index, szName);
				hKeyValues.GoBack();
				continue;
			}
			
			iCounter++;
			hKeyValues.GoBack();
		}
		
		bPatched = false;
	}
	
	hKeyValues.Rewind();
	delete hKeyValues;
	
	if (iCounter)
		PrintToServer("[Nav Fixes] Pathing areas has been finished (%i areas patched)", iCounter);
}

public void OnOutput(const char[] output, int caller, int activator, float delay)
{
	CreateTimer(0.1, tPatch, GetEntProp(caller, Prop_Data, "m_iHammerID"));
}

public Action tPatch (Handle timer, int index)
{
	StoreToAddress(g_iPatches[index][0] + view_as<Address>(84), g_iPatches[index][1], NumberType_Int32); 
	StoreToAddress(g_iPatches[index][0] + view_as<Address>(127), g_iPatches[index][2], NumberType_Int32); 
}

int FindEntity (int index)
{
	for (int i = MaxClients; i <= 2048; i++)
		if (IsValidEntity(i) && GetEntProp(i, Prop_Data, "m_iHammerID") == index)
			return i;
	return -1;
}

KeyValues ConfigOpen(const char[] szPath)
{
	if (!FileExists(szPath))
	{
		File hFile = OpenFile(szPath, "w");
		hFile.WriteLine("");
		delete hFile;
	}

	KeyValues hFile = new KeyValues("Nav Data");
	
	if (!hFile.ImportFromFile(szPath))
	{
		delete hFile;
		return null;
	}

	return hFile;
}