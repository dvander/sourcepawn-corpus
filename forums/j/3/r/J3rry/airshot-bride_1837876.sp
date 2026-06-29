// Enable strict semicolon mode
#pragma semicolon 1

// Includes
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

// Include SMLIB
#include <smlib>

// Constants
#define PLUGIN_VERSION "1.1.0"
#define BUFFER_SIZE 1024
#define MAX_WEAPON_LENGTH 128

// Information about the plugin
public Plugin:myinfo =
{
	name = "[TF2] Airshot Bride",
	author = "Jerry",
	description = "Plays a sound upon a successful airshot.",
	version = PLUGIN_VERSION,
	url = "http://jerry.devzero.info/"
}; // myinfo

// CVars
new Handle:CVarSoundFile = INVALID_HANDLE;
new Handle:CVarSoundVolume = INVALID_HANDLE;
new Handle:CVarPlaybackMode = INVALID_HANDLE;
new Handle:CVarStopSound = INVALID_HANDLE;
new Handle:CVarHeadshotOnly = INVALID_HANDLE;
new Handle:CVarMinimumHeight = INVALID_HANDLE;
new Handle:CVarPlayOnSuicide = INVALID_HANDLE;

// Variables (sound files)
new SoundFileCount;
new LastSoundFile;
new Handle:SoundsArray = INVALID_HANDLE;

// Variables (weapons)
new Handle:WeaponsArray = INVALID_HANDLE;
new Handle:HeadshotWeaponsArray = INVALID_HANDLE;

// Default list of weapons that can be used to trigger the airshot sound
new String:DefaultWeaponList[][] =
{
	// Rocket Launchers
	"tf_projectile_rocket",             // Rocket Launcher
	"rocketlauncher_directhit",
	"blackbox",
	"liberty_launcher",
	"quake_rl",                         // Original
	"dumpster_device",                  // Beggar's Bazooka
	"cow_mangler",

	// Grenade Launchers
	"tf_projectile_pipe",               // Grenade Launcher
	"loch_n_load",
	"loose_cannon_impact",
	"loose_cannon_explosion",

	// Stickybomb Launchers
	"tf_projectile_pipe_remote",        // Stickybomb Launcher
	"sticky_resistance",                // Scottish Resistance

	// Sniper Rifles
	"sniperrifle",
	"huntsman",
	"sydney_sleeper",
	"bazaar_bargain",
	"machina",
	"pro_rifle",                        // Hitman's Heatmaker

	// Revolvers
	"revolver",
	"samrevolver",                      // Big Kill
	"ambassador",
	"letranger",
	"enforcer",
	"diamondback",

	// Fun stuff
	"market_gardener"
}; // DefaultWeaponList[][]

// Default list of weapons that must headshot in headshot-only-mode (including weapons that can't headshot)
new String:DefaultHeadshotWeaponList[][] =
{
	"sniperrifle",
	"huntsman",
	"sydney_sleeper",
	"bazaar_bargain",
	"machina",
	"pro_rifle",                        // Hitman's Heatmaker

	"revolver",
	"samrevolver",                      // Big Kill
	"ambassador",
	"letranger",
	"enforcer",
	"diamondback"
}; // DefaultHeadshotWeaponList[][]

// OnPluginStart(): Perform plugin initialization
public OnPluginStart()
{
	// Hook the player_death event
	HookEvent("player_death", EventPlayerDeath);

	// Create CVars and have SourceMod automatically create the configuration file for us
	CVarSoundFile = CreateConVar("sm_airshot_sound", "addons/sourcemod/configs/airshot-bride.sounds.txt", "Path to the sound file(s) played when a player dies to an airshot");
	CVarSoundVolume = CreateConVar("sm_airshot_volume", "1.0", "Volume of the airshot sound (0.0 = completely muted, 1.0 = full volume)", 0, true, 0.0, true, 1.0);
	CVarPlaybackMode = CreateConVar("sm_airshot_playback_mode", "0", "Order in which the airshot sound files will be played (0 = random, 1 = sequential)", 0, true, 0.0, true, 1.0);
	CVarStopSound = CreateConVar("sm_airshot_stopsound", "1", "If set to 1, the airshot sound will be restarted if it's still playing while another airshot occurs.");
	CVarHeadshotOnly = CreateConVar("sm_airshot_headshot_only", "1", "If set to 1, players using any Sniper Rifle or Revolver *will* have to do headshots for the airshot sound to play.");
	CVarMinimumHeight = CreateConVar("sm_airshot_min_height", "100.0", "The minimum distance above the ground a player needs to be to trigger the airshot sound. Set to 0 to disable.", 0, true, 0.0);
	CVarPlayOnSuicide = CreateConVar("sm_airshot_play_on_suicide", "0", "If set to 1, the sound will be played if players kill themselves while they are in the air.");
	AutoExecConfig();

	// Prepare the arrays
	SoundsArray = CreateArray(ByteCountToCells(PLATFORM_MAX_PATH));
	WeaponsArray = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
	HeadshotWeaponsArray = CreateArray(ByteCountToCells(MAX_WEAPON_LENGTH));
} // OnPluginStart()

// OnConfigsExecuted(): Read in the list of sound files to play and the list of eligible weapons, precache all sounds and add them to the downloads table
public OnConfigsExecuted()
{
	new String:fileName[PLATFORM_MAX_PATH];
	new String:buffer[BUFFER_SIZE];
	new Handle:fileHandle;
	new weaponCount;
	new headshotWeaponCount;
	new offset;
	new i;

	// Reset the array
	ClearArray(SoundsArray);

	GetConVarString(CVarSoundFile, fileName, sizeof(fileName));
	if (StrEqual(fileName[strlen(fileName) - strlen(".txt")], ".txt", true))
	{
		// Filename ends with ".txt", treat it like a list of sound files to play
		LogMessage("Reading list of sound files from file: %s", fileName);
		if (!FileExists(fileName))
			SetFailState("Cannot read list of sound files: file \"%s\" does not exist.", fileName);

		fileHandle = OpenFile(fileName, "r");
		if (fileHandle == INVALID_HANDLE)
			SetFailState("Cannot read list of sound files: could not open file \"%s\".", fileName);

		SoundFileCount = 0;

		while (ReadFileLine(fileHandle, buffer, sizeof(buffer)))
		{
			// Skip comments (by cutting off where the comment started)
			if ((offset = StrContains(buffer, "//")) != -1)
				buffer[offset] = '\0';
			if ((offset = StrContains(buffer, "#")) != -1)
				buffer[offset] = '\0';

			TrimString(buffer);

			// Skip empty lines
			if (strlen(buffer) == 0)
				continue;

			if (!ValidateSoundFile(buffer))
			{
				LogMessage("Skipping invalid sound file: %s", buffer);
				continue;
			}

			// Prepare the sound
			PushArrayString(SoundsArray, buffer);
			++SoundFileCount;
			PrepareSound(buffer);
		}

		CloseHandle(fileHandle);

		if (SoundFileCount < 1)
			SetFailState("No valid sound file has been specified.");
	}
	else
	{
		// Treat the filename as a single sound file to play
		if (!ValidateSoundFile(fileName))
			SetFailState("Invalid sound file specified: %s", fileName);

		LogMessage("Preparing single sound file: %s", fileName);
		SoundFileCount = 1;
		PushArrayString(SoundsArray, fileName);
		PrepareSound(fileName);
	}

	BuildPath(Path_SM, fileName, sizeof(fileName), "configs/airshot-bride.weapons.txt");
	if (!FileExists(fileName))
	{
		LogMessage("Weapon list missing (%s), falling back to default.", fileName);
		weaponCount = sizeof(DefaultWeaponList);
		headshotWeaponCount = sizeof(DefaultHeadshotWeaponList);

		// Copy over the default lists
		ResizeArray(WeaponsArray, weaponCount);
		for (i = 0; i < weaponCount; ++i)
			SetArrayString(WeaponsArray, i, DefaultWeaponList[i]);

		ResizeArray(HeadshotWeaponsArray, headshotWeaponCount);
		for (i = 0; i < headshotWeaponCount; ++i)
			SetArrayString(HeadshotWeaponsArray, i, DefaultHeadshotWeaponList[i]);
	}
	else
	{
		LogMessage("Reading list of weapons from file: %s", fileName);
		fileHandle = OpenFile(fileName, "r");
		if (fileHandle == INVALID_HANDLE)
			SetFailState("Cannot read list of weapons: could not open file: %s", fileName);

		// Prepare the arrays
		ClearArray(WeaponsArray);
		ClearArray(HeadshotWeaponsArray);
		weaponCount = 0;
		headshotWeaponCount = 0;

		while (ReadFileLine(fileHandle, buffer, sizeof(buffer)))
		{
			// Skip comments (by cutting off where the comment started)
			if ((offset = StrContains(buffer, "//")) != -1)
				buffer[offset] = '\0';
			if ((offset = StrContains(buffer, "#")) != -1)
				buffer[offset] = '\0';

			TrimString(buffer);

			// Skip empty lines
			if (strlen(buffer) == 0)
				continue;

			// Check for headshots
			if (buffer[0] == '*')
			{
				// This weapon must do headshots in headshot-only-mode. Remove the * and any subsequent whitespace from the weapon name.
				buffer[0] = ' ';
				TrimString(buffer);
				PushArrayString(HeadshotWeaponsArray, buffer);
				++headshotWeaponCount;
			}

			// Non-existing weapons don't hurt - no validation here. Just add the weapon to the list.
			// Notifying the user in case they mistyped a weapon name would be nice, but I don't want to
			// maintain a complete list of all weapons in this code.
			PushArrayString(WeaponsArray, buffer);
			++weaponCount;
		}

		CloseHandle(fileHandle);

		if (weaponCount < 1)
			SetFailState("No weapons that can trigger the airshot sound were specified.");
	}

	LogMessage("Setup complete, %d sound file(s) and %d weapon(s) loaded.", SoundFileCount, weaponCount);
} // OnConfigsExecuted()

// ValidateSoundFile(): Check whether a sound file is valid
bool:ValidateSoundFile(String:filename[])
{
	if (!FileExists(filename))
		return false;

	if (StrContains(filename, "sound/") != 0)
		return false;
	
	return true;
} // ValidateSoundFile()

// PrepareSound(): Precache a sound and add it to the downloads table
PrepareSound(String:filename[])
{
	// We just assume that it has already been validated and begins with "sound/"
	PrecacheSound(filename[strlen("sound/")]);
	AddFileToDownloadsTable(filename);
} // PrepareSound()

// EventPlayerDeath(): Handle a player's death and play a sound if necessary
public Action:EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Attacker and victim
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));

	// Weapon stuff
	new String:weapon[MAX_WEAPON_LENGTH];
	new customkill;

	// Sound stuff
	new String:soundFile[PLATFORM_MAX_PATH];
	new soundIndex;
	new playbackMode;

	// Height check
	new Float:min_height = GetConVarFloat(CVarMinimumHeight);

	// If the attacker or the victim isn't valid, it might be an environmental death which should be ignored.
	if (!Client_IsValid(attacker) || !Client_IsValid(victim))
		return Plugin_Continue;

	// Ignore people who blow themselves up, unless we've been told not to
	if ((attacker == victim) && !(GetConVarBool(CVarPlayOnSuicide)))
		return Plugin_Continue;

	// If they are not in the water and not in the air, they are airborne. And if they're not airborne, it's not an airshot.
	if ((GetEntityFlags(victim) & (FL_INWATER | FL_ONGROUND)))
		return Plugin_Continue;

	// Get the name of the used weapon
	GetEventString(event, "weapon", weapon, sizeof(weapon));

	// Only continue if the weapon can trigger airshots.
	if (!(FindStringInArray(WeaponsArray, weapon) >= 0))
		return Plugin_Continue;

	// Check for the required height
	if ((min_height > 0) && (DistanceAboveGround(victim) < min_height))
		return Plugin_Continue;

	// Do we need to check for headshots?
	if (GetConVarBool(CVarHeadshotOnly))
	{
		// Headshot-only-mode is enabled, check whether this weapon can do headshots.
		if (FindStringInArray(HeadshotWeaponsArray, weapon) >= 0)
		{
			// It can, or rather, must do headshots to play the airshot sound.
			customkill = GetEventInt(event, "customkill");
			if ((customkill != TF_CUSTOM_HEADSHOT) && (customkill != TF_CUSTOM_HEADSHOT_DECAPITATION) && (customkill != TF_CUSTOM_PENETRATE_HEADSHOT))
			{
				// A headshot is necessary to trigger the sound, but this kill wasn't a headshot, so we return at this point.
				return Plugin_Continue;
			}
		}
	}

	// Stop the sound first if necessary.
	if (GetConVarBool(CVarStopSound))
	{
		GetArrayString(SoundsArray, LastSoundFile, soundFile, sizeof(soundFile));
		EmitSoundToAll(soundFile[strlen("sound/")], _, _, _, SND_STOPLOOPING);
	}

	// Determine which file to play
	playbackMode = GetConVarInt(CVarPlaybackMode);
	if (playbackMode == 0)
	{
		// Play a random sound file.
		soundIndex = GetRandomInt(0, SoundFileCount - 1);
	}
	else if (playbackMode == 1)
	{
		// Play the next sound file.
		soundIndex = LastSoundFile + 1;

		// Reset to 0 if necessary
		if (soundIndex >= SoundFileCount)
			soundIndex = 0;
	}
	GetArrayString(SoundsArray, soundIndex, soundFile, sizeof(soundFile));

	// Remember the last file we played
	LastSoundFile = soundIndex;

	// Play the sound
	EmitSoundToAll(soundFile[strlen("sound/")], _, _, _, _, GetConVarFloat(CVarSoundVolume));

	return Plugin_Continue;
} // EventPlayerDeath()

// DistanceAboveGround(): Calculate a player's distance above the ground.
// Code borrowed from MGE Mod, thanks to Lange!
Float:DistanceAboveGround(client)
{
	decl Float:vStart[3];
	decl Float:vEnd[3];
	new Float:vAngles[3] = {90.0, 0.0, 0.0};
	new Handle:trace;
	new Float:distance = -1.0;

	// Get the client's origin vector and start up the trace ray
	GetClientAbsOrigin(client, vStart);
	trace = TR_TraceRayFilterEx(vStart, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if (TR_DidHit(trace))
	{
		// Calculate the distance.
		TR_GetEndPosition(vEnd, trace);
		distance = GetVectorDistance(vStart, vEnd, false);
	}
	else
	{
		// There should always be some ground under the player.
		LogError("[Airshot Bride] Trace error: client %N (%d)", client, client);
	}

	// Clean up and return
	CloseHandle(trace);
	return distance;
} // DistanceAboveGround()

// TraceEntityFilterPlayer(): Ignore players in a trace ray
public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return !Client_IsValid(entity);
} // TraceEntityFilterPlayer()
