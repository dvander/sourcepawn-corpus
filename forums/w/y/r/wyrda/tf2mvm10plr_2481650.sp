#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
	name = "TF2 MVM 10 Players",
	author = "wyrda",
	description = "Patch server to set visible players to 10",
	version = "0.0.1",
	url = "http://wyrdaprogramming.tk/"
};

new Handle:hGameConf;
new String:error_s[128];

public OnPluginStart()
{
	
	hGameConf = LoadGameConfigFile("tf2mvm10plr.games");
	if(!hGameConf)
	{
		Format(error_s, sizeof(error_s), "Failed to find tf2mvm10plr.games");
		SetFailState(error_s);
	}
	
	
	if(PatchAddress("PreClientUpdate", "MvMMaxPlayers_Offset", 6, 10) == false)
	{
		SetFailState(error_s);
		
	}
	else if(PatchAddress("Sig2", "MvMMaxPlayers2_Offset", 6, 10) == false)
	{
		PatchAddress("PreClientUpdate", "MvMMaxPlayers_Offset", 10, 6);
		SetFailState(error_s);
	}	
	
	CloseHandle(hGameConf);
	
}

bool:PatchAddress(const char[] address_s, const char[] offset_s, oldVal, newVal) 
{
	new Address:addr = GameConfGetAddress(hGameConf, address_s);
	new Address:offset = Address:GameConfGetOffset(hGameConf, offset_s);	
	

	if(addr == Address:0 || LoadFromAddress(addr+offset, NumberType_Int8) != oldVal)
	{
		CloseHandle(hGameConf);
		Format(error_s, sizeof(error_s), "Failed to get valid patch value for %s", address_s);
		return false;
		
	}
	
	StoreToAddress(addr+Address:offset, newVal, NumberType_Int8);
	return true;
	
}
