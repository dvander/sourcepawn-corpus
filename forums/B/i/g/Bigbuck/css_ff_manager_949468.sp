/**
 * CSS Friendly Fire Manager
 * Created by Bigbuck
 *
 */

/*
	v1.0.0
	- Initial Release

	v1.0.1
	- Moved FF check to OnConfigsExecuted to prevent first run error
	- Added check for self inflicted damage
	- Changed URL to point to its own page

	v1.0.2
	- Added check for warmup.smx plugin to prevent fail state being triggered
	- Plugin should now check if a warmup round is active before checking mp_friendlyfire

	v1.0.3
	- Modified check for Warmup Round Plugin to be every round instead of just once
	- Plugin now announces if it is enabled or not

	v1.0.4
	- Removed mp_friendlyfire check

	v1.0.5
	- Added translation support

	v1.0.6
	- Added seperate CVAR's for FF type and announcements
	- Added CVAR to enable/disable slap sound
	- Overall optimization
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
 * Constants
 *
 */
#define PLUGIN_VERSION	"1.0.6"
#define CVAR_FLAGS			FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

/**
 * Handles
 *
 */
new Handle: CSS_FF						= INVALID_HANDLE;
new Handle: Type_Slap					= INVALID_HANDLE;
new Handle: Type_Reflective			= INVALID_HANDLE;
new Handle: Slap_Damage				= INVALID_HANDLE;
new Handle: Slap_Sound					= INVALID_HANDLE;
new Handle: Log							= INVALID_HANDLE;
new Handle: Announcements_Clients	 	= INVALID_HANDLE;
new Handle: Announcements_All	 		= INVALID_HANDLE;
// Log file string
new String:	FF_LogFile[128];

/**
 * Plugin Information
 *
 */
public Plugin: myinfo =
{
	name = "[CS:S] Friendly Fire Manager",
	author = "Bigbuck",
	description = "Basic friendly fire manager for Counter Strike: Source.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck-sm.assembla.com/spaces/dashboard/index/bigbuck-sm"
};

/**
 * Ran when plugin is started
 *
 */
public OnPluginStart()
{
	// Require CSS
	decl String: GameName[50];
	GetGameFolderName(GameName, sizeof(GameName));
	if (!StrEqual(GameName, "cstrike", false))
	{
		SetFailState("Use this in Counter Strike: Source only.");
	}

	// Create convars
	CreateConVar("sm_css_ff_manager_version", PLUGIN_VERSION, "[CS:S] Friendly Fire Manager Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CSS_FF						= FindConVar("mp_friendlyfire");
	Type_Slap					= CreateConVar("sm_css_ffm_type_slap", "1", "The player who commited FF is slapped with the total FF damage amount.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Type_Reflective			= CreateConVar("sm_css_ffm_type_reflective", "0", "FF damage done to a teammate is reflected back onto the player who did it.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Slap_Damage				= CreateConVar("sm_css_ffm_slap_damage", "0", "If FF type slap is on, how much damage to slap the user with?", CVAR_FLAGS, true, 0.0, true, 100.0);
	Slap_Sound					= CreateConVar("sm_css_ffm_slap_sound", "1", "If FF type slap is on, should we play a sound when the user is slapped?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Log							= CreateConVar("sm_css_ffm_log", "1", "Log friendly fire incidents?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Announcements_Clients		= CreateConVar("sm_css_ffm_announcements_clients", "1", "Announces FF incidents only to those involved.", CVAR_FLAGS, true, 0.0, true, 1.0);
	Announcements_All			= CreateConVar("sm_css_ffm_announcements_all", "0", "Announces FF incidents to everyone.", CVAR_FLAGS, true, 0.0, true, 1.0);

	// Exec config
	AutoExecConfig(true, "css_ff_manager");
	// Load translations
	LoadTranslations("css_ff_manager");

	//Hook Events
	HookEvent("player_hurt",	Event_PlayerHurt,	EventHookMode_Pre);

	// Create log file if needed
	if (GetConVarInt(Log))
	{
		BuildPath(Path_SM, FF_LogFile, 128, "logs/css_ff_manager.log");
	}
}

/**
 * Handles when a player gets hurt
 *
 */
public Event_PlayerHurt(Handle: event, const String: name[], bool: dontBroadcast)
{
	// If FF is off we can quit now
	if (!GetConVarInt(CSS_FF))
	{
		return;
	}

	// Get event structure
	new victim_id 		= GetEventInt(event, "userid");
	new attacker_id 	= GetEventInt(event, "attacker");
	new damage_health	= GetEventInt(event, "dmg_health");
	new damage_armor 	= GetEventInt(event, "dmg_armor");
	new total_damage	= damage_health + damage_armor;

	// Get correct client ID
	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);

	// Make sure the client is valid
	// Handles 0 being returned from GetClientOfUserId
	if (!victim || !attacker)
	{
		return;
	}

	// If damage was self inflicted, ignore it
	if (victim == attacker)
	{
		return;
	}

	// We don't care about bots
	if (IsFakeClient(victim) || IsFakeClient(attacker))
	{
		return;
	}

	// Get clients team
	new victim_team 	= GetClientTeam(victim);
	new attacker_team	= GetClientTeam(attacker);

	// If there was no FF incident then we can quit
	if (victim_team != attacker_team)
	{
		return;
	}

	// Get clients name
	decl String: victim_name[64];
	decl String: attacker_name[64];
	GetClientName(victim, victim_name, sizeof(victim_name));
	GetClientName(attacker, attacker_name, sizeof(attacker_name));

	// Slap type
	if (GetConVarInt(Type_Slap))
	{
		new slap_damage = GetConVarInt(Slap_Damage);
		SlapPlayer(attacker, slap_damage, GetConVarBool(Slap_Sound));

		// Log it if needed
		if (GetConVarInt(Log))
		{
			LogToFile(FF_LogFile, "%s attacked %s for %i damage and was slapped with %i damage", attacker_name, victim_name, total_damage, slap_damage);
		}

		// Announce it if needed
		if (GetConVarInt(Announcements_Clients))
		{
			PrintToChat(victim, "%t", "L_FF_VICTIM", attacker_name);
			PrintToChat(attacker, "%t", "L_FF_ATTACKER", victim_name);
		}
		if (GetConVarInt(Announcements_All))
		{
			PrintToChatAll("%t", "L_FF_ALL", attacker_name, victim_name);
		}
	}

	// Reflective type
	if (GetConVarInt(Type_Reflective))
	{
		new attacker_health = GetClientHealth(attacker);
		new reflective_damage = attacker_health - damage_health;
		SetEntityHealth(attacker, reflective_damage);

		// Log it if needed
		if (GetConVarInt(Log))
		{
			LogToFile(FF_LogFile, "%s attacked %s for %i damage and was penalized %i health", attacker_name, victim_name, total_damage, reflective_damage);
		}

		// Announce it if needed
		if (GetConVarInt(Announcements_Clients))
		{
			PrintToChat(victim, "%t", "L_FF_VICTIM", attacker_name);
			PrintToChat(attacker, "%t", "L_FF_ATTACKER", victim_name);
		}
		if (GetConVarInt(Announcements_All))
		{
			PrintToChatAll("%t", "L_FF_ALL", attacker_name, victim_name);
		}
	}
}