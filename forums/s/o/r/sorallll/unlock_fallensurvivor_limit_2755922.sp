#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

#define GAMEDATA "unlock_fallensurvivor_limit"

ArrayList
	g_aByteSaved,
	g_aBytePatch;

Address
	g_pIsFallenSurvivorAllowed;

public Plugin myinfo = 
{
	name = "Unlock FallenSurvivor Spawn Limit",
	author = "sorallll",
	description = "Unlock FallenSurvivor Spawn Limit",
	version = "1.0.0",
	url = ""
};

public void OnPluginStart()
{
	vLoadGameData();
	vIsFallenSurvivorAllowedPatch(true);
}

public void OnPluginEnd()
{
	vIsFallenSurvivorAllowedPatch(false);
}

void vIsFallenSurvivorAllowedPatch(bool bPatch)
{
	static bool bPatched;
	if(!bPatched && bPatch)
	{
		bPatched = true;
		int iLength = g_aBytePatch.Length;
		for(int i; i < iLength; i++)
			StoreToAddress(g_pIsFallenSurvivorAllowed + view_as<Address>(i), g_aBytePatch.Get(i), NumberType_Int8);
	}
	else if(bPatched && !bPatch)
	{
		bPatched = false;
		int iLength = g_aByteSaved.Length;
		for(int i; i < iLength; i++)
			StoreToAddress(g_pIsFallenSurvivorAllowed + view_as<Address>(i), g_aByteSaved.Get(i), NumberType_Int8);
	}
}

void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	int iOffset = hGameData.GetOffset("IsFallenSurvivorAllowed_Offset");
	if(iOffset == -1)
		LogError("Failed to load offset: IsFallenSurvivorAllowed_Offset");

	int iByteMatch = hGameData.GetOffset("IsFallenSurvivorAllowed_Byte");
	if(iByteMatch == -1)
		LogError("Failed to load byte: IsFallenSurvivorAllowed_Byte");

	int iByteCount = hGameData.GetOffset("IsFallenSurvivorAllowed_Count");
	if(iByteCount == -1)
		LogError("Failed to load count: IsFallenSurvivorAllowed_Count");

	g_pIsFallenSurvivorAllowed = hGameData.GetAddress("IsFallenSurvivorAllowed");
	if(!g_pIsFallenSurvivorAllowed)
		LogError("Failed to load address: IsFallenSurvivorAllowed");
	
	g_pIsFallenSurvivorAllowed += view_as<Address>(iOffset);

	g_aByteSaved = new ArrayList();
	g_aBytePatch = new ArrayList();

	for(int i; i < iByteCount; i++)
		g_aByteSaved.Push(LoadFromAddress(g_pIsFallenSurvivorAllowed + view_as<Address>(i), NumberType_Int8));
	
	if(g_aByteSaved.Get(0) != iByteMatch)
		LogError("Failed to load 'IsFallenSurvivorAllowed', byte mis-match @ %d (0x%02X != 0x%02X)", iOffset, g_aByteSaved.Get(0), iByteMatch);

	switch(iByteMatch)
	{
		case 0x0F:
		{
			g_aBytePatch.Push(0x90);
			g_aBytePatch.Push(0xE9);
		}

		case 0x74:
		{
			g_aBytePatch.Push(0x90);
			g_aBytePatch.Push(0x90);
		}
	}

	delete hGameData;
}