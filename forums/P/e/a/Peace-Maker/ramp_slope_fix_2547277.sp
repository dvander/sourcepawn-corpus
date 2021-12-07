#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <dhooks>

Address g_iPatchAddress[2];
int g_iPatchRestore[2][100];
int g_iPatchSize[2];

Handle g_hPlayerRoughLandingEffectsHook;

// https://github.com/momentum-mod/game/issues/16
public Plugin myinfo = 
{
	name = "CS:GO Ramp Slope Fix",
	author = "Peace-Maker",
	description = "Fixes players getting stuck on surf ramps.",
	version = "1.0",
	url = "http://www.wcfan.de/"
}

public void OnPluginStart()
{
	// Load the gamedata file.
	Handle hGameConf = LoadGameConfigFile("ramp_slope_fix.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Can't find ramp_slope_fix.games.txt gamedata.");
	
	PatchBytes(0, hGameConf, "PlayerDidntMove", "PlayerDidntMove_Offset", "PlayerDidntMove_PatchSize", "PlayerDidntMove_Replacement");
	PatchBytes(1, hGameConf, "OppositeDirection", "OppositeDirection_Offset", "OppositeDirection_PatchSize", "OppositeDirection_Replacement");
	
	delete hGameConf;

	if (LibraryExists("dhooks"))
		OnLibraryAdded("dhooks");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "dhooks"))
	{
		// Optionally setup a hook on CGameMovement::PlayerRoughLandingEffects to stop the screen shakes.
		Handle hGameData = LoadGameConfigFile("ramp_slope_fix.games");
		if(hGameData == null)
		{
			LogError("Failed to load ramp_slope_fix.games.txt gamedata for CGameMovement::PlayerRoughLandingEffects hook.");
			return;
		}

		Address pGameMovement = GameConfGetAddress(hGameData, "g_pGameMovement");
		if (pGameMovement == Address_Null)
		{
			LogError("Failed to find g_pGameMovement address");
			return;
		}

		int iOffset = GameConfGetOffset(hGameData, "CGameMovement::PlayerRoughLandingEffects");
		delete hGameData;

		if(iOffset == -1)
		{
			LogError("Can't find CGameMovement::PlayerRoughLandingEffects offset in gamedata.");
			return;
		}
		
		g_hPlayerRoughLandingEffectsHook = DHookCreate(iOffset, HookType_Raw, ReturnType_Void, ThisPointer_Ignore, DHooks_OnPlayerRoughLandingEffects);
		if(g_hPlayerRoughLandingEffectsHook == null)
		{
			LogError("Failed to create CGameMovement::PlayerRoughLandingEffects hook.");
			return;
		}

		DHookAddParam(g_hPlayerRoughLandingEffectsHook, HookParamType_Float);
		DHookRaw(g_hPlayerRoughLandingEffectsHook, false, pGameMovement);
	}
}

public MRESReturn DHooks_OnPlayerRoughLandingEffects(Handle hParams)
{
	float fvol = DHookGetParam(hParams, 1);
	if (fvol > 0.0)
	{
		//LogMessage("Blocked CGameMovement::PlayerRoughLandingEffects(%f)", fvol);
		return MRES_Supercede;
	}
	return MRES_Ignored;
}

void PatchBytes(int iIndex, Handle hGameConf, const char[] sAddress, const char[] sOffset, const char[] sPatchSize, const char[] sReplacement)
{
	// Get the address near our patch area inside CGameMovement::TryPlayerMove
	Address iAddr = GameConfGetAddress(hGameConf, sAddress);
	if(iAddr == Address_Null)
	{
		LogError("Can't find %s address.", sAddress);
		return;
	}
	
	// Get the offset from the start of the signature to the start of our patch area.
	int iOffset = GameConfGetOffset(hGameConf, sOffset);
	if(iOffset == -1)
	{
		LogError("Can't find %s in gamedata.", sOffset);
		return;
	}

	// Get how many bytes we want to replace.
	g_iPatchSize[iIndex] = GameConfGetOffset(hGameConf, sPatchSize);
	if(g_iPatchSize[iIndex] == -1)
	{
		LogError("Can't find %s in gamedata.", sPatchSize);
		return;
	}
	
	// See what we should patch the area to.
	int iReplacement = GameConfGetOffset(hGameConf, sReplacement);
	if (iReplacement == -1)
	{
		LogError("Can't find %s in gamedata.", sReplacement);
		return;
	}
	
	// Move right in front of the instructions we want to replace.
	iAddr += view_as<Address>(iOffset);
	g_iPatchAddress[iIndex] = iAddr;
	
	//LogMessage("%s patch area starts at %x", sAddress, g_iPatchAddress[iIndex]);
	
	int iData;
	for(int i; i < g_iPatchSize[iIndex]; i++)
	{
		// Save the current instructions, so we can restore them on unload.
		iData = LoadFromAddress(iAddr, NumberType_Int8);
		g_iPatchRestore[iIndex][i] = iData;
		
		//LogMessage("%x: %02x", iAddr, iData);
		
		StoreToAddress(iAddr, iReplacement, NumberType_Int8);
		
		iAddr++;
	}
}

public void OnPluginEnd()
{
	for (int i; i < sizeof(g_iPatchAddress); i++)
	{
		// Restore the original instructions, if we patched them.
		if(g_iPatchAddress[i] != Address_Null)
		{
			for(int b; b < g_iPatchSize[i]; b++)
			{
				StoreToAddress(g_iPatchAddress[i] + view_as<Address>(b), g_iPatchRestore[i][b], NumberType_Int8);
			}
		}
	}
}