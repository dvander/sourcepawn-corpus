#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_VERSION "3.0"
#pragma semicolon 1

EngineVersion g_EngineVersion;

new Handle:ksSoundFile = INVALID_HANDLE;
new String:ksSoundName[PLATFORM_MAX_PATH];

new Handle:ksEnabled = INVALID_HANDLE;
new Handle:ksOnlyClient = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "KnifeSound 3.0",
	author = "IceQ?!",
	description = "Plays a specified sound when a player gets killed with a knife",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/official_iceq"
};

public OnPluginStart()
{
	g_EngineVersion = GetEngineVersion();
	CreateConVar("sm_knifesound_version", PLUGIN_VERSION, "Plays a specified sound when a player gets killed with a knife", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	ksEnabled = CreateConVar("sm_knifesound_enable", "1", "0: Disable Plugin | 1: Enable Plugin");
	ksSoundFile = CreateConVar("sm_knifesound_file", "knifesound/humiliation.mp3",	"Customizable Knifesound File ( without sound/ )");
	ksOnlyClient = CreateConVar("sm_knifesound_client_only", "0", "0: Plays the sound to everybody | 1: Plays the sound only to the killed player");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public OnConfigsExecuted()
{
	GetConVarString(ksSoundFile, ksSoundName, PLATFORM_MAX_PATH);
	decl String:buffer[PLATFORM_MAX_PATH];
	PrecacheSound(ksSoundName, true);
	Format(buffer, sizeof(buffer), "sound/%s", ksSoundName);
	AddFileToDownloadsTable(buffer);
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
	new bool:clientOnly = GetConVarBool(ksOnlyClient);
	new bool:isCSGO = g_EngineVersion == Engine_CSGO;
	
	if (isEnabled) {
		if (StrContains(weapon, "knife", false) != -1 || (isCSGO && StrContains(weapon, "bayonet", false) != -1)) {
			if (clientOnly)
				EmitSoundToClient(client, ksSoundName);		
			else
				EmitSoundToAll(ksSoundName);
		}
	}
	
	return Plugin_Continue;
}