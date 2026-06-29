/**
* CS:GO Admin ESP by Root
*
* Description:
*   Plugin show positions of all players through walls to admin when he/she is observing, dead or spectate.
*
* Version 1.1
* Changelog & more info at http://goo.gl/4nKhJ
*/

// ====[ SEMICOLON ]======================================================================
#pragma semicolon 1

// ====[ CONSTANTS ]======================================================================
#define PLUGIN_NAME    "CS:GO Admin ESP"
#define PLUGIN_VERSION "1.1"
#define TEAM_SPECTATOR 1

// ====[ VARIABLES ]======================================================================
new	Handle:AdminESP, Handle:mp_teammates_are_enemies,
	bool:IsAllowedToESP[MAXPLAYERS + 1] = {false, ...},
	bool:IsUsingESP[MAXPLAYERS + 1]     = {false, ...};

// ====[ PLUGIN ]=========================================================================
public Plugin:myinfo =
{
	name        = PLUGIN_NAME,
	author      = "Root",
	description = "ESP/WH for Admins",
	version     = PLUGIN_VERSION,
	url         = "forums.alliedmods.net/showthread.php?p=211117"
};


/* OnPluginStart()
 *
 * When the plugin starts up.
 * --------------------------------------------------------------------------------------- */
public OnPluginStart()
{
	// Create ConVars
	CreateConVar("sm_csgo_adminesp_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AdminESP = CreateConVar("sm_csgo_adminesp", "1", "Whether or not automatically enable ESP/WH when Admin with cheat flag (Default: \"n\") dies", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Hook ConVar change
	HookConVarChange(AdminESP, OnConVarChange);

	// You want to ask: what is that? Its a magic!
	mp_teammates_are_enemies = FindConVar("mp_teammates_are_enemies");

	// Mod is not supported?
	if (mp_teammates_are_enemies == INVALID_HANDLE)
		SetFailState("Fatal Error: Could not find \"mp_teammates_are_enemies\" ConVar! Disabling plugin...");

	// Manually trigger OnConVarChange to hook plugin's events
	OnConVarChange(AdminESP, "0", "1");
}

/* OnConVarChange()
 *
 * Called when a convar's value is changed.
 * --------------------------------------------------------------------------------------- */
public OnConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// Since old/newValue's is strings, convert them to integers
	switch (StringToInt(newValue))
	{
		// Unhook all needed events on plugin disabling
		case false:
		{
			UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
			UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
			UnhookEvent("player_team",  OnTeamChange,  EventHookMode_Post);
		}

		case true:
		{
			HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
			HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
			HookEvent("player_team",  OnTeamChange,  EventHookMode_Post);
		}
	}
}

/* OnClientPostAdminCheck()
 *
 * When a client is in game and fully authorized.
 * --------------------------------------------------------------------------------------- */
public OnClientPostAdminCheck(client)
{
	// Make sure connected client is validated
	if (IsValidClient(client))
	{
		// Make sure player is having appropriate access, and give it to him
		if (CheckCommandAccess(client, "csgo_admin_esp", ADMFLAG_CHEATS))
		{
			// Client can use ESP, so enable it now!
			IsAllowedToESP[client] = true;
			EnableESP(client);
		}
		else
		{
			// Otherwise disable it (why? because ConVarValue was changed!)
			IsAllowedToESP[client] = false;
			DisableESP(client);
		}
	}
}

/* OnClientDisconnect()
 *
 * When a client disconnects from the server.
 * --------------------------------------------------------------------------------------- */
public OnClientDisconnect(client)
{
	// Since bots also can disconnect - make sure disconnected clients is not bots!
	if (IsValidClient(client))
	{
		DisableESP(client);
		IsAllowedToESP[client] = false;
	}
}

/* OnPlayerSpawn()
 *
 * Called after a player spawns.
 * --------------------------------------------------------------------------------------- */
public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Make sure client is valid in all cases
	if (IsValidClient(client) == true
	&& IsAllowedToESP[client] == true)
	{
		EnableESP(client);
	}
}

/* OnPlayerDeath()
 *
 * Called after a player dies.
 * --------------------------------------------------------------------------------------- */
public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get client index from event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If client was used ESP, make sure to disable it now
	if (IsValidClient(client) == true
	&& IsAllowedToESP[client] == true)
	{
		DisableESP(client);
	}
}

/* OnTeamChange()
 *
 * Called after a player changes his team.
 * --------------------------------------------------------------------------------------- */
public OnTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// Same here, but also check if player changed team to spectator
	if (IsValidClient(client) == true
	&& IsAllowedToESP[client] == true
	&& GetEventInt(event, "team") <= TEAM_SPECTATOR)
	{
		EnableESP(client);
	}
}

/* EnableESP()
 *
 * Enables ESP for specified client.
 * --------------------------------------------------------------------------------------- */
EnableESP(client)
{
	// Magic stuff
	IsUsingESP[client] = true;
	SendConVarValue(client, mp_teammates_are_enemies, "1");
}

/* DisableESP()
 *
 * Disables ESP for specified client.
 * --------------------------------------------------------------------------------------- */
DisableESP(client)
{
	// Client is no longer used ESP
	IsUsingESP[client] = false;
	SendConVarValue(client, mp_teammates_are_enemies, "0");
}

/* IsValidClient()
 *
 * Checks if a client is valid.
 * --------------------------------------------------------------------------------------- */
bool:IsValidClient(client) return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client)) ? true : false;