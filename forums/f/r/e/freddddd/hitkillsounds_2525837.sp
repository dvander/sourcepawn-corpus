///////////////////////////////////////////////////////
//
// License information
//
// Creative Commons Zero
// Public Domain Dedication
//
// CC0 1.0 Universal
// https://creativecommons.org/publicdomain/zero/1.0
//
///////////////////////////////////////////////////////

//////////////
// Includes //
//////////////

#include <sourcemod>
#include <clientprefs>
#include <sdktools_sound>

////////////////////////
// Plugin information //
////////////////////////

public Plugin myinfo =
{
	name = "Hit & Kill Sounds",
	description = "Hit and kill sounds with extended features",
	author = "Fred",
	version = "1.2a",
	url = "https://forums.alliedmods.net/showthread.php?t=298169"
}

//////////////////
// Plugin start //
//////////////////

public void OnPluginStart()
{
	// Server console variables
	
	CreateConVar("hks_enabled", "1", "Toggle Hit & Kill Sounds [0 - 1] [1]");
	CreateConVar("hks_hitsound", "1", "Toggle hit sound [0 - 1] [1]");
	CreateConVar("hks_hitsound_file", "buttons/button15.wav", "Hit sound file [buttons/button15.wav]");
	CreateConVar("hks_hitsound_volume", "0.80", "Hit sound volume [0.0 - 1.0] [0.80]");
	CreateConVar("hks_killsound", "1", "Toggle kill sound [0 - 1] [1]");
	CreateConVar("hks_killsound_file", "buttons/button17.wav", "Kill sound file [buttons/button17.wav]");
	CreateConVar("hks_killsound_volume", "0.80", "Kill sound volume [0.0 - 1.0] [0.80]");
	
		// Client setting cookies
	
	RegClientCookie("hks_enabled", "Toggle Hit & Kill Sounds [0 - 1] [1]", CookieAccess_Public);
	RegClientCookie("hks_hitsound", "Toggle hit sound [0 - 1] [1]", CookieAccess_Public);
	RegClientCookie("hks_hitsound_file", "Hit sound file [buttons/button15.wav]", CookieAccess_Public);
	RegClientCookie("hks_hitsound_volume", "Hit sound volume [0.0 - 1.0] [0.80]", CookieAccess_Public);
	RegClientCookie("hks_killsound", "Toggle kill sound [0 - 1] [1]", CookieAccess_Public);
	RegClientCookie("hks_killsound_file", "buttons/button17.wav", CookieAccess_Public);
	RegClientCookie("hks_killsound_volume", "Kill sound volume [0.0 - 1.0] [0.80]", CookieAccess_Public);
	
	// Hooks
	
	HookEvent("player_hurt", PlayerHurt);
	HookEvent("player_death", PlayerDeath);
	
	// Automatic server configuration generation
	
	AutoExecConfig(true, "hitkillsounds", "sourcemod/hitkillsounds");
}

//////////////////////
// Player hurt hook //
//////////////////////

public void PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	// Check if server allows
	
	ConVar consolePluginEnabled = FindConVar("hks_enabled");
	ConVar consoleHitSound = FindConVar("hks_hitsound");
	
	bool serverPluginEnabled = GetConVarBool(consolePluginEnabled);
	bool serverHitSound = GetConVarBool(consoleHitSound);
	
	if (serverPluginEnabled && serverHitSound)
	{
		// Check if client allows
		
		int attackerID = event.GetInt("attacker");
		int attacker = GetClientOfUserId(attackerID);
		
		Handle cookiePluginEnabled = FindClientCookie("hks_enabled");
		Handle cookieHitSound = FindClientCookie("hks_hitsound");
		
		char valuePluginEnabled[8];
		char valueHitSound[8];
		
		GetClientCookie(attacker, cookiePluginEnabled, valuePluginEnabled, sizeof(valuePluginEnabled));
		GetClientCookie(attacker, cookieHitSound, valueHitSound, sizeof(valueHitSound));
		
		// Proceed unless client explicitly disabled feature
		
		bool clientPluginEnabledEmpty = StrEqual(valuePluginEnabled, "");
		bool clientHitSoundEmpty = StrEqual(valueHitSound, "");
		
		bool clientPluginEnabled = bool:StringToInt(valuePluginEnabled);
		bool clientHitSoundEnabled = bool:StringToInt(valueHitSound);
		
		if ((clientPluginEnabled || clientPluginEnabledEmpty) && (clientHitSoundEnabled || clientHitSoundEmpty))
		{
			// If client setting empty fall back to server setting
			
			char hitSoundFile[256];
			float hitSoundVolume;
			
			Handle cookieHitSoundFile = FindClientCookie("hks_hitsound_file");
			Handle cookieHitSoundVolume = FindClientCookie("hks_hitsound_volume");
			
			char valueHitSoundFile[256];
			char valueHitSoundVolume[8];
			
			GetClientCookie(attacker, cookieHitSoundFile, valueHitSoundFile, sizeof(valueHitSoundFile));
			GetClientCookie(attacker, cookieHitSoundVolume, valueHitSoundVolume, sizeof(valueHitSoundVolume));
			
			bool clientHitSoundFileEmpty = StrEqual(valueHitSoundFile, "");
			bool clientHitSoundVolumeEmpty = StrEqual(valueHitSoundVolume, "");
			
			if (clientHitSoundFileEmpty)
			{
				// Use server value
				
				ConVar consoleHitSoundFile = FindConVar("hks_hitsound_file");
				GetConVarString(consoleHitSoundFile, hitSoundFile, sizeof(hitSoundFile));
			}
			else
			{
				// Use client value
				
				hitSoundFile = valueHitSoundFile;
			}
			
			if (clientHitSoundVolumeEmpty)
			{
				// Use server value
				
				ConVar consoleHitSoundVolume = FindConVar("hks_hitsound_volume");
				hitSoundVolume = GetConVarFloat(consoleHitSoundVolume);
			}
			else
			{
				// Use client value
				
				hitSoundVolume = StringToFloat(valueHitSoundVolume);
			}
			
			// Send sound to client
			PrecacheSound(hitSoundFile);
			EmitSoundToClient(attacker, hitSoundFile, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_NOFLAGS, hitSoundVolume);
		}
	}
}

///////////////////////
// Player death hook //
///////////////////////

public void PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	// Check if server allows
	
	ConVar consolePluginEnabled = FindConVar("hks_enabled");
	ConVar consoleKillSound = FindConVar("hks_killsound");
	
	bool serverPluginEnabled = GetConVarBool(consolePluginEnabled);
	bool serverKillSound = GetConVarBool(consoleKillSound);
	
	if (serverPluginEnabled && serverKillSound)
	{
		// Check if client allows
		
		int attackerID = event.GetInt("attacker");
		int attacker = GetClientOfUserId(attackerID);
		
		Handle cookiePluginEnabled = FindClientCookie("hks_enabled");
		Handle cookieKillSound = FindClientCookie("hks_killsound");
		
		char valuePluginEnabled[8];
		char valueKillSound[8];
		
		GetClientCookie(attacker, cookiePluginEnabled, valuePluginEnabled, sizeof(valuePluginEnabled));
		GetClientCookie(attacker, cookieKillSound, valueKillSound, sizeof(valueKillSound));
		
		// Proceed unless client explicitly disabled feature
		
		bool clientPluginEnabledEmpty = StrEqual(valuePluginEnabled, "");
		bool clientKillSoundEmpty = StrEqual(valueKillSound, "");
		
		bool clientPluginEnabled = bool:StringToInt(valuePluginEnabled);
		bool clientKillSoundEnabled = bool:StringToInt(valueKillSound);
		
		if ((clientPluginEnabled || clientPluginEnabledEmpty) && (clientKillSoundEnabled || clientKillSoundEmpty))
		{
			// If client setting empty fall back to server setting
			
			char killSoundFile[256];
			float killSoundVolume;
			
			Handle cookieKillSoundFile = FindClientCookie("hks_killsound_file");
			Handle cookieKillSoundVolume = FindClientCookie("hks_killsound_volume");
			
			char valueKillSoundFile[256];
			char valueKillSoundVolume[8];
			
			GetClientCookie(attacker, cookieKillSoundFile, valueKillSoundFile, sizeof(valueKillSoundFile));
			GetClientCookie(attacker, cookieKillSoundVolume, valueKillSoundVolume, sizeof(valueKillSoundVolume));
			
			bool clientKillSoundFileEmpty = StrEqual(valueKillSoundFile, "");
			bool clientKillSoundVolumeEmpty = StrEqual(valueKillSoundVolume, "");
			
			if (clientKillSoundFileEmpty)
			{
				// Use server value
				
				ConVar consoleKillSoundFile = FindConVar("hks_killsound_file");
				GetConVarString(consoleKillSoundFile, killSoundFile, sizeof(killSoundFile));
			}
			else
			{
				// Use client value
				
				killSoundFile = valueKillSoundFile;
			}
			
			if (clientKillSoundVolumeEmpty)
			{
				// Use server value
				
				ConVar consoleKillSoundVolume = FindConVar("hks_killsound_volume");
				killSoundVolume = GetConVarFloat(consoleKillSoundVolume);
			}
			else
			{
				// Use client value
				
				killSoundVolume = StringToFloat(valueKillSoundVolume);
			}
			
			// Send sound to client
			PrecacheSound(killSoundFile);
			EmitSoundToClient(attacker, killSoundFile, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_NOFLAGS, killSoundVolume);
		}
	}
}