#include <sourcemod>

public Plugin:myinfo =
{
	name = "Valve Server Plugin Late Load Fix",
	author = "backwards",
	description = "Allows Server Operators To Run The Plugin_Load Command After A Maps Been Loaded.",
	version = SOURCEMOD_VERSION,
	url = "http://www.steamcommunity.com/id/mypassword"
}

public OnPluginStart()
{
	new Address:PluginLoad = GameConfGetAddress(LoadGameConfigFile("VSPLateLoadFix"), "PluginLoad");

	if(!PluginLoad)
		SetFailState("'Gamedata\\VSPLateLoadFix.txt' needs updated.");
	
	new OS = LoadFromAddress(PluginLoad + Address:1, NumberType_Int8);
	switch(OS)
	{
		case 0x89: //Linux
		{
			StoreToAddress(PluginLoad + Address:0x37, 0x7E, NumberType_Int8);	
		}
		case 0x8B: //Windows
		{
			StoreToAddress(PluginLoad + Address:0x13, 0x7D, NumberType_Int8);	
		}
		default:
		{
			SetFailState("VSPLateLoadFix Signature Incorrect. (0x%x)", OS);
		}
	}
}