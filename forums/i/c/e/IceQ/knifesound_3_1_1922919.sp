#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_VERSION "3.1"
#pragma semicolon 1

EngineVersion g_EngineVersion;

new Handle:ksSoundFile = INVALID_HANDLE;
new String:ksSoundName[PLATFORM_MAX_PATH];

new Handle:ksSoundPath = INVALID_HANDLE;
new Handle:ksSoundFiles = INVALID_HANDLE;

new Handle:ksEnabled = INVALID_HANDLE;
new Handle:ksRandom = INVALID_HANDLE;
new Handle:ksOnlyClient = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "KnifeSound 3.0",
	author = "IceQ?!",
	description = "Plays a specified or random sound when a player gets killed with a knife",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/official_iceq"
};

public OnPluginStart()
{
	g_EngineVersion = GetEngineVersion();
	
	ksSoundFiles = CreateArray(PLATFORM_MAX_PATH);
	
	CreateConVar("sm_knifesound_version", PLUGIN_VERSION, "Plays a specified or random sound when a player gets killed with a knife", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ksEnabled = CreateConVar("sm_knifesound_enable", "1", "0: Disable Plugin | 1: Enable Plugin");
	ksSoundFile = CreateConVar("sm_knifesound_file", "knifesound/humiliation.mp3",	"Customizable Knifesound File ( without sound/ )");	
	ksSoundPath = CreateConVar("sm_knifesound_path", "knifesound",	"Customizable Knifesound Path ( without sound/ )");
	ksRandom = CreateConVar("sm_knifesound_random", "0", "0: Plays the specified sound file | 1: Plays a random sound file from path");
	ksOnlyClient = CreateConVar("sm_knifesound_client_only", "0", "0: Plays the sound to everybody | 1: Plays the sound only to the killed player");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnConfigsExecuted()
{
	GetConVarString(ksSoundFile, ksSoundName, PLATFORM_MAX_PATH);
	FetchAllSoundFiles();
}

FetchAllSoundFiles()
{
	ClearArray(ksSoundFiles);
	
	decl String:sound_dir[PLATFORM_MAX_PATH];
	GetConVarString(ksSoundPath, sound_dir, sizeof(sound_dir));

	decl String:sound_path[PLATFORM_MAX_PATH];
	Format(sound_path, sizeof(sound_path), "sound/%s", sound_dir);
	if (!DirExists(sound_path)) {
		LogError("Directory '%s' does not exist.", sound_path);
		return;
	}
	
	new Handle:h_dir = OpenDirectory(sound_path);
	if (h_dir == INVALID_HANDLE) {
		LogError("'%s'", sound_path);
		return;
	}
	
	new FileType:type = FileType_Unknown;
	new String:filename[PLATFORM_MAX_PATH];
	while (ReadDirEntry(h_dir, filename, sizeof(filename), type))
	{
		if (type != FileType_File) {
			continue;
		}
		decl String:file_ext[5];
		strcopy(file_ext, sizeof(file_ext), filename[strlen(filename) - 4]);
		if (strcmp(file_ext, ".mp3", false) != 0) {
			continue;
		}
		Format(filename, sizeof(filename), "%s/%s", sound_dir, filename);
		PushArrayString(ksSoundFiles, filename);
	}
	if (GetArraySize(ksSoundFiles) == 0)
	{
		LogError("Cannot find any sound files. Path: '%s'", sound_path);
	}
	
	new sounds = GetArraySize(ksSoundFiles);
	decl String:buffer[PLATFORM_MAX_PATH];
	for (new i = 0; i < sounds; i++)
	{
		GetArrayString(ksSoundFiles, i, buffer, sizeof(buffer));
		PrecacheSound(buffer, true);
		Format(buffer, sizeof(buffer), "sound/%s", buffer);
		AddFileToDownloadsTable(buffer);
	}
}



public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (client == 0 || attacker == 0 || client == attacker) {
		return Plugin_Continue;
	}

	decl String:weapon[32];	
	GetEventString(event, "weapon", weapon, sizeof(weapon));		
	
	new bool:isEnabled = GetConVarBool(ksEnabled);
	new bool:isRandom = GetConVarBool(ksRandom);
	new bool:clientOnly = GetConVarBool(ksOnlyClient);
	new bool:isCSGO = g_EngineVersion == Engine_CSGO;
	
	if (isEnabled) {
		if (StrContains(weapon, "knife", false) != -1 || (isCSGO && StrContains(weapon, "bayonet", false) != -1)) {
			if (isRandom) {
				decl String:random_sound[PLATFORM_MAX_PATH];
				new random = GetRandomInt(0, GetArraySize(ksSoundFiles) - 1);
				GetArrayString(ksSoundFiles, random, random_sound, sizeof(random_sound));
				if (clientOnly)
					EmitSoundToClient(client, random_sound);		
				else
					EmitSoundToAll(random_sound);
			} else {
				if (clientOnly)
					EmitSoundToClient(client, ksSoundName);		
				else
					EmitSoundToAll(ksSoundName);
			}
		}
	}
	
	return Plugin_Continue;
}