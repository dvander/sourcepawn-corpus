/**
* No Domination Broadcast by Root
*
* Description:
*   Disables "Domination & Revenge" features in Team Fortress 2.
*
* Version 1.2.2
* Changelog & more info at http://goo.gl/4nKhJ
*/

#pragma semicolon 1

// ====[ INCLUDES ]==================================================
#include <tf2_stocks> // <tf2_stocks> is automatically includes sdktools.inc and tf2.inc
#include <sdkhooks>
#undef REQUIRE_PLUGIN
#include <updater>

// ====[ CONSTANTS ]=================================================
#define PLUGIN_NAME    "No Domination Broadcast"
#define PLUGIN_VERSION "1.2.2"
#define UPDATE_URL     "https://raw.github.com/zadroot/TF2_NoDominationBroadcast/master/updater.txt"

// ====[ VARIABLES ]=================================================
new	Handle:nobroadcast = INVALID_HANDLE,
	m_bPlayerDominated, m_bPlayerDominatingMe, m_iActiveDominations, // NetProps
	zeroCount[MAXPLAYERS + 1];

// ====[ PLUGIN ]====================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "Disables Domination & Revenge broadcasting",
	version     = PLUGIN_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=1807594"
};


/* OnPluginStart()
 *
 * When the plugin starts up.
 * ------------------------------------------------------------------ */
public OnPluginStart()
{
	// Create console variables
	CreateConVar("sm_nodominations_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	nobroadcast = CreateConVar("sm_nodominations", "1", "Disable Domination & Revenge broadcasting?", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Always use event hook mode 'Pre' if need to block or rewrite an event
	HookEvent("player_death",     OnPlayerDeath, EventHookMode_Pre);
	HookConVarChange(nobroadcast, OnConVarChange);

	// Find the dominations NetProps
	m_bPlayerDominated    = GetSendPropInfo("CTFPlayer", "m_bPlayerDominated");
	m_bPlayerDominatingMe = GetSendPropInfo("CTFPlayer", "m_bPlayerDominatingMe");
	m_iActiveDominations  = GetSendPropInfo("CTFPlayerResource", "m_iActiveDominations");

	// Updater stuff
	if (LibraryExists("updater"))
	{
		// Adds plugin to the updater
		Updater_AddPlugin(UPDATE_URL);
	}
}

/* OnLibraryAdded()
 *
 * Called after a library is added that the current plugin references.
 * ------------------------------------------------------------------ */
public OnLibraryAdded(const String:name[])
{
	// Make sure the 'updater' library is avalible
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/* OnMapStart()
 *
 * Called when the map has loaded.
 * ------------------------------------------------------------------ */
public OnConfigsExecuted()
{
	// Plugin is enabled?
	if (GetConVarBool(nobroadcast))
	{
		// Retrieves the entity index of the PlayerResource entity
		new entity = GetPlayerResourceEntity();

		// Check if resource entity is valid then hook it
		if (entity != -1)
		{
			SDKHook(entity, SDKHook_ThinkPost, OnThinkPost);
		}

		// Disable plugin if PlayerResource entity is invalid or N/A
		else
		{
			SetFailState("Unable to find resource entity!");
		}
	}
}

/* OnConVarChange()
 *
 * Called when a convar's value is changed.
 * ------------------------------------------------------------------ */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Changed since SM 1.5
	new entity = GetPlayerResourceEntity();

	// Get changed value
	switch (StringToInt(newValue))
	{
		case false: // Unhook all features if convar value changed to 0
		{
			SDKUnhook(entity, SDKHook_ThinkPost, OnThinkPost);
			UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
		}
		case true: // If changed to 1 - hook everything back
		{
			SDKHook(entity, SDKHook_ThinkPost, OnThinkPost);
			HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
		}
	}
}

/* OnPlayerDeath()
 *
 * Called when a player dies.
 * ------------------------------------------------------------------ */
public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Getting attacker's user ID (who killed) and victim's user ID (who died)
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim   = GetClientOfUserId(GetEventInt(event, "userid"));

	// Way to get dominations and revenges is death_flags
	new death_flags = GetEventInt(event, "death_flags");

	// Thanks to FaTony for this!
	death_flags &= ~(TF_DEATHFLAG_KILLERDOMINATION | TF_DEATHFLAG_ASSISTERDOMINATION | TF_DEATHFLAG_KILLERREVENGE | TF_DEATHFLAG_ASSISTERREVENGE);

	// Sets the integer value of a game event's key
	SetEventInt(event, "death_flags", death_flags);

	// Disable domination features
	SetNetProps(attacker, victim);
}

/* OnThinkPost()
 *
 * A SDKHooks 'after think' feature.
 * ------------------------------------------------------------------ */
public OnThinkPost(entity)
{
	// Copies an array of cells to an entity at a dominations offset
	SetEntDataArray(entity, m_iActiveDominations, zeroCount, MaxClients + 1);
}

/* SetNetProps()
 *
 * Sets net properites for dominations and revenges.
 * ------------------------------------------------------------------ */
SetNetProps(attacker, victim)
{
	// Make sure attacker is valid
	if (attacker > 0 && IsClientInGame(attacker))
	{
		// First remove 'DOMINATED' icon in a scoreboard
		SetEntData(attacker, m_bPlayerDominated + victim, 0, 4, true);
	}

	// And victim
	if (victim > 0 && IsClientInGame(victim))
	{
		// Then remove 'NEMESIS' icon in a scoreboard
		SetEntData(victim, m_bPlayerDominatingMe + attacker, 0, 4, true);
	}
}

/* GetSendPropInfo()
 *
 * Returns the offset of the specified network property.
 * ------------------------------------------------------------------ */
GetSendPropInfo(const String:serverClass[64], const String:propName[64])
{
	new entity = FindSendPropInfo(serverClass, propName);

	// Log an error and disable plugin if a networkable send property offset wasnt found
	if (!entity)
	{
		SetFailState("Unable to find prop \"%s::%s\"!", serverClass, propName);
	}

	return entity;
}