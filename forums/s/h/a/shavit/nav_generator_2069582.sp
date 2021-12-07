#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Auto NAV file creator",
	description = "Plugin that automatically creates a .nav file for the current map, meant to be used for custom AIs like replay bots.",
	author = "shavit",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=163134"
}

public OnPluginStart()
{
	CreateConVar("sm_navfilegenerator", PLUGIN_VERSION, "Plugin version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_PLUGIN);
}

public OnMapStart()
{
	new String:map[64];
	GetCurrentMap(map, 64);
	
	Format(map, 64, "maps/%s.nav", map);
	
	if(!FileExists(map))
	{
		File_Copy("maps/base.nav", map);
		
		GetCurrentMap(map, 64);
		ForceChangeLevel(map, ".nav file generate");
	}
}

/*
 * Copies file source to destination
 * Based on code of javalia:
 * http://forums.alliedmods.net/showthread.php?t=159895
 *
 * @param source		Input file
 * @param destination	Output file
 */
stock bool:File_Copy(const String:source[], const String:destination[])
{
	new Handle:file_source = OpenFile(source, "rb");

	if (file_source == INVALID_HANDLE) {
		return false;
	}

	new Handle:file_destination = OpenFile(destination, "wb");

	if (file_destination == INVALID_HANDLE) {
		CloseHandle(file_source);
		return false;
	}

	new buffer[32];
	new cache;

	while (!IsEndOfFile(file_source)) {
		cache = ReadFile(file_source, buffer, 32, 1);
		WriteFile(file_destination, buffer, cache, 1);
	}

	CloseHandle(file_source);
	CloseHandle(file_destination);

	return true;
}
