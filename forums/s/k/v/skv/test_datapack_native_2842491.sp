#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo = 
{
	name 		= "test_datapack_native",
	author 		= "Skv",
	description = "",
	version 	= "1.0",
	url 		= ""
}

DataPack gh_pack;

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
	CreateNative("ClosePack", native_ClosePack);
		
	return APLRes_Success;
}

any native_ClosePack(Handle plugin, int numParams)
{
	gh_pack = GetNativeCellRef(1);
	SetNativeCellRef(1, 0);   /* Zero out the variable by reference */

	CreateTimer(1.0, RemovePack);
	
	return true;
}

void RemovePack(Handle timer)
{
	// Here I try to delete it, but it remains in the dump :(
	delete gh_pack;
}