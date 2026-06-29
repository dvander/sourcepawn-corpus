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
#define SOUND_WITCH		"npc/witch/voice/attack/Female_DistantScream2.wav"

/**
 * Handles
 *
 */
new Handle: Sound		= INVALID_HANDLE;
new Handle: Announce	= INVALID_HANDLE;

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
	Sound		= CreateConVar("sm_l4d_ch_sound", "1", "Play a sound when the witch has been crowned?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Announce	= CreateConVar("sm_l4d_ch_announce", "1", "Enable or disable announcements.", CVAR_FLAGS, true, 0.0, true, 1.0);

	// Hook events
	HookEvent("witch_killed", Event_WitchKilled);
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
	new bool: crowned	= GetEventBool(event, "oneshot");

	// If the witch wasn't crowned we're done
	if (!crowned)
	{
		return;
	}

	// Play sound if needed
	if (GetConVarInt(Sound))
	{
		// Precache sound if needed
		if (!IsSoundPrecached(SOUND_WITCH))
		{
			PrecacheSound(SOUND_WITCH, false);
		}

		EmitSoundToAll(SOUND_WITCH, witch_id, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 100.0, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
	}

	// Trigger the horde
	BypassAndExecuteCommand(witch_id, "director_force_panic_event", "");

	// Announce who crowned witch if needed
	if (GetConVarInt(Announce))
	{
		// Get attacker information
		new attacker = GetClientOfUserId(attacker_id);
		decl String: attacker_name[64];
		GetClientName(attacker, attacker_name, sizeof(attacker_name));

		// Tell everyone who set off the horde
		PrintToChatAll("%s has crowned a witch and alerted the horde!", attacker_name);
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