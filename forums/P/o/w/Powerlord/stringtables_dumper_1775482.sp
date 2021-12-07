#include <sourcemod>
#include <sdktools>

#define VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[DEV] Stringtables Dumper",
	author = "Powerlord",
	description = "Dump Stringtables status to a file",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=193361"
}

public OnPluginStart()
{
	CreateConVar("stringtables_dumper_version", VERSION, "Stringtables Dumper version", FCVAR_DONTRECORD | FCVAR_NOTIFY);
	
	RegServerCmd("sm_stringtables_info_dump", Command_Stringtables_Dump, "Dumps string tables to file");
}

public Action:Command_Stringtables_Dump(args)
{
	if (args == 0)
	{
		PrintToServer("Usage: sm_stringtables_dump <filename>");
		return Plugin_Handled;
	}
	
	decl String:filename[PLATFORM_MAX_PATH];
	GetCmdArgString(filename, PLATFORM_MAX_PATH);
	
	new Handle:file;
	file = OpenFile(filename, "w");
	
	if (file == INVALID_HANDLE)
	{
		PrintToServer("Could not open file %s", filename);
		return Plugin_Handled;
	}
	
	new stringTableCount = GetNumStringTables();
	
	for (new i = 0; i < stringTableCount; i++)
	{
		decl String:name[PLATFORM_MAX_PATH];
		GetStringTableName(i, name, sizeof(name));
		
		new stringsCount = GetStringTableNumStrings(i);
		new stringsMax = GetStringTableMaxStrings(i);
		
		new Float:stringsPercent = float(stringsCount) / float(stringsMax) * 100;
		
		WriteFileLine(file, "%s: %d/%d (%d%% full)", name, stringsCount, stringsMax, RoundToNearest(stringsPercent));
	}
	FlushFile(file);
	CloseHandle(file);
	
	return Plugin_Handled;
}

