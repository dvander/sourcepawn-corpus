#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Address:g_iPatchAddress;
new g_iPatchRestore[100];
new g_iPatchRestoreBytes;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "CS:GO Movement Unlocker",
	author = "Peace-Maker",
	description = "Removes max speed limitation from players on the ground. Feels like CS:S.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	// Load the gamedata file.
	new Handle:hGameConf = LoadGameConfigFile("csgo_movement_unlocker.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Can't find csgo_movement_unlocker.games.txt gamedata.");
	
	// Get the address near our patch area inside CGameMovement::WalkMove
	new Address:iAddr = GameConfGetAddress(hGameConf, "WalkMoveMaxSpeed");
	if(iAddr == Address_Null)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find WalkMoveMaxSpeed address.");
	}
	
	// Get the offset from the start of the signature to the start of our patch area.
	new iCapOffset = GameConfGetOffset(hGameConf, "CappingOffset");
	if(iCapOffset == -1)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find CappingOffset in gamedata.");
	}
	
	// Move right in front of the instructions we want to NOP.
	iAddr += Address:iCapOffset;
	g_iPatchAddress = iAddr;
	
	// Get how many bytes we want to NOP.
	g_iPatchRestoreBytes = GameConfGetOffset(hGameConf, "PatchBytes");
	if(g_iPatchRestoreBytes == -1)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find PatchBytes in gamedata.");
	}
	CloseHandle(hGameConf);
	
	//PrintToServer("CGameMovement::WalkMove VectorScale(wishvel, mv->m_flMaxSpeed/wishspeed, wishvel); ... at address %x", g_iPatchAddress);
	
	new iData;
	for(new i=0;i<g_iPatchRestoreBytes;i++)
	{
		// Save the current instructions, so we can restore them on unload.
		iData = LoadFromAddress(iAddr, NumberType_Int8);
		g_iPatchRestore[i] = iData;
		
		//PrintToServer("%x: %x", iAddr, iData);
		
		// NOP
		StoreToAddress(iAddr, 0x90, NumberType_Int8);
		
		iAddr++;
	}
	
}

public OnPluginEnd()
{
	// Restore the original instructions, if we patched them.
	if(g_iPatchAddress != Address_Null)
	{
		for(new i=0;i<g_iPatchRestoreBytes;i++)
		{
			StoreToAddress(g_iPatchAddress+Address:i, g_iPatchRestore[i], NumberType_Int8);
		}
	}
}