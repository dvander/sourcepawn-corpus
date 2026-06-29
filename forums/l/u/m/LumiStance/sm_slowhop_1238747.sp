/* sm_slowhop.sp
Name: Slow Hop
Author: LumiStance
Date: 2010 - 07/15

Description:
	Limits players horizontal speed after every jump. The objective is to reduce the number of
	'speed hacker' complaints you receive.  This plugin evaluates a player's velocity one tenth
	of a second after every jump.  If the magnitude of the x and y velocity vectors exceeds the
	configurable limit, then the x and y velocity vectors are scaled down to the limit.

	Servers using this mod: http://www.game-monitor.com/search.php?vars=sm_slowhop_version

Suggest limits:
	250 First Jump Speed stock CS:S
	375 First Jump Speed with sumguy14 Bunny Hop Plugin
	400 to allow fun speeds

Background:
	See http://en.wikipedia.org/wiki/Bunny_hopping#In_Quake_engine_and_GoldSrc_engine_games
	Inspired by players complaining about 'Speed Hackers'
	Uses different method than BunnyStopper by Bullet.
		BunnyStopper temporarily modifies players gravity.
		See http://forums.alliedmods.net/showthread.php?t=84735
	Uses TeleportEntity, as noted in Bunny Hop by Fredd (suggested by bl4nk).
		See http://forums.alliedmods.net/showthread.php?t=67988
	Tested with BunnyHop [V1.0.1] by sumguy14
		See http://forums.alliedmods.net/showthread.php?t=57900

ToDo:
	* Option to limit Z axis velocity

Files:
	cstrike/addons/sourcemod/plugins/sm_slowhop.smx
	cstrike/cfg/sourcemod/slowhop.cfg

Configuration Variables (Change in dmlite.cfg):
	sm_slowhop_limit - Maximum velocity a play is allowed when jumping. 0 Disables limiting. (Default: "250.0")

Changelog:
	0.2 <-> 2010 - 07/15 LumiStance
		Updated code to scale speed only if it needs scaled down
		Change default limit
	0.1 <-> 2010 - 07/14 LumiStance
		Public Beta Release
		Added Plugin Info and Version Cvar
	null <-> 2010 - 07/09 LumiStance
		Initial Coding and Testing
*/

#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Plugin definitions
#define PLUGIN_VERSION "0.2-lm"
public Plugin:myinfo =
{
	name = "Slow Hop",
	author = "LumiStance",
	description = "Limits players speed after every jump",
	version = PLUGIN_VERSION,
	url = "http://srcds.lumistance.com/"
};

// Console Variables
new Handle:g_ConVar_Limit;
// Configuration
new Float:g_VelocityLimit = 375.0;

public OnPluginStart()
{
	// Specify console variables used to configure plugin
	g_ConVar_Limit = CreateConVar("sm_slowhop_limit", "375.0", "Maximum velocity a play is allowed when jumping. 0 Disables limiting.", FCVAR_PLUGIN|FCVAR_SPONLY);
	AutoExecConfig(true, "slowhop");

	// Version of plugin - Visible to game-monitor.com - Don't store in configuration file - Force correct value
	SetConVarString(
		CreateConVar("sm_slowhop_version", PLUGIN_VERSION, "[SM] Slow Hop Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD),
		PLUGIN_VERSION);

	// Event Hooks
	HookConVarChange(g_ConVar_Limit, Event_CvarChange);
	HookEvent("player_jump", Event_PlayerJump);
}

// Synchronize Cvar Cache after configuration loaded
public OnConfigsExecuted()
{
	RefreshCvarCache();
}

// Synchronize Cvar Cache when change made
public Event_CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	RefreshCvarCache();
}

stock RefreshCvarCache()
{
	g_VelocityLimit = GetConVarFloat(g_ConVar_Limit);
}

// Player Jumped - Check velocity after delay
public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_VelocityLimit)
		CreateTimer(0.1, Event_PostJump, GetClientOfUserId(GetEventInt(event, "userid")));
}

// Make our adjustment after other plugins
public Action:Event_PostJump(Handle:timer, any:client_index)
{
	// Get present velocity vectors
	decl Float:vVel[3];
	GetEntPropVector(client_index, Prop_Data, "m_vecVelocity", vVel);

	// Determine how much each vector must be scaled for the magnitude to equal the limit
	// scale = limit / (vx^2 + vy^2)^0.5)
	// Derived from Pythagorean theorem, where the hypotenuse represents the magnitude of velocity,
	// and the two legs represent the x and y velocity components.
	// As a side effect, velocity component signs are also handled.
	new Float:scale = FloatDiv(g_VelocityLimit, SquareRoot( FloatAdd( Pow(vVel[0], 2.0), Pow(vVel[1], 2.0) ) ) );

	// A scale < 1 indicates a magnitude > limit
	if (scale < 1.0)
	{
		// Reduce each vector by the appropriate amount
		vVel[0] = FloatMul(vVel[0], scale);
		vVel[1] = FloatMul(vVel[1], scale);

		// Impart new velocity onto player
		TeleportEntity(client_index, NULL_VECTOR, NULL_VECTOR, vVel);
	}
}
