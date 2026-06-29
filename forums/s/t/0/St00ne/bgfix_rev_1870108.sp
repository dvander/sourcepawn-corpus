/**
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

#include <cstrike>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "2.1"

new Handle:bgfix_enabled;

public Plugin:myinfo =
{
	name = "bgfix",
	author = "St00ne",
	description = "Fix for mg_big_city, so that players won't get killed by the vehicules that they are driving. Suitable for many other maps.",
	version = PLUGIN_VERSION,
	url = "http://www.esc90.fr"
}

public OnPluginStart()
{
	new Handle:version_cvar = CreateConVar("sm_bgfix_version", PLUGIN_VERSION, "Version of bgfix", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_PRINTABLEONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(version_cvar, PLUGIN_VERSION, false, false);
	bgfix_enabled = CreateConVar("sm_bgfix_enabled", "1", "Enables/disables all features of the plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	if (GetConVarInt(bgfix_enabled) == 1)
	{
		PrintToChat(client, "Plugin bgfix by St00ne enabled: protection against world damages activated.");
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (GetConVarInt(bgfix_enabled) == 1)
	{
		if (damagetype & DMG_CRUSH)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/**END**/