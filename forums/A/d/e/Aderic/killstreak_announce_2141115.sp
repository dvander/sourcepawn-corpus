#pragma semicolon 						1

#include <sourcemod>
#include <sdktools>
#include <regex>

#define MAX_LEVEL_LENGTH				4

#define MAX_IDENTITY_COUNT				16
#define MAX_IDENTITY_SECTION_LENGTH		256
#define MAX_IDENTITY_LENGTH				19

#define PLUGIN_VERSION	"1.0"
#define PLUGIN_PREFIX	"[Killstreak Announce]"

new Handle:CVAR_pluginVersion;
new Handle:soundObjects;

enum killstreakKey {
	ksk_level = 0,
	String:ksk_soundFile[PLATFORM_MAX_PATH],
	Float:ksk_volume,
	Handle:ksk_identities
}

public Plugin:myinfo = 
{
	name = "Killstreak Announce",
	author = "Aderic",
	description = "Plays a specific sound when a player gets a certain killstreak number.",
	version = PLUGIN_VERSION
}

public OnPluginStart() {
	if (GetEngineVersion() != Engine_TF2) {
		SetFailState("Plugin is only compatible with TF2.");
	}
	
	CVAR_pluginVersion =  CreateConVar("sm_killstreakannounce_version", 	PLUGIN_VERSION, 		"Current version of the plugin. Read Only", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	HookConVarChange(CVAR_pluginVersion, 	OnPluginVersionChanged);
	
	HookEvent("player_death", OnPlayerDeath);
	
	soundObjects = CreateArray(killstreakKey);
	
	decl String:configPath[256];
	BuildPath(Path_SM, configPath, sizeof(configPath), "configs/killstreak_announce.cfg");
	
	new Handle:config = CreateKeyValues("killstreak_announce");
	
	if (!FileToKeyValues(config, configPath)) {
		CloseHandle(config);
	}
	
	if (!KvGotoFirstSubKey(config)) {
		CloseHandle(config);
	}
	
	do {
		decl String:soundPath[PLATFORM_MAX_PATH];
		KvGetString(config, "sound", soundPath, PLATFORM_MAX_PATH, NULL_STRING);
		
		if (StrIsNull(soundPath)) {
			KvGetSectionName(config, soundPath, PLATFORM_MAX_PATH);
			PrintToServer("%s Warning: No sound file specified for level %s!", PLUGIN_PREFIX, soundPath);
			continue; // Skip this misconfigured key.
		}
		
		decl String:killstreakLevel[MAX_LEVEL_LENGTH];
		KvGetSectionName(config, killstreakLevel, PLATFORM_MAX_PATH);
		
		decl String:identityString[MAX_IDENTITY_SECTION_LENGTH];
		KvGetString(config, "restrict", identityString, MAX_IDENTITY_SECTION_LENGTH, NULL_STRING);
		
		new Float:volume = KvGetFloat(config, "volume", 1.0);
		
		new Handle:identities;
		
		if (StrIsNull(identityString) == false) {
			new String:parts[MAX_IDENTITY_COUNT][MAX_IDENTITY_LENGTH];
			ExplodeString(identityString, ";", parts, MAX_IDENTITY_COUNT, MAX_IDENTITY_LENGTH);

			identities = CreateArray(MAX_IDENTITY_LENGTH);
			
			for (new partIndex = 0; partIndex < MAX_IDENTITY_COUNT; partIndex++) {
				if (StrIsNull(parts[partIndex])) break;
				
				if (IsValidSteamId(parts[partIndex])) {
					for (new char = 0; char < 5; char++) {
						parts[partIndex][char] = CharToUpper(parts[partIndex][char]);
					}
				}
				
				PushArrayString(identities, parts[partIndex]);
			}
		}
		
		// Add item
		new object[killstreakKey];
		object[ksk_level] = StringToInt(killstreakLevel);
		strcopy(object[ksk_soundFile], PLATFORM_MAX_PATH, soundPath);
		object[ksk_volume] = volume;
		object[ksk_identities] = identities;
		PushArrayArray(soundObjects, object);
		
	} while (KvGotoNextKey(config));
	
	CloseHandle(config);
}
// Blocks changing of the plugin version.
public OnPluginVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	// If the newly set value is different from the actual version number.
	if (StrEqual(newVal, PLUGIN_VERSION) == false) {
		// Set it back to the way it was supposed to be.
		SetConVarString(cvar, PLUGIN_VERSION);
	}
}

// Prepare sounds for download and usage.
public OnMapStart() {
	decl String:fileName[PLATFORM_MAX_PATH];
	new arrSize = GetArraySize(soundObjects);
	new soundObj[killstreakKey];
	
	for (new cId = 0; cId < arrSize; cId++) {
		GetArrayArray(soundObjects, cId, soundObj);
		
		PrecacheSound(soundObj[ksk_soundFile], true);
		
		Format(fileName, PLATFORM_MAX_PATH, "sound/%s", soundObj[ksk_soundFile]);
		AddFileToDownloadsTable(fileName);
	}	
}
// Plays sound when player dies.
public Action:OnPlayerDeath(Handle:event, String:name[], bool:dontBroadcast) {
	new attackerEnt = GetEventInt(event, "attacker");
	if (attackerEnt < 1 || attackerEnt > MaxClients)
		return Plugin_Continue;
	
	new client = GetClientOfUserId(attackerEnt);
	
	new killstreak = GetEventInt(event, "kill_streak_total");
	
	if (killstreak == 0)
		return Plugin_Continue;
	
	new arraySize = GetArraySize(soundObjects);
	
	decl String:soundPath[PLATFORM_MAX_PATH];
	decl Float:volume;
	
	for (new kIndex = 0; kIndex < arraySize; kIndex++) {
		volume = GetAnnounceInfo(kIndex, client, killstreak, soundPath, kIndex == arraySize-1);
		while (volume != 0.0) {
			if (volume < 1.0) {
				EmitSoundToAll(soundPath, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_CHANGEVOL, volume);
				return Plugin_Continue;
			}
			else {
				EmitSoundToAll(soundPath, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS);
				volume -= 1.0;
				
				if (volume == 0.0)
					return Plugin_Continue;
			}
		}
	}
	
	return Plugin_Continue;
}


Float:GetAnnounceInfo(const index, const client, const killCount, String:soundPath[PLATFORM_MAX_PATH], bool:mustPlay=false) {
	new object[killstreakKey];
	GetArrayArray(soundObjects, index, object);
	
	// Our fallback sound for when no other sound exists to be played.
	if (mustPlay == true && (killCount % 5) == 0) {
		strcopy(soundPath, PLATFORM_MAX_PATH, object[ksk_soundFile]);
		return object[ksk_volume];
	}
	
	if (killCount != object[ksk_level]) {
		return 0.0;
	}
	
	if (object[ksk_identities] == INVALID_HANDLE) {
		strcopy(soundPath, PLATFORM_MAX_PATH, object[ksk_soundFile]);
		return object[ksk_volume];
	}
	
	if (GetUserAdmin(client) == INVALID_ADMIN_ID) {
		return 0.0;
	}
	
	new identityCount = GetArraySize(object[ksk_identities]);
	
	new String:identifier[MAX_IDENTITY_LENGTH];
	
	new String:clientSteam[MAX_IDENTITY_LENGTH];
	GetClientAuthString(client, clientSteam, MAX_IDENTITY_LENGTH);
	
	for (new identityIndex = 0; identityIndex < identityCount; identityIndex++) {
		GetArrayString(object[ksk_identities], identityIndex, identifier, MAX_IDENTITY_LENGTH);
		
		if (IsValidSteamId(identifier) && StrEqual(clientSteam, identifier)) {
			strcopy(soundPath, PLATFORM_MAX_PATH, object[ksk_soundFile]);
			return object[ksk_volume];
		}
		else {
			if (CheckCommandAccess(client, NULL_STRING, buildBitString(identifier), true)) {
				strcopy(soundPath, PLATFORM_MAX_PATH, object[ksk_soundFile]);
				return object[ksk_volume];
			}
		}
	}
	
	return 0.0;
}

buildBitString(const String:string[]) {
	new bitString;
	new strLen = strlen(string);
	new flag;
	
	for (new charIndex = 0; charIndex < strLen; charIndex++) {
		if (FindFlagByChar(char:string[charIndex], AdminFlag:flag)) {
			bitString |=(1<<flag);
		}
	}
	
	return bitString;
}

bool:StrIsNull(const String:string[]) {
	return string[0] == 0;
}
bool:IsValidSteamId(String:string[]) {
	return (SimpleRegexMatch(string, "^((?i)STEAM)_0:[01]:[0-9]{1,9}$") != 0);
}