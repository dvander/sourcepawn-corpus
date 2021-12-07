/**
 * vim: set ts=4 :
 * =============================================================================
 * No First Blood by J-Factor
 * Disables First Blood in arena
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>

/* Constants ############################################################### */
#define PLUGIN_VERSION "0.1"

// Text Color -----------------------------------------------------------------

// Plugin name
#define C_PLUGIN  0x05
// Normal text
#define C_NORMAL  0x01

// Player Condition  ----------------------------------------------------------
#define PLAYER_FIRSTBLOOD (1 << 11)

/* Global Variables ######################################################## */

// Convars --------------------------------------------------------------------
new Handle:cvPluginEnable = INVALID_HANDLE;

// General --------------------------------------------------------------------
new bool:pluginEnabled = false;

/* Plugin info ############################################################# */

public Plugin:myinfo =
{
	name = "No First Blood",
	author = "J-Factor",
	description = "Disables First Blood in Arena",
	version = PLUGIN_VERSION,
	url = "http://j-factor.com/"
};

/* Events ################################################################## */

/* OnPluginStart()
**
** When the plugin is loaded.
** ------------------------------------------------------------------------- */
public OnPluginStart()
{
	CreateConVar("sm_nofirstblood_version", PLUGIN_VERSION, "No First Blood version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvPluginEnable = CreateConVar("sm_nofirstblood_enable", "1", "Enables No First Blood", FCVAR_PLUGIN);
	HookConVarChange(cvPluginEnable, Event_EnableChange);
	
	// Initialize
	Initialize(GetConVarBool(cvPluginEnable));
}

/* Event_EnableChange()
**
** When the plugin is enabled/disabled.
** ------------------------------------------------------------------------- */
public Event_EnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Initialize(strcmp(newValue, "1") == 0);
}

/* Event_PlayerDeath()
**
** When a player dies.
** ------------------------------------------------------------------------- */
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (pluginEnabled) {
		new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
		new cond = GetEntProp(killer, Prop_Send, "m_nPlayerCond");
		
		SetEntProp(killer, Prop_Send, "m_nPlayerCond", cond & ~PLAYER_FIRSTBLOOD);
	}
	
	return Plugin_Continue;
}

/* Functions ############################################################### */

/* Initialize()
**
** Initializes the plugin.
** ------------------------------------------------------------------------- */
public Initialize(bool:enable)
{
	if (enable && !pluginEnabled) {
		// Enable
		HookEvent("player_death", Event_PlayerDeath);
		
		pluginEnabled = true;
		PrintToChatAll("%c[SM] %cNo First Blood%c has been enabled!", C_NORMAL, C_PLUGIN, C_NORMAL);
	} else if (!enable && pluginEnabled) {
		// Disable
		UnhookEvent("player_death", Event_PlayerDeath);
		
		pluginEnabled = false;
		PrintToChatAll("%c[SM] %cNo First Blood%c has been disabled!", C_NORMAL, C_PLUGIN, C_NORMAL);
	}
}