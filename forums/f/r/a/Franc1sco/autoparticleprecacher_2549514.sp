#include <sourcemod>

#pragma semicolon 1

#define MANIFEST_FOLDER         "maps/"
#define MANIFEST_EXTENSION      "_particles.txt"


public OnPluginStart(){ 
	RegAdminCmd("sm_precache_particles", Command_PrecacheParticles, ADMFLAG_ROOT, "Precaches a particle system.");
}

public OnMapStart()
{
	decl String:sMap[PLATFORM_MAX_PATH];
	GetCurrentMap(sMap, sizeof(sMap));
	
	decl String:sManifestFullPath[PLATFORM_MAX_PATH];
	FormatEx(sManifestFullPath, sizeof(sManifestFullPath), "%s%s%s", MANIFEST_FOLDER, sMap, MANIFEST_EXTENSION);

	// If the file exists then we jump into the depths of it and precache stuff
	if (!FileExists(sManifestFullPath, true, NULL_STRING))
	{
		//PrintToServer("\n\nManifest file \'%s\' not found.", sManifestFullPath);
		return;
	}
	
	ProcessParticleManifest(sManifestFullPath);
}

public Action:Command_PrecacheParticles(client, args){
	if (args < 1){
		return Plugin_Handled;
	}
	new String:path[256];
	GetCmdArg(1, path, sizeof(path));
	PrintToConsole(client, "Particle precacher called for: %s", path);
	PrecacheParticle(path);
	return Plugin_Handled;
}

ProcessParticleManifest(const String:path[])
{
	new Handle:hFile = OpenFile(path, "r", true, NULL_STRING);

	new Handle:hKeyValue = CreateKeyValues("particles_manifest");
	FileToKeyValues(hKeyValue, path);

	if (!KvJumpToKey(hKeyValue, "file", false))
	{
		//PrintToServer("\n\nFailed going to first key");
		CloseHandle(hKeyValue);
		CloseHandle(hFile);
		return;
	}
	
	decl String:buffer[256];
	do
	{
		KvGetString(hKeyValue, NULL_STRING, buffer, sizeof(buffer), NULL_STRING);
		PrecacheParticle(buffer);
	} while (KvGotoNextKey(hKeyValue, false));
 
	CloseHandle(hKeyValue);
	CloseHandle(hFile);
}

public PrecacheParticle(const String:path[])
{
	if(!FileExists(path, true, NULL_STRING))
	{
		//PrintToServer("\nParticle file \'%s\' not found.", path);
		//return;
	}
	
	PrecacheGeneric(path, true);
}