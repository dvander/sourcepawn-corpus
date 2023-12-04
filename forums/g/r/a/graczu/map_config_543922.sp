#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.2"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Maps and Prefix Maps Configs",
	author = "graczu",
	description = "Execing configs for map, and maps prefixs",
	version = PLUGIN_VERSION,
	url = "http://sourcemod.net"
};

//#define debugmsg false; // debugmsg mode, logs adding
new bool:debugmsg = false;

new String:breaker[] = "_";
new String:prefix[12];
new String:mapfile[PLATFORM_MAX_PATH];
new String:mapprefixfile[PLATFORM_MAX_PATH];

public OnMapStart(){
	CreateTimer(2.0, Read_Files);
}

public Action:Read_Files(Handle:timer){
	decl String:currentMap[64];
	GetCurrentMap(currentMap, 64);
	if(strlen(currentMap) > 2 && !(StrContains(currentMap,breaker) == -1)){
		SplitString(currentMap, breaker, prefix, sizeof(prefix));
		BuildPath(Path_SM,mapfile,sizeof(mapfile),"configs/mapscfg/%s.cfg", currentMap);
		BuildPath(Path_SM,mapprefixfile,sizeof(mapprefixfile),"configs/mapscfg/%s_.cfg", prefix);
		if(debugmsg == true){
			LogMessage("0 Patch mapfile: %s",mapfile);
			LogMessage("0 Patch prefix: %s",mapprefixfile);
		}
		if(FileExists(mapprefixfile)){
			readFileConfig(mapprefixfile);
		} else if(debugmsg == true){
			LogMessage("0 Map Prefix dosent exist: %s",mapprefixfile);
		}
		if(FileExists(mapfile)){
			readFileConfig(mapfile);
		} else if(debugmsg == true){
			LogMessage("0 Mapfile dosent exists: %s",mapfile);
		}
	} else if(strlen(currentMap) > 1){
		BuildPath(Path_SM,mapfile,sizeof(mapfile),"configs/mapscfg/%s.cfg", currentMap);
		if(debugmsg == true){
			LogMessage("1 Patch mapfile: %s",mapfile);
		}
		if(FileExists(mapfile)){
			readFileConfig(mapfile);
		} else if(debugmsg == true){
			LogMessage("1 Mapfile dosent exists: %s",mapfile);
		}
	}
}

public readFileConfig(String:file[]){

	new Handle:hFile = OpenFile(file, "rt");
	new String:szReadData[128];
	if(hFile == INVALID_HANDLE)
	{
		return;
	}
	while(!IsEndOfFile(hFile) && ReadFileLine(hFile, szReadData, sizeof(szReadData)))
	{
		ServerCommand("%s", szReadData);
		if(debugmsg == true){
			LogMessage("Execute: %s", szReadData);
		}
	}
	CloseHandle(hFile);
}