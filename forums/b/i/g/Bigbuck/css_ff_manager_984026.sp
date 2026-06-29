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
#define PLUGIN_VERSION	"1.0.4"
#define CVAR_FLAGS		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY

/**
 * Handles
 *
 */
new Handle: FriendlyFire_Type	= INVALID_HANDLE;
new Handle: Slap_Damage			= INVALID_HANDLE;
new Handle: Log_Actions			= INVALID_HANDLE;
new Handle: Announce_Actions	= INVALID_HANDLE;
new String:	FF_LogFile[128];

/**
 * Plugin Information
 *
 */
public Plugin: myinfo =
{
	name = "CS:S Friendly Fire Manager",
	author = "Bigbuck",
	description = "Basic friendly fire manager for Counter Strike: Source.",
	version = PLUGIN_VERSION,
	url = "http://bigbuck.team-havoc.com/index.php?page=projects&project=ff_manager"
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
	CreateConVar("sm_css_ff_manager_version", PLUGIN_VERSION, "CSS Friendly Fire Manager version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	FriendlyFire_Type	= CreateConVar("sm_css_ffm_type", "1", "Set the type of friendly fire you would like. (0 = normal FF/plugin off, 1 = slap, 2 = reflective", CVAR_FLAGS, true, 0.0, true, 2.0);
	Slap_Damage			= CreateConVar("sm_css_ffm_slap_damage", "0", "If FF type is set to 1, how much damage to slap the user with?", CVAR_FLAGS, true, 0.0, true, 100.0);
	Log_Actions			= CreateConVar("sm_css_ffm_log", "1", "Log friendly fire incidents?", CVAR_FLAGS, true, 0.0, true, 1.0);
	Announce_Actions	= CreateConVar("sm_css_ffm_announce", "2", "Announce friendly fire incidents? (0 = off, 1 = victim/attacker, 2 = everyone)", CVAR_FLAGS, true, 0.0, true, 2.0);

	//Hook Events
	HookEvent("player_hurt", 	Event_PlayerHurt, EventHookMode_Pre);

	// Create log file if needed
	if (GetConVarInt(Log_Actions))
	{
		BuildPath(Path_SM, FF_LogFile, 128, "logs/css_ff_manager.log");
	}

	// Exec config
	AutoExecConfig(true, "css_ff_manager");
}

/**
 * Handles when a player gets hurt
 *
 */
public Event_PlayerHurt(Handle: event, const String: name[], bool: dontBroadcast)
{
	// If FF type is set to normal then we don't need to be here
	if (!GetConVarInt(FriendlyFire_Type))
	{
		return;
	}

	// Get event structure
	new victim_id 		= GetEventInt(event, "userid");
	new attacker_id 		= GetEventInt(event, "attacker");
	new damage_health	= GetEventInt(event, "dmg_health");
	new damage_armor 	= GetEventInt(event, "dmg_armor");
	new total_damage		= damage_health + damage_armor;

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
	new victim_team = GetClientTeam(victim);
	new attacker_team = GetClientTeam(attacker);

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

	// Switch for FF type
	new FF_Type = GetConVarInt(FriendlyFire_Type);
	switch (FF_Type)
	{
		// Slap
		case 1:
		{
			new slap_damage = GetConVarInt(Slap_Damage);
			SlapPlayer(attacker, slap_damage, true);

			// Log it if needed
			if (GetConVarInt(Log_Actions))
			{
				LogToFile(FF_LogFile, "%s attacked %s for %i damage and was slapped with %i damage", attacker_name, victim_name, total_damage, slap_damage);
			}

			// Announce it if needed
			if (GetConVarInt(Announce_Actions) != 0)
			{
				new Announce_Type = GetConVarInt(Announce_Actions);
				switch (Announce_Type)
				{
					case 1:
					{
						PrintToChat(victim, "\x03 [FFM] \x01 You were attacked by %s", attacker_name);
						PrintToChat(attacker, "\x03 [FFM] \x01 You attacked %s, please watch your fire!", victim_name);
					}
					case 2:
					{
						PrintToChatAll("\x03 [FFM] \x01 %s attacked %s", attacker_name, victim_name);
					}
				}
			}
		}
		// Reflective
		case 2:
		{
			new attacker_health = GetClientHealth(attacker);
			new reflective_damage = attacker_health - damage_health;
			SetEntityHealth(attacker, reflective_damage);

			// Log it if needed
			if (GetConVarInt(Log_Actions))
			{
				LogToFile(FF_LogFile, "%s attacked %s for %i damage and was penalized %i health", attacker_name, victim_name, total_damage, reflective_damage);
			}

			// Announce it if needed
			if (GetConVarInt(Announce_Actions) != 0)
			{
				new Announce_Type = GetConVarInt(Announce_Actions);
				switch (Announce_Type)
				{
					case 1:
					{
						PrintToChat(victim, "\x03 [FFM] \x01 You were attacked by %s", attacker_name);
						PrintToChat(attacker, "\x03 [FFM] \x01 You attacked %s, please watch your fire!", victim_name);
					}
					case 2:
					{
						PrintToChatAll("\x03 [FFM] \x01 %s attacked %s", attacker_name, victim_name);
					}
				}
			}
		}
	}
}