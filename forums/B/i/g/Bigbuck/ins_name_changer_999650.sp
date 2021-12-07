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
#define MAX_PLAYERS 		50
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

/**
 * Handles
 *
 */
new Handle: Name				= INVALID_HANDLE;
new Handle: Announcements	= INVALID_HANDLE;
new Handle: Timer_Announcements[MAX_PLAYERS + 1];

/**
 * Global variables
 *
 */
// Determines if clients name was changed or not
new bool: name_changed = false;

/**
 * Plugin information
 *
 */
public Plugin: myinfo =
{
	name = "[INS] Name Changer",
	author = "Bigbuck",
	description = "Autmatically changes default INS name to one set in config.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck.team-havoc.com/"
};

/**
 * Setup plugins first run
 *
 */
public OnPluginStart()
{
	// Create convars
	CreateConVar("sm_ins_name_changer_version", PLUGIN_VERSION, "[INS] Name Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	Name				= CreateConVar("sm_ins_nm_name", "Not a Grunt", "The name you want Grunt to be changed to.", CVAR_FLAGS);
	Announcements	= CreateConVar("sm_ins_nm_announcements", "1", "Enable or disable plugin announcements.", CVAR_FLAGS, true, 0.0, true, 1.0);
}

/**
 * Called when a client is entering the game
 *
 * @param: Client - The client being put in the server
 *
 */
public OnClientPutInServer(Client)
{
	new String: name[64];
	GetClientName(Client, name, sizeof(name));
	if (StrEqual(name, "Grunt", false))
	{
		new String: new_name[64];
		GetConVarString(Name, new_name, sizeof(new_name));
		ServerCommand("sm_rename %s %s", name, new_name);
		name_changed = true;
	}

	// Create timer for announcements
	if (GetConVarInt(Announcements) && name_changed)
	{
		// Only do this for humans
		if (!IsFakeClient(Client))
		{
			Timer_Announcements[Client] = CreateTimer(15.0, WelcomePlayers, Client);
		}
	}
}

/**
 * Called when a player is disconnecting
 *
 * @param: Client - The Client that is disconnecting
 */
public OnClientDisconnect(Client)
{
	// This shouldn't need to be called on bots
	if (!IsFakeClient(Client))
	{
		// Kill the announcement timer
		if (Timer_Announcements[Client] != INVALID_HANDLE)
		{
			KillTimer(Timer_Announcements[Client]);
			Timer_Announcements[Client] = INVALID_HANDLE;
		}
	}
}

/**
 * Handles printing announcements to players
 *
 * @handle: timer - Timer called from OnClientPutInServer
 * @param: Client - The specified Client
 *
 */
public Action: WelcomePlayers(Handle: timer, any: Client)
{
	new String: name[64];
	GetClientName(Client, name, sizeof(name));
	PrintToChat(Client, "Grunt is not an allowed name on this server.  Your name has been changed to %s.", name);

	Timer_Announcements[Client] = INVALID_HANDLE;
}