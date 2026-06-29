#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "[L4D2][Win] Modelprecache resize",
	author = "BHaType",
	description = "Allows you to resize modelprecache table",
	version = "0.0.0",
	url = "N/A"
}

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("DataTable");
	Address hAddress = GameConfGetAddress(hGameConf, "Patch");
	StoreToAddress(hAddress + view_as<Address>(89), 30, NumberType_Int8);
	delete hGameConf;
}