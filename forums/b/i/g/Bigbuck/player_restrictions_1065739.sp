/**
 * [ANY] Player Restrictions
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
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

/**
 * Handles
 *
 */
new Handle: Kick_Message	= INVALID_HANDLE;

/**
 * Plugin information
 *
 */
public Plugin: myinfo =
{
	name = "[ANY] Player Restrictions",
	author = "Bigbuck",
	description = "Restricts players on your server to the ones whose SteamID is on the list.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck-sm.assembla.com/spaces/dashboard/index/bigbuck-sm"
};

/**
 * Setup plugins first run
 *
 */
public OnPluginStart()
{
	// Create convars
	CreateConVar("player_restrictions_version", PLUGIN_VERSION, "[ANY] Player Restrictions", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Kick_Message	= CreateConVar("pl_kick_message", "You're SteamID is not on the list of allowed players", "The message clients will get when they are kicked", CVAR_FLAGS);

	// Load config
	AutoExecConfig(true, "player_restrictions");
}

/**
 * Called when a client gets a SteamID
 *
 * @parm: client - The client that has been authorized
 * @String: auth - The clients SteamID
 *
 */
public OnClientAuthorized(client, const String: auth[])
{
	// We don't care about bots
	if (IsFakeClient(client))
	{
		return;
	}

	// Setup
	new String: kick_message[128];
	GetConVarString(Kick_Message, kick_message, sizeof(kick_message));

	// Create the keyvalues
	new Handle: steamd_ids = CreateKeyValues("PlayerRestrictions");
	if (!FileToKeyValues(steamd_ids, "addons/sourcemod/configs/player_restrictions.txt"))
	{
		LogError("Cannot find player_restrictions.txt");
	}

	// Check for the steam id
	if (!KvJumpToKey(steamd_ids, auth))
	{
		LogMessage("Kicking client %N", client);
		KickClient(client, kick_message);
	}
	else
	{
		LogMessage("Valid SteamID found, %s", auth);
	}
}