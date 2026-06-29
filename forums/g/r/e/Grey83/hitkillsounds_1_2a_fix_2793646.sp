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
	version = "1.2a_fix",
	url = "https://forums.alliedmods.net/showthread.php?t=298169"
}

//////////////////
// Plugin start //
//////////////////

public void OnPluginStart()
{
	// Server console variables
	CreateConVar("hks_enabled", "1", "Toggle Hit & Kill Sounds [0 - 1] [1]", _, true, _, true, 1.0);
	CreateConVar("hks_hitsound", "1", "Toggle hit sound [0 - 1] [1]", _, true, _, true, 1.0);
	CreateConVar("hks_hitsound_file", "buttons/button15.wav", "Hit sound file [buttons/button15.wav]", FCVAR_PRINTABLEONLY);
	CreateConVar("hks_hitsound_volume", "0.80", "Hit sound volume [0.0 - 1.0] [0.80]", _, true, _, true, 1.0);
	CreateConVar("hks_killsound", "1", "Toggle kill sound [0 - 1] [1]", _, true, _, true, 1.0);
	CreateConVar("hks_killsound_file", "buttons/button17.wav", "Kill sound file [buttons/button17.wav]", FCVAR_PRINTABLEONLY);
	CreateConVar("hks_killsound_volume", "0.80", "Kill sound volume [0.0 - 1.0] [0.80]", _, true, _, true, 1.0);

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
	bool serverPluginEnabled = GetConVarBool(consolePluginEnabled);
	ConVar consoleHitSound = FindConVar("hks_hitsound");
	bool serverHitSound = GetConVarBool(consoleHitSound);

	if(serverPluginEnabled && serverHitSound)
	{
		// Check if client allows
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if(!attacker || !IsClientInGame(attacker) || IsFakeClient(attacker)) return;


		char valuePluginEnabled[8], valueHitSound[8];
		Handle cookiePluginEnabled = FindClientCookie("hks_enabled");
		GetClientCookie(attacker, cookiePluginEnabled, valuePluginEnabled, sizeof(valuePluginEnabled));
		Handle cookieHitSound = FindClientCookie("hks_hitsound");
		GetClientCookie(attacker, cookieHitSound, valueHitSound, sizeof(valueHitSound));

		// Proceed unless client explicitly disabled feature
		if((StringToInt(valuePluginEnabled) || !valuePluginEnabled[0])
		&& (StringToInt(valueHitSound) || !valueHitSound[0]))
		{
			// If client setting empty fall back to server setting
			char hitSoundFile[256], valueHitSoundFile[256], valueHitSoundVolume[8];

			Handle cookieHitSoundFile = FindClientCookie("hks_hitsound_file");
			GetClientCookie(attacker, cookieHitSoundFile, valueHitSoundFile, sizeof(valueHitSoundFile));
			if(!valueHitSoundFile[0])
			{
				// Use server value
				ConVar consoleHitSoundFile = FindConVar("hks_hitsound_file");
				GetConVarString(consoleHitSoundFile, hitSoundFile, sizeof(hitSoundFile));
			}
			else hitSoundFile = valueHitSoundFile;	// Use client value

			float hitSoundVolume;
			Handle cookieHitSoundVolume = FindClientCookie("hks_hitsound_volume");
			GetClientCookie(attacker, cookieHitSoundVolume, valueHitSoundVolume, sizeof(valueHitSoundVolume));
			if(!valueHitSoundVolume[0])
			{
				// Use server value
				ConVar consoleHitSoundVolume = FindConVar("hks_hitsound_volume");
				hitSoundVolume = GetConVarFloat(consoleHitSoundVolume);
			}
			else hitSoundVolume = StringToFloat(valueHitSoundVolume);	// Use client value

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
	bool serverPluginEnabled = GetConVarBool(consolePluginEnabled);
	ConVar consoleKillSound = FindConVar("hks_killsound");
	bool serverKillSound = GetConVarBool(consoleKillSound);

	if(serverPluginEnabled && serverKillSound)
	{
		// Check if client allows
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if(!attacker || !IsClientInGame(attacker) || IsFakeClient(attacker)) return;


		char valuePluginEnabled[8], valueKillSound[8];
		Handle cookiePluginEnabled = FindClientCookie("hks_enabled");
		GetClientCookie(attacker, cookiePluginEnabled, valuePluginEnabled, sizeof(valuePluginEnabled));
		Handle cookieKillSound = FindClientCookie("hks_killsound");
		GetClientCookie(attacker, cookieKillSound, valueKillSound, sizeof(valueKillSound));

		// Proceed unless client explicitly disabled feature
		if((StringToInt(valuePluginEnabled) || !valuePluginEnabled[0])
		&& (StringToInt(valueKillSound) || !valueKillSound[0]))
		{
			// If client setting empty fall back to server setting
			char killSoundFile[256], valueKillSoundFile[256], valueKillSoundVolume[8];

			Handle cookieKillSoundFile = FindClientCookie("hks_killsound_file");
			GetClientCookie(attacker, cookieKillSoundFile, valueKillSoundFile, sizeof(valueKillSoundFile));
			if(!valueKillSoundFile[0])
			{
				// Use server value
				ConVar consoleKillSoundFile = FindConVar("hks_killsound_file");
				GetConVarString(consoleKillSoundFile, killSoundFile, sizeof(killSoundFile));
			}
			else killSoundFile = valueKillSoundFile;	// Use client value

			float killSoundVolume;
			Handle cookieKillSoundVolume = FindClientCookie("hks_killsound_volume");
			GetClientCookie(attacker, cookieKillSoundVolume, valueKillSoundVolume, sizeof(valueKillSoundVolume));
			if(!valueKillSoundVolume[0])
			{
				// Use server value
				ConVar consoleKillSoundVolume = FindConVar("hks_killsound_volume");
				killSoundVolume = GetConVarFloat(consoleKillSoundVolume);
			}
			else killSoundVolume = StringToFloat(valueKillSoundVolume);	// Use client value

			// Send sound to client
			PrecacheSound(killSoundFile);
			EmitSoundToClient(attacker, killSoundFile, SOUND_FROM_PLAYER, SNDCHAN_BODY, SNDLEVEL_NORMAL, SND_NOFLAGS, killSoundVolume);
		}
	}
}