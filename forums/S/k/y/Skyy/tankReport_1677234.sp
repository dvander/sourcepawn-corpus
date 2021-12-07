#define ZOMBIECLASS_TANK		8

#define PLUGIN_VERSION			"1.1c"

#define CVAR_SHOW				FCVAR_NOTIFY | FCVAR_PLUGIN
#define CVAR_HIDE				~FCVAR_NOTIFY | FCVAR_PLUGIN

#include <sourcemod>

#include "left4downtown.inc"

new Handle:displayType;
new Handle:Logging;

// - Attacker, Victim
new damageReport[MAXPLAYERS + 1][MAXPLAYERS + 1];

// stored when a tank player spawns, in case a plugin is altering the
// health value, so percentages can be properly calculated
new startHealth[MAXPLAYERS + 1];
new class[MAXPLAYERS + 1];

public Plugin:myinfo = {
	name = "Tank Damage Reporter",
	author = "",
	description = "Displays Damage Information on Tank Death.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=181151"
}

public OnPluginStart()
{
	CreateConVar("tdr_version", PLUGIN_VERSION, "plugin version.", CVAR_SHOW);

	displayType					= CreateConVar("tdr_display_type","1","0 - Displays tank damage info to players privately. 1 - Displays all information publicly.", CVAR_SHOW);
	Logging						= CreateConVar("tdr_logging","1","whether or not to enable logging.", CVAR_SHOW);
	
	AutoExecConfig(true, "tdr_config");

	//Database_OnPluginStart();
	// Will add support for printing to the web

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("tank_killed", Event_TankKilled);
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
}

public OnClientPostAdminCheck(client)
{
	if (client != 0 && !IsFakeClient(client))
	{
		EC_OnClientPostAdminCheck(client);
	}
}

#include			"tdr/events_damage.sp"
#include			"tdr/events_connect.sp"
#include			"tdr/wrappers.sp"