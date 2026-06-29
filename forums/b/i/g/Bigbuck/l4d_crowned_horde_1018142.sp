/**
 * [L4D/2] Crowned Horde
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

	v1.0.3
	- Added option to randomly alert the horde

	v1.0.4
	- Added option to set delay between witches scream and the horde being alerted
	- Added option to set the size of the alerted horde
	- Added option to randomly set the size of the alerted horde
	- Added option to alert the horde when the witch has been killed but not crowned
	- Fixed potential bug in the random logic

	v1.0.5
	- Fixed bug with AlertHorde timers

	v1.0.6
	- Removed redundant cvar, l4d_ch_trigger_killed_not_crowned
	- Removed sm_ from cvar's to comply with guidelines

	v1.0.7
	- Fixed bug in random logic that always ran the random code
	- Fixed invalid client bug
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
#define PLUGIN_VERSION	"1.0.7"
#define MAX_PLAYERS 		256
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define CVAR_FLAGS_NO		FCVAR_PLUGIN|FCVAR_SPONLY

/**
 * Handles
 *
 */
new Handle: Sound							= INVALID_HANDLE;
new Handle: Sound_File						= INVALID_HANDLE;
new Handle: Announcements					= INVALID_HANDLE;
new Handle: Trigger_Annoyed				= INVALID_HANDLE;
new Handle: Trigger_Annoyed_First			= INVALID_HANDLE;
new Handle: Trigger_Killed				= INVALID_HANDLE;
new Handle: Trigger_Killed_Crowned		= INVALID_HANDLE;
new Handle: Trigger_Random				= INVALID_HANDLE;
new Handle: Trigger_Random_Alert_Horde	= INVALID_HANDLE;
new Handle: Trigger_Random_Horde_Size	= INVALID_HANDLE;
new Handle: Trigger_Horde_Size			= INVALID_HANDLE;
new Handle:	Trigger_Delay					= INVALID_HANDLE;
// Timer handles
new Handle: Timer_AlertHorde[MAX_PLAYERS + 1];

/**
 * Global variables
 *
 */
// Detects L4D2
new bool: game_l4d2 = false;
// Lets us know if we need to trigger the horde
new bool: alert_horde = true;
// Determines the size of the horde
new horde_size = 0;

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
	CreateConVar("l4d_crowned_horde_version", PLUGIN_VERSION, "[L4D/2] Crowned Horde Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Sound							= CreateConVar("l4d_ch_sound", "1", "Play a sound when the trigger event has been activated?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Sound_File						= CreateConVar("l4d_ch_sound_file", "npc/witch/voice/attack/Female_DistantScream2.wav", "If sound is enabled, the sound file to play relative to the sounds directory.", CVAR_FLAGS);
	Announcements					= CreateConVar("l4d_ch_announcements", "1", "Enable or disable announcements.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Trigger_Annoyed				= CreateConVar("l4d_ch_trigger_annoyed", "0", "Alerts the horde when a witch is annoyed.", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Annoyed_First			= CreateConVar("l4d_ch_trigger_annoyed_first", "0", "Alerts the horde when a witch is annoyed for the first time only (L4D2 only).", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Killed				= CreateConVar("l4d_ch_trigger_killed", "0", "Alerts the horde when a witch is killed.", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Killed_Crowned		= CreateConVar("l4d_ch_trigger_killed_crowned", "0", "Alerts the horde when a witch is crowned.", CVAR_FLAGS_NO, true, 0.0, true, 1.0);
	Trigger_Random				= CreateConVar("l4d_ch_trigger_random", "1", "Randomly picks which event alerts the horde.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Trigger_Random_Alert_Horde	= CreateConVar("l4d_ch_trigger_random_alert_horde", "0", "If random option is selected, randomly decide if a horde should be alerted.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Trigger_Random_Horde_Size	= CreateConVar("l4d_ch_trigger_random_horde_size", "0", "If random option is selected, randomly decide what size horde should be alerted.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Trigger_Horde_Size			= CreateConVar("l4d_ch_trigger_horde_size", "0", "Size of the alerted horde (0 = mob, 1 = forced panic).", CVAR_FLAGS, true, 0.0, true, 1.0);
	Trigger_Delay					= CreateConVar("l4d_ch_trigger_delay", "0", "The delay between the witches scream and the horde being alerted.", CVAR_FLAGS, true, 0.0);

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
	if (!GetConVarInt(Trigger_Random))
	{
		horde_size = GetConVarInt(Trigger_Horde_Size);
		return;
	}

	// Set a random event to trigger the horde
	switch (game_l4d2)
	{
		case 0:
		{
			new trigger_event = GetRandomInt(0, 2);
			switch (trigger_event)
			{
				case 0:
				{
					SetConVarInt(Trigger_Annoyed, 1);
				}
				case 1:
				{
					SetConVarInt(Trigger_Killed, 1);
				}
				case 2:
				{
					SetConVarInt(Trigger_Killed_Crowned, 1);
				}
			}
		}
		case 1:
		{
			new trigger_event = GetRandomInt(0, 3);
			switch (trigger_event)
			{
				case 0:
				{
					SetConVarInt(Trigger_Annoyed, 1);
				}
				case 1:
				{
					SetConVarInt(Trigger_Annoyed_First, 1);
				}
				case 2:
				{
					SetConVarInt(Trigger_Killed, 1);
				}
				case 3:
				{
					SetConVarInt(Trigger_Killed_Crowned, 1);
				}
			}
		}
	}

	// Randomly select if a horde should be alerted
	if (GetConVarInt(Trigger_Random_Alert_Horde))
	{
		new trigger_alert_horde = GetRandomInt(0, 1);
		if (!trigger_alert_horde)
		{
			alert_horde = false;
		}
	}

	// Randomly select the horde size
	if (GetConVarInt(Trigger_Random_Horde_Size))
	{
		new trigger_horde_size = GetRandomInt(0, 1);
		switch (trigger_horde_size)
		{
			case 0:
			{
				horde_size = 0;
			}
			case 1:
			{
				horde_size = 1;
			}
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
	if (!GetConVarInt(Trigger_Annoyed) && !GetConVarInt(Trigger_Annoyed_First))
	{
		return;
	}

	// Get event information
	new attacker_id	= GetEventInt(event, "userid");
	new witch_id		= GetEventInt(event, "witchid");
	// Get the correct client id
	new attacker 		= GetClientOfUserId(attacker_id);

	// If this is the first time the witch has been annoyed
	if (GetConVarInt(Trigger_Annoyed_First))
	{
		if (game_l4d2)
		{
			new bool: annoyed_first = GetEventBool(event, "first");
			if (annoyed_first)
			{
				WitchAnnoyedFirst(attacker, witch_id);
			}
		}
		return;
	}
	else if (!GetConVarInt(Trigger_Annoyed))
	{
		return;
	}

	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	if (alert_horde)
	{
		Timer_AlertHorde[attacker] = CreateTimer(GetConVarFloat(Trigger_Delay), AlertHorde, attacker);
	}

	// Announce who woke up the witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_ANNOYED", attacker_name);
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
	if (!GetConVarInt(Trigger_Killed) && !GetConVarInt(Trigger_Killed_Crowned))
	{
		return;
	}

	// Get event information
	new attacker_id	= GetEventInt(event, "userid");
	new witch_id		= GetEventInt(event, "witchid");
	new bool: crowned	= GetEventBool(event, "oneshot");
	// Get the correct client id
	new attacker 		= GetClientOfUserId(attacker_id);

	// If witch was crowned
	if (GetConVarInt(Trigger_Killed_Crowned))
	{
		if (crowned)
		{
			WitchCrowned(attacker, witch_id);
		}

		return;
	}
	else if (!GetConVarInt(Trigger_Killed))
	{
		return;
	}

	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	if (alert_horde)
	{
		Timer_AlertHorde[attacker] = CreateTimer(GetConVarFloat(Trigger_Delay), AlertHorde, attacker);
	}

	// Announce who killed witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_KILLED", attacker_name);
	}

	// We need to reset any changed convars
	if (GetConVarInt(Trigger_Random))
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
WitchCrowned(any: attacker, any: witch_id)
{
	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	if (alert_horde)
	{
		Timer_AlertHorde[attacker] = CreateTimer(GetConVarFloat(Trigger_Delay), AlertHorde, attacker);
	}

	// Announce who killed witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_CROWNED", attacker_name);
	}

	// We need to reset any changed convars
	if (GetConVarInt(Trigger_Random))
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
WitchAnnoyedFirst(any: attacker, any: witch_id)
{
	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		PlaySound(witch_id);
	}

	// Trigger the horde
	if (alert_horde)
	{
		Timer_AlertHorde[attacker] = CreateTimer(GetConVarFloat(Trigger_Delay), AlertHorde, attacker);
	}

	// Announce who killed witch if needed
	if (GetConVarInt(Announcements))
	{
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		PrintToChatAll("%t", "L_WITCH_ANNOYED_FIRST", attacker_name);
	}
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
 * Alerts the horde
 *
 * @handle: timer - Handle to the timer
 * @param: attacker - The witches attacker id
 *
 */
public Action: AlertHorde(Handle: timer, any: attacker)
{
	// Alert the correct size horde
	switch (horde_size)
	{
		case 0:
		{
			BypassAndExecuteCommand(attacker, "z_spawn", "mob");
		}
		case 1:
		{
			BypassAndExecuteCommand(attacker, "director_force_panic_event", "");
		}
	}

	KillTimer(Timer_AlertHorde[attacker]);
	Timer_AlertHorde[attacker] = INVALID_HANDLE;
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
	// Fixes invalid client bug
	if (!Client)
	{
		return;
	}

	new Flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, Flags);
}

/**
 * Resets any changed convars
 *
 */
ResetConVars()
{
	ResetConVar(Trigger_Annoyed);
	ResetConVar(Trigger_Annoyed_First);
	ResetConVar(Trigger_Killed);
	ResetConVar(Trigger_Killed_Crowned);
}