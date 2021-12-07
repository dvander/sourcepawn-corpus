// Based upon Kinfe Mug by FlyingMongoose & sslice
// When a player is stabbed they get publicly humilated in chat and HAHA or other sound in game
// Modified by TnTSCS slightly

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define KO_VERSION 			"1.1a"
#define MAX_FILE_LEN 		80
#define MAX_WEAPON_LENGTH	80

new Handle:g_CvarSoundName = INVALID_HANDLE;
new String:g_soundName[MAX_FILE_LEN];

// Define author information
public Plugin:myinfo = 
{
	name = "Knife Owned",
	author = "MoggieX",
	description = "Ownd by Knife",
	version = KO_VERSION,
	url = "http://www.UKManDown.co.uk"
};

new Handle:cvarEnable;
new bool:g_enabled;

public OnPluginStart()
{
	CreateConVar("sm_knife_Owned_version", KO_VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_DONTRECORD);
	
	cvarEnable = CreateConVar("sm_knife_enable","1","Plays sound and gives chat ntoification when a player is knifed",FCVAR_PLUGIN,true,0.0,true,1.0);
	g_enabled = GetConVarBool(cvarEnable);
	HookConVarChange(cvarEnable, OnEnabledChange);
	
	g_CvarSoundName = CreateConVar("sm_knife_sound", "misc/haha.wav", "The sound to play when a player is knifed");
	GetConVarString(g_CvarSoundName, g_soundName, sizeof(g_soundName));
	HookConVarChange(g_CvarSoundName, OnSoundNameChange);
}

// For sounds and its caching
public OnConfigsExecuted()
{
	decl String:buffer[MAX_FILE_LEN];
	buffer[0] = '\0';
	
	Format(buffer, sizeof(buffer), "sound/%s", g_soundName);
	
	if (FileExists(buffer))
	{
		AddFileToDownloadsTable(buffer);
		
		if (!PrecacheSound(g_soundName, true))
		{
			LogError("Unable to precache sound %s", g_soundName);
		}
	}
	else
	{
		SetFailState("Unalbe to load sound %s", buffer);
	}
}

public OnEnabledChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	g_enabled = GetConVarBool(cvar);
	
	if (g_enabled)
	{
		HookEvent("player_death",ev_PlayerDeath);
	}
	else
	{
		UnhookEvent("player_death",ev_PlayerDeath);
	}
}

public OnSoundNameChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GetConVarString(cvar, g_soundName, sizeof(g_soundName));
}

public ev_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if enabled, if not bail out
	if (!g_enabled)
	{
		return;
	}
	
	decl String:weaponName[MAX_WEAPON_LENGTH];
	
	GetEventString(event, "weapon", weaponName, sizeof(weaponName));

	// if the weapon used in death was a knife it continues
	if (StrEqual(weaponName, "knife"))
	{
		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		
		if (killer > 0 && killer <= MaxClients)
		{
			new victim = GetClientOfUserId(GetEventInt(event, "userid"));
			
			new victimTeam = GetClientTeam(victim);
			new killerTeam = GetClientTeam(killer);
			
			if (killerTeam != victimTeam)
			{
				PrintToChatAll("\x04%N\x03 was OWND with a knife by \x04%N", victim, killer);
				EmitSoundToAll(g_soundName, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_RAIDSIREN);
			}
		}
	}
}

