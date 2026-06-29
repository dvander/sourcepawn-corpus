#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "Timescale Windows Fix"
#define PLUGIN_DESC "Fixes host_timescale without sv_cheats on Windows servers"
#define PLUGIN_AUTHOR "Bakugo"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "https://steamcommunity.com/profiles/76561198020610103"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	Handle conf;
	Address addr;
	
	CreateConVar("sm_timescale_win_fix__version", PLUGIN_VERSION, (PLUGIN_NAME ... " - Version"), (FCVAR_NOTIFY|FCVAR_DONTRECORD));
	
	conf = LoadGameConfigFile("timescale_win_fix");
	
	if (conf == null) {
		SetFailState("Failed to load gamedata");
	}
	
	addr = GameConfGetAddress(conf, "TimescaleCheatCheck");
	
	if (addr != Address_Null) {
		// go to the target instruction
		addr += view_as<Address>(4);
		
		// check if it's the instruction we want (JNE)
		if (LoadFromAddress(addr, NumberType_Int8) == 0x75) {
			// replace JNE with JMP
			StoreToAddress(addr, 0xEB, NumberType_Int8);
			
			LogMessage("Successfully patched host_timescale cheat check");
		}
	}
	
	CloseHandle(conf);
}
