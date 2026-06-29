#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[L4D2] Gascan Announcer",
	author = "BHaType",
	description = "Notifies about who broke the gascan",
	version = "0.1",
	url = "SDKCall"
};

public void OnPluginStart()
{
	GameData hData = new GameData("l4d2_gascan_data");
	
	Address hAddress, iOffset;
	
	if ((hAddress = hData.GetAddress("CGasCan::Event_Killed")) == Address_Null || (iOffset = view_as<Address>(hData.GetOffset("iOffset"))) <= Address_Null)
	{
		delete hData;
		SetFailState("Invalid data, please check your gamedata");
	}
	
	StoreToAddress(hAddress + iOffset, 0x9090, NumberType_Int16);
	delete hData;
}