#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

new Address:g_iPatchAddress;
new g_iPatchRestore[100];
new g_iPatchRestoreBytes;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "CS:GO ApplyAbsVelocityImpulse Unlocker",
	author = "Peace-Maker",
	description = "Removes max speed limitation trigger_push.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	// Load the gamedata file.
	new Handle:hGameConf = LoadGameConfigFile("csgo_applyabsvelocityimpulse_unlocker.games");
	if(hGameConf == INVALID_HANDLE)
		SetFailState("Can't find csgo_applyabsvelocityimpulse_unlocker.games.txt gamedata.");
	
	// Get the address of CBaseEntity::ApplyAbsVelocityImpulse
	new Address:iAddr = GameConfGetAddress(hGameConf, "ApplyAbsVelocityImpulseCap");
	if(iAddr == Address_Null)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find ApplyAbsVelocityImpulseCap address.");
	}
	
	// Get the offset from the start of the signature to the start of our patch area.
	new iCapOffset = GameConfGetOffset(hGameConf, "CheckEntityVelcocityConditionOffset");
	if(iCapOffset == -1)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find CheckEntityVelcocityConditionOffset in gamedata.");
	}
	
	// Move right in front of the instructions we want to NOP.
	iAddr += Address:iCapOffset;
	g_iPatchAddress = iAddr;
	
	// Get how many bytes we want to NOP.
	g_iPatchRestoreBytes = GameConfGetOffset(hGameConf, "CheckEntityVelcocityConditionBytes");
	if(g_iPatchRestoreBytes == -1)
	{
		CloseHandle(hGameConf);
		SetFailState("Can't find CheckEntityVelcocityConditionBytes in gamedata.");
	}
	CloseHandle(hGameConf);
	
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