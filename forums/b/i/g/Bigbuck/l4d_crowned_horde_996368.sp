/**
 * [L4D] Crowned Horde
 * Created by Bigbuck
 *
 */

/**
	v1.0.0
	- Initial Release
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
#define PLUGIN_VERSION	"1.0.0"
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

/**
 * Handles
 *
 */
new Handle: Sound			= INVALID_HANDLE;
new Handle: Sound_File	= INVALID_HANDLE;
new Handle: Announce		= INVALID_HANDLE;

/**
 * Plugin information
 *
 */
public Plugin: myinfo =
{
	name = "[L4D] Crowned Horde",
	author = "Bigbuck",
	description = "Sends out a horde when a witched has been crowned.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck.team-havoc.com/"
};

/**
 * Setup plugins first run
 *
 */
public OnPluginStart()
{
	// Require Left 4 Dead
	decl String: GameName[50];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "left4dead", false))
	{
		SetFailState("Use this in Left 4 Dead only.");
	}

	// Create convars
	CreateConVar("sm_l4d_crowned_horde_version", PLUGIN_VERSION, "[L4D] Crowned Horde Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Sound			= CreateConVar("sm_l4d_ch_sound", "1", "Play a sound when the witch has been crowned?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Sound_File	= CreateConVar("sm_l4d_ch_sound_file", "npc/witch/voice/attack/Female_DistantScream2.wav", "The sound file to play relative to the sounds directory.", CVAR_FLAGS);
	Announce		= CreateConVar("sm_l4d_ch_announce", "1", "Enable or disable announcements.", CVAR_FLAGS, true, 0.0, true, 1.0);

	// Hook events
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
		new String: sound_witch[128];
		GetConVarString(Sound_File, sound_witch, sizeof(sound_witch));

		// Precache sound if needed
		if (!IsSoundPrecached(sound_witch))
		{
			PrecacheSound(sound_witch, false);
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
	// Get event information
	new attacker_id	= GetEventInt(event, "userid");
	new witch_id		= GetEventInt(event, "witchid");

	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		// Get user defined sound
		new String: sound_witch[128];
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

	// Trigger the horde
	BypassAndExecuteCommand(attacker_id, "z_spawn", "mob");

	// Announce who crowned witch if needed
	if (GetConVarInt(Announce))
	{
		// Get attacker information
		new attacker = GetClientOfUserId(attacker_id);
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		// Tell everyone who set off the horde
		PrintToChatAll("%s has startled the witch and alerted the horde!", attacker_name);
	}
}

/**
 * Bypasses the sv_cheats to use command
 * Thanks to Damizean
 *
 */
BypassAndExecuteCommand(Client, String: strCommand[], String: strParam1[])
{
	new Flags = GetCommandFlags(strCommand);
	SetCommandFlags(strCommand, Flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", strCommand, strParam1);
	SetCommandFlags(strCommand, Flags);
}