#include <sourcemod>

#define PLUGIN_VERSION "1.0"

new String:Path[PLATFORM_MAX_PATH];
new String:Map[255];

public Plugin:myinfo = 
{
	name = "Map Commands",
	author = "SimonTheOne",
	description = "Execute commands at the beginning of the map that are set in the configuration file.",
	version = PLUGIN_VERSION,
	url = "<- URL ->"
}

public OnPluginStart()
{
	CreateConVar("sm_map_commands_version", PLUGIN_VERSION, "Map Commands Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart()
{	
	BuildPath(Path_SM, Path, 256, "data/mapcommands_config.txt");
	if (!FileExists(Path))
	{
		PrintToServer("Error: File doesn't exist: %s.", Path);
		return;
	}
	
	GetCurrentMap(Map, sizeof(Map));
	
	new Handle:kv = CreateKeyValues("root");
	FileToKeyValues(kv, Path);
	
	if (!KvJumpToKey(kv, Map))
	{
		CloseHandle(kv);
		return;
	}
	
	new String:KeyString[10] = "0";
	new String:Command[255] = "Starting executing Commands.";
	new KeyInt = 0;
	
	if (KvGetNum(kv, "allmaps", 1) == 1)
	{
		KvRewind(kv);
		KvJumpToKey(kv, "allmaps");
		
		while (!StrEqual(Command, "echo Allmaps Commands have been executed."))
		{
			PrintToServer("[Map Commands] %s", Command);
			
			KvGetString(kv, KeyString, Command, sizeof(Command), "echo Allmaps Commands have been executed.");
			KeyInt = StringToInt(KeyString);
			KeyInt++;
			IntToString(KeyInt, KeyString, sizeof(KeyString));
			
			ServerCommand(Command);
		}
		
		KeyString = "0";
		Command = "Finished executing allmaps commands.";
		KeyInt = 0;
		
		KvRewind(kv);
		KvJumpToKey(kv, Map);
	}
	
	while (!StrEqual(Command, "echo Map Commands have been executed."))
	{
		PrintToServer("[Map Commands] %s", Command);
		
		KvGetString(kv, KeyString, Command, sizeof(Command), "echo Map Commands have been executed.");
		KeyInt = StringToInt(KeyString);
		KeyInt++;
		IntToString(KeyInt, KeyString, sizeof(KeyString));
		
		ServerCommand(Command);
	}
	
	CloseHandle(kv);
	
	PrintToServer("[Map Commands] Finished executing commands.");
	return;
}