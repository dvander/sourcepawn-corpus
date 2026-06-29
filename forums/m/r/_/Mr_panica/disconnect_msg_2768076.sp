#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = ""
};

public void OnPluginStart()
{
	GameData conf = new GameData("disconnect_msg");
	if(conf == null)
		SetFailState("Failed to load disconnect_msg gamedata");
	
	Address addr = conf.GetAddress("CNetChan::ProcessControlMessage");
	if(!addr)
		SetFailState("Failed to load CNetChan::ProcessControlMessage signature from gamedata");
	
	int offset = conf.GetOffset("CNetChan::ProcessControlMessage");
	if(offset == -1)
		SetFailState("Failed, BRO");
	
	for (int i = 0; i < 8; ++i)
		StoreToAddress(addr + view_as<Address>(offset) + view_as<Address>(i), 0x90, NumberType_Int8);
	
	conf.Close();
}