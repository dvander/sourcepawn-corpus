/****

Aug 29, 2008

Author =Mammal Master


_____________________


****/

#include <sourcemod>
#include <sdktools>

#define ARENA_FIX_VERSION "0.1"
new Handle:ErrorChecking;


public Plugin:myinfo = 
{
	name = "Kill wait time",
	author = "Mammal",
	description = "Only way I cna get my stupid server to play arena maps.",
	version = ARENA_FIX_VERSION,
	url = "www.necrophix.com"
}


public OnPluginStart()
{
	CreateConVar("arena_fix_version", ARENA_FIX_VERSION, "ARENA fix version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ErrorChecking = CreateConVar("arena_fix_error_check","0","Shows Error Messages in-game chat, 0= don't show, 1 = show", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	//Donator_enabled		=	CreateConVar("donator_enabled", 		"1",				"1 = Enabled, 0 = Disabled");
	
	
}


public OnMapStart(){
	CreateTimer(10.0, Fix_Arena);
	
}

public Action:Fix_Arena(Handle:timer){
	new String:map_name[128];
	GetCurrentMap(map_name,128);
	PrintToServer("\x04[Arena_fix]\x03 Map is %s ",map_name);
	if(StrContains(map_name, "arena") != -1){
	ServerCommand("mp_waitingforplayers_cancel 1");
	PrintToServer("\x04[Arena_fix]\x03 Trying to fix");
	
	}else{
	PrintToServer("\x04[Arena_fix]\x03 Not Arena map");
	}
	
	
  	return;
	
}