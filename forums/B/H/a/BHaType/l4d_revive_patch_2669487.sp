#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D2] Revive Patch",
	author = "BHaType",
	description = "Allows you to revive a survivor even if it takes damage",
	version = "0.0.1",
	url = "N/A"
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("l4d2_revive_gamedata");
	Address hAddress = GameConfGetAddress(hGameConf, "FuncAddr") + view_as<Address>(GameConfGetOffset(hGameConf, "PatchAddr"));
	
	int count = GameConfGetOffset(hGameConf, "PatchCount");
	
	for (int i; i <= count; i++) 
		StoreToAddress(hAddress + view_as<Address>(i), 0x90, NumberType_Int8);
		
	delete hGameConf;
}