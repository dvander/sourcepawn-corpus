/**
 * [L4D] Crowned Horde
 * Created by Bigbuck
 *
 */

/**
	v1.0.0
	- Initial Release

	v1.0.1
	- Added translation support
	- Added option to set what event(s) trigger the horde

	v1.0.2
	- Added seperate CVAR's to control trigger events
 */

// Force strict semicolon mode
#pragma semicolon 1

/**
 * Includes
 *
 */
#include <sourcemod>
#include <sdktools>

/**
 * Defines
 *
 */
#define PLUGIN_VERSION	"1.0.2"
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define CVAR_FLAGS_NO	FCVAR_PLUGIN|FCVAR_SPONLY

/**
 * Handles
 *
 */
new Handle: Sound								= INVALID_HANDLE;
new Handle: Sound_File						= INVALID_HANDLE;
new Handle: Announcements					= INVALID_HANDLE;
new Handle: Trigger_Witch_Annoyed			= INVALID_HANDLE;
new Handle: Trigger_Witch_Annoyed_First	= INVALID_HANDLE;
new Handle: Trigger_Witch_Killed			= INVALID_HANDLE;
new Handle: Trigger_Witch_Crowned			= INVALID_HANDLE;
new Handle: Trigger_Witch_Random			= INVALID_HANDLE;

/**
 * Global variables
 *
 */
// Detects L4D2
new bool: game_l4d2 = false;

/**
 * Plugin information
 *
 */
public Plugin: myinfo =
{
	name = "[L4D/2] Crowned Horde",
	author = "Bigbuck",
	description = "Sends out a horde when a witched has been killed.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck-sm.assembla.com/spaces/dashboard/index/bigbuck-sm"
};

/**
 * Setup plugins first run
 *
 */
public OnPluginStart()
{
	// Require Left 4 Dead
	decl String: game_name[64];
	GetGameFolderName(game_name, sizeof(game_name));
	if (!StrEqual(game_name, "left4dead", false) && !StrEqual(game_name, "left4dead2", false))
	{
		SetFailState("Use this in Left 4 Dead or Left 4 Dead 2 only.");
	}
	// We need to know if L4D2 is running
	if (StrEqual(game_name, "left4dead2", false))
	{
		game_l4d2 = true;
	}

	// Create convars
	CreateConVar("sm_l4d_crowned_horde_version", PLUGIN_VERSION, "[L4D/2] Crowned Horde Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Sound								= CreateConVar("sm_l4d_ch_sound", "1", "Play a sound when the witch has been crowned?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Sound_File						= CreateConVar("sm_l4d_ch_sound_file", "npc/witch/voice/attack/Female_DistantScream2.wav", "The sound file to play relative to the sounds directory.", CVAR_FLAGS);
	Announcements					= CreateConVar("sm_l4d_ch_announcements", "1", "Enable or disable announcements.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Trigger_Witch_Annoyed			= CreateConVar("sm_l4d_ch_trigger_witch_annoyed", "0", "Alerts the horde when a witch is annoyed", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Witch_Annoyed_First	= CreateConVar("sm_l4d_ch_trigger_witch_annoyed_first", "0", "Alerts the horde when a witch is annoyed for the first time only (L4D2 only)", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Witch_Killed			= CreateConVar("sm_l4d_ch_trigger_witch_killed", "0", "Alerts the horde when a witch is killed", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Witch_Crowned			= CreateConVar("sm_l4d_ch_trigger_witch_crowned", "0", "Alerts the horde when a witch is crowned", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Witch_Random			= CreateConVar("sm_l4d_ch_trigger_witch_random", "1", "Randomly picks which event alerts the horde", CVAR_FLAGS, true, 0.0, true, 1.0);

	// Load config
	AutoExecConfig(true, "l4d_crowned_horde");
	// Load translations
	LoadTranslations("l4d_crowned_horde");

	// Hook events
	HookEvent("witch_harasser_set",	Event_WitchHarasserSet);
	HookEvent("witch_spawn",		Event_WitchSpawn);
	HookEvent("witch_killed",		Event_WitchKilled);
}

/**
 * Called when all configs have been executed
 *
 */
public OnConfigsExecuted()
{
	if (GetConVarInt(Sound))
	{
		// Get user defined sound
		decl String: sound_witch[128];
		GetConVarString(Sound_File, sound_witch, sizeof(sound_witch));

		// Precache sound if needed
		if (!IsSoundPrecached(sound_witch))
		{
			PrecacheSound(sound_witch, false);
		}
	}
}

/**
 * Handles when a witch becomes annoyed
 *
 * @handle: event - The witch_harasser_set event
 * @string: name - Name of the event
 * @bool: dontBroadcast - Enable/disable broadcasting of event triggering
 *
 */
public Event_WitchHarasserSet(Handle: event, const String: name[], bool: dontBroadcast)
{
	// Make sure we can continue
	if (!GetConVarInt(Trigger_Witch_Annoyed) && !GetConVarInt(Trigger_Witch_Annoyed_First))
	{
		return;
	}

	// Get event information
	new attacker_id	= GetEventInt(event, "userid");
	new witch_id		= GetEventInt(event, "witchid");

	// If this is the first time the witch has been annoyed
	if (GetConVarInt(Trigger_Witch_Annoyed_First))
	{
		if (game_l4d2)
		{
			new bool: annoyed_first = GetEventBool(event, "first");
			if (annoyed_first)
			{
				WitchAnnoyedFirst(attacker_id, witch_id);
			}
		}
		return;
	}
	else if (!GetConVarInt(Trigger_Witch_Annoyed))
	{
		return;
	}

	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	new attacker = GetClientOfUserId(attacker_id);
	BypassAndExecuteCommand(attacker, "director_force_panic_event", "director_force_panic_event");

	// Announce who woke up the witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_ANNOYED", attacker_name);
	}
}

/**
 * Handles when a witch spawns
 *
 * @handle: event - The witch_spawn event
 * @string: name - Name of the event
 * @bool: dontBroadcast - Enable/disable broadcasting of event triggering
 *
 */
public Event_WitchSpawn(Handle: event, const String: name[], bool: dontBroadcast)
{
	// Make sure we can continue
	if (!GetConVarInt(Trigger_Witch_Random))
	{
		return;
	}

	// Set a random event to trigger the horde
	if (game_l4d2)
	{
		new trigger_event = GetRandomInt(0, 4);
		switch (trigger_event)
		{
			case 0:
			{
				SetConVarInt(Trigger_Witch_Annoyed, 1);
			}
			case 1:
			{
				SetConVarInt(Trigger_Witch_Annoyed_First, 1);
			}
			case 2:
			{
				SetConVarInt(Trigger_Witch_Killed, 1);
			}
			case 3:
			{
				SetConVarInt(Trigger_Witch_Crowned, 1);
			}
		}
	}
	else
	{
		new trigger_event = GetRandomInt(0, 3);
		switch (trigger_event)
		{
			case 0:
			{
				SetConVarInt(Trigger_Witch_Annoyed, 1);
			}
			case 1:
			{
				SetConVarInt(Trigger_Witch_Killed, 1);
			}
			case 2:
			{
				SetConVarInt(Trigger_Witch_Crowned, 1);
			}
		}
	}
}

/**
 * Handles when a witch is killed
 *
 * @handle: event - The witch_killed event
 * @string: name - Name of the event
 * @bool: dontBroadcast - Enable/disable broadcasting of event triggering
 *
 */
public Event_WitchKilled(Handle: event, const String: name[], bool: dontBroadcast)
{
	// Make sure we can continue
	if (!GetConVarInt(Trigger_Witch_Killed) && !GetConVarInt(Trigger_Witch_Crowned))
	{
		return;
	}

	// Get event information
	new attacker_id	= GetEventInt(event, "userid");
	new witch_id		= GetEventInt(event, "witchid");
	new bool: crowned	= GetEventBool(event, "oneshot");

	// If witch was crowned
	if (GetConVarInt(Trigger_Witch_Crowned))
	{
		if (crowned)
		{
			WitchCrowned(attacker_id, witch_id);
			return;
		}
	}
	else if (!GetConVarInt(Trigger_Witch_Killed))
	{
		return;
	}

	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	new attacker = GetClientOfUserId(attacker_id);
	BypassAndExecuteCommand(attacker, "director_force_panic_event", "director_force_panic_event");

	// Announce who killed witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_KILLED", attacker_name);
	}

	// We need to reset any changed convars
	if (GetConVarInt(Trigger_Witch_Random))
	{
		ResetConVars();
	}
}

/**
 * Handles the witch being crowned
 *
 * @param: witch_id - ID of the witch
 *
 */
WitchCrowned(any: attacker_id, any: witch_id)
{
	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	new attacker = GetClientOfUserId(attacker_id);
	BypassAndExecuteCommand(attacker, "director_force_panic_event", "director_force_panic_event");

	// Announce who killed witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_CROWNED", attacker_name);
	}

	// We need to reset any changed convars
	if (GetConVarInt(Trigger_Witch_Random))
	{
		ResetConVars();
	}
}

/**
 * Handles the witch being annoyed for the first time
 *
 * @param: attacker_id - ID of the attacker
 * @param: witch_id - ID of the witch
 *
 */
WitchAnnoyedFirst(any: attacker_id, any: witch_id)
{
	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	new attacker = GetClientOfUserId(attacker_id);
	BypassAndExecuteCommand(attacker, "director_force_panic_event", "director_force_panic_event");

	// Announce who killed witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_ANNOYED_FIRST", attacker_name);
	}
}

/**
 * Bypasses the sv_cheats to use command
 * Thanks to Damizean
 *
 * @param: Client - The Client to execute the command on
 * @string: strCommand - The command to execute
 * @string: strParam1 - Parameter of the command
 *
 */
BypassAndExecuteCommand(Client, String: strCommand[], String: strParam1[])
{
	new Flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, Flags);
}

/**
 * Plays the witches scream
 *
 * @param: witch - ID of the witch
 *
 */
PlaySound(any: witch_id)
{
	// Get user defined sound
	decl String: sound_witch[128];
	GetConVarString(Sound_File, sound_witch, sizeof(sound_witch));

	// Play the sound to each client
	new i;
	for (i = 1; i <= GetMaxClients(); i++)
	{
		if (!IsClientConnected(i))
		{
			continue;
		}
		if (IsFakeClient(i))
		{
			continue;
		}

		EmitSoundToClient(i, sound_witch, witch_id, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}
}

/**
 * Resets any changed convars
 *
 */
ResetConVars()
{
	ResetConVar(Trigger_Witch_Annoyed);
	ResetConVar(Trigger_Witch_Annoyed_First);
	ResetConVar(Trigger_Witch_Killed);
	ResetConVar(Trigger_Witch_Crowned);
}